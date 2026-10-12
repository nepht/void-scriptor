import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/workspace_layout/domain/workspace_tab.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/workspace_tab_bar.dart';

/// WCAG 2.2 - 2.4.3 Focus Order audit for the workspace tab bar.
///
/// Every tab exposes two independent affordances: the tab body (select) and a
/// trailing close button. A pointer user can aim at either; a keyboard user
/// must be able to reach both, in a predictable order, without the active tab
/// silently reordering the ring. This contract locks the traversal that the
/// mouse never has to think about.
///
/// Ground truth measured with a temporary tab-traversal probe on Flutter
/// 3.47.6, viewport 1536x1024, devicePixelRatio 1.0, three tabs
/// (Qowner / Dagger / The Void) with the SECOND tab active:
///
///   Tab 1 Qowner     L=0.0   T=0.0  W=180.0 H=36.0   (tab body)
///   Tab 2 close 'a'  L=150.0 T=6.0  W=22.0  H=22.0   (icon-only)
///   Tab 3 Dagger     L=181.0 T=0.0  W=180.0 H=36.0
///   Tab 4 close 'b'  L=331.0 T=6.0  W=22.0  H=22.0
///   Tab 5 The Void   L=362.0 T=0.0  W=180.0 H=36.0
///   Tab 6 close 'c'  L=512.0 T=6.0  W=22.0  H=22.0
///   Tab 7 wraps back to Qowner -> ring closed at 6 stops.
///
/// The ring follows declaration order (a, b, c) even though tab b is active:
/// activation is a visual state, not a traversal reorder. With no tabs the bar
/// exposes zero affordances (only the root focus scope is reachable).
///
/// Evidence: docs/evidence/wcag-2.2-audit-login-screen-2026-09-30.md

const Size _desktopViewport = Size(1536, 1024);
const int _maxStops = 14;
const double _tabWidth = 180;

const List<WorkspaceTab> _tabs = [
  WorkspaceTab(
    id: 'a',
    assetId: 'asset-a',
    assetType: AssetType.character,
    title: 'Qowner',
  ),
  WorkspaceTab(
    id: 'b',
    assetId: 'asset-b',
    assetType: AssetType.weapon,
    title: 'Dagger',
  ),
  WorkspaceTab(
    id: 'c',
    assetId: 'asset-c',
    assetType: AssetType.environment,
    title: 'The Void',
  ),
];

typedef _Stop = ({String label, Rect rect});

