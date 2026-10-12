import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/presentation/scene_beat_editor.dart';

/// WCAG 2.2 SC 2.4.3 (Focus Order) contract for [SceneBeatEditor].
///
/// This is a non-screen focus surface (`lib/features/story/presentation/
/// scene_beat_editor.dart`), not a `*_screen.dart` route. It is audited here
/// because the reorderable beat list is the only keyboard-reachable editor for
/// scene beats and its traversal was never locked.
///
/// Measured probe baseline (viewport 1536x1024, dpr 1.0, Tab pressed until a
/// focus rect repeats):
/// * 3 beats -> exactly 3 stops, one per beat, in list order. Each stop is the
///   trailing delete `IconButton` (rect 40x40 at left=1464; the `Icon` inside
///   is 24x24 at left=1472, so the stop lands on the button, not the glyph).
///   Tops are 20 -> 100 -> 180 (80px pitch), left edge identical.
/// * The reorder drag handles are `ReorderableDelayedDragStartListener`
///   (long-press/pointer) and are NOT keyboard stops: 3 handles exist but add
///   zero Tab stops.
/// * 1 beat -> 1 stop; 0 beats -> 0 affordance stops (only the root focus
///   scope is reachable). The empty state adds no focusable affordance.
/// * No `Tooltip` is present; the delete buttons expose no accessible name
///   (a 4.1.2 name-role-value observation, reported separately, not part of
///   this 2.4.3 contract).
const Size _viewport = Size(1536, 1024);

SceneBeatEditorItem _beat(int i) => SceneBeatEditorItem(
  id: 'b$i',
  content: 'Beat $i',
  beatType: 'setup',
  startSecond: (i - 1) * 5.0,
  durationSeconds: 5.0,
);

/// Label a focus stop by the first non-`Icon` [Text] of its nearest ancestor
/// [ListTile] (the leading start-second string), which uniquely identifies the
/// beat and is orderable.
String _labelOf(BuildContext context) {
  final element = context as Element;
  Element? tile;
  element.visitAncestorElements((candidate) {
    if (candidate.widget is ListTile) {
      tile = candidate;
      return false;
    }
    return true;
  });
  var label = '';
  void visit(Element node) {
    if (label.isNotEmpty) return;
    final widget = node.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    node.visitChildren(visit);
  }

  visit(tile ?? element);
  return label.isEmpty ? 'widget:${element.widget.runtimeType}' : label;
}

({String label, Rect rect, Type widget})? _currentStop() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final object = context.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (
    label: _labelOf(context),
    rect: rect,
    widget: context.widget.runtimeType,
  );
}

