// Sprint 110.44 - Automated Test Matrix.
//
// Verifier-style slice that fills the four missing test suites called out by
// sprint_110.json step 110.44 (required_suites: unit, property, integration,
// contract, migration, ui, end_to_end, regression). Pre-existing widget tests
// already cover ui; domain code has no persistence so migration is not
// applicable while D-SCHEMA-01 is OPEN; end_to_end is reserved for the host
// app boundary (110.49 acceptance gate). This file therefore adds:
//
//   - property tests  : invariants over many inputs (calendar round-trip,
//                       rumor reachability, violation explain byte-stability)
//   - contract tests  : validated factories reject bad input; reports stay
//                       immutable and deterministic across calls
//   - integration tests : cross-module chains (WorldClock -> CalendarConversion
//                         -> AgeCalculator; CrossSimulationIntegration path;
//                         RumorPropagationSimulator source chain)
//   - regression tests : exercise the slice paths that downstream validators
//                         (110.22 era location, 110.28 age/location, 110.41
//                         era technology) build on top of.
//
// Domain-only: no persistence, UI, wall clock, locale, random, network.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/age_at_time.dart";
import "package:void_scriptor/features/world_logic/domain/calendar_conversion.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";
import "package:void_scriptor/features/world_logic/domain/cross_simulation_integration.dart";
import "package:void_scriptor/features/world_logic/domain/power_rule_violation_detector.dart";
import "package:void_scriptor/features/world_logic/domain/power_rulebook.dart";
import "package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart";
import "package:void_scriptor/features/world_logic/domain/rumor_propagation.dart";
import "package:void_scriptor/features/world_logic/domain/world_time_state_authority.dart";

CustomCalendar _standardCalendar() {
  return CustomCalendar(
    months: const <CustomMonth>[
      CustomMonth(name: "M1", daysInMonth: 30, indexInYear: 0),
      CustomMonth(name: "M2", daysInMonth: 30, indexInYear: 1),
      CustomMonth(name: "M3", daysInMonth: 30, indexInYear: 2),
    ],
  );
}

CalendarConversionService _conversionService(
  CustomCalendar cal, {
  int epoch = 0,
}) {
  return CalendarConversionService(
    registry: CalendarRegistry(<String, CustomCalendar>{"std": cal}),
    epoch: CalendarEpoch(ticksAtEpoch: epoch),
    defaultLocale: const CalendarLocale(id: "en", separator: "-", order: "ymd"),
  );
}

