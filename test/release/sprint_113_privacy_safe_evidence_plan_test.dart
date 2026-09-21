import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/privacy_safe_evidence_plan.dart';

void main() {
  group('113.4 Privacy-Safe Evidence Plan', () {
    test('manifest exists with correct canonical step', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.4 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.4');
      expect(document['title'], 'Privacy-Safe Evidence Plan');
    });

    test('manifest has all required top-level keys', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in PrivacySafeEvidencePlan.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('evidence types cover all six allowed categories', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final evidenceTypes = document['evidence_types'] as List<dynamic>;
      expect(
        evidenceTypes.length,
        greaterThanOrEqualTo(PrivacySafeEvidencePlan.minEvidenceTypes),
      );

      final typeIds = evidenceTypes
          .map((e) => (e as Map<String, dynamic>)['id'].toString())
          .toList();
      for (final required in PrivacySafeEvidencePlan.requiredEvidenceTypeIds) {
        expect(
          typeIds.contains(required),
          isTrue,
          reason: 'Evidence type $required must be defined',
        );
      }
    });

    test(
      'collection principles include privacy-first and no-creative-default',
      () {
        final file = File(PrivacySafeEvidencePlan.manifestPath);
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        final principles = document['collection_principles'] as List<dynamic>;
        expect(principles, isNotEmpty);

        final principleText = principles
            .map((p) => p.toString().toLowerCase())
            .join(' ');
        expect(
          principleText.contains('creative') &&
              principleText.contains('default'),
          isTrue,
          reason:
              'Principles must address creative content not collected by default',
        );
      },
    );

    test('excluded evidence explicitly bans creative content collection', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final excluded = document['excluded_evidence'] as List<dynamic>;
      expect(excluded, isNotEmpty);

      final excludedText = excluded
          .map((e) => e.toString().toLowerCase())
          .join(' ');
      expect(
        excludedText.contains('novel') ||
            excludedText.contains('manuscript') ||
            excludedText.contains('creative'),
        isTrue,
        reason:
            'Excluded evidence must ban creative content (novel/manuscript/creative)',
      );
    });

    test('storage policy defines retention and access control', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final storage = document['storage_policy'] as Map<String, dynamic>;
      expect(storage.containsKey('retention_period'), isTrue);
      expect(storage['retention_period'].toString().isNotEmpty, isTrue);
      expect(storage.containsKey('access_control'), isTrue);
      expect(storage['access_control'].toString().isNotEmpty, isTrue);
    });

    test('decision and limits are defined', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('decision'), isTrue);
      expect(document['decision'].toString().isNotEmpty, isTrue);
      expect(document.containsKey('limits'), isTrue);
      final limits = document['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
    });

    test('each evidence type has id, description, and privacy_level', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final evidenceTypes = document['evidence_types'] as List<dynamic>;
      for (final et in evidenceTypes) {
        final map = et as Map<String, dynamic>;
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('description'), isTrue);
        expect(map.containsKey('privacy_level'), isTrue);
        expect(map['id'].toString().isNotEmpty, isTrue);
        expect(map['description'].toString().isNotEmpty, isTrue);
        expect(map['privacy_level'].toString().isNotEmpty, isTrue);
      }
    });

    test('domain validation passes with valid manifest', () {
      final result = PrivacySafeEvidencePlan.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('manifest JSON is valid and round-trip stable', () {
      final file = File(PrivacySafeEvidencePlan.manifestPath);
      final raw = file.readAsStringSync();
      final reparsed = jsonDecode(raw);
      expect(reparsed, isA<Map>());
      expect((reparsed as Map).containsKey('canonical_step'), isTrue);
    });
  });
}
