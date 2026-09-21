import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/release_validation_charter.dart';

void main() {
  group('113.2 Release Validation Charter', () {
    test('manifest exists with correct canonical step', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.2 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.2');
      expect(document['title'], 'Release Validation Charter');
    });

    test('manifest has all required top-level keys', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in ReleaseValidationCharter.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('has at least 5 validation questions with scope and owner', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final questions = document['validation_questions'] as List<dynamic>;
      expect(
        questions.length,
        greaterThanOrEqualTo(ReleaseValidationCharter.minQuestions),
      );

      for (final q in questions) {
        final map = q as Map<String, dynamic>;
        expect(map['id'], isNotEmpty);
        expect(map['question'], isNotEmpty);
        expect(map['scope'], isNotEmpty);
        expect(map['owner'], isNotEmpty);
      }
    });

    test('validation window has duration and owner', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final window = document['validation_window'] as Map<String, dynamic>;
      expect(window['duration'], isNotEmpty);
      expect(window['owner'], isNotEmpty);
    });

    test('scope has included and excluded lists', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final scope = document['scope'] as Map<String, dynamic>;
      final included = scope['included'] as List<dynamic>;
      final excluded = scope['excluded'] as List<dynamic>;
      expect(included, isNotEmpty);
      expect(excluded, isNotEmpty);
    });

    test('non-goals list is defined', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final nonGoals = document['non_goals'] as List<dynamic>;
      expect(nonGoals, isNotEmpty);
      expect(nonGoals, contains('New feature development'));
    });

    test('has at least 3 stop conditions', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final stopConditions = document['stop_conditions'] as List<dynamic>;
      expect(
        stopConditions.length,
        greaterThanOrEqualTo(ReleaseValidationCharter.minStopConditions),
      );
    });

    test('decision owners are defined for key roles', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final owners = document['decision_owners'] as Map<String, dynamic>;
      expect(owners['validation_result'], isNotEmpty);
      expect(owners['stop_ship'], isNotEmpty);
      expect(owners['rollback'], isNotEmpty);
    });

    test('domain validation passes with valid charter', () {
      final result = ReleaseValidationCharter.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('success criteria define go/no-go requirements', () {
      final file = File(ReleaseValidationCharter.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final criteria = document['success_criteria'] as Map<String, dynamic>;
      expect(criteria.containsKey('all_questions_answered'), isTrue);
      expect(criteria.containsKey('no_release_blockers'), isTrue);
      expect(criteria.containsKey('quality_gates_green'), isTrue);
      expect(criteria.containsKey('rollback_verified'), isTrue);
    });
  });
}
