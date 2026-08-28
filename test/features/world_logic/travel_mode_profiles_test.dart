// Sprint 110.10 - Travel Mode Profiles.
//
// Domain-only travel mode profiles: walk / mount / vehicle / ship / custom
// with terrain limits, capacity, rest schedule, and weather modifier.
// No persistence, UI, wall clock, locale, or random input; calculations are
// deterministic and unit-based.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart";

void main() {
  group("walk", () {
    test(
      "walk profile membawa base speed, kapasitas, dan daftar medan yang dapat dilalui",
      () {
        const profile = TravelModes.walk;

        expect(profile.id, "walk");
        expect(profile.baseSpeedKmPerHour, inInclusiveRange(2.0, 8.0));
        expect(profile.capacityPersons, greaterThanOrEqualTo(1));
        expect(profile.passableTerrains, contains(TerrainKind.plain));
        expect(profile.passableTerrains, isNot(contains(TerrainKind.mountain)));
      },
    );
  });

  group("mount", () {
    test("mount profile lebih cepat dari walk pada medan yang sama", () {
      const walk = TravelModes.walk;
      const mount = TravelModes.mount;

      expect(mount.baseSpeedKmPerHour, greaterThan(walk.baseSpeedKmPerHour));
      expect(mount.passableTerrains, contains(TerrainKind.mountain));
    });

    test("mount menolak masuk ke terrain yang tidak termasuk daftar", () {
      const mount = TravelModes.mount;
      expect(
        () => mount.requireTerrain(TerrainKind.ocean),
        throwsA(isA<TravelModeIncompatibleTerrain>()),
      );
    });
  });

  group("vehicle", () {
    test(
      "vehicle profile membawa kapasitas besar dan hanya dapat melewati jalan darat",
      () {
        const vehicle = TravelModes.vehicle;
        expect(vehicle.capacityPersons, greaterThanOrEqualTo(4));
        expect(vehicle.passableTerrains, contains(TerrainKind.plain));
        expect(vehicle.passableTerrains, contains(TerrainKind.forest));
        expect(vehicle.passableTerrains, isNot(contains(TerrainKind.ocean)));
      },
    );
  });

  group("ship", () {
    test(
      "ship profile hanya dapat melewati air dan mengabaikan medan lain",
      () {
        const ship = TravelModes.ship;
        expect(
          ship.passableTerrains,
          equals(<TerrainKind>{TerrainKind.ocean, TerrainKind.river}),
        );
      },
    );

    test("ship dapat melewati laut meski tidak memiliki medan mountain", () {
      const ship = TravelModes.ship;
      expect(ship.canTraverse(TerrainKind.ocean), isTrue);
    });
  });

  group("custom_mode", () {
    test(
      "custom mode dapat dideklarasikan oleh penulis dan dipakai dalam kalkulasi",
      () {
        final custom = const TravelModeProfile(
          id: "sky_sled",
          label: "Sky Sled",
          baseSpeedKmPerHour: 90,
          capacityPersons: 2,
          passableTerrains: {TerrainKind.plain, TerrainKind.mountain},
          restAfterHours: 6,
          restDurationHours: 1,
        ).validated();

        expect(custom.id, "sky_sled");
        expect(custom.canTraverse(TerrainKind.mountain), isTrue);
        expect(custom.canTraverse(TerrainKind.ocean), isFalse);
      },
    );

    test(
      "custom mode menolak id kosong, base speed negatif, atau kapasitas nol",
      () {
        expect(
          () => const TravelModeProfile(
            id: "",
            label: "Empty",
            baseSpeedKmPerHour: 5,
            capacityPersons: 1,
            passableTerrains: {TerrainKind.plain},
            restAfterHours: 8,
            restDurationHours: 1,
          ).validated(),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test("mode kustom terdaftar di registry dan dapat diambil kembali", () {
      final registry = TravelModeRegistry.builtIn.withProfile(
        const TravelModeProfile(
          id: "glider",
          label: "Glider",
          baseSpeedKmPerHour: 40,
          capacityPersons: 1,
          passableTerrains: {TerrainKind.plain, TerrainKind.mountain},
          restAfterHours: 4,
          restDurationHours: 0,
        ),
      );

      expect(registry.profile("glider").id, "glider");
      expect(registry.profile("walk").id, "walk");
      expect(() => registry.profile("unknown"), throwsA(isA<ArgumentError>()));
    });
  });

  group("weather_modifier", () {
    test(
      "cuaca buruk memperlambat moda perjalanan dan dijelaskan alasannya",
      () {
        const walk = TravelModes.walk;
        final modified = walk.applyWeather(WeatherCondition.storm);

        expect(modified.baseSpeedKmPerHour, lessThan(walk.baseSpeedKmPerHour));
        expect(modifierExplanation(modified), contains("storm"));
      },
    );

    test(
      "cuaca cerah tidak mengubah base speed dan tidak menambah catatan",
      () {
        const walk = TravelModes.walk;
        final modified = walk.applyWeather(WeatherCondition.clear);
        expect(modified.baseSpeedKmPerHour, walk.baseSpeedKmPerHour);
        expect(modifierExplanation(modified), isEmpty);
      },
    );

    test("cuaca ekstrem menolak moda yang dilarang melintasinya", () {
      const ship = TravelModes.ship;
      expect(
        () => ship.applyWeather(WeatherCondition.hurricane),
        throwsA(isA<TravelModeWeatherRefused>()),
      );
    });
  });
}
