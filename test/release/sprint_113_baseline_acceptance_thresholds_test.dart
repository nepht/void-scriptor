import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/baseline_acceptance_thresholds.dart';

void main() {
  group('113.8 Baseline & Acceptance Thresholds', () {
    test('manifest exists with correct canonical step', () {
      final file = File(BaselineAcceptanceThresholds.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.8 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.8');
      expect(document['title'], 'Baseline & Acceptance Thresholds');
    });

    test('manifest has all required top-level keys', () {
      final file = File(BaselineAcceptanceThresholds.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in BaselineAcceptanceThresholds.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('thresholds list has at least 5 metrics', () {
      final file = File(BaselineAcceptanceThresholds.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final thresholds = document['thresholds'] as List<dynamic>;
      expect(
        thresholds.length,
        greaterThanOrEqualTo(BaselineAcceptanceThresholds.minThresholds),
      );
    });

    test(
      'each threshold has metric, baseline, threshold, owner, and decision_rule',
      () {
        final file = File(BaselineAcceptanceThresholds.manifestPath);
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

        final thresholds = document['thresholds'] as List<dynamic>;
        for (final t in thresholds) {
          final map = t as Map<String, dynamic>;
          expect(map.containsKey('metric'), isTrue);
          expect(map.containsKey('baseline'), isTrue);
          expect(map.containsKey('threshold'), isTrue);
          expect(map.containsKey('owner'), isTrue);
          expect(map.containsKey('decision_rule'), isTrue);
        }
      },
    );

    test('thresholds cover stability, performance, and migration', () {
      final file = File(BaselineAcceptanceThresholds.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final thresholds = document['thresholds'] as List<dynamic>;
      final categories = thresholds
          .map((t) => (t as Map<String, dynamic>)['category'].toString())
          .toList();

      expect(categories, contains('stability'));
      expect(categories, contains('performance'));
      expect(categories, contains('migration'));
    });

    test('overall decision rule is defined', () {
      final file = File(BaselineAcceptanceThresholds.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('overall_decision_rule'), isTrue);
      expect(document['overall_decision_rule'].toString().isNotEmpty, isTrue);
    });

    test('decision and limits are defined', () {
      final file = File(BaselineAcceptanceThresholds.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('decision'), isTrue);
      expect(document['decision'].toString().isNotEmpty, isTrue);
      expect(document.containsKey('limits'), isTrue);
      final limits = document['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
    });

    test('domain validation passes with valid manifest', () {
      final result = BaselineAcceptanceThresholds.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
