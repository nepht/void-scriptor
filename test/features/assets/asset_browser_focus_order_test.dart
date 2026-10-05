import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/assets/domain/asset_search_query.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/assets/presentation/asset_browser_screen.dart';

/// WCAG 2.2 SC 2.4.3 (Focus Order) contract for [AssetBrowserScreen].
///
/// Probe (2026-10-04, viewport 1536x1024 @ dpr 1.0, constructor-injected
/// assets, no session/database) produced exactly nine focusable stops:
///
///   0 "Grid view"              (1396,   8,  40x40)
///   1 "List view"              (1444,   8,  40x40)
///   2 "Compact view"           (1492,   8,  40x40)
///   3 "Search everything..."   ( 64,  84, 1049x24)
///   4 "Favorites"              (1137,  77, 161x38)
///   5 "All types"              (1306,  72, 218x48)
///   6 "Qowner"                 ( 12, 148, 206x210)
///   7 "Void Sword"             (230, 148, 206x210)
///   8 "Create stand-alone asset" (1283, 952, 237x56)
///
/// The contract locks the stop count, the label sequence, non-zero focus
/// areas, and the toolbar left-to-right / top-to-bottom geometry so a
/// reordering regression fails loudly instead of passing silently.
///
/// Probe (2026-10-05, viewport 1536x1024 @ dpr 1.0, same fixture): the grid
/// pass above only ever traverses [AssetCard]. Tapping the `List view` and
/// `Compact view` toolbar controls re-renders the result area as
/// [AssetListTile] rows, a focus path that keeps the same nine labels but
/// changes the geometry to full-width stacked rows (1536x72 list,
/// 1536x48 compact, versus 206x210 grid cards). Both variants are locked
/// below so a broken view-mode switch cannot masquerade as a passing audit.
///
/// Icon-only controls resolve to their [Tooltip] message, [TextField] stops
/// to their hint text, and remaining stops to the first non-empty [Text]
/// descendant; a marker describing the widget runtime type is used when the
/// stop carries no text at all.
String assetBrowserFocusLabel(BuildContext ctx) {
  final root = ctx as Element;
  final tooltip = root.findAncestorWidgetOfExactType<Tooltip>();
  final tooltipMessage = tooltip?.message?.trim();
  if (tooltipMessage != null && tooltipMessage.isNotEmpty) {
    return tooltipMessage;
  }
  final field = root.findAncestorWidgetOfExactType<TextField>();
  final hint =
      field?.decoration?.hintText ?? field?.decoration?.labelText ?? '';
  if (hint.trim().isNotEmpty) return hint.trim();

  final queue = <BuildContext>[root];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final widget = current.widget;
    if (widget is Icon) continue;
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isNotEmpty) return data.trim();
    }
    current.visitChildElements(queue.add);
  }
  return '<non-text:${ctx.widget.runtimeType}>';
}

