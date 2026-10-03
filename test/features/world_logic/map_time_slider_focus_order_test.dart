// Focus Order contract for MapTimeSliderView (WCAG 2.2 SC 2.4.3).
//
// Locks the deterministic keyboard traversal of the time-slider control
// cluster: slider -> 8 key buttons -> per-layer chip plus its delete button,
// then wrap. Facts below were measured with a temporary probe at 1536x1024 and
// 390x844 (dpr 1.0) and are recorded in
// docs/evidence/wcag-2.2-audit-login-screen-2026-09-30.md.
//
// Production code is unchanged by this test: it is an audit lock, not a fix.
//
// Measured labels note: a layer chip's delete affordance is rendered by the
// Material chip internals as an InkWell (not an IconButton), so it is detected
// as `delete:` by the absence of a chip-button onTap and the 18x18 icon-sized
// focus rect.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

import "package:void_scriptor/features/world_logic/domain/historical_layer_resolver.dart";
import "package:void_scriptor/features/world_logic/domain/temporal_map_state.dart";
import "package:void_scriptor/features/world_logic/presentation/map_time_slider.dart";

/// One measured keyboard stop.
typedef FocusStop = ({String label, Rect rect});

const int kExpectedStopCount = 15;

/// Traversal measured at 1536x1024. Identical in stop count and order at
/// 390x844; only geometry differs because the key row wraps there.
const List<String> kExpectedWideOrder = <String>[
  "slider:map-time-slider",
  "key:map-time-key-advanceSmall",
  "key:map-time-key-retreatSmall",
  "key:map-time-key-advanceBig",
  "key:map-time-key-retreatBig",
  "key:map-time-key-jumpStart",
  "key:map-time-key-jumpEnd",
  "key:map-time-key-nextKeyTick",
  "key:map-time-key-prevKeyTick",
  "chip:map-time-layer-chip-0|Tick 0",
  "delete:map-time-layer-chip-0",
  "chip:map-time-layer-chip-40|Tick 40",
  "delete:map-time-layer-chip-40",
  "chip:map-time-layer-chip-80|Tick 80",
  "delete:map-time-layer-chip-80",
];

const List<String> _keyButtonLabels = <String>[
  "key:map-time-key-advanceSmall",
  "key:map-time-key-retreatSmall",
  "key:map-time-key-advanceBig",
  "key:map-time-key-retreatBig",
  "key:map-time-key-jumpStart",
  "key:map-time-key-jumpEnd",
  "key:map-time-key-nextKeyTick",
  "key:map-time-key-prevKeyTick",
];

const List<String> _chipTicks = <String>["0", "40", "80"];

/// Three enabled layers with three distinct key ticks (0, 40, 80).
TemporalMapState _sampleState() {
  return TemporalMapState(
    branchId: "prime",
    locations: const <TemporalLocation>[
      TemporalLocation(
        id: "loc-a",
        name: "A",
        validFrom: 0,
        validUntil: 100,
        controlHistory: <ControlChange>[
          ControlChange(id: "cc-a1", validFrom: 0, factionId: "fac-old"),
          ControlChange(id: "cc-a2", validFrom: 30, factionId: "fac-new"),
        ],
        statusHistory: <StatusChange>[
          StatusChange(
            id: "sc-a1",
            validFrom: 0,
            status: LocationStatus.active,
          ),
          StatusChange(
            id: "sc-a2",
            validFrom: 40,
            status: LocationStatus.ruined,
          ),
        ],
      ),
      TemporalLocation(id: "loc-b", name: "B", validFrom: 0, validUntil: 60),
      TemporalLocation(id: "loc-c", name: "C", validFrom: 80),
    ],
  );
}

MapTimeSliderController _controller() {
  final controller = MapTimeSliderController.forState(_sampleState());
  controller.enableLayerAt(0);
  controller.enableLayerAt(40);
  controller.enableLayerAt(80);
  return controller;
}

String _keyName(Key? key) {
  if (key is ValueKey<String>) {
    return key.value;
  }
  return key.toString();
}

