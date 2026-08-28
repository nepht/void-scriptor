// ignore_for_file: prefer_const_constructors
// Sprint 110.13 - Custom Calendar and Celestial Time (Wave 2 F5).
//
// Domain-only calendar + celestial cycle + season derivation + deterministic
// weather sampler. No persistence, UI, hidden wall clock, locale, or random input.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";
import "package:void_scriptor/features/world_logic/domain/route_network.dart"
    show Season;


void main() {
  group("CustomMonth", () {
    test("saves properties", () {
      const m = CustomMonth(name: "X", daysInMonth: 30, indexInYear: 0);
      expect(m.name, "X");
      expect(m.daysInMonth, 30);
      expect(m.indexInYear, 0);
    });
    test("equality on same fields", () {
      const a = CustomMonth(name: "Y", daysInMonth: 31, indexInYear: 1);
      const b = CustomMonth(name: "Y", daysInMonth: 31, indexInYear: 1);
      expect(a, equals(b));
    });
  });

  group("CustomCalendar", () {
    test("builds and sums days", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 31, indexInYear: 1),
        CustomMonth(name: "C", daysInMonth: 31, indexInYear: 2),
        CustomMonth(name: "D", daysInMonth: 30, indexInYear: 3),
      ];
      final cal = CustomCalendar(months: months);
      expect(cal.daysPerYear, 122);
      expect(cal.monthsPerYear, 4);
    });
    test("rejects empty list", () {
      expect(
        () => CustomCalendar(months: const <CustomMonth>[]),
        throwsA(isA<ArgumentError>()),
      );
    });
    test("rejects zero-day month", () {
      expect(
        () => CustomCalendar(
          months: const <CustomMonth>[
            CustomMonth(name: "Bad", daysInMonth: 0, indexInYear: 0),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
    test("rejects empty month name", () {
      expect(
        () => CustomCalendar(
          months: const <CustomMonth>[
            CustomMonth(name: "", daysInMonth: 30, indexInYear: 0),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
    test("dateFromTick named month and day", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 31, indexInYear: 1),
      ];
      final cal = CustomCalendar(months: months);
      expect(cal.dateFromTick(0).monthName, "A");
      expect(cal.dateFromTick(0).dayOfMonth, 1);
      expect(cal.dateFromTick(0).monthIndex, 0);
      expect(cal.dateFromTick(29).monthName, "A");
      expect(cal.dateFromTick(29).dayOfMonth, 30);
      expect(cal.dateFromTick(30).monthName, "B");
      expect(cal.dateFromTick(30).dayOfMonth, 1);
      expect(cal.dateFromTick(30).monthIndex, 1);
      expect(cal.dateFromTick(60).monthName, "B");
      expect(cal.dateFromTick(60).dayOfMonth, 31);
    });
    test("round trip tick to date and back", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 31, indexInYear: 1),
        CustomMonth(name: "C", daysInMonth: 28, indexInYear: 2),
      ];
      final cal = CustomCalendar(months: months);
      for (final t in <int>[0, 5, 30, 35, 61, 89]) {
        final d = cal.dateFromTick(t);
        expect(cal.tickFromDate(d), t);
      }
    });
    test("year rolls for tick beyond daysPerYear", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 31, indexInYear: 1),
      ];
      final cal = CustomCalendar(months: months);
      expect(cal.dateFromTick(61).yearNumber, 2);
    });
    test("rejects negative tick", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
      ];
      final cal = CustomCalendar(months: months);
      expect(() => cal.dateFromTick(-1), throwsA(isA<ArgumentError>()));
    });
    test("monthByName lookup", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 31, indexInYear: 1),
      ];
      final cal = CustomCalendar(months: months);
      expect(cal.monthByName("B")?.daysInMonth, 31);
      expect(cal.monthByName("Unknown"), isNull);
    });
  });
  group("CelestialPhase", () {
    test("declares lunar phases", () {
      expect(CelestialPhase.newMoon, isNotNull);
      expect(CelestialPhase.fullMoon, isNotNull);
      expect(CelestialPhase.waxingCrescent, isNotNull);
      expect(CelestialPhase.waningCrescent, isNotNull);
    });
  });

  group("CelestialCycle", () {
    test("phaseAt consistent for same tick", () {
      final cycle = CelestialCycle(name: "Lunar", lengthInDays: 28, phases: 8);
      expect(cycle.phaseAt(0), cycle.phaseAt(0));
      expect(cycle.phaseAt(15), cycle.phaseAt(15));
    });
    test("phaseAt repeats every lengthInDays", () {
      final cycle = CelestialCycle(name: "Lunar", lengthInDays: 28, phases: 8);
      expect(cycle.phaseAt(0), cycle.phaseAt(28));
      expect(cycle.phaseAt(5), cycle.phaseAt(33));
    });
    test("phaseAt deterministic for same input", () {
      final cycle = CelestialCycle(name: "Lunar", lengthInDays: 28, phases: 8);
      expect(cycle.phaseAt(7), cycle.phaseAt(7));
    });
    test("rejects cycle length zero", () {
      expect(
        () => CelestialCycle(name: "Bad", lengthInDays: 0, phases: 4),
        throwsA(isA<ArgumentError>()),
      );
    });
    test("rejects phases zero", () {
      expect(
        () => CelestialCycle(name: "Bad", lengthInDays: 30, phases: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
    test("rejects empty cycle name", () {
      expect(
        () => CelestialCycle(name: "", lengthInDays: 30, phases: 4),
        throwsA(isA<ArgumentError>()),
      );
    });
    test("phaseDistribution within range", () {
      final cycle = CelestialCycle(name: "Lunar", lengthInDays: 28, phases: 8);
      final dist = cycle.phaseDistribution(0, 28);
      expect(dist.length, lessThanOrEqualTo(8));
      expect(dist.length, greaterThan(0));
    });
  });
  group("SeasonalCalendar", () {
    test("derives Season for first months", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 30, indexInYear: 1),
        CustomMonth(name: "C", daysInMonth: 30, indexInYear: 2),
        CustomMonth(name: "D", daysInMonth: 30, indexInYear: 3),
      ];
      final cal = CustomCalendar(months: months);
      final seasonal = SeasonalCalendar(
        calendar: cal,
        seasonByMonth: const {
          0: Season.winter,
          1: Season.winter,
          2: Season.spring,
          3: Season.spring,
        },
      );
      expect(seasonal.seasonAt(0), Season.winter);
      expect(seasonal.seasonAt(60), Season.spring);
    });
    test("Season.spring consistent for full month range", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 30, indexInYear: 1),
      ];
      final cal = CustomCalendar(months: months);
      final seasonal = SeasonalCalendar(
        calendar: cal,
        seasonByMonth: const {0: Season.spring, 1: Season.autumn},
      );
      for (int t = 0; t < 30; t++) {
        expect(seasonal.seasonAt(t), Season.spring);
      }
    });
    test("Season repeats every calendar year", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 30, indexInYear: 1),
      ];
      final cal = CustomCalendar(months: months);
      final seasonal = SeasonalCalendar(
        calendar: cal,
        seasonByMonth: const {0: Season.spring, 1: Season.autumn},
      );
      expect(seasonal.seasonAt(0), seasonal.seasonAt(60));
      expect(seasonal.seasonAt(30), seasonal.seasonAt(90));
    });
    test("rejects incomplete seasonByMonth map", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "B", daysInMonth: 30, indexInYear: 1),
      ];
      final cal = CustomCalendar(months: months);
      expect(
        () => SeasonalCalendar(
          calendar: cal,
          seasonByMonth: const {0: Season.spring},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
  group("WeatherCalendarSampler", () {
    test("deterministic for same seed and tick", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
      ];
      final cal = CustomCalendar(months: months);
      final sampler = WeatherCalendarSampler(calendar: cal, seed: 42);
      final a = sampler.sampleAt(0);
      final b = sampler.sampleAt(0);
      expect(a.condition, b.condition);
      expect(a.provenance.origin, contains("calendar"));
    });
    test("different seed can produce different sequence", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
      ];
      final cal = CustomCalendar(months: months);
      final s1 = WeatherCalendarSampler(calendar: cal, seed: 1);
      final s2 = WeatherCalendarSampler(calendar: cal, seed: 2);
      var anyDiff = false;
      for (int t = 0; t < 20; t++) {
        if (s1.sampleAt(t).condition != s2.sampleAt(t).condition) {
          anyDiff = true;
          break;
        }
      }
      expect(anyDiff, isTrue);
    });
    test("provenance includes seed and reason", () {
      const months = <CustomMonth>[
        CustomMonth(name: "A", daysInMonth: 30, indexInYear: 0),
      ];
      final cal = CustomCalendar(months: months);
      final sampler = WeatherCalendarSampler(calendar: cal, seed: 99);
      final sample = sampler.sampleAt(5);
      expect(sample.provenance.sourceId, contains("seed:99"));
      expect(sample.provenance.reason, isNotEmpty);
    });
  });
}
