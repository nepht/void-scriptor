import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/power_escalation_signals.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rulebook.dart';
import 'package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart';

void main() {
  group('Power Escalation Signals', () {
    final rulebook = PowerRulebook.validated(abilities: const []);
    final source = PowerUsageSource.validated(
      revision: 'draft-1',
      reason: 'canon',
    );

    test('new_power_signal flags first occurrence of an ability', () {
      final detector = PowerEscalationSignals(rulebook: rulebook);
      final ledger = PowerUsageLedger.validated(
        events: [
          PowerUsageEvent.validated(
            id: 'use-1',
            abilityId: 'fly',
            actorId: 'qowner',
            sceneId: 'scene-1',
            tick: 5,
            resourceChanges: const [],
            consequences: const [],
            source: source,
          ),
        ],
      );
      final report = detector.evaluate(ledger: ledger, dismissal: const {});
      expect(
        report.signals.map((s) => s.kind),
        contains(PowerEscalationKind.newPower),
      );
    });

    test(
      'unearned_exception_signal flags usage without prerequisite in history',
      () {
        final detector = PowerEscalationSignals(rulebook: rulebook);
        final ledger = PowerUsageLedger.validated(
          events: [
            PowerUsageEvent.validated(
              id: 'use-2',
              abilityId: 'fly',
              actorId: 'qowner',
              sceneId: 'scene-1',
              tick: 100,
              resourceChanges: const [],
              consequences: const [],
              source: source,
            ),
          ],
        );
        final report = detector.evaluate(
          ledger: ledger,
          dismissal: const {},
          contextPrerequisitesForAbility: {
            "fly": ["training"],
          },
        );
        expect(
          report.signals.map((s) => s.kind),
          contains(PowerEscalationKind.unearnedException),
        );
      },
    );

    test(
      'scale_jump_signal flags magnitude growth beyond custom threshold',
      () {
        final detector = PowerEscalationSignals(
          rulebook: rulebook,
          scaleJumpThreshold: 3,
        );
        final ledger = PowerUsageLedger.validated(
          events: [
            PowerUsageEvent.validated(
              id: 'use-3',
              abilityId: 'fly',
              actorId: 'qowner',
              sceneId: 'scene-1',
              tick: 1,
              resourceChanges: [
                PowerResourceChange.validated(
                  resource: 'mana',
                  amount: -1,
                  reason: 'channeling',
                ),
              ],
              consequences: const [],
              source: source,
            ),
            PowerUsageEvent.validated(
              id: 'use-4',
              abilityId: 'fly',
              actorId: 'qowner',
              sceneId: 'scene-1',
              tick: 10,
              resourceChanges: [
                PowerResourceChange.validated(
                  resource: 'mana',
                  amount: -5,
                  reason: 'channeling',
                ),
              ],
              consequences: const [],
              source: source,
            ),
          ],
        );
        final report = detector.evaluate(ledger: ledger, dismissal: const {});
        expect(
          report.signals.map((s) => s.kind),
          contains(PowerEscalationKind.scaleJump),
        );
      },
    );

    test('dismissal_reason suppresses future signal', () {
      final detector = PowerEscalationSignals(rulebook: rulebook);
      final ledger = PowerUsageLedger.validated(
        events: [
          PowerUsageEvent.validated(
            id: 'use-5',
            abilityId: 'fly',
            actorId: 'qowner',
            sceneId: 'scene-1',
            tick: 5,
            resourceChanges: const [],
            consequences: const [],
            source: source,
          ),
        ],
      );
      final report = detector.evaluate(
        ledger: ledger,
        dismissal: {
          'fly': const PowerEscalationDismissal(
            kind: PowerEscalationKind.newPower,
            reason: 'awakened in chapter 2',
          ),
        },
      );
      expect(
        report.signals.map((s) => s.kind),
        isNot(contains(PowerEscalationKind.newPower)),
      );
      expect(report.dismissals.single.reason, 'awakened in chapter 2');
    });

    test('report explain lists signals deterministically', () {
      final detector = PowerEscalationSignals(rulebook: rulebook);
      final ledger = PowerUsageLedger.validated(
        events: [
          PowerUsageEvent.validated(
            id: 'use-6',
            abilityId: 'fly',
            actorId: 'qowner',
            sceneId: 'scene-1',
            tick: 5,
            resourceChanges: const [],
            consequences: const [],
            source: source,
          ),
        ],
      );
      final report = detector.evaluate(ledger: ledger, dismissal: const {});
      final note = report.explain();
      expect(note, contains('fly'));
      expect(note, isNotEmpty);
      expect(report.isClean, isFalse);
    });
  });
}
