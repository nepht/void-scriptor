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
  });
}
