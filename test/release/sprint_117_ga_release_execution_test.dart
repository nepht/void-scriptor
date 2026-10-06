import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_ga_release_execution.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.3/sprint_117_ga_release_execution.json',
  );

  group('117.46 General Availability Release', () {
    test(
      '117.46-GATE-ORDER declares the seven canonical execution requirements in canonical order',
      () {
        expect(Sprint117GaReleaseExecution.requiredOutputs, <String>[
          'approval_recorded',
          'artifact_published',
          'connector_subset_enforced',
          'uncertified_hidden',
          'monitoring_active',
          'support_ready',
          'rollback_available',
        ]);
        expect(Sprint117GaReleaseExecution.canonicalStep, '117.46');
      },
    );

    test(
      'execution manifest exists and is honest about external boundaries',
      () {
        expect(manifestFile.existsSync(), isTrue);
        final manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        expect(manifest['canonical_step'], '117.46');
        expect(manifest['status'], 'PARTIAL-LOCAL');
        expect(manifest['decision'], 'BLOCKED_EXTERNAL_GATES');
        expect(manifest['execution_authorized'], isFalse);

        final outputs = manifest['outputs'] as Map<String, dynamic>;
        expect(
          manifest['approval_source'],
          'docs/planning/v1.3/sprint_117_ga_approval_gate.json',
        );
        expect(
          (outputs['approval_recorded'] as Map<String, dynamic>)['status'],
          isNot('VERIFIED'),
        );
        expect(
          outputs.keys.toSet(),
          Sprint117GaReleaseExecution.requiredOutputs.toSet(),
        );
        for (final name in Sprint117GaReleaseExecution.requiredOutputs) {
          final output = outputs[name] as Map<String, dynamic>;
          expect(output['status'], isA<String>());
          expect(output['evidence'], isA<List<dynamic>>());
          expect((output['note'] as String).trim(), isNotEmpty);
        }

        final limitations = (manifest['limitations'] as List<dynamic>)
            .join(' ')
            .toLowerCase();
        expect(limitations, contains('hosted ci'));
        expect(limitations, contains('public telemetry'));
      },
    );

    test(
      '117.46-EVIDENCE-TOPIC evidence paths exist and are topically about their output',
      () {
        final manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        const topicalKeywords = <String, String>{
          'approval_recorded': 'approval',
          'artifact_published': 'artifact',
          'connector_subset_enforced': 'subset',
          'uncertified_hidden': 'hidden',
          'monitoring_active': 'telemetry',
          'support_ready': 'support',
          'rollback_available': 'rollback',
        };
        final outputs = manifest['outputs'] as Map<String, dynamic>;
        for (final entry in topicalKeywords.entries) {
          final output = outputs[entry.key] as Map<String, dynamic>;
          final paths = (output['evidence'] as List<dynamic>).cast<String>();
          expect(paths, isNotEmpty, reason: '${entry.key} cites no evidence');
          final bodies = StringBuffer();
          for (final path in paths) {
            final file = File(path);
            expect(
              file.existsSync(),
              isTrue,
              reason: '$path cited by ${entry.key} does not exist',
            );
            bodies.write(file.readAsStringSync().toLowerCase());
            bodies.write(' ');
          }
          expect(
            bodies.toString(),
            contains(entry.value),
            reason:
                'evidence cited by ${entry.key} never mentions "${entry.value}"',
          );
        }
      },
    );

    test('domain fails closed when any execution output is unverified', () {
      final complete = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: <String>['evidence.json'],
            note: 'verified',
          ),
      };
      final pending = Map<String, Sprint117GaOutputRecord>.from(complete)
        ..['monitoring_active'] = const Sprint117GaOutputRecord(
          status: Sprint117GaOutputStatus.unverifiable,
          evidence: <String>[],
          note: 'public telemetry unavailable',
        );

      final evaluation = Sprint117GaReleaseExecution.evaluate(
        const Sprint117GaReleaseExecution(
          approvalAuthorized: true,
          outputs: {},
        ),
      );
      expect(evaluation.state, Sprint117GaReleaseExecutionState.blocked);
      expect(evaluation.missing, contains('approval_recorded'));

      final partial = Sprint117GaReleaseExecution.evaluate(
        Sprint117GaReleaseExecution(approvalAuthorized: true, outputs: pending),
      );
      expect(partial.state, Sprint117GaReleaseExecutionState.blocked);
      expect(partial.missing, contains('monitoring_active'));

      final pass = Sprint117GaReleaseExecution.evaluate(
        Sprint117GaReleaseExecution(
          approvalAuthorized: true,
          outputs: complete,
        ),
      );
      expect(pass.state, Sprint117GaReleaseExecutionState.pass);
      expect(pass.missing, isEmpty);
    });

    test('authorization is required even when all outputs are present', () {
      final complete = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: <String>['evidence.json'],
            note: 'verified',
          ),
      };
      final evaluation = Sprint117GaReleaseExecution.evaluate(
        Sprint117GaReleaseExecution(
          approvalAuthorized: false,
          outputs: complete,
        ),
      );
      expect(evaluation.state, Sprint117GaReleaseExecutionState.fail);
      expect(evaluation.notes.join(' '), contains('authorization'));
    });

    test('117.46-GATE-BOUND the gate evaluates the committed manifest, not a '
        'caller-supplied record, and reports the honest blocked verdict', () {
      final report = const Sprint117GaReleaseGate().evaluate();
      expect(
        report.state,
        Sprint117GaReleaseExecutionState.blocked,
        reason:
            'committed evidence records BLOCKED_EXTERNAL_GATES with all '
            'outputs unverified; the gate must not report pass',
      );
      expect(report.verdict, 'GA_RELEASE_EXECUTION_BLOCKED_EXTERNAL');
      expect(report.missingOutputs, contains('approval_recorded'));
      expect(report.violations, isEmpty);
      expect(
        report.openItems.any((item) => item.startsWith('release_decision:')),
        isTrue,
        reason: 'the recorded release decision must be carried, not hidden',
      );
    });

    test('117.46-GATE-FAIL-CLOSED an unreadable manifest is undetermined, '
        'never permission', () {
      final report = const Sprint117GaReleaseGate().evaluateWith(null);
      expect(report.state, Sprint117GaReleaseExecutionState.blocked);
      expect(report.verdict, 'GA_RELEASE_EXECUTION_MANIFEST_UNREADABLE');
      expect(
        report.missingOutputs.toSet(),
        Sprint117GaReleaseExecution.requiredOutputs.toSet(),
      );
      expect(report.violations, contains('execution_manifest_unreadable'));
    });

    test('117.46-GATE-OVERCLAIM a verified output with absent evidence fails '
        'the gate instead of passing it', () {
      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };
      final overclaim = Map<String, Sprint117GaOutputRecord>.from(outputs)
        ..['artifact_published'] = const Sprint117GaOutputRecord(
          status: Sprint117GaOutputStatus.verified,
          evidence: <String>['docs/planning/v1.3/does_not_exist.json'],
          note: 'claims verified',
        );

      final report = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: overclaim,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
        ),
      );
      expect(report.state, Sprint117GaReleaseExecutionState.fail);
      expect(report.verdict, 'GA_RELEASE_EXECUTION_EVIDENCE_VIOLATION');
      expect(
        report.violations.any(
          (v) => v.startsWith('verified_without_evidence:artifact_published:'),
        ),
        isTrue,
      );
    });

    test('117.46-GATE-DECISION a blocking release decision forbids pass even '
        'when every output record claims verified', () {
      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };

      final blocked = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'DELAY',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'AUTHORIZED',
        ),
      );
      expect(blocked.state, Sprint117GaReleaseExecutionState.fail);
      expect(blocked.verdict, 'GA_RELEASE_EXECUTION_DECISION_BLOCKS_RELEASE');

      // Control: with a genuine authorization the same record does pass, so
      // the gate is not simply always-fail.
      final authorized = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'AUTHORIZED',
        ),
      );
      expect(authorized.state, Sprint117GaReleaseExecutionState.pass);
      expect(authorized.verdict, 'GA_RELEASE_EXECUTION_VERIFIED');
    });

    test('117.46-GATE-DRIFT an unknown status word or unknown decision is '
        'drift, not a pass', () {
      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };

      final unknownStatus = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{
            'monitoring_active': 'WONKY',
          },
          approvalSourceAuthorized: true,
        ),
      );
      expect(unknownStatus.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        unknownStatus.violations,
        contains('unknown_output_status:monitoring_active:WONKY'),
      );

      final unknownDecision = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'SHIP_IT',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
        ),
      );
      expect(unknownDecision.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        unknownDecision.violations,
        contains('unknown_release_decision:SHIP_IT'),
      );
    });

    test('117.46-GATE-AUTHORIZATION the execution manifest cannot be the only '
        'witness to its own authorization', () {
      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };

      // The record claims authorization, but the committed approval gate says
      // otherwise: that disagreement fails, it does not pass.
      final disagrees = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: false,
          approvalSourceDecision: 'delay',
        ),
      );
      expect(disagrees.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        disagrees.violations.any(
          (v) => v.startsWith('authorization_disagrees_with_approval_gate:'),
        ),
        isTrue,
      );

      // An unreadable approval source is undetermined, so it cannot be
      // treated as a pass either.
      final unreadable = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
        ),
      );
      expect(unreadable.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        unreadable.violations,
        contains('authorization_source_unreadable'),
      );
    });

    test('117.46-GATE-AUTH-DECISION a blocking approval-source decision forbids '
        'pass even when the approval flag reads authorized', () {
      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };

      // The committed approval gate (117.45) records decision "delay". The
      // decision word is a second witness in the same source as the boolean
      // flag: even if the flag read true, a gate that says delay cannot
      // authorize execution.
      final blocking = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'delay',
        ),
      );
      expect(blocking.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        blocking.violations.any(
          (v) =>
              v.startsWith('authorization_source_decision_blocks_execution:'),
        ),
        isTrue,
      );

      // An unrecognised approval-source decision word is drift, not permission.
      final unknown = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'MAYBE_LATER',
        ),
      );
      expect(unknown.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        unknown.violations.any(
          (v) => v.startsWith('unknown_approval_source_decision:'),
        ),
        isTrue,
      );

      // Control: a genuinely authorized approval source still passes, so the
      // gate is not simply always-fail.
      final authorized = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'AUTHORIZED',
        ),
      );
      expect(authorized.state, Sprint117GaReleaseExecutionState.pass);
    });

    test('117.46-GATE-AUTH-DECISION-MISSING an approval source that '
        'authorized by its flag but recorded no decision word is '
        'undetermined, not permission', () {
      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };

      // The approval source's boolean reads authorized, but its decision word
      // is absent. The decision word is a second witness in the same source:
      // a source that is silent about its decision has not corroborated the
      // flag, and absent evidence is undetermined, never permission.
      final absent = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: null,
        ),
      );
      expect(absent.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        absent.violations,
        contains('authorization_source_decision_missing'),
      );

      // The same holds when the word is present but blank: an empty string is
      // absence, not a decision.
      final blank = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: '   ',
        ),
      );
      expect(blank.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        blank.violations,
        contains('authorization_source_decision_missing'),
      );

      // Control: when the decision word is present and authorizing, the same
      // record passes, so the gate is not simply always-fail.
      final authorized = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'AUTHORIZED',
        ),
      );
      expect(authorized.state, Sprint117GaReleaseExecutionState.pass);
    });

    test('117.46-STATUS-VOCABULARY partial is a representable status and is '
        'never silently promoted to verified', () {
      expect(
        Sprint117GaReleaseContract.statusFromText('PARTIAL'),
        Sprint117GaOutputStatus.partial,
      );
      expect(
        Sprint117GaReleaseContract.statusFromText('partial'),
        Sprint117GaOutputStatus.partial,
      );
      expect(
        Sprint117GaReleaseContract.statusFromText('WONKY'),
        Sprint117GaOutputStatus.blocked,
      );
      expect(Sprint117GaReleaseContract.isKnownStatus('PARTIAL'), isTrue);
      expect(Sprint117GaReleaseContract.isKnownStatus('WONKY'), isFalse);
    });

    test('117.46-EVALUATION-RECORD the emitted evaluation record agrees with '
        'the gate it came from', () {
      final record = File(
        'docs/planning/v1.3/sprint_117_ga_release_execution_evaluation.json',
      );
      expect(
        record.existsSync(),
        isTrue,
        reason: 'the evaluation record must be emitted by the gate',
      );
      final decoded =
          jsonDecode(record.readAsStringSync()) as Map<String, dynamic>;
      final report = const Sprint117GaReleaseGate().evaluate();

      expect(decoded['canonical_step'], '117.46');
      expect(decoded['state'], report.state.name);
      expect(decoded['verdict'], report.verdict);
      expect(decoded['missing_outputs'], report.missingOutputs);
      expect(decoded['violations'], report.violations);
      expect(decoded['open_items'], report.openItems);
      expect(decoded['execution_authorized'], isFalse);
      expect(
        decoded['approval_source'],
        Sprint117GaReleaseContract.approvalManifestPath,
      );
    });
    test('117.46-GATE-TOPIC a verified output backed by an existing but '
        'off-topic file fails the gate instead of passing it', () {
      // The contract's topical witness must be the same vocabulary the gate
      // enforces, pinned here by a literal so the two cannot drift apart.
      expect(Sprint117GaReleaseContract.outputTopics, const <String, String>{
        'approval_recorded': 'approval',
        'artifact_published': 'artifact',
        'connector_subset_enforced': 'subset',
        'uncertified_hidden': 'hidden',
        'monitoring_active': 'telemetry',
        'support_ready': 'support',
        'rollback_available': 'rollback',
      });

      const realEvidence = <String>[
        'docs/planning/v1.3/sprint_117_ga_release_execution.json',
      ];
      final outputs = <String, Sprint117GaOutputRecord>{
        for (final name in Sprint117GaReleaseExecution.requiredOutputs)
          name: const Sprint117GaOutputRecord(
            status: Sprint117GaOutputStatus.verified,
            evidence: realEvidence,
            note: 'verified',
          ),
      };

      // The committed execution manifest is topically about every output, so
      // the same record passes: the control proves the new rule is not
      // always-fail.
      final control = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: outputs,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'AUTHORIZED',
        ),
      );
      expect(control.state, Sprint117GaReleaseExecutionState.pass);

      // An existing file that says nothing about telemetry is not evidence
      // that monitoring is active. Presence is not relevance: accepting it
      // would let the word "verified" do no work.
      final offTopic = Map<String, Sprint117GaOutputRecord>.from(outputs)
        ..['monitoring_active'] = const Sprint117GaOutputRecord(
          status: Sprint117GaOutputStatus.verified,
          evidence: <String>['pubspec.yaml'],
          note: 'claims verified',
        );
      final report = const Sprint117GaReleaseGate().evaluateWith(
        Sprint117GaReleaseEvidence(
          execution: Sprint117GaReleaseExecution(
            approvalAuthorized: true,
            outputs: offTopic,
          ),
          recordedDecision: 'AUTHORIZED',
          recordedAuthorized: true,
          unrecognisedStatuses: const <String, String>{},
          approvalSourceAuthorized: true,
          approvalSourceDecision: 'AUTHORIZED',
        ),
      );
      expect(report.state, Sprint117GaReleaseExecutionState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith(
            'verified_without_topical_evidence:monitoring_active',
          ),
        ),
        isTrue,
      );
    });
  });
}