void main() {
  group("110.44 property - CustomCalendar round-trip", () {
    final cal = _standardCalendar();

    test("dateFromTick(tickFromDate(d)) equals d for every sampled tick", () {
      const int sampleYears = 5;
      final int maxTick = cal.daysPerYear * sampleYears;
      for (int tick = 0; tick < maxTick; tick += 7) {
        final date = cal.dateFromTick(tick);
        final restored = cal.tickFromDate(date);
        expect(
          restored,
          tick,
          reason:
              "tick=$tick date=${date.yearNumber}-${date.monthIndex}-${date.dayOfMonth}",
        );
      }
    });

    test("daysPerYear and monthsPerYear match constructor input", () {
      expect(cal.daysPerYear, 90);
      expect(cal.monthsPerYear, 3);
      expect(cal.monthByName("M2")?.indexInYear, 1);
    });

    test("CalendarConversionService format -> parse round-trip is stable", () {
      final svc = _conversionService(cal);
      for (final t in const <int>[0, 1, 30, 31, 60, 89, 90, 179, 449]) {
        final display = svc.format(absoluteTick: t, calendarId: "std");
        final parsed = svc.parse(display: display, calendarId: "std");
        expect(parsed, t, reason: "tick=$t text=${display.text}");
      }
    });

    test(
      "CalendarConversionService daysInPreviousMonth wraps year boundary",
      () {
        final svc = _conversionService(cal);
        final jan1 = svc.format(absoluteTick: 0, calendarId: "std").date;
        expect(svc.daysInPreviousMonth("std", jan1), 30);
        final apr1 = svc.format(absoluteTick: 90, calendarId: "std").date;
        expect(svc.daysInPreviousMonth("std", apr1), 30);
      },
    );
  });

  group(
    "110.44 property - WorldClock advances monotonically and rejects bad input",
    () {
      test("advance returns new tick and never decreases", () {
        final clock = WorldClock(initialTick: 0);
        int last = clock.now;
        for (int i = 0; i < 100; i++) {
          final next = clock.advance(3);
          expect(next, greaterThan(last));
          last = next;
        }
        expect(clock.now, 300);
      });

      test("advance(0) is a no-op and returns current tick", () {
        final clock = WorldClock(initialTick: 7);
        expect(clock.advance(0), 7);
        expect(clock.now, 7);
      });

      test("negative tick constructor and negative advance both throw", () {
        expect(() => WorldClock(initialTick: -1), throwsArgumentError);
        final clock = WorldClock(initialTick: 5);
        expect(() => clock.advance(-1), throwsArgumentError);
      });
    },
  );

  group("110.44 contract - validated factories reject bad input", () {
    test("CustomCalendar rejects empty month list and zero-day months", () {
      expect(
        () => CustomCalendar(months: const <CustomMonth>[]),
        throwsArgumentError,
      );
      expect(
        () => CustomCalendar(
          months: const <CustomMonth>[
            CustomMonth(name: "bad", daysInMonth: 0, indexInYear: 0),
          ],
        ),
        throwsArgumentError,
      );
    });

    test("CalendarRegistry resolves unknown calendar id as ArgumentError", () {
      final registry = CalendarRegistry(<String, CustomCalendar>{});
      expect(() => registry.resolve("nope"), throwsArgumentError);
    });

    test("PowerUsageSource.revision/reason must be non-empty", () {
      expect(
        () => PowerUsageSource.validated(revision: "", reason: "ok"),
        throwsArgumentError,
      );
      expect(
        () => PowerUsageSource.validated(revision: "ok", reason: ""),
        throwsArgumentError,
      );
    });

    test("PowerResourceChange rejects zero amount and empty fields", () {
      expect(
        () => PowerResourceChange.validated(
          resource: "mana",
          amount: 0,
          reason: "ok",
        ),
        throwsArgumentError,
      );
      expect(
        () => PowerResourceChange.validated(
          resource: "",
          amount: -1,
          reason: "ok",
        ),
        throwsArgumentError,
      );
    });

    test("PowerAbility prerequisites collection is unmodifiable", () {
      final ability = PowerAbility.validated(id: "fireball", name: "Fireball");
      expect(
        () => ability.prerequisites.add(
          PowerPrerequisite.validated(id: "x", description: "y"),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => ability.costs.add(
          PowerCost.validated(resource: "mana", amount: 1, reason: "cast"),
        ),
        throwsUnsupportedError,
      );
    });

    test("PowerRulebook rejects duplicate ability ids", () {
      final ability = PowerAbility.validated(id: "dup", name: "Dup");
      expect(
        () => PowerRulebook.validated(
          abilities: <PowerAbility>[ability, ability],
        ),
        throwsArgumentError,
      );
    });

    test("RumorSeed rejects empty id, summary, and origin without ids", () {
      expect(
        () => RumorSeed.validated(
          id: "",
          summary: "ok",
          origin: const RumorOrigin(personId: "p1"),
          tick: 0,
          source: const RumorSource(revision: "r", reason: "x"),
        ),
        throwsArgumentError,
      );
      expect(
        () => RumorSeed.validated(
          id: "ok",
          summary: "",
          origin: const RumorOrigin(personId: "p1"),
          tick: 0,
          source: const RumorSource(revision: "r", reason: "x"),
        ),
        throwsArgumentError,
      );
      expect(
        () => RumorSeed.validated(
          id: "ok",
          summary: "ok",
          origin: const RumorOrigin(),
          tick: 0,
          source: const RumorSource(revision: "r", reason: "x"),
        ),
        throwsArgumentError,
      );
    });

    test("RumorNetwork rejects self-loop and unknown person references", () {
      expect(
        () => RumorNetwork(
          persons: <String>{"a"},
          edges: const <RumorEdge>[RumorEdge(from: "a", to: "a")],
        ),
        throwsArgumentError,
      );
      expect(
        () => RumorNetwork(
          persons: <String>{"a"},
          edges: const <RumorEdge>[RumorEdge(from: "a", to: "missing")],
        ),
        throwsArgumentError,
      );
    });
  });

  group(
    "110.44 contract - PowerViolationReport is explainable and deterministic",
    () {
      PowerRulebook simpleRulebook() {
        return PowerRulebook.validated(
          abilities: <PowerAbility>[
            PowerAbility.validated(
              id: "fireball",
              name: "Fireball",
              prerequisites: <PowerPrerequisite>[
                PowerPrerequisite.validated(id: "spark", description: "Spark"),
              ],
              costs: <PowerCost>[
                PowerCost.validated(
                  resource: "mana",
                  amount: 5,
                  reason: "cast",
                ),
              ],
            ),
          ],
        );
      }

      test("unknown ability yields single unknownAbility violation", () {
        final rulebook = simpleRulebook();
        final detector = PowerRuleViolationDetector(rulebook: rulebook);
        final report = detector.detect(
          PowerUsageEvent.validated(
            id: "evt-1",
            abilityId: "missing",
            actorId: "hero",
            sceneId: "scene-1",
            tick: 0,
            source: PowerUsageSource.validated(revision: "r", reason: "x"),
          ),
          satisfiedPrerequisites: const <String>["spark"],
        );
        expect(report.isClean, isFalse);
        expect(report.violations, hasLength(1));
        expect(
          report.violations.single.kind,
          PowerViolationKind.unknownAbility,
        );
        expect(report.violations.single.abilityId, "missing");
        expect(report.explain(), report.explain());
      });

      test("missing prerequisite + insufficient cost flagged together", () {
        final rulebook = simpleRulebook();
        final detector = PowerRuleViolationDetector(rulebook: rulebook);
        final report = detector.detect(
          PowerUsageEvent.validated(
            id: "evt-2",
            abilityId: "fireball",
            actorId: "hero",
            sceneId: "scene-1",
            tick: 0,
            resourceChanges: <PowerResourceChange>[
              PowerResourceChange.validated(
                resource: "mana",
                amount: -2,
                reason: "partial",
              ),
            ],
            source: PowerUsageSource.validated(revision: "r", reason: "x"),
          ),
          satisfiedPrerequisites: const <String>[],
        );
        expect(report.isClean, isFalse);
        final kinds = report.violations.map((v) => v.kind).toSet();
        expect(kinds, contains(PowerViolationKind.missingPrerequisite));
        expect(kinds, contains(PowerViolationKind.insufficientCost));
      });

      test(
        "clean event with satisfied prereq + sufficient cost reports isClean",
        () {
          final rulebook = simpleRulebook();
          final detector = PowerRuleViolationDetector(rulebook: rulebook);
          final report = detector.detect(
            PowerUsageEvent.validated(
              id: "evt-3",
              abilityId: "fireball",
              actorId: "hero",
              sceneId: "scene-1",
              tick: 0,
              resourceChanges: <PowerResourceChange>[
                PowerResourceChange.validated(
                  resource: "mana",
                  amount: -5,
                  reason: "cast",
                ),
              ],
              source: PowerUsageSource.validated(revision: "r", reason: "x"),
            ),
            satisfiedPrerequisites: const <String>["spark"],
          );
          expect(report.isClean, isTrue);
          expect(report.violations, isEmpty);
          // explain() must not leak any violation marker when clean.
          expect(report.explain(), isNot(contains("violation:")));
        },
      );
    },
  );

  group(
    "110.44 property - RumorPropagationSimulator determinism + reachability",
    () {
      RumorSeed seedFactory({
        int tick = 0,
        String summary = "the vault cracked open",
      }) {
        return RumorSeed.validated(
          id: "rumor-1",
          summary: summary,
          origin: const RumorOrigin(personId: "p1"),
          tick: tick,
          source: const RumorSource(revision: "rev-1", reason: "witness saw"),
        );
      }

      test("two runs with identical inputs produce identical recipients", () {
        const sim = RumorPropagationSimulator();
        final network = RumorNetwork(
          persons: <String>{"p1", "p2", "p3", "p4"},
          edges: const <RumorEdge>[
            RumorEdge(from: "p1", to: "p2"),
            RumorEdge(from: "p2", to: "p3"),
            RumorEdge(from: "p3", to: "p4"),
          ],
        );
        const traits = RumorTraits(
          reliability: 10,
          distortionFactor: 0,
          propagationDelayTicks: 1,
        );
        final seed = seedFactory();
        final a = sim.simulate(
          seed: seed,
          network: network,
          traits: traits,
          upToTick: 5,
        );
        final b = sim.simulate(
          seed: seed,
          network: network,
          traits: traits,
          upToTick: 5,
        );
        expect(a.recipients.length, b.recipients.length);
        for (int i = 0; i < a.recipients.length; i++) {
          expect(a.recipients[i].personId, b.recipients[i].personId);
          expect(a.recipients[i].arrivalTick, b.recipients[i].arrivalTick);
          expect(a.recipients[i].confidence, b.recipients[i].confidence);
        }
      });

      test(
        "seed source revision is preserved on every recipient sourceChain",
        () {
          const sim = RumorPropagationSimulator();
          final network = RumorNetwork(
            persons: <String>{"p1", "p2"},
            edges: const <RumorEdge>[RumorEdge(from: "p1", to: "p2")],
          );
          final result = sim.simulate(
            seed: seedFactory(),
            network: network,
            traits: const RumorTraits(),
            upToTick: 5,
          );
          expect(result.recipients.any((r) => r.personId == "p2"), isTrue);
          final p2 = result.recipients.firstWhere((r) => r.personId == "p2");
          expect(p2.sourceChain, isNotEmpty);
          expect(p2.sourceChain.first, "rumor-1");
        },
      );

      test("recipients beyond upToTick are dropped", () {
        const sim = RumorPropagationSimulator();
        final network = RumorNetwork(
          persons: <String>{"p1", "p2", "p3", "p4"},
          edges: const <RumorEdge>[
            RumorEdge(from: "p1", to: "p2"),
            RumorEdge(from: "p2", to: "p3"),
            RumorEdge(from: "p3", to: "p4"),
          ],
        );
        final result = sim.simulate(
          seed: seedFactory(tick: 0),
          network: network,
          traits: const RumorTraits(propagationDelayTicks: 1),
          upToTick: 1,
        );
        final ids = result.recipients.map((r) => r.personId).toSet();
        expect(ids, contains("p2"));
        expect(ids, isNot(contains("p4")));
      });

      test("distortion=0 keeps summary verbatim on direct hop", () {
        const sim = RumorPropagationSimulator();
        final network = RumorNetwork(
          persons: <String>{"p1", "p2"},
          edges: const <RumorEdge>[RumorEdge(from: "p1", to: "p2")],
        );
        final result = sim.simulate(
          seed: seedFactory(summary: "verbatim"),
          network: network,
          traits: const RumorTraits(distortionFactor: 0),
          upToTick: 5,
        );
        final p2 = result.recipients.firstWhere((r) => r.personId == "p2");
        expect(p2.distortedSummary, "verbatim");
        expect(p2.distortion, 0.0);
      });
    },
  );

  group(
    "110.44 integration - WorldClock + CalendarConversion + AgeCalculator",
    () {
      test(
        "WorldClock -> CalendarConversion -> AgeCalculator chronology chain",
        () {
          final cal = _standardCalendar();
          final svc = _conversionService(cal);
          final ageCalc = AgeCalculator(calendarId: "std", conversion: svc);

          final clock = WorldClock(initialTick: 0);
          const birthTick = 10;
          final ageAtBirth = ageCalc.computeAt(
            personId: "hero",
            sceneTick: birthTick,
            birthTick: birthTick,
            deathTick: null,
          );
          expect(ageAtBirth.years, 0);

          final now = clock.advance(100);
          final display = svc.format(absoluteTick: now, calendarId: "std");
          expect(display.calendarId, "std");
          expect(display.date.yearNumber, greaterThanOrEqualTo(1));

          final ageNow = ageCalc.computeAt(
            personId: "hero",
            sceneTick: now,
            birthTick: birthTick,
            deathTick: null,
          );
          expect(ageNow.years, greaterThan(0));
          expect(ageNow.isDeceased, isFalse);

          const deathTick = 200;
          final ageAfterDeath = ageCalc.computeAt(
            personId: "hero",
            sceneTick: 300,
            birthTick: birthTick,
            deathTick: deathTick,
          );
          expect(ageAfterDeath.isDeceased, isTrue);
        },
      );

      test(
        "unknown birth tick yields AgeResult.unknown with traceable reason",
        () {
          final cal = _standardCalendar();
          final svc = _conversionService(cal);
          final ageCalc = AgeCalculator(calendarId: "std", conversion: svc);
          final result = ageCalc.computeAt(
            personId: "mystery",
            sceneTick: 0,
            birthTick: null,
            deathTick: null,
          );
          expect(result.years, 0);
          expect(result.months, 0);
          expect(result.days, 0);
          expect(result.isDeceased, isFalse);
          expect(result.reason, contains("mystery"));
        },
      );

      test(
        "CrossSimulationIntegration clock + default registry round-trip",
        () {
          final cal = _standardCalendar();
          final svc = _conversionService(cal);
          final csi = CrossSimulationIntegration.withDefaults(
            clock: WorldClock(initialTick: 0),
          );
          final start = csi.currentTick;
          final next = csi.advanceTime(45);
          expect(next, start + 45);
          expect(csi.currentTick, next);

          expect(
            () => svc.format(absoluteTick: 0, calendarId: "missing"),
            throwsArgumentError,
          );
        },
      );
    },
  );

  group(
    "110.44 regression - shared invariants downstream validators depend on",
    () {
      test("CustomCalendar.daysPerYear is the sum of month lengths", () {
        final cal = CustomCalendar(
          months: const <CustomMonth>[
            CustomMonth(name: "A", daysInMonth: 7, indexInYear: 0),
            CustomMonth(name: "B", daysInMonth: 13, indexInYear: 1),
            CustomMonth(name: "C", daysInMonth: 5, indexInYear: 2),
          ],
        );
        expect(cal.daysPerYear, 7 + 13 + 5);
        expect(cal.monthsPerYear, 3);
      });

      test("RumorOrigin.hasAny rejects origin with all-null ids", () {
        expect(const RumorOrigin().hasAny, isFalse);
        expect(const RumorOrigin(personId: "").hasAny, isFalse);
        expect(const RumorOrigin(locationId: "loc").hasAny, isTrue);
      });

      test("WorldDate equality is structural", () {
        const a = WorldDate(year: 1, month: 2, day: 3);
        const b = WorldDate(year: 1, month: 2, day: 3);
        const c = WorldDate(year: 1, month: 2, day: 4);
        expect(a, b);
        expect(a, isNot(c));
        expect(a.hashCode, b.hashCode);
      });
    },
  );
}
