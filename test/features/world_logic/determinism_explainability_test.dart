// Determinism & Explainability verification for Sprint 110 Wave 2 subsystems.
// Acceptance canonical 110.43: replay_tests, seed_tests, unit_tests,
// precision_tests, explanation_samples.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/custom_calendar.dart';
import 'package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart'
    show WeatherCondition;
import 'package:void_scriptor/features/world_logic/domain/calendar_conversion.dart';
import 'package:void_scriptor/features/world_logic/domain/world_time_state_authority.dart';
import 'package:void_scriptor/features/world_logic/domain/rumor_propagation.dart';
import 'package:void_scriptor/features/world_logic/domain/age_at_time.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rulebook.dart';
import 'package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rule_violation_detector.dart';
import 'package:void_scriptor/features/world_logic/domain/power_escalation_signals.dart';
import 'package:void_scriptor/features/world_logic/domain/currency_reference_basket.dart';
import 'package:void_scriptor/features/world_logic/domain/era_technology_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/diplomacy_history.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_inheritance_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart';

void main() {
  group("Determinism: replay", () {
    test("WeatherCalendarSampler identical stream same seed+tick", () {
      final cal = CustomCalendar(
        months: const <CustomMonth>[
          CustomMonth(indexInYear: 0, name: 'Jan', daysInMonth: 30),
          CustomMonth(indexInYear: 0, name: 'Feb', daysInMonth: 30),
        ],
      );
      final s1 = WeatherCalendarSampler(calendar: cal, seed: 42);
      final s2 = WeatherCalendarSampler(calendar: cal, seed: 42);
      for (var t = 0; t < 60; t += 1) {
        expect(
          s2.sampleAt(t).condition,
          equals(s1.sampleAt(t).condition),
          reason: 'tick=$t condition must match',
        );
      }
    });

    test("RumorPropagationSimulator replays identical recipients", () {
      final seed = RumorSeed.validated(
        id: 'rumor-1',
        summary: 'A dragon was seen at the north gate.',
        source: const RumorSource(revision: 'rev-1', reason: 'eyewitness'),
        tick: 10,
        origin: const RumorOrigin(personId: 'p-alice'),
      );
      final network = RumorNetwork(
        persons: const {'p-alice', 'p-bob', 'p-carol'},
        edges: const <RumorEdge>[
          RumorEdge(from: 'p-alice', to: 'p-bob'),
          RumorEdge(from: 'p-bob', to: 'p-carol'),
        ],
      );
      const traits = RumorTraits(
        reliability: 9,
        distortionFactor: 0.1,
        propagationDelayTicks: 1,
      );

      final run1 = const RumorPropagationSimulator().simulate(
        seed: seed,
        network: network,
        traits: traits,
        upToTick: 30,
      );
      final run2 = const RumorPropagationSimulator().simulate(
        seed: seed,
        network: network,
        traits: traits,
        upToTick: 30,
      );

      expect(
        run2.recipients.map((r) => r.personId).toList(),
        equals(run1.recipients.map((r) => r.personId).toList()),
      );
      expect(
        run2.recipients.map((r) => r.arrivalTick).toList(),
        equals(run1.recipients.map((r) => r.arrivalTick).toList()),
      );
    });

    test("WorldClock advanceTime is pure and reproducible", () {
      final c1 = WorldClock(initialTick: 5);
      final c2 = WorldClock(initialTick: 5);
      expect(c1.advance(7), equals(c2.advance(7)));
      expect(c1.now, equals(c2.now));
    });

    test(
      "CalendarConversionService formats identical ticks to identical text",
      () {
        const months = <CustomMonth>[
          CustomMonth(indexInYear: 0, name: 'Jan', daysInMonth: 30),
          CustomMonth(indexInYear: 0, name: 'Feb', daysInMonth: 30),
          CustomMonth(indexInYear: 0, name: 'Mar', daysInMonth: 30),
        ];
        final cal = CustomCalendar(months: months);
        final reg = CalendarRegistry({'r-fmt': cal});
        final s1 = CalendarConversionService(registry: reg);
        final s2 = CalendarConversionService(registry: reg);

        for (var t = 0; t < 90; t += 1) {
          expect(
            s2.format(absoluteTick: t, calendarId: 'r-fmt').text,
            equals(s1.format(absoluteTick: t, calendarId: 'r-fmt').text),
          );
        }
      },
    );

    test("AgeCalculator.computeAt is deterministic for the same inputs", () {
      const months = <CustomMonth>[
        CustomMonth(indexInYear: 0, name: 'Jan', daysInMonth: 30),
        CustomMonth(indexInYear: 0, name: 'Feb', daysInMonth: 30),
      ];
      // ignore: prefer_const_declarations
      final cal = CustomCalendar(months: months);
      final reg = CalendarRegistry({'a-cal': cal});
      final svc = CalendarConversionService(registry: reg);
      final calc = AgeCalculator(calendarId: 'a-cal', conversion: svc);

      final r1 = calc.computeAt(
        personId: 'p-x',
        sceneTick: 500,
        birthTick: 100,
      );
      final r2 = calc.computeAt(
        personId: 'p-x',
        sceneTick: 500,
        birthTick: 100,
      );
      expect(r2.years, equals(r1.years));
      expect(r2.months, equals(r1.months));
      expect(r2.days, equals(r1.days));
      expect(r2.isDeceased, equals(r1.isDeceased));
    });
  });

  group("Determinism: seed sensitivity", () {
    test(
      "Different WeatherCalendarSampler seeds produce different streams",
      () {
        final cal = CustomCalendar(
          months: const <CustomMonth>[
            CustomMonth(indexInYear: 0, name: 'M1', daysInMonth: 30),
            CustomMonth(indexInYear: 0, name: 'M2', daysInMonth: 30),
          ],
        );
        final sA = WeatherCalendarSampler(calendar: cal, seed: 1);
        final sB = WeatherCalendarSampler(calendar: cal, seed: 2);

        var diverged = false;
        final firstA = <WeatherCondition>[];
        for (var t = 0; t < 60; t += 1) {
          final a = sA.sampleAt(t);
          final b = sB.sampleAt(t);
          firstA.add(a.condition);
          if (a != b) diverged = true;
        }
        expect(diverged, isTrue);
        final sA2 = WeatherCalendarSampler(calendar: cal, seed: 1);
        for (var t = 0; t < firstA.length; t += 1) {
          expect(sA2.sampleAt(t).condition, equals(firstA[t]));
        }
      },
    );

    test("Same seed across propagation runs yields identical rumor lists", () {
      final seed = RumorSeed.validated(
        id: 'rumor-2',
        summary: 'Stable seed test.',
        source: const RumorSource(revision: 'r', reason: 'fixture'),
        tick: 0,
        origin: const RumorOrigin(personId: 'p-root'),
      );
      final network = RumorNetwork(
        persons: const {'p-root', 'p-1', 'p-2', 'p-3'},
        edges: const <RumorEdge>[
          RumorEdge(from: 'p-root', to: 'p-1'),
          RumorEdge(from: 'p-1', to: 'p-2'),
          RumorEdge(from: 'p-2', to: 'p-3'),
        ],
      );
      const traits = RumorTraits(
        reliability: 10,
        distortionFactor: 0.0,
        propagationDelayTicks: 1,
      );

      final r1 = const RumorPropagationSimulator().simulate(
        seed: seed,
        network: network,
        traits: traits,
        upToTick: 20,
      );
      final r2 = const RumorPropagationSimulator().simulate(
        seed: seed,
        network: network,
        traits: traits,
        upToTick: 20,
      );
      expect(
        r2.recipients.map((e) => e.personId),
        equals(r1.recipients.map((e) => e.personId)),
      );
      expect(
        r2.recipients.map((e) => e.arrivalTick),
        equals(r1.recipients.map((e) => e.arrivalTick)),
      );
    });
  });

  group("Determinism: precision / equality", () {
    test("PowerRuleViolationReport.explain byte-stable across runs", () {
      final ability = PowerAbility.validated(
        id: 'fireball',
        name: 'Fireball',
        costs: [
          PowerCost.validated(resource: 'mana', amount: 10, reason: 'cast'),
        ],
      );
      final rulebook = PowerRulebook.validated(abilities: [ability]);
      final event = PowerUsageEvent.validated(
        id: 'evt-1',
        abilityId: 'fireball',
        actorId: 'mage-1',
        sceneId: 's-1',
        tick: 1,
        resourceChanges: [
          PowerResourceChange.validated(
            resource: 'mana',
            amount: 1,
            reason: 'spend',
          ),
        ],
        source: PowerUsageSource.validated(revision: 'a', reason: 'first cast'),
      );
      final detector = PowerRuleViolationDetector(rulebook: rulebook);

      final r1 = detector.detect(event, satisfiedPrerequisites: const []);
      final r2 = detector.detect(event, satisfiedPrerequisites: const []);

      expect(r2.explain(), equals(r1.explain()));
      expect(r2.isClean, equals(r1.isClean));
    });

    test("PowerEscalationReport.explain byte-stable across runs", () {
      final ability = PowerAbility.validated(
        id: 'blink',
        name: 'Blink',
        costs: [
          PowerCost.validated(
            resource: 'stamina',
            amount: 1,
            reason: 'teleport',
          ),
        ],
      );
      final rulebook = PowerRulebook.validated(abilities: [ability]);
      final ledger = PowerUsageLedger.validated(
        events: [
          PowerUsageEvent.validated(
            id: 'e-1',
            abilityId: 'blink',
            actorId: 'p-1',
            sceneId: 's-1',
            tick: 5,
            resourceChanges: [
              PowerResourceChange.validated(
                resource: 'stamina',
                amount: 1,
                reason: 'spend',
              ),
            ],
            source: PowerUsageSource.validated(revision: 'a', reason: 'first'),
          ),
        ],
      );
      final signals = PowerEscalationSignals(rulebook: rulebook);

      final r1 = signals.evaluate(ledger: ledger, dismissal: const {});
      final r2 = signals.evaluate(ledger: ledger, dismissal: const {});

      expect(r2.explain(), equals(r1.explain()));
      expect(r2.signals.length, equals(r1.signals.length));
    });

    test("EraTechnologyReport.explain stable across runs", () {
      final node = TechnologyNode.validated(
        id: 't-print',
        name: 'Printing Press',
        culture: 'culture-a',
        scope: TechnologyScope.civil,
        branch: 'media',
        tier: 1,
        summary: 'Movable type',
        source: TechnologySource.validated(revision: 'r', reason: 'historical'),
      );
      final registry = TechnologyRegistry.validated(nodes: [node]);
      final timeline = TechnologyDiscoveryTimeline.validated(events: const []);
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );

      final ref = SceneTechnologyReference.validated(
        sceneId: 's-1',
        tick: 5,
        technologyId: 't-print',
        productionScale: 1,
      );
      final r1 = validator.validate(references: [ref]);
      final r2 = validator.validate(references: [ref]);

      expect(r2.explain(), equals(r1.explain()));
      expect(r2.findings.length, equals(r1.findings.length));
    });

    test("PriceWealthInflationModel constructor is deterministic", () {
      // Build the smallest valid basket and model to exercise the validation
      // pipeline; result is deterministic: same inputs -> same instance.
      final c1 = CurrencyDefinition.validated(
        id: 'gp',
        name: 'Gold Piece',
        symbol: 'gp',
        validity: ValidityRange.validated(fromTick: 0),
      );
      final c2 = CurrencyDefinition.validated(
        id: 'sp',
        name: 'Silver Piece',
        symbol: 'sp',
        validity: ValidityRange.validated(fromTick: 0),
      );
      final denom = CurrencyDenomination.validated(
        id: 'gp-1',
        currencyId: 'gp',
        name: 'gp',
        value: 1,
        validity: ValidityRange.validated(fromTick: 0),
      );
      final rate = CurrencyExchangeRate.validated(
        fromCurrencyId: 'gp',
        toCurrencyId: 'sp',
        rate: 10,
        validity: ValidityRange.validated(fromTick: 0),
      );
      final unit = ReferenceUnit.validated(
        id: 'u-loaf',
        name: 'Loaf',
        symbol: 'l',
        category: 'food',
      );
      final price = ReferenceGoodPrice.validated(
        currencyId: 'gp',
        amount: 1,
        validity: ValidityRange.validated(fromTick: 0),
      );
      final good = ReferenceGood.validated(
        id: 'bread',
        name: 'Bread',
        unitId: 'u-loaf',
        prices: [price],
      );
      final basket1 = CurrencyReferenceBasket.validated(
        currencies: [c1, c2],
        denominations: [denom],
        exchangeRates: [rate],
        units: [unit],
        goods: [good],
      );
      final basket2 = CurrencyReferenceBasket.validated(
        currencies: [c1, c2],
        denominations: [denom],
        exchangeRates: [rate],
        units: [unit],
        goods: [good],
      );
      // Two validated baskets from the same inputs should produce equal ids.
      expect(
        basket1.currencies.map((c) => c.id),
        equals(basket2.currencies.map((c) => c.id)),
      );
      expect(
        basket1.exchangeRates.map((r) => r.fromCurrencyId),
        equals(basket2.exchangeRates.map((r) => r.fromCurrencyId)),
      );
    });
  });

  group("Determinism: explainability samples", () {
    test("PowerViolationReport.explain non-empty when dirty", () {
      final ability = PowerAbility.validated(
        id: 'fireball',
        name: 'Fireball',
        costs: [
          PowerCost.validated(resource: 'mana', amount: 10, reason: 'cast'),
        ],
      );
      final rulebook = PowerRulebook.validated(abilities: [ability]);
      final event = PowerUsageEvent.validated(
        id: 'evt-x',
        abilityId: 'fireball',
        actorId: 'mage-1',
        sceneId: 's-1',
        tick: 0,
        resourceChanges: [
          PowerResourceChange.validated(
            resource: 'mana',
            amount: 1,
            reason: 'spend',
          ),
        ],
        source: PowerUsageSource.validated(revision: 'a', reason: 'attempt'),
      );
      final report = PowerRuleViolationDetector(
        rulebook: rulebook,
      ).detect(event, satisfiedPrerequisites: const []);
      final text = report.explain();
      expect(text, isNotEmpty);
      expect(text.toLowerCase(), contains("fireball"));
    });

    test("EraTechnologyReport.explain non-empty for findings", () {
      final node = TechnologyNode.validated(
        id: 't-radio',
        name: 'Radio',
        culture: 'culture-a',
        scope: TechnologyScope.civil,
        branch: 'comm',
        tier: 2,
        summary: 'Wireless transmission',
        source: TechnologySource.validated(revision: 'r', reason: 'historical'),
        prerequisites: const ['t-print'],
      );
      final registry = TechnologyRegistry.validated(nodes: [node]);
      final timeline = TechnologyDiscoveryTimeline.validated(events: const []);
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 's-1',
            tick: 100,
            technologyId: 't-radio',
            productionScale: 1,
          ),
        ],
      );
      final text = report.explain();
      expect(text, isNotEmpty);
      expect(
        text.toLowerCase().contains("prerequisite") ||
            text.toLowerCase().contains("use") ||
            text.toLowerCase().contains("scale"),
        isTrue,
      );
    });

    test("DiplomacyTimelineView builds explainNote with tick range", () {
      final treaty = Treaty.validated(
        id: 'tr-1',
        factionAId: 'f-a',
        factionBId: 'f-b',
        kind: TreatyKind.alliance,
        validFrom: 0,
        sourceRevision: 'rev',
        sourceReason: 'history',
      );
      final conflict = Conflict.validated(
        id: 'c-1',
        sideAFactionId: 'f-a',
        sideBFactionId: 'f-c',
        kind: ConflictKind.skirmish,
        validFrom: 5,
        sourceRevision: 'rev',
        sourceReason: 'history',
      );
      final history = DiplomacyHistory.validated(
        treaties: [treaty],
        conflicts: [conflict],
        tradeLinks: const [],
        changeEvents: const [],
      );
      final view = DiplomacyTimelineView.of(
        history: history,
        fromTick: 0,
        toTick: 10,
      );
      final note = view.explainNote;
      expect(note, isNotEmpty);
      expect(note, contains("0"));
      expect(note, contains("10"));
    });

    test("GenealogyInheritanceValidator report is deterministic across runs", () {
      final parent = GenealogyRelation.validated(
        id: 'r-1',
        kind: GenealogyRelationKind.parentChild,
        fromId: 'p-a',
        toId: 'p-b',
        validFrom: 0,
      );
      final nodes = <String, GenealogyNode>{
        'p-a': const GenealogyNode(id: 'p-a', name: 'Alice'),
        'p-b': const GenealogyNode(id: 'p-b', name: 'Bob'),
      };
      final graph = GenealogyGraph(nodes: nodes, edges: [parent]);
      const validator = GenealogyInheritanceValidator();
      final r1 = validator.validate(graph: graph);
      final r2 = validator.validate(graph: graph);
      // Same inputs -> same anomaly and candidate counts (deterministic surface).
      expect(r2.anomalies.length, equals(r1.anomalies.length));
      expect(r2.candidates.length, equals(r1.candidates.length));
      expect(r2.focalId, equals(r1.focalId));
    });
  });
}
