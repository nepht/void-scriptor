// ignore_for_file: prefer_const_constructors
// Sprint 110.15 - Celestial Cycles & Seasons (Wave 2 F5).
//
// Models moon phases, multiple celestial bodies, season rules, festivals,
// and a deterministic preview window. Domain-only, no persistence/UI/clock.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/celestial_cycles.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";
import "package:void_scriptor/features/world_logic/domain/route_network.dart"
    show Season;

void main() {
  group("moon_cycles", () {
    test("8-phase moon names new and full moon by tick", () {
      final moon = CelestialBody(
        name: "Luna",
        cycle: CelestialCycle(name: "lunar", lengthInDays: 8, phases: 8),
      );
      expect(moon.phaseAt(0), "newMoon");
      expect(moon.phaseAt(4), "fullMoon");
      expect(moon.phaseIndexAt(4), 4);
    });
  });

  group("multi_body_cycles", () {
    test("alignment true only when all bodies at phase 0", () {
      final sys = CelestialSystem(
        calendar: _cal(),
        bodies: [
          CelestialBody(
            name: "Luna",
            cycle: CelestialCycle(name: "lunar", lengthInDays: 4, phases: 4),
          ),
          CelestialBody(
            name: "Sol",
            cycle: CelestialCycle(name: "solar", lengthInDays: 7, phases: 7),
          ),
        ],
      );
      expect(sys.alignmentAt(0), isTrue);
      expect(sys.alignmentAt(1), isFalse);
    });

    test("unknown body name throws", () {
      final sys = CelestialSystem(calendar: _cal(), bodies: []);
      expect(() => sys.body("Nope"), throwsArgumentError);
    });
  });

  group("season_rules", () {
    test("season name resolved at tick", () {
      final cal = _cal();
      final seasonal = SeasonalCalendar(
        calendar: cal,
        seasonByMonth: {
          0: Season.spring,
          1: Season.summer,
          2: Season.autumn,
          3: Season.winter,
        },
      );
      expect(seasonal.seasonAt(0), Season.spring);
      expect(seasonal.seasonNameAt(0), "spring");
      expect(seasonal.coversAllMonths, isTrue);
    });
  });

  group("festival_dates", () {
    test("fixed tick festival active only on its tick", () {
      final fest = Festival(
        id: "f1",
        name: "New Year",
        matcher: FixedTickFestival(0),
      );
      final sys = CelestialSystem(calendar: _cal(), bodies: []);
      expect(fest.isActiveAt(0, sys), isTrue);
      expect(fest.isActiveAt(1, sys), isFalse);
    });

    test("lunar festival active on specific phase tick", () {
      final moon = CelestialBody(
        name: "Luna",
        cycle: CelestialCycle(name: "lunar", lengthInDays: 8, phases: 8),
      );
      final fest = Festival(
        id: "harvest",
        name: "Harvest Moon",
        matcher: LunarFestival("Luna", 4),
      );
      final sys = CelestialSystem(calendar: _cal(), bodies: [moon]);
      expect(fest.isActiveAt(4, sys), isTrue);
      expect(fest.isActiveAt(0, sys), isFalse);
    });

    test("monthly festival active on a calendar date each year", () {
      final fest = Festival(
        id: "founders",
        name: "Founders Day",
        matcher: MonthlyFestival(monthIndex: 1, dayOfMonth: 1),
      );
      final sys = CelestialSystem(calendar: _cal(), bodies: []);
      // tick 0 = year1 month A day1; tick 30 = year1 month B day1
      expect(fest.isActiveAt(30, sys), isTrue);
      expect(fest.isActiveAt(31, sys), isFalse);
    });
  });

  group("cycle_preview", () {
    test("window projects phases season and festivals", () {
      final moon = CelestialBody(
        name: "Luna",
        cycle: CelestialCycle(name: "lunar", lengthInDays: 8, phases: 8),
      );
      final fest = Festival(
        id: "ny",
        name: "New Year",
        matcher: FixedTickFestival(0),
      );
      final cal = _cal();
      final seasonal = SeasonalCalendar(
        calendar: cal,
        seasonByMonth: {
          0: Season.spring,
          1: Season.summer,
          2: Season.autumn,
          3: Season.winter,
        },
      );
      final sys = CelestialSystem(
        calendar: cal,
        bodies: [moon],
        seasonal: seasonal,
        festivals: [fest],
      );
      final preview = CyclePreview(sys);
      final win = preview.window(0, 3);
      expect(win.length, 3);
      expect(win[0].bodyPhases["Luna"], "newMoon");
      expect(win[0].season, Season.spring);
      expect(win[0].activeFestivals, contains("ny"));
      expect(win[1].activeFestivals, isEmpty);
      expect(win[2].date.monthName, "A");
    });
  });
}

CustomCalendar _cal() => CustomCalendar(
  months: const [
    CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
    CustomMonth(name: "B", daysInMonth: 31, indexInYear: 1),
    CustomMonth(name: "C", daysInMonth: 31, indexInYear: 2),
    CustomMonth(name: "D", daysInMonth: 30, indexInYear: 3),
  ],
);
