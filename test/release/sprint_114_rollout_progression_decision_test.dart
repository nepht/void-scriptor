import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/rollout_progression_decision_v114.dart';

void main() {
  group('114.37 Rollout Progression Decision', () {
    test('declares the four canonical decisions in roadmap order', () {
      expect(
        RolloutProgressionDecision.values
            .map((decision) => decision.wireName)
            .toList(growable: false),
        <String>['EXPAND', 'HOLD', 'REDUCE', 'ROLLBACK'],
      );
    });

    test('empty register is blocked without claiming a decision', () {
      final report = RolloutProgressionDecisionRegister().evaluate();

      expect(report.state, RolloutProgressionState.blocked);
      expect(report.decision, isNull);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('healthy evidence permits each canonical decision', () {
      for (final decision in RolloutProgressionDecision.values) {
        final register = RolloutProgressionDecisionRegister()
          ..add(
            RolloutProgressionRecord(
              healthEvidence: _healthEvidence(),
              decision: decision,
              rationale: 'Local health evidence supports this decision.',
            ),
          );

        final report = register.evaluate();
        expect(
          report.state,
          RolloutProgressionState.pass,
          reason: decision.wireName,
        );
        expect(report.decision, decision);
        expect(report.violations, isEmpty, reason: decision.wireName);
      }
    });

    test('failed health evidence cannot be expanded', () {
      final report =
          (RolloutProgressionDecisionRegister()..add(
                const RolloutProgressionRecord(
                  healthEvidence: <RolloutProgressionHealthEvidence>[
                    RolloutProgressionHealthEvidence(
                      name: 'crash_free_sessions',
                      source: 'local-fixture',
                      status: RolloutProgressionHealthStatus.failed,
                    ),
                  ],
                  decision: RolloutProgressionDecision.expand,
                  rationale:
                      'Attempt to expand despite a failed health signal.',
                ),
              ))
              .evaluate();

      expect(report.state, RolloutProgressionState.fail);
      expect(report.decision, RolloutProgressionDecision.expand);
      expect(report.violations, contains('health_failure_ignored'));
    });

    test('hold, reduce, and rollback remain valid with failed health', () {
      for (final decision in <RolloutProgressionDecision>[
        RolloutProgressionDecision.hold,
        RolloutProgressionDecision.reduce,
        RolloutProgressionDecision.rollback,
      ]) {
        final report =
            (RolloutProgressionDecisionRegister()..add(
                  RolloutProgressionRecord(
                    healthEvidence: <RolloutProgressionHealthEvidence>[
                      const RolloutProgressionHealthEvidence(
                        name: 'migration_health',
                        source: 'local-fixture',
                        status: RolloutProgressionHealthStatus.failed,
                      ),
                    ],
                    decision: decision,
                    rationale:
                        'Contain or pause the rollout until health recovers.',
                  ),
                ))
                .evaluate();

        expect(
          report.state,
          RolloutProgressionState.pass,
          reason: decision.wireName,
        );
        expect(report.violations, isEmpty, reason: decision.wireName);
      }
    });

    test('missing evidence, source, and rationale fail closed', () {
      final report =
          (RolloutProgressionDecisionRegister()..add(
                const RolloutProgressionRecord(
                  healthEvidence: <RolloutProgressionHealthEvidence>[],
                  decision: RolloutProgressionDecision.hold,
                  rationale: '   ',
                ),
              ))
              .evaluate();

      expect(report.state, RolloutProgressionState.fail);
      expect(report.violations, contains('health_evidence missing'));
      expect(report.violations, contains('rationale missing'));

      final malformed =
          (RolloutProgressionDecisionRegister()..add(
                const RolloutProgressionRecord(
                  healthEvidence: <RolloutProgressionHealthEvidence>[
                    RolloutProgressionHealthEvidence(
                      name: '   ',
                      source: '   ',
                      status: RolloutProgressionHealthStatus.healthy,
                    ),
                  ],
                  decision: RolloutProgressionDecision.hold,
                  rationale: 'Keep the local corrective scope paused.',
                ),
              ))
              .evaluate();
      expect(malformed.state, RolloutProgressionState.fail);
      expect(malformed.violations, contains('health name missing'));
      expect(malformed.violations, contains('health source missing'));
    });

    test(
      'manifest records the local decision contract and external boundary',
      () {
        final manifest =
            json.decode(
                  File(
                    'docs/planning/v1.2/sprint_114_rollout_progression_decision.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;

        expect(manifest['canonical_step'], '114.37');
        expect(manifest['decisions'], <String>[
          'EXPAND',
          'HOLD',
          'REDUCE',
          'ROLLBACK',
        ]);
        expect(manifest['external_rollout_execution'], 'DEFERRED-EXTERNAL');
        expect(manifest['actual_rollout_decision'], 'DEFERRED-EXTERNAL');
      },
    );
  });
}

List<RolloutProgressionHealthEvidence> _healthEvidence() {
  return <RolloutProgressionHealthEvidence>[
    const RolloutProgressionHealthEvidence(
      name: 'crash_free_sessions',
      source: 'local-fixture',
      status: RolloutProgressionHealthStatus.healthy,
    ),
  ];
}
