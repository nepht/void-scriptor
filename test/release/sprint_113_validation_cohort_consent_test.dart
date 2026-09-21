import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/validation_cohort_consent.dart';

void main() {
  group('113.3 Validation Cohort & Consent', () {
    test('manifest exists with correct canonical step', () {
      final file = File(ValidationCohortConsent.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.3 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.3');
      expect(document['title'], 'Validation Cohort & Consent');
    });

    test('manifest has all required top-level keys', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in ValidationCohortConsent.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('consent contract requires EXPLICIT_WRITTEN consent', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final consent = document['consent_contract'] as Map<String, dynamic>;
      expect(consent['consent_type'], 'EXPLICIT_WRITTEN');
      expect(consent['required_elements'], isNotEmpty);
      expect(consent['consent_record_path'], isNotEmpty);
    });

    test('data boundaries define collected and not_collected lists', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final boundaries = document['data_boundaries'] as Map<String, dynamic>;
      final collected = boundaries['collected'] as List<dynamic>;
      final notCollected = boundaries['not_collected'] as List<dynamic>;
      expect(collected, isNotEmpty);
      expect(notCollected, isNotEmpty);
      expect(boundaries['retention_period'], isNotEmpty);
      expect(boundaries['deletion_policy'], isNotEmpty);

      // Creative content must NOT be collected by default
      expect(
        notCollected.any(
          (item) =>
              '$item'.toLowerCase().contains('novel') ||
              '$item'.toLowerCase().contains('manuscript') ||
              '$item'.toLowerCase().contains('creative'),
        ),
        isTrue,
        reason: 'Creative content must be in not_collected',
      );
    });

    test('no fabricated participants is verified', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final noFab =
          document['no_fabricated_participants'] as Map<String, dynamic>;
      expect(noFab['verified'], isTrue);
      expect(noFab['note'], isNotEmpty);
    });

    test('withdrawal process defines how and no-penalty', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final withdrawal = document['withdrawal_process'] as Map<String, dynamic>;
      expect(withdrawal['how'], isNotEmpty);
      expect(withdrawal['no_penalty'], isNotEmpty);
    });

    test('support channel is defined with response time', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final support = document['support_channel'] as Map<String, dynamic>;
      expect(support['response_time'], isNotEmpty);
      expect(support['primary'], isNotEmpty);
    });

    test('compensation is EQUAL_FOR_ALL', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final comp = document['compensation'] as Map<String, dynamic>;
      expect(comp['type'], 'EQUAL_FOR_ALL');
      expect(comp['description'], isNotEmpty);
      expect(comp.containsKey('anti_incentive_note'), isTrue);
    });

    test('selection criteria define requirements and exclusions', () {
      final file = File(ValidationCohortConsent.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final criteria = document['selection_criteria'] as Map<String, dynamic>;
      expect(criteria['primary'], isNotEmpty);
      expect(criteria['requirements'], isNotEmpty);
      expect(criteria['exclusions'], isNotEmpty);
    });

    test('domain validation passes with valid consent contract', () {
      final result = ValidationCohortConsent.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
