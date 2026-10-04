import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinematic_production/presentation/cinematic_production_workspace_screen.dart';

/// WCAG 2.2 A / SC 2.4.3 (Focus Order) contract for
/// [ProductionValidationCenterScreen].
///
/// Measured probe baseline (viewport 1536x1024, dpr 1.0, Tab pressed until a
/// focus rect repeats):
/// * route pushed + 2 issues -> 2 stops:
///   `Back@8,8 40x40` -> refresh `@1492,8 40x40` -> repeat `Back`.
/// * route pushed + 0 issues -> 2 stops (`Back`, refresh): the empty-state
///   `ListTile('No production issues found.')` has no `onTap` and adds no
///   tab stop.
/// * no parent route (screen is home) + 2 issues -> 1 stop (refresh): the
///   `Back` affordance comes from the pushed route, not from the screen.
///
/// The issue rows (`ListTile` without `onTap`) are never focusable in any
/// variant: adding issues changes no stop count.
const Size _viewport = Size(1536, 1024);

class _Stop {
  const _Stop(this.label, this.rect);

  final String label;
  final Rect rect;
}

Future<List<_Stop>> _collectStops(
  WidgetTester tester, {
  required bool pushRoute,
  required List<ProductionValidationIssue> issues,
}) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final screen = ProductionValidationCenterScreen(
    issues: issues,
    onRefresh: () {},
  );
  if (pushRoute) {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => screen)),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  } else {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  final stops = <_Stop>[];
  final seen = <String>[];
  for (var i = 0; i < 25; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = tester.binding.focusManager.primaryFocus;
    final renderObject = node?.context?.findRenderObject();
    Rect? rect;
    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    }
    if (rect == null) continue;
    final stop = _Stop(_labelFor(node), rect);
    final key = '${stop.label}@${stop.rect}';
    if (seen.contains(key)) break;
    seen.add(key);
    stops.add(stop);
  }
  return stops;
}

List<String> _labelsOf(List<_Stop> stops) =>
    stops.map((stop) => stop.label).toList();

void _expectRectsInViewport(List<_Stop> stops) {
  for (final stop in stops) {
    expect(stop.rect.width, greaterThan(0), reason: stop.label);
    expect(stop.rect.height, greaterThan(0), reason: stop.label);
    expect(stop.rect.width, lessThanOrEqualTo(_viewport.width));
    expect(stop.rect.height, lessThanOrEqualTo(_viewport.height));
    expect(stop.rect.left, greaterThanOrEqualTo(0), reason: stop.label);
    expect(stop.rect.top, greaterThanOrEqualTo(0), reason: stop.label);
    expect(stop.rect.right, lessThanOrEqualTo(_viewport.width));
    expect(stop.rect.bottom, lessThanOrEqualTo(_viewport.height));
  }
}

const _twoIssues = <ProductionValidationIssue>[
  ProductionValidationIssue(
    title: 'Missing thumbnail',
    detail: 'Shot 12 has no hero render.',
    severity: ProductionValidationSeverity.error,
  ),
  ProductionValidationIssue(
    title: 'Stale reference',
    detail: 'Wardrobe sheet points at an old path.',
    severity: ProductionValidationSeverity.warning,
  ),
];

void main() {
  testWidgets('route with two issues: 2 stops Back -> refresh', (tester) async {
    final stops = await _collectStops(
      tester,
      pushRoute: true,
      issues: _twoIssues,
    );

    expect(_labelsOf(stops), <String>['Back', '<icon-button>']);
    _expectRectsInViewport(stops);

    // Back is the top-left route affordance.
    expect(stops[0].rect.left, lessThanOrEqualTo(16));
    expect(stops[0].rect.top, lessThanOrEqualTo(16));

    // Refresh action sits in the AppBar's right half, on the same top row.
    expect(stops[1].rect.left, greaterThan(_viewport.width / 2));
    expect(stops[1].rect.top, stops[0].rect.top);

    // Left-to-right order: Back is left of the refresh action.
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));

    // The issue rows are present but never focusable.
    expect(find.text('Missing thumbnail'), findsOneWidget);
    expect(find.text('2 validation issue(s)'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'route with zero issues: still 2 stops, empty state not focusable',
    (tester) async {
      final stops = await _collectStops(
        tester,
        pushRoute: true,
        issues: const [],
      );

      expect(_labelsOf(stops), <String>['Back', '<icon-button>']);
      _expectRectsInViewport(stops);
      expect(stops[0].rect.left, lessThanOrEqualTo(16));
      expect(stops[1].rect.left, greaterThan(_viewport.width / 2));
      expect(stops[1].rect.top, stops[0].rect.top);

      // Empty-state card renders but adds no tab stop.
      expect(find.text('No production issues found.'), findsOneWidget);
      expect(find.text('0 validation issue(s)'), findsOneWidget);
      expect(stops.length, 2);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('screen without a parent route: 1 stop refresh only', (
    tester,
  ) async {
    final stops = await _collectStops(
      tester,
      pushRoute: false,
      issues: _twoIssues,
    );

    expect(_labelsOf(stops), <String>['<icon-button>']);
    _expectRectsInViewport(stops);
    expect(stops[0].rect.left, greaterThan(_viewport.width / 2));
    expect(_labelsOf(stops), isNot(contains('Back')));

    expect(tester.takeException(), isNull);
  });
}

/// Resolves the accessible label of the currently focused element: the
/// focused element itself or an ancestor carrying a label
/// (IconButton.tooltip, Tooltip.message, Text). Falls back to `<icon-button>`
/// for an icon-only control, then to `<no-text>`.
String _labelFor(FocusNode? node) {
  final context = node?.context;
  if (context == null) return '<no-focus>';
  var sawIconish = false;

  void visit(Element element, void Function(String) assign) {
    final widget = element.widget;
    if (widget is IconButton) {
      sawIconish = true;
      final tip = widget.tooltip;
      if (tip != null && tip.isNotEmpty) {
        assign(tip);
        return;
      }
    } else if (widget is Tooltip && (widget.message ?? '').isNotEmpty) {
      assign(widget.message!);
      return;
    } else if (widget is Icon) {
      sawIconish = true;
    } else if (widget is Text && (widget.data ?? '').trim().isNotEmpty) {
      assign(widget.data!.trim());
      return;
    }
    element.visitChildren((child) => visit(child, assign));
  }

  var label = '?';
  visit(context as Element, (value) {
    if (label == '?') label = value;
  });
  if (label == '?') {
    Element? cursor = context;
    while (cursor != null && label == '?') {
      final widget = cursor.widget;
      if (widget is IconButton) {
        sawIconish = true;
        final tip = widget.tooltip;
        if (tip != null && tip.isNotEmpty) label = tip;
      } else if (widget is Tooltip && (widget.message ?? '').isNotEmpty) {
        label = widget.message!;
      } else if (widget is Text && (widget.data ?? '').trim().isNotEmpty) {
        label = widget.data!.trim();
      }
      Element? ancestor;
      cursor.visitAncestorElements((next) {
        ancestor = next;
        return false;
      });
      cursor = ancestor;
    }
  }
  if (label == '?') label = sawIconish ? '<icon-button>' : '<no-text>';
  return label;
}
