import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/capabilities/reactivation_dependency_map.dart';

/// Sprint 145.39 - Non-Core Preservation and Disablement.
///
/// Gap: "document reactivation dependencies". Setiap capability deferred
/// (sumber kanonik: core_mvp_scope_reset_spec.json -> deferred_until_evidence)
/// wajib punya entri reaktivasi eksplisit: id stabil, label, feature flag
/// (atau null bila belum ada flag khusus), modul lib/features yang benar-benar
/// ada di tree, entry evidence sesuai kontrak 145.17, dan default state.
///
/// Test ini RED dulu: ReactivationDependencyMap belum ada.
void main() {
  group('ReactivationDependencyMap contract', () {
    test('mendaftarkan semua 10 capability deferred dari spec kanonik', () {
      const entries = ReactivationDependencyMap.entries;
      final ids = entries.map((e) => e.capabilityId).toSet();

      expect(ids, contains('COMMUNITY_CHAT'));
      expect(ids, contains('READER_PLATFORM'));
      expect(ids, contains('PUBLIC_PUBLISHING'));
      expect(ids, contains('AUTHOR_PAYMENT_AND_PAYOUT'));
      expect(ids, contains('CONNECTOR_MARKETPLACE'));
      expect(ids, contains('DEVELOPER_PLATFORM'));
      expect(ids, contains('MULTI_REGION'));
      expect(ids, contains('MOBILE_FULL_EDITOR'));
      expect(ids, contains('MACOS_RELEASE'));
      expect(ids, contains('DOZENS_OF_AI_AND_CLOUD_PROVIDERS'));

      expect(entries.length, greaterThanOrEqualTo(10));
    });

    test(
      'setiap entry punya id unik, label, dan entry evidence non-kosong',
      () {
        const entries = ReactivationDependencyMap.entries;
        final ids = <String>[];
        for (final entry in entries) {
          expect(entry.capabilityId, isNotEmpty);
          expect(entry.label, isNotEmpty, reason: entry.capabilityId);
          expect(entry.layer, isNotEmpty, reason: entry.capabilityId);
          final flag = entry.owningFlag;
          if (flag != null) {
            expect(
              flag.startsWith('vs12_'),
              isTrue,
              reason: 'flag harus namespace registry vs12_: $flag',
            );
          }
          expect(
            entry.entryEvidence,
            isNotEmpty,
            reason:
                '${entry.capabilityId} wajib punya entry evidence '
                '(kontrak 145.17)',
          );
          expect(
            ids.contains(entry.capabilityId),
            isFalse,
            reason: 'duplicate capabilityId ${entry.capabilityId}',
          );
          ids.add(entry.capabilityId);
        }
      },
    );

    test('setiap module yang dideklarasikan benar-benar ada di tree', () {
      const entries = ReactivationDependencyMap.entries;
      final missing = <String>[];
      for (final entry in entries) {
        for (final module in entry.featureModules) {
          final dir = Directory('lib/features/$module');
          if (!dir.existsSync()) missing.add('${entry.capabilityId}:$module');
        }
      }
      expect(
        missing,
        isEmpty,
        reason:
            'peta reaktivasi tidak boleh menyebut modul imajiner: '
            '${missing.join(', ')}',
      );
    });

    test('tidak ada capability deferred yang mengklaim modul Core', () {
      const entries = ReactivationDependencyMap.entries;
      const forbiddenCorePaths = <String>[
        'lib/core/feature_flags',
        'lib/core/capabilities',
        'lib/core/project_package',
        'lib/core/persistence',
        'lib/core/domain',
      ];
      final violations = <String>[];
      for (final entry in entries) {
        for (final module in entry.featureModules) {
          if (forbiddenCorePaths.contains('lib/features/$module')) {
            violations.add('${entry.capabilityId}:$module');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'capability deferred tidak boleh mengklaim modul Core '
            'sebagai miliknya: ${violations.join(', ')}',
      );
    });

    test('semua capability deferred default-nya OFF atau DEFERRED', () {
      const entries = ReactivationDependencyMap.entries;
      for (final entry in entries) {
        expect(
          entry.defaultState == ReactivationDefaultState.off ||
              entry.defaultState == ReactivationDefaultState.deferred,
          isTrue,
          reason:
              '${entry.capabilityId} default harus off/deferred, '
              'bukan ${entry.defaultState}',
        );
      }
    });

    test('entry tanpa modul tree hanya boleh untuk platform follow-up', () {
      const entries = ReactivationDependencyMap.entries;
      for (final entry in entries) {
        expect(entry.entryEvidence, isNotEmpty);
        if (entry.featureModules.isEmpty) {
          expect(
            entry.capabilityId,
            isIn(<String>[
              // Platform follow-up tanpa modul tree, plus demo engine
              // capabilities (dibekukan Choi 2026-09-05) yang modul demonya
              // hidup di lib/core/<domain>/, bukan lib/features/.
              'MOBILE_FULL_EDITOR',
              'MACOS_RELEASE',
              'MULTI_REGION',
              'RENDER_ENGINE',
              'ANIMATION_ENGINE',
              'VIRTUAL_PRODUCTION',
              'ENTERPRISE_STUDIO',
              'KNOWLEDGE_ENGINE',
              'AGENT_RUNTIME',
              'STUDIO_COMMAND_CENTER',
              'CREATIVE_OS',
              'XR_STUDIO',
              'METAVERSE_STUDIO',
            ]),
            reason:
                'hanya platform follow-up dan demo engine yang boleh '
                'tanpa modul lib/features',
          );
        }
      }
    });
  });
}
