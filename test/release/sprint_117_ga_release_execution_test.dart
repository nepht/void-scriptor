import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/ga_release_execution.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.3/sprint_117_ga_release_execution.json',
  );

  group('117.46 General Availability Release', () {
    test('declares the seven canonical execution requirements in order', () {
      expect(GaReleaseExecution.requiredOutputs, <String>[
        'approval_recorded',
        'artifact_published',
        'connector_subset_enforced',
        'uncertified_hidden',
        'support_ready',
        'monitoring_active',
        'rollback_available',
      ]);
      expect(GaReleaseExecution.canonicalStep, '117.46');
    });

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
          GaReleaseExecution.requiredOutputs.toSet(),
        );
        for (final name in GaReleaseExecution.requiredOutputs) {
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

    test('domain fails closed when any execution output is unverified', () {
      final complete = <String, GaOutputRecord>{
        for (final name in GaReleaseExecution.requiredOutputs)
          name: const GaOutputRecord(
            status: GaOutputStatus.verified,
            evidence: <String>['evidence.json'],
            note: 'verified',
          ),
      };
      final pending = Map<String, GaOutputRecord>.from(complete)
        ..['monitoring_active'] = const GaOutputRecord(
          status: GaOutputStatus.unverifiable,
          evidence: <String>[],
          note: 'public telemetry unavailable',
        );

      final evaluation = GaReleaseExecution.evaluate(
        const GaReleaseExecution(approvalAuthorized: true, outputs: {}),
      );
      expect(evaluation.state, GaReleaseExecutionState.blocked);
      expect(evaluation.missing, contains('approval_recorded'));

      final partial = GaReleaseExecution.evaluate(
        GaReleaseExecution(approvalAuthorized: true, outputs: pending),
      );
      expect(partial.state, GaReleaseExecutionState.blocked);
      expect(partial.missing, contains('monitoring_active'));

      final pass = GaReleaseExecution.evaluate(
        GaReleaseExecution(approvalAuthorized: true, outputs: complete),
      );
      expect(pass.state, GaReleaseExecutionState.pass);
      expect(pass.missing, isEmpty);
    });

    test('authorization is required even when all outputs are present', () {
      final complete = <String, GaOutputRecord>{
        for (final name in GaReleaseExecution.requiredOutputs)
          name: const GaOutputRecord(
            status: GaOutputStatus.verified,
            evidence: <String>['evidence.json'],
            note: 'verified',
          ),
      };
      final evaluation = GaReleaseExecution.evaluate(
        GaReleaseExecution(approvalAuthorized: false, outputs: complete),
      );
      expect(evaluation.state, GaReleaseExecutionState.fail);
      expect(evaluation.notes.join(' '), contains('authorization'));
    });
  });
}
