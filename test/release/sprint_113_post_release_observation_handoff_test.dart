import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/post_release_observation_handoff.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_113_post_release_observation_handoff.json',
  );

  group('113.45 Post-Release Observation Handoff', () {
    test('declares the seven canonical handoff outputs in order', () {
      expect(PostReleaseObservationHandoff.requiredOutputs, <String>[
        'health_baseline',
        'monitoring_owners',
        'incident_queue',
        'feedback_queue',
        'risk_register',
        'rollback_criteria',
        'observation_window',
      ]);
      expect(PostReleaseObservationHandoff.canonicalStep, '113.45');
    });

    test(
      'manifest records deferred-release handoff without false activation',
      () {
        expect(manifestFile.existsSync(), isTrue);
        final manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        expect(manifest['canonical_step'], '113.45');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['handoff_mode'], 'DEFERRED_RELEASE');
        expect(manifest['monitoring_active'], isFalse);
        expect(manifest['external_communication_sent'], isFalse);

        final outputs = manifest['outputs'] as Map<String, dynamic>;
        expect(
          outputs.keys.toSet(),
          PostReleaseObservationHandoff.requiredOutputs.toSet(),
        );
        for (final name in PostReleaseObservationHandoff.requiredOutputs) {
          final output = outputs[name] as Map<String, dynamic>;
          expect(output['status'], isA<String>());
          expect((output['evidence'] as List<dynamic>), isNotEmpty);
          expect((output['note'] as String).trim(), isNotEmpty);
        }
      },
    );

    test('requires explicit deferred mode and all output records', () {
      final complete = <String, HandoffOutput>{
        for (final name in PostReleaseObservationHandoff.requiredOutputs)
          name: const HandoffOutput(
            status: HandoffOutputStatus.deferred,
            evidence: <String>['handoff.json'],
            note: 'deferred pending external gate',
          ),
      };

      expect(
        PostReleaseObservationHandoff.evaluate(null).state,
        ObservationHandoffState.blocked,
      );
      final noMode = PostReleaseObservationHandoff.evaluate(
        PostReleaseObservationHandoff(
          deferredRelease: false,
          outputs: complete,
        ),
      );
      expect(noMode.state, ObservationHandoffState.fail);
      expect(noMode.notes.join(' '), contains('deferred'));

      final partial = Map<String, HandoffOutput>.from(complete)
        ..remove('risk_register');
      final incomplete = PostReleaseObservationHandoff.evaluate(
        PostReleaseObservationHandoff(deferredRelease: true, outputs: partial),
      );
      expect(incomplete.state, ObservationHandoffState.blocked);
      expect(incomplete.missing, contains('risk_register'));

      final pass = PostReleaseObservationHandoff.evaluate(
        PostReleaseObservationHandoff(deferredRelease: true, outputs: complete),
      );
      expect(pass.state, ObservationHandoffState.pass);
      expect(pass.missing, isEmpty);
    });
  });
}
