import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/rollback_drill.dart';

void main() {
  group('113.7 Rollback Drill', () {
    test('manifest exists with correct canonical step', () {
      final file = File(RollbackDrill.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.7 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.7');
      expect(document['title'], 'Rollback Drill');
    });

    test('manifest has all required top-level keys', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in RollbackDrill.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('drill script is defined with steps', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final drillScript = document['drill_script'] as Map<String, dynamic>;
      expect(drillScript.containsKey('steps'), isTrue);
      final steps = drillScript['steps'] as List<dynamic>;
      expect(steps.length, greaterThanOrEqualTo(3));
      for (final step in steps) {
        final map = step as Map<String, dynamic>;
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('command'), isTrue);
      }
    });

    test('artifact withdrawal procedure is defined', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final withdrawal =
          document['artifact_withdrawal'] as Map<String, dynamic>;
      expect(withdrawal.containsKey('method'), isTrue);
      expect(withdrawal.containsKey('verification'), isTrue);
    });

    test('flag disable drill covers shared kill switch', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final flagDisable = document['flag_disable'] as Map<String, dynamic>;
      expect(flagDisable.containsKey('method'), isTrue);
      expect(flagDisable.containsKey('flags_affected'), isTrue);
      expect(flagDisable.containsKey('verification'), isTrue);
    });

    test('backup restore drill is defined', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final backupRestore = document['backup_restore'] as Map<String, dynamic>;
      expect(backupRestore.containsKey('steps'), isTrue);
      expect(backupRestore.containsKey('success_criteria'), isTrue);
    });

    test('communication draft template exists', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final comm = document['communication_draft'] as Map<String, dynamic>;
      expect(comm.containsKey('template'), isTrue);
      expect(comm['template'].toString().isNotEmpty, isTrue);
      expect(comm.containsKey('channels'), isTrue);
    });

    test('timings and findings sections exist', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('timings'), isTrue);
      expect(document.containsKey('findings'), isTrue);

      final timings = document['timings'] as Map<String, dynamic>;
      expect(timings.containsKey('estimated_duration'), isTrue);

      final findings = document['findings'] as Map<String, dynamic>;
      expect(findings.containsKey('status'), isTrue);
    });

    test('decision and limits are defined', () {
      final file = File(RollbackDrill.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('decision'), isTrue);
      expect(document['decision'].toString().isNotEmpty, isTrue);
      expect(document.containsKey('limits'), isTrue);
      final limits = document['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
    });

    test('domain validation passes with valid manifest', () {
      final result = RollbackDrill.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
