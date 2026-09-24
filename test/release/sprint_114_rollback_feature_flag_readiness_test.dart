import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/features/world_logic/domain/rollback_feature_flag_readiness_v114.dart';

void main() {
  group('114.36 Rollback & Feature-Flag Readiness', () {
    test('declares all six canonical evidence groups in roadmap order', () {
      expect(RollbackFeatureFlagReadiness.requiredEvidence, <String>[
        'rollback_artifact',
        'kill_switch',
        'flag_matrix',
        'data_compatibility',
        'rollback_drill',
        'user_guidance',
      ]);
      expect(
        RollbackFeatureFlagReadiness.requiredEvidence.toSet().length,
        RollbackFeatureFlagReadiness.requiredEvidence.length,
      );
    });

    test('empty readiness is blocked without claiming rollback readiness', () {
      final report = RollbackFeatureFlagReadinessRegister().evaluate();

      expect(report.status, RollbackReadinessStatus.blocked);
      expect(report.readyEvidence, isEmpty);
      expect(
        report.missingEvidence,
        RollbackFeatureFlagReadiness.requiredEvidence,
      );
    });

    test('complete unique evidence evaluates ready', () {
      final register = RollbackFeatureFlagReadinessRegister()
        ..addEntries(_completeEvidence());
      final report = register.evaluate();

      expect(report.status, RollbackReadinessStatus.ready);
      expect(
        report.readyEvidence,
        containsAll(RollbackFeatureFlagReadiness.requiredEvidence),
      );
      expect(report.missingEvidence, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('missing or malformed evidence fails closed by canonical name', () {
      final register = RollbackFeatureFlagReadinessRegister()
        ..addEntries(
          _completeEvidence().where(
            (entry) =>
                entry.name != 'data_compatibility' &&
                entry.name != 'kill_switch',
          ),
        )
        ..add(
          const RollbackFeatureFlagReadinessEvidence(
            name: 'kill_switch',
            status: RollbackReadinessEvidenceStatus.verifiedLocal,
            sources: <String>[],
          ),
        );
      final report = register.evaluate();

      expect(report.status, RollbackReadinessStatus.fail);
      expect(report.missingEvidence, <String>['data_compatibility']);
      expect(report.invalidEvidence, <String>['kill_switch']);
      expect(report.violations, isNotEmpty);
    });

    test('duplicate and unexpected evidence never pass', () {
      final duplicate = RollbackFeatureFlagReadinessRegister()
        ..addEntries(_completeEvidence())
        ..add(
          const RollbackFeatureFlagReadinessEvidence(
            name: 'rollback_artifact',
            status: RollbackReadinessEvidenceStatus.verifiedLocal,
            sources: <String>['duplicate'],
          ),
        );
      final duplicateReport = duplicate.evaluate();
      expect(duplicateReport.status, RollbackReadinessStatus.fail);
      expect(duplicateReport.duplicateEvidence, <String>['rollback_artifact']);
      expect(duplicateReport.violations, isNotEmpty);

      final unexpected =
          (RollbackFeatureFlagReadinessRegister()..add(
                const RollbackFeatureFlagReadinessEvidence(
                  name: 'unknown_evidence',
                  status: RollbackReadinessEvidenceStatus.verifiedLocal,
                  sources: <String>['unexpected'],
                ),
              ))
              .evaluate();
      expect(unexpected.status, RollbackReadinessStatus.fail);
      expect(unexpected.unexpectedEvidence, <String>['unknown_evidence']);
    });

    test('unverified or deferred evidence is never counted as ready', () {
      final register = RollbackFeatureFlagReadinessRegister()
        ..addEntries(
          _completeEvidence().map(
            (entry) => entry.name == 'rollback_artifact'
                ? entry.copyWith(
                    status: RollbackReadinessEvidenceStatus.deferredExternal,
                  )
                : entry,
          ),
        );
      final report = register.evaluate();

      expect(report.status, RollbackReadinessStatus.fail);
      expect(report.unverifiedEvidence, <String>['rollback_artifact']);
      expect(report.violations.join(' '), contains('rollback_artifact'));
    });

    test('live kill-switch disables every registered v1.2 flag', () {
      final registry = FeatureFlagRegistry();
      registry.enable('vs12_lore_links');
      registry.enable('vs12_export');
      registry.enable('vs12_quests');

      registry.engageKillSwitch();

      expect(registry.killSwitchActive, isTrue);
      expect(registry.enabledFlags, isEmpty);
      for (final flag in kVs12FeatureFlags) {
        expect(registry.isEnabled(flag), isFalse, reason: flag);
      }
    });

    test('live compatibility constants match the retained data boundary', () {
      expect(VoidProjectFormat.currentSchema, 16);
      expect(kRollbackFeatureFlagReadinessDatabaseSchema, 62);
      expect(kRollbackFeatureFlagReadinessSupportedSourceSchemas, <int>[
        55,
        58,
        60,
        61,
      ]);
      expect(kRollbackFeatureFlagReadinessFutureSchemaPolicy, 'reject');
    });

    test(
      'manifest records every evidence source without claiming public trust',
      () {
        final file = File(
          'docs/planning/v1.2/sprint_114_rollback_feature_flag_readiness.json',
        );
        expect(file.existsSync(), isTrue);
        final manifest =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        expect(manifest['canonical_step'], '114.36');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(
          manifest['required_evidence'],
          RollbackFeatureFlagReadiness.requiredEvidence,
        );
        final evidence = manifest['evidence'] as Map<String, dynamic>;
        expect(
          evidence.keys.toList(),
          RollbackFeatureFlagReadiness.requiredEvidence,
        );
        for (final entry in evidence.values.cast<Map<String, dynamic>>()) {
          expect(entry['status'], 'verified_local');
          expect(entry['sources'], isNotEmpty);
        }
        expect(manifest['public_trust'], 'DEFERRED-EXTERNAL');
        expect(manifest['published_artifact_drill'], 'DEFERRED-EXTERNAL');
        expect(manifest['limits'], isNotEmpty);
      },
    );
  });
}

List<RollbackFeatureFlagReadinessEvidence> _completeEvidence() {
  return <RollbackFeatureFlagReadinessEvidence>[
    for (final name in RollbackFeatureFlagReadiness.requiredEvidence)
      RollbackFeatureFlagReadinessEvidence(
        name: name,
        status: RollbackReadinessEvidenceStatus.verifiedLocal,
        sources: <String>['docs/source/$name.json'],
      ),
  ];
}