/// Human-readable label of the focused control: the first non-Icon Text in the
/// focused subtree, falling back to the widget type when icon-only.
String _focusLabel(BuildContext context) {
  var label = '';
  void visit(Element element) {
    if (label.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  return label.isEmpty ? 'widget:${context.widget.runtimeType}' : label;
}

/// Global focus rect of the currently focused control, in logical pixels.
Rect _focusRect() {
  final object = FocusManager.instance.primaryFocus?.context
      ?.findRenderObject();
  if (object is! RenderBox || !object.hasSize) return Rect.zero;
  return object.localToGlobal(Offset.zero) & object.size;
}

/// Walks the focus ring by Tab until it repeats a rect, returning every stop in
/// order. A repeated rect marks wrap-around, which is where the ring closes.
Future<List<_Stop>> _traceTabRing(WidgetTester tester) async {
  final stops = <_Stop>[];
  final seen = <String>{};
  for (var i = 0; i < _maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final rect = _focusRect();
    if (!seen.add('${rect.left}|${rect.top}|${rect.width}|${rect.height}')) {
      break;
    }
    stops.add((label: _focusLabel(context), rect: rect));
  }
  return stops;
}

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

Rect _rectOf(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

Rect _closeRect(WidgetTester tester, String id) =>
    _rectOf(tester, find.byKey(Key('close-tab-$id')));

/// Mounts the bar at the top-left of a full desktop viewport so that geometry
/// assertions compare against a stable origin.
Future<void> _pumpBar(
  WidgetTester tester, {
  List<WorkspaceTab> tabs = _tabs,
  String? activeTabId = 'b',
}) async {
  tester.view.physicalSize = _desktopViewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: WorkspaceTabBar(
            tabs: tabs,
            activeTabId: activeTabId,
            onSelect: (_) {},
            onClose: (_) {},
            onCloseOthers: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // Leave focus unscoped so the first Tab enters the ring from its start.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  group('WorkspaceTabBar focus order (WCAG 2.4.3)', () {
    testWidgets('each tab exposes a select body and a close affordance', (
      tester,
    ) async {
      await _pumpBar(tester);

      // Two interactive InkWells per tab: body + close.
      expect(find.byType(InkWell), findsNWidgets(_tabs.length * 2));
      for (final tab in _tabs) {
        expect(find.byKey(Key('close-tab-${tab.id}')), findsOneWidget);
      }
    });

    testWidgets('Tab order interleaves each tab body with its close button', (
      tester,
    ) async {
      await _pumpBar(tester);

      final stops = await _traceTabRing(tester);

      expect(stops.map((stop) => stop.label).toList(), <String>[
        'Qowner',
        'widget:Focus',
        'Dagger',
        'widget:Focus',
        'The Void',
        'widget:Focus',
      ]);
      expect(stops, hasLength(_tabs.length * 2));
    });

    testWidgets('the ring follows declaration order, not the active tab', (
      tester,
    ) async {
      // Tab b is active, yet the ring must still start at tab a.
      await _pumpBar(tester, activeTabId: 'b');

      final stops = await _traceTabRing(tester);
      final titles = <String>[stops[0].label, stops[2].label, stops[4].label];

      expect(titles, <String>['Qowner', 'Dagger', 'The Void']);
      expect(titles, isNot(<String>['Dagger', 'Qowner', 'The Void']));
    });

    testWidgets('every close stop lands on the matching close button', (
      tester,
    ) async {
      await _pumpBar(tester);

      final stops = await _traceTabRing(tester);
      expect(stops, hasLength(6));

      final closeStops = <Rect>[stops[1].rect, stops[3].rect, stops[5].rect];
      final expected = <Rect>[
        _closeRect(tester, 'a'),
        _closeRect(tester, 'b'),
        _closeRect(tester, 'c'),
      ];

      expect(closeStops, expected);
    });

    testWidgets('tabs run left to right and close sits right of its title', (
      tester,
    ) async {
      await _pumpBar(tester);

      final stops = await _traceTabRing(tester);
      expect(stops, hasLength(6));

      final bodies = <Rect>[stops[0].rect, stops[2].rect, stops[4].rect];
      final closes = <Rect>[stops[1].rect, stops[3].rect, stops[5].rect];

      // Tabs are laid out left to right in declaration order.
      expect(bodies[0].left, lessThan(bodies[1].left));
      expect(bodies[1].left, lessThan(bodies[2].left));

      // Within a tab the close affordance sits to the right of the body and
      // vertically overlaps the same row.
      for (var i = 0; i < bodies.length; i++) {
        expect(closes[i].left, greaterThan(bodies[i].left));
        expect(closes[i].top, lessThan(bodies[i].bottom));
        expect(closes[i].bottom, greaterThan(bodies[i].top));
      }

      // Tab bodies are uniform width, so the row reads as an even strip.
      for (final body in bodies) {
        expect(body.width, _tabWidth);
      }
    });

    testWidgets('every stop has a non-zero focus rect inside the viewport', (
      tester,
    ) async {
      await _pumpBar(tester);

      final stops = await _traceTabRing(tester);
      expect(stops, isNotEmpty);

      for (final stop in stops) {
        expect(stop.rect.width, greaterThan(0), reason: stop.label);
        expect(stop.rect.height, greaterThan(0), reason: stop.label);
        expect(stop.rect.left, greaterThanOrEqualTo(0), reason: stop.label);
        expect(stop.rect.top, greaterThanOrEqualTo(0), reason: stop.label);
        expect(
          stop.rect.right,
          lessThanOrEqualTo(_desktopViewport.width),
          reason: stop.label,
        );
        expect(
          stop.rect.bottom,
          lessThanOrEqualTo(_desktopViewport.height),
          reason: stop.label,
        );
      }
    });

    testWidgets('Shift+Tab unwinds the ring in reverse', (tester) async {
      await _pumpBar(tester);

      expect(
        (await _traceTabRing(tester)).map((stop) => stop.label).toList(),
        hasLength(6),
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      final backwards = <String>[];
      for (var i = 0; i < 3; i++) {
        await _shiftTab(tester);
        final context = FocusManager.instance.primaryFocus?.context;
        expect(context, isNotNull);
        backwards.add(_focusLabel(context!));
      }

      // Backwards traversal starts on the last stop and unwinds the ring.
      expect(backwards, <String>['widget:Focus', 'The Void', 'widget:Focus']);
    });

    testWidgets('focus never drops to null while traversing', (tester) async {
      await _pumpBar(tester);

      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.primaryFocus?.context,
          isNotNull,
          reason: 'Tab must never leave the ring without a target',
        );
      }

      expect(find.byType(WorkspaceTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty tab bar exposes no affordance stops', (tester) async {
      await _pumpBar(tester, tabs: const [], activeTabId: null);

      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(WorkspaceTabBar), findsOneWidget);

      final stops = await _traceTabRing(tester);

      // Only the root focus scope is reachable; no tab affordance exists.
      expect(stops, hasLength(1));
      expect(stops.single.label, startsWith('widget:'));
      expect(tester.takeException(), isNull);
    });
  });
}
