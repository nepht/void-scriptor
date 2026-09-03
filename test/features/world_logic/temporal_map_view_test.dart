// Sprint 110.21 -- Map Time Slider and Historical Layers.
//
// RED test for temporal map view atop TerritorialControlRegistry.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/territorial_control.dart";
import "package:void_scriptor/features/world_logic/domain/temporal_map_view.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart"
    show ValidityRange;

void main() {
  group("TemporalMapView", () {
    test("rejects asOfTick below the slider min", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      expect(
        () => TemporalMapView(
          registry: registry,
          asOfTick: -1,
          sliderMin: 0,
          sliderMax: 100,
          palette: const <String, String>{"c1": "#ff0000"},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("rejects asOfTick above the slider max", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      expect(
        () => TemporalMapView(
          registry: registry,
          asOfTick: 200,
          sliderMin: 0,
          sliderMax: 100,
          palette: const <String, String>{"c1": "#ff0000"},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("rejects slider min greater than max", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      expect(
        () => TemporalMapView(
          registry: registry,
          asOfTick: 0,
          sliderMin: 50,
          sliderMax: 10,
          palette: const <String, String>{"c1": "#ff0000"},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("keyboard control: negative step is rejected", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      expect(
        () => TemporalMapView(
          registry: registry,
          asOfTick: 0,
          sliderMin: 0,
          sliderMax: 100,
          step: -1,
          palette: const <String, String>{"c1": "#ff0000"},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("time slider exposes closed min/max and current asOfTick", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 42,
        sliderMin: 0,
        sliderMax: 100,
        palette: const <String, String>{"c1": "#ff0000"},
      );
      expect(view.asOfTick, 42);
      expect(view.sliderMin, 0);
      expect(view.sliderMax, 100);
      expect(view.sliderRange, 100);
    });

    test("historical layers aggregate every controller active at asOfTick", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>[
        const TerritorialControl(
          controllerId: "north",
          locationId: "loc_north",
          validity: ValidityRange(fromTick: 0, toTick: 50),
        ),
        const TerritorialControl(
          controllerId: "south",
          locationId: "loc_south",
          validity: ValidityRange(fromTick: 0),
        ),
        const TerritorialControl(
          controllerId: "east",
          locationId: "loc_east",
          validity: ValidityRange(fromTick: 60),
        ),
      ]);
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 30,
        sliderMin: 0,
        sliderMax: 100,
        palette: const <String, String>{
          "north": "#aabbcc",
          "south": "#112233",
          "east": "#445566",
        },
      );
      final layers = view.historicalLayers;
      expect(layers.map((l) => l.locationId), <String>[
        "loc_north",
        "loc_south",
      ]);
      expect(layers.first.controllerId, "north");
      expect(layers.first.validity.fromTick, 0);
      expect(layers.first.validity.toTick, 50);
    });

    test(
      "change highlight lists locations whose controller changed at boundary",
      () {
        final registry = TerritorialControlRegistry(<TerritorialControl>[
          const TerritorialControl(
            controllerId: "north",
            locationId: "loc_north",
            validity: ValidityRange(fromTick: 0, toTick: 19),
          ),
          const TerritorialControl(
            controllerId: "south",
            locationId: "loc_north",
            validity: ValidityRange(fromTick: 20, toTick: 60),
          ),
          const TerritorialControl(
            controllerId: "north",
            locationId: "loc_south",
            validity: ValidityRange(fromTick: 0),
          ),
        ]);
        final view = TemporalMapView(
          registry: registry,
          asOfTick: 20,
          sliderMin: 0,
          sliderMax: 100,
          palette: const <String, String>{
            "north": "#101010",
            "south": "#202020",
          },
        );
        final changes = view.changedLocations;
        expect(changes, <String>["loc_north"]);
      },
    );

    test("change highlight returns empty when no controller changed", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>[
        const TerritorialControl(
          controllerId: "north",
          locationId: "loc_north",
          validity: ValidityRange(fromTick: 0, toTick: 100),
        ),
      ]);
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 30,
        sliderMin: 0,
        sliderMax: 100,
        palette: const <String, String>{"north": "#101010"},
      );
      expect(view.changedLocations, isEmpty);
    });

    test("legend lists distinct controllers with their assigned color", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>[
        const TerritorialControl(
          controllerId: "north",
          locationId: "loc_north",
          validity: ValidityRange(fromTick: 0),
        ),
        const TerritorialControl(
          controllerId: "south",
          locationId: "loc_south",
          validity: ValidityRange(fromTick: 0),
        ),
      ]);
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 0,
        sliderMin: 0,
        sliderMax: 100,
        palette: const <String, String>{
          "north": "#aabbcc",
          "south": "#112233",
          "extra": "#999999",
        },
      );
      final legend = view.legend;
      expect(legend.length, 2);
      expect(legend["north"], "#aabbcc");
      expect(legend["south"], "#112233");
      expect(legend.containsKey("extra"), isFalse);
    });

    test("keyboard control: right arrow advances, clamped at max", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 95,
        sliderMin: 0,
        sliderMax: 100,
        step: 10,
        palette: const <String, String>{"c1": "#ff0000"},
      );
      expect(view.keyboardAdvance(TemporalSliderStep.right), 100);
      expect(view.keyboardAdvance(TemporalSliderStep.right), 100);
    });

    test("keyboard control: left arrow regresses, clamped at min", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 3,
        sliderMin: 0,
        sliderMax: 100,
        step: 5,
        palette: const <String, String>{"c1": "#ff0000"},
      );
      expect(view.keyboardAdvance(TemporalSliderStep.left), 0);
      expect(view.keyboardAdvance(TemporalSliderStep.left), 0);
    });

    test(
      "withTick returns a new view with updated tick and preserved bounds",
      () {
        final registry = TerritorialControlRegistry(<TerritorialControl>{});
        final view = TemporalMapView(
          registry: registry,
          asOfTick: 10,
          sliderMin: 0,
          sliderMax: 100,
          step: 5,
          palette: const <String, String>{"c1": "#ff0000"},
        );
        final moved = view.withTick(45);
        expect(identical(view, moved), isFalse);
        expect(moved.asOfTick, 45);
        expect(moved.sliderMin, 0);
        expect(moved.sliderMax, 100);
        expect(moved.step, 5);
        expect(view.asOfTick, 10);
      },
    );

    test("withTick rejects tick outside slider bounds", () {
      final registry = TerritorialControlRegistry(<TerritorialControl>{});
      final view = TemporalMapView(
        registry: registry,
        asOfTick: 10,
        sliderMin: 0,
        sliderMax: 100,
        palette: const <String, String>{"c1": "#ff0000"},
      );
      expect(() => view.withTick(-5), throwsA(isA<ArgumentError>()));
      expect(() => view.withTick(200), throwsA(isA<ArgumentError>()));
    });
  });
}
