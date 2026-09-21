import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/ga_entry_gate.dart';

void main() {
  group('113.1 GA Entry Gate', () {
    test('manifest exists with correct canonical step and version', () {
      final file = File(GaEntryGate.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.1 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.1');
      expect(document['title'], 'GA Entry Gate');
      expect(document['version'], '1.2.0-rc.1');
      expect(document['target_version'], '1.2.0');
    });

    test('manifest has all six required evidence categories', () {
      final file = File(GaEntryGate.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final evidence = document['required_evidence'] as Map<String, dynamic>;
      for (final key in GaEntryGate.requiredEvidenceKeys) {
        expect(
          evidence.containsKey(key),
          isTrue,
          reason: 'Required evidence key missing: $key',
        );
      }
    });

    test('manifest references all nine Sprint 112 quality gates', () {
      final file = File(GaEntryGate.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final evidence = document['required_evidence'] as Map<String, dynamic>;
      final qualityGates =
          evidence['quality_gate_results'] as Map<String, dynamic>;
      final gates = qualityGates['gates'] as List<dynamic>;
      expect(gates.length, 9, reason: 'Must reference 9 quality gates');

      for (final gatePath in GaEntryGate.qualityGatePaths) {
        expect(
          gates.any((g) => g['path'] == gatePath),
          isTrue,
          reason: 'Quality gate path missing: $gatePath',
        );
      }
    });

    test('manifest documents limits and decision', () {
      final file = File(GaEntryGate.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final limits = document['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
      expect(limits.join(' '), contains('DEFERRED'));

      expect(document['decision'], isNotEmpty);
      expect(document['decision'], contains('LOCAL'));
    });

    test('all quality gate manifest files exist on disk', () {
      for (final path in GaEntryGate.qualityGatePaths) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Quality gate manifest must exist: $path',
        );
      }
    });

    test('required documentation files exist', () {
      expect(
        File(GaEntryGate.knownLimitsPath).existsSync(),
        isTrue,
        reason: 'Known limits doc must exist',
      );
      expect(
        File(GaEntryGate.recoveryGuidePath).existsSync(),
        isTrue,
        reason: 'Recovery guide must exist',
      );
      expect(
        File(GaEntryGate.supportPlaybookPath).existsSync(),
        isTrue,
        reason: 'Support playbook must exist',
      );
      expect(
        File(GaEntryGate.rcApprovalPath).existsSync(),
        isTrue,
        reason: 'RC approval gate doc must exist',
      );
      expect(
        File(GaEntryGate.rcArtifactPath).existsSync(),
        isTrue,
        reason: 'RC artifact reproducibility doc must exist',
      );
    });

    test('release build artifact exists', () {
      expect(
        File(GaEntryGate.releaseExe).existsSync(),
        isTrue,
        reason: 'Release executable must exist',
      );
    });

    test('domain validation passes with all evidence present', () {
      final result = GaEntryGate.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('Sprint 112 closure is verified', () {
      final file = File(GaEntryGate.rcApprovalPath);
      expect(file.existsSync(), isTrue);

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['decision'], 'DEFERRED_EXTERNAL_GATES');
      expect(document['rollback_readiness'], isNotNull);

      final rollback = document['rollback_readiness'] as Map<String, dynamic>;
      expect(rollback['status'], isNotEmpty);
      expect(rollback['backup_before_migration'], isTrue);
    });
  });
}
