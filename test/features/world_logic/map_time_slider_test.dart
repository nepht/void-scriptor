// Sprint 110.21 - Map Time Slider & Historical Layers (widget).
//
// Widget tests covering the user-facing surface of MapTimeSliderView:
//   * time_slider renders currentTick and supports drag.
//   * historical_layers renders enabled layers with key tick labels.
//   * change_highlight renders a badge per LocationHighlight.
//   * legend renders a MapLegend entry list.
//   * keyboard_control exposes the MapTimeKey surface as IconButton
//     actions that invoke MapTimeSliderController.applyKey.

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "package:void_scriptor/features/world_logic/domain/historical_layer_resolver.dart";
import "package:void_scriptor/features/world_logic/domain/temporal_map_state.dart";
import "package:void_scriptor/features/world_logic/presentation/map_time_slider.dart";

TemporalMapState _sampleState() {
  return TemporalMapState(
    branchId: "prime",
    locations: const [
      TemporalLocation(
        id: "loc-a",
        name: "A",
        validFrom: 0,
        validUntil: 100,
        controlHistory: [
          ControlChange(id: "cc-a1", validFrom: 0, factionId: "fac-old"),
          ControlChange(id: "cc-a2", validFrom: 30, factionId: "fac-new"),
        ],
        statusHistory: [
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

Future<void> _pumpView(
  WidgetTester tester,
  MapTimeSliderController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: MapTimeSliderView(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("time_slider", () {
    testWidgets("renders the current tick label", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      expect(find.text("Tick 0"), findsOneWidget);
    });

    testWidgets("drag updates currentTick via onChanged", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      // Programmatically drive Slider.onChanged without gesture math.
      Slider sliderWidget = tester.widget<Slider>(slider);
      sliderWidget.onChanged!(40);
      sliderWidget.onChangeEnd!(40);
      await tester.pumpAndSettle();
      expect(c.currentTick, 40);
      expect(find.text("Tick 40"), findsOneWidget);
    });

    testWidgets("displays min and max anchors", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      expect(find.textContaining("0"), findsWidgets);
      expect(find.textContaining("100"), findsWidgets);
    });
  });

  group("historical_layers", () {
    testWidgets("renders enabled layer ticks as togglable chips", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(40);
      await _pumpView(tester, c);
      expect(find.byKey(const Key("map-time-layer-chip-0")), findsOneWidget);
      expect(find.byKey(const Key("map-time-layer-chip-40")), findsOneWidget);
    });

    testWidgets("tapping a layer chip disables it", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(40);
      await _pumpView(tester, c);
      expect(c.isLayerEnabledAt(40), isTrue);
      await tester.tap(find.byKey(const Key("map-time-layer-chip-40")));
      await tester.pumpAndSettle();
      expect(c.isLayerEnabledAt(40), isFalse);
    });

    testWidgets("shows empty-state hint when no layers enabled", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      expect(find.byKey(const Key("map-time-layers-empty")), findsOneWidget);
    });
  });

  group("change_highlight", () {
    testWidgets("renders highlight badge for current layer", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(40);
      c.seekTo(40);
      await _pumpView(tester, c);
      final badgeFinder = find.byKey(
        const Key("map-time-highlight-statusChange-loc-a"),
      );
      expect(badgeFinder, findsOneWidget);
      final Text badgeText = tester.widget<Text>(
        find.descendant(of: badgeFinder, matching: find.byType(Text)),
      );
      expect(badgeText.data, contains("ruined"));
    });

    testWidgets("renders appeared badge for newly active location", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(80);
      c.seekTo(80);
      await _pumpView(tester, c);
      expect(
        find.byKey(const Key("map-time-highlight-appeared-loc-c")),
        findsOneWidget,
      );
    });

    testWidgets("does not render highlight area when no layer enabled", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      expect(
        find.byKey(const Key("map-time-highlights-empty")),
        findsOneWidget,
      );
    });
  });

  group("legend", () {
    testWidgets("renders every MapLegend entry as a legend row", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      for (final entry in MapLegend.standard().entries) {
        expect(
          find.byKey(Key("map-time-legend-${entry.token}")),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(Key("map-time-legend-${entry.token}")),
            matching: find.text(entry.label),
          ),
          findsOneWidget,
        );
      }
    });
  });

  group("keyboard_control", () {
    testWidgets("advanceSmall button moves currentTick forward", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(40);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-advanceSmall")));
      await tester.pumpAndSettle();
      expect(c.currentTick, 41);
      expect(find.text("Tick 41"), findsOneWidget);
    });

    testWidgets("retreatSmall button moves currentTick back", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(40);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-retreatSmall")));
      await tester.pumpAndSettle();
      expect(c.currentTick, 39);
    });

    testWidgets("advanceBig button advances by 10", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(20);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-advanceBig")));
      await tester.pumpAndSettle();
      expect(c.currentTick, 30);
    });

    testWidgets("jumpStart snaps to minTick", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(50);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-jumpStart")));
      await tester.pumpAndSettle();
      expect(c.currentTick, 0);
    });

    testWidgets("jumpEnd snaps to maxTick", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(50);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-jumpEnd")));
      await tester.pumpAndSettle();
      expect(c.currentTick, 100);
    });

    testWidgets("nextKeyTick advances to next key tick", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(0);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-nextKeyTick")));
      await tester.pumpAndSettle();
      expect(c.currentTick, greaterThan(0));
      expect(c.keyTicks, contains(c.currentTick));
    });

    testWidgets("prevKeyTick retreats to previous key tick", (tester) async {
      final c = MapTimeSliderController.forState(_sampleState());
      c.seekTo(100);
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-prevKeyTick")));
      await tester.pumpAndSettle();
      expect(c.currentTick, lessThan(100));
      expect(c.keyTicks, contains(c.currentTick));
    });

    testWidgets("retreatSmall at boundary is a no-op (no crash)", (
      tester,
    ) async {
      final c = MapTimeSliderController.forState(_sampleState());
      await _pumpView(tester, c);
      await tester.tap(find.byKey(const Key("map-time-key-retreatSmall")));
      await tester.pumpAndSettle();
      expect(c.currentTick, 0);
      expect(tester.takeException(), isNull);
    });
  });

  group("integration", () {
    testWidgets("no RenderFlex overflow at 360px wide", (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(0);
      c.enableLayerAt(40);
      c.enableLayerAt(80);
      await _pumpView(tester, c);
      expect(tester.takeException(), isNull);
    });

    testWidgets("no RenderFlex overflow at 1024px wide", (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final c = MapTimeSliderController.forState(_sampleState());
      c.enableLayerAt(40);
      await _pumpView(tester, c);
      expect(tester.takeException(), isNull);
    });
  });
}