void main() {
  const assets = [
    SearchableAsset(
      id: 'qowner',
      projectId: 'p1',
      name: 'Qowner',
      type: AssetType.character,
      tags: {'void'},
      favorite: true,
    ),
    SearchableAsset(
      id: 'sword',
      projectId: 'p1',
      name: 'Void Sword',
      type: AssetType.weapon,
      tags: {'void', 'combat'},
    ),
  ];

  Future<List<({String label, Rect rect})>> collectStops(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AssetBrowserScreen(assets: assets)),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final stops = <({String label, Rect rect})>[];
    final seen = <String>{};
    for (var i = 0; i < 24; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final node = FocusManager.instance.primaryFocus;
      if (node == null) break;
      if (node.context?.widget is FocusScope) break;
      final ctx = node.context!;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) break;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
      if (!seen.add(key)) break;
      stops.add((label: assetBrowserFocusLabel(ctx), rect: rect));
    }
    return stops;
  }

  /// Same traversal, but activates one toolbar view mode first so the result
  /// area renders [AssetListTile] rows instead of [AssetCard] grid cards.
  Future<List<({String label, Rect rect})>> collectStopsInMode(
    WidgetTester tester,
    String modeTooltip,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AssetBrowserScreen(assets: assets)),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.byTooltip(modeTooltip));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final stops = <({String label, Rect rect})>[];
    final seen = <String>{};
    for (var i = 0; i < 24; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final node = FocusManager.instance.primaryFocus;
      if (node == null) break;
      if (node.context?.widget is FocusScope) break;
      final ctx = node.context!;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) break;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
      if (!seen.add(key)) break;
      stops.add((label: assetBrowserFocusLabel(ctx), rect: rect));
    }
    return stops;
  }

  const listModeLabels = <String>[
    'Grid view',
    'List view',
    'Compact view',
    'Search everything...',
    'Favorites',
    'All types',
    'Qowner',
    'Void Sword',
    'Create stand-alone asset',
  ];

  testWidgets('focus order: 9 stops left-to-right then top-to-bottom', (
    tester,
  ) async {
    final stops = await collectStops(tester);

    expect(tester.takeException(), isNull);
    expect(stops.map((s) => s.label).toList(), const <String>[
      'Grid view',
      'List view',
      'Compact view',
      'Search everything...',
      'Favorites',
      'All types',
      'Qowner',
      'Void Sword',
      'Create stand-alone asset',
    ], reason: 'WCAG 2.4.3 stop count and sequence');

    for (final stop in stops) {
      expect(
        stop.rect.width * stop.rect.height,
        greaterThan(0),
        reason: 'focus area of ${stop.label} must be non-zero',
      );
      expect(stop.rect.left, greaterThanOrEqualTo(0));
      expect(stop.rect.top, greaterThanOrEqualTo(0));
      expect(stop.rect.right, lessThanOrEqualTo(1536));
      expect(stop.rect.bottom, lessThanOrEqualTo(1024));
    }

    // View-mode toggles share the top strip and read left to right.
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(stops[1].rect.top, stops[2].rect.top);
    expect(
      stops[0].rect.left,
      lessThan(stops[1].rect.left),
      reason: 'view toggles stay in reading order (left to right)',
    );
    expect(
      stops[1].rect.left,
      lessThan(stops[2].rect.left),
      reason: 'view toggles stay in reading order (left to right)',
    );

    // The filter strip sits below the view strip and reads left to right.
    for (final index in const [3, 4, 5]) {
      expect(
        stops[index].rect.top,
        greaterThan(stops[2].rect.bottom),
        reason: 'filters are reached after the view toggles',
      );
    }
    expect(
      stops[3].rect.left,
      lessThan(stops[4].rect.left),
      reason: 'search field comes before the filter controls',
    );
    expect(
      stops[4].rect.left,
      lessThan(stops[5].rect.left),
      reason: 'favorite filter comes before the type filter',
    );

    // Asset cards follow the toolbar, reading left to right, then the
    // primary create action closes the traversal at the bottom.
    expect(stops[6].rect.top, greaterThan(stops[5].rect.bottom));
    expect(stops[6].rect.top, stops[7].rect.top);
    expect(
      stops[6].rect.left,
      lessThan(stops[7].rect.left),
      reason: 'cards read left to right',
    );
    expect(
      stops[8].rect.top,
      greaterThan(stops[7].rect.bottom),
      reason: 'bottom action is the last stop, below the card grid',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order: traversal wraps back to the first stop', (
    tester,
  ) async {
    final stops = await collectStops(tester);
    expect(
      stops,
      hasLength(9),
      reason: 'contract prerequisite for the wrap assertion',
    );
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(FocusManager.instance.primaryFocus!.hasFocus, isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));

  Future<void> expectStackedRows(
    WidgetTester tester, {
    required String modeTooltip,
    required double rowHeight,
  }) async {
    final stops = await collectStopsInMode(tester, modeTooltip);

    expect(tester.takeException(), isNull);
    expect(
      stops.map((s) => s.label).toList(),
      listModeLabels,
      reason: 'WCAG 2.4.3 stop count and sequence in $modeTooltip',
    );

    for (final stop in stops) {
      expect(
        stop.rect.width * stop.rect.height,
        greaterThan(0),
        reason: 'focus area of ${stop.label} must be non-zero',
      );
      expect(stop.rect.left, greaterThanOrEqualTo(0));
      expect(stop.rect.top, greaterThanOrEqualTo(0));
      expect(stop.rect.right, lessThanOrEqualTo(1536));
      expect(stop.rect.bottom, lessThanOrEqualTo(1024));
    }

    // The view toggles keep their left-to-right toolbar geometry.
    expect(stops[0].rect.top, stops[1].rect.top);
    expect(stops[1].rect.top, stops[2].rect.top);
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[1].rect.left, lessThan(stops[2].rect.left));

    // Filters sit under the toolbar, still reading left to right.
    for (final index in const [3, 4, 5]) {
      expect(stops[index].rect.top, greaterThan(stops[2].rect.bottom));
    }
    expect(stops[3].rect.left, lessThan(stops[4].rect.left));
    expect(stops[4].rect.left, lessThan(stops[5].rect.left));

    // The result rows are full-width list tiles stacked top-to-bottom.
    expect(
      stops[6].rect.top,
      greaterThan(stops[5].rect.bottom),
      reason: 'rows are reached after the filter strip',
    );
    for (final index in const [6, 7]) {
      final rect = stops[index].rect;
      expect(
        rect.width,
        1536,
        reason: '${stops[index].label} spans the full viewport width',
      );
      expect(
        rect.height,
        rowHeight,
        reason: '${stops[index].label} row height locks the list render path',
      );
      expect(rect.left, 0, reason: 'list rows are flush left');
      expect(
        stops[index - 1].rect.top,
        lessThan(rect.top),
        reason: 'list rows read top-to-bottom',
      );
    }

    // The primary action closes the traversal below the rows.
    expect(stops[8].rect.top, greaterThan(stops[7].rect.bottom));
  }

  testWidgets('focus order (list view): 9 stops, stacked full-width rows', (
    tester,
  ) async {
    await expectStackedRows(tester, modeTooltip: 'List view', rowHeight: 72);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order (compact view): 9 stops, stacked 48px rows', (
    tester,
  ) async {
    await expectStackedRows(tester, modeTooltip: 'Compact view', rowHeight: 48);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