/// True when the focused context sits inside a real interactive affordance
/// (button/field). The bare root focus scope that Flutter keeps reachable is
/// not an affordance and must not be counted as a Tab stop.
bool _isAffordance(BuildContext context) {
  var found = false;
  (context as Element).visitAncestorElements((candidate) {
    final widget = candidate.widget;
    if (widget is IconButton ||
        widget is ButtonStyleButton ||
        widget is InkWell ||
        widget is InkResponse ||
        widget is TextField) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

Future<List<({String label, Rect rect, Type widget})>> _stops(
  WidgetTester tester,
) async {
  final stops = <({String label, Rect rect, Type widget})>[];
  final seen = <String>{};
  for (var i = 0; i < 16; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) break;
    final key =
        '${stop.rect.left}|${stop.rect.top}|'
        '${stop.rect.width}|${stop.rect.height}';
    if (!seen.add(key)) break;
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null || !_isAffordance(context)) continue;
    stops.add(stop);
  }
  return stops;
}

Rect _rectOf(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _pump(WidgetTester tester, List<SceneBeatEditorItem> beats) async {
  tester.view.physicalSize = _viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SceneBeatEditor(
          beats: beats,
          onReordered: (_) {},
          onDelete: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  group('SceneBeatEditor — kontrak focus order 2.4.3', () {
    testWidgets('1. tiga beat menghasilkan tiga stop dengan urutan baca', (
      tester,
    ) async {
      await _pump(tester, [for (var i = 1; i <= 3; i++) _beat(i)]);
      expect(find.byType(IconButton), findsNWidgets(3));
      final stops = await _stops(tester);
      expect(
        stops.map((stop) => stop.label).toList(),
        <String>['00.0', '05.0', '10.0'],
        reason:
            'Tab must walk the three beats in list order; the label is the '
            'leading start-second text of each beat row.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. setiap stop ber-rect non-zero, menumpuk atas-ke-bawah', (
      tester,
    ) async {
      await _pump(tester, [for (var i = 1; i <= 3; i++) _beat(i)]);
      final stops = await _stops(tester);
      expect(stops, hasLength(3));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Every focus stop must have a non-zero focus area.',
      );
      expect(
        stops[1].rect.top,
        greaterThan(stops[0].rect.top),
        reason: 'Focus must move top-to-bottom down the beat list.',
      );
      expect(
        stops[2].rect.top,
        greaterThan(stops[1].rect.top),
        reason: 'Focus must continue top-to-bottom across all three beats.',
      );
      expect(
        stops.map((stop) => stop.rect.left).toSet(),
        hasLength(1),
        reason: 'All trailing delete buttons share one left edge.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. tiap stop mendarat tepat pada tombol delete beat-nya', (
      tester,
    ) async {
      await _pump(tester, [for (var i = 1; i <= 3; i++) _beat(i)]);
      // The keyboard stop lands on the button's inner focus target (40x40)
      // inside the 48x48 IconButton box. Assert the stop is contained in the
      // matching button and shares its centre, which uniquely maps each stop
      // to a beat row.
      final buttonRects = <Rect>[
        for (var i = 0; i < 3; i++)
          _rectOf(tester, find.byType(IconButton).at(i)),
      ];
      final stops = await _stops(tester);
      expect(stops, hasLength(3));
      for (var i = 0; i < 3; i++) {
        final button = buttonRects[i];
        expect(
          button.contains(stops[i].rect.center),
          isTrue,
          reason:
              'Stop $i must land inside the delete button of beat ${i + 1} '
              '(index order == visual top-to-bottom order).',
        );
        expect(
          stops[i].rect.center,
          button.center,
          reason: 'Stop $i must be centred on its delete button.',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Tab setelah beat terakhir kembali ke beat pertama', (
      tester,
    ) async {
      await _pump(tester, [for (var i = 1; i <= 3; i++) _beat(i)]);
      final stops = await _stops(tester);
      expect(stops, hasLength(3));
      // _stops berhenti tepat saat rect berulang -> fokus sudah kembali ke
      // tombol delete beat pertama dengan rect sama.
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, '00.0');
      expect(wrapped.rect, stops.first.rect);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. drag handle pointer-only tidak menambah stop keyboard', (
      tester,
    ) async {
      await _pump(tester, [for (var i = 1; i <= 3; i++) _beat(i)]);
      expect(
        find.byType(ReorderableDelayedDragStartListener),
        findsNWidgets(3),
        reason: 'Each beat exposes one pointer drag handle.',
      );
      final stops = await _stops(tester);
      expect(
        stops,
        hasLength(3),
        reason:
            'Drag handles are ReorderableDelayedDragStartListener (long-press '
            'pointer) and must not become Tab stops.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. satu beat hanya menyisakan satu stop', (tester) async {
      await _pump(tester, [_beat(1)]);
      final stops = await _stops(tester);
      expect(stops, hasLength(1));
      expect(stops.single.label, '00.0');
      expect(stops.single.rect.width, greaterThan(0));
      expect(stops.single.rect.height, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('7. daftar kosong tidak menyisakan stop affordance', (
      tester,
    ) async {
      await _pump(tester, const <SceneBeatEditorItem>[]);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
      final stops = await _stops(tester);
      expect(
        stops,
        isEmpty,
        reason:
            'An empty beat list has no focusable affordance; only the root '
            'focus scope is reachable, which is not an affordance stop.',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