String _firstText(Element root) {
  var text = "";
  void visit(Element element) {
    if (text.isNotEmpty) {
      return;
    }
    final widget = element.widget;
    if (widget is Icon) {
      return;
    }
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(root);
  return text;
}

/// Walks ancestors and returns the first element carrying an exact-type widget.
/// Flutter 3.44 exposes no `findAncestorElementOfExactType` helper, and
/// `findAncestorWidgetOfExactType` cannot hand back the owning Element that
/// `_firstText` needs, so the walk is explicit.
Element? _ancestorElementOfExactType<T extends Widget>(BuildContext context) {
  Element? found;
  context.visitAncestorElements((Element element) {
    if (found != null) {
      return false;
    }
    if (element.widget is T) {
      found = element;
      return false;
    }
    return true;
  });
  return found;
}

/// Classifies a focused node as slider / key button / layer chip / chip delete,
/// keyed on widget identity rather than pixel position so the contract stays
/// meaningful across viewport sizes.
///
/// The chip delete affordance needs a dedicated discriminator: Material renders
/// it as a nested InkWell carrying its own internally created FocusNode, and
/// that node is not reachable from the InputChip (`chip.focusNode` is null
/// unless the caller supplies one, so identity cannot separate the two stops).
///
/// Measured at 1536x1024: the chip label stop spans the full chip width
/// (138.6 wide, matching the 138.6-wide chip), while the delete stop is the
/// nested 18x18 icon box. Width is therefore the discriminator; height is NOT,
/// because the label stop (38) is also shorter than the chip (48).
String _describe(BuildContext focusContext) {
  final chipElement = _ancestorElementOfExactType<InputChip>(focusContext);
  if (chipElement != null) {
    final chip = chipElement.widget as InputChip;
    final chipObject = chipElement.findRenderObject();
    final focusObject = focusContext.findRenderObject();
    if (chipObject is RenderBox &&
        chipObject.hasSize &&
        focusObject is RenderBox &&
        focusObject.hasSize) {
      if (focusObject.size.width < chipObject.size.width - 0.5) {
        return "delete:${_keyName(chip.key)}";
      }
    }
    return "chip:${_keyName(chip.key)}|${_firstText(chipElement)}";
  }

  final iconButton = focusContext.findAncestorWidgetOfExactType<IconButton>();
  if (iconButton != null) {
    return "key:${_keyName(iconButton.key)}";
  }

  final slider = focusContext.findAncestorWidgetOfExactType<Slider>();
  if (slider != null) {
    return "slider:${_keyName(slider.key)}";
  }

  final element = focusContext as Element;
  return "widget:${element.widget.runtimeType}";
}

/// Presses Tab [presses] times and records the focus stop after each press.
Future<List<FocusStop>> _traverse(WidgetTester tester, int presses) async {
  final stops = <FocusStop>[];
  for (var i = 0; i < presses; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) {
      break;
    }
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _describe(context), rect: rect));
  }
  return stops;
}

Future<void> _pumpSlider(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MapTimeSliderView(controller: _controller())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    "2.4.3 focus order visits slider, key row, then each layer chip and delete",
    (tester) async {
      await _pumpSlider(tester, const Size(1536, 1024));

      final stops = await _traverse(tester, kExpectedStopCount);

      expect(
        stops.map((FocusStop stop) => stop.label).toList(),
        kExpectedWideOrder,
      );
    },
  );

  testWidgets("2.4.3 traversal wraps back to the first stop", (tester) async {
    await _pumpSlider(tester, const Size(1536, 1024));

    final stops = await _traverse(tester, kExpectedStopCount + 1);

    expect(stops, hasLength(kExpectedStopCount + 1));
    expect(stops.first.label, stops.last.label);
    expect(stops.first.rect, stops.last.rect);
  });

  testWidgets("2.4.3 every stop exposes a non-zero focus area", (tester) async {
    await _pumpSlider(tester, const Size(1536, 1024));

    final stops = await _traverse(tester, kExpectedStopCount);

    for (final stop in stops) {
      expect(
        stop.rect.width,
        greaterThan(0),
        reason: "stop ${stop.label} has zero width",
      );
      expect(
        stop.rect.height,
        greaterThan(0),
        reason: "stop ${stop.label} has zero height",
      );
    }
  });

  testWidgets(
    "2.4.3 rows are traversed top to bottom, left to right within a row",
    (tester) async {
      await _pumpSlider(tester, const Size(1536, 1024));

      final stops = await _traverse(tester, kExpectedStopCount);

      // Row 1: the slider sits above the key buttons.
      expect(stops[0].rect.top, lessThan(stops[1].rect.top));

      // Row 2: at desktop width all eight key buttons share one row and
      // advance strictly left to right. Do not assert a shared top: the probe
      // measured advance/retreat 1-tick at t=108 and the 10-tick pair at the
      // same row, so the row invariant is left-to-right only.
      for (var i = 1; i <= 7; i++) {
        expect(
          stops[i + 1].rect.left,
          greaterThan(stops[i].rect.left),
          reason: "key button $i must sit to the right of its predecessor",
        );
      }
      expect(stops[1].rect.top, stops[7].rect.top);

      // Row 3: layer chips advance left to right, each before its delete button.
      for (var i = 0; i < _chipTicks.length; i++) {
        final chipIndex = 9 + (i * 2);
        if (i > 0) {
          expect(
            stops[chipIndex].rect.left,
            greaterThan(stops[chipIndex - 2].rect.left),
            reason: "layer chip $i must sit right of the previous chip",
          );
        }
        expect(
          stops[chipIndex + 1].rect.left,
          greaterThan(stops[chipIndex].rect.left),
          reason: "delete button must follow its chip horizontally",
        );
        expect(stops[chipIndex].rect.top, stops[9].rect.top);
      }
    },
  );

  testWidgets(
    "2.4.3 narrow viewport keeps stop count and order while wrapping rows",
    (tester) async {
      await _pumpSlider(tester, const Size(390, 844));

      final stops = await _traverse(tester, kExpectedStopCount);

      expect(
        stops.map((FocusStop stop) => stop.label).toList(),
        kExpectedWideOrder,
      );
      expect(tester.takeException(), isNull);

      // Measured at 390x844: the key row wraps, so the last two key buttons
      // drop to a second line and the third layer chip wraps below the first.
      final keyTops = _keyButtonLabels
          .map((String label) => _topOf(stops, label))
          .toList();
      expect(keyTops[6], greaterThan(keyTops[0]));
      expect(keyTops[7], keyTops[6]);

      final thirdChip = _topOf(stops, "chip:map-time-layer-chip-80|Tick 80");
      expect(
        thirdChip,
        greaterThan(_topOf(stops, "chip:map-time-layer-chip-0|Tick 0")),
      );
    },
  );
}

double _topOf(List<FocusStop> stops, String label) {
  return stops.firstWhere((FocusStop stop) => stop.label == label).rect.top;
}
