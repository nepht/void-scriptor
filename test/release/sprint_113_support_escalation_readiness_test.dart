import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/support_escalation_readiness.dart';

void main() {
  group('113.5 Support & Escalation Readiness', () {
    test('manifest exists with correct canonical step', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.5 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.5');
      expect(document['title'], 'Support & Escalation Readiness');
    });

    test('manifest has all required top-level keys', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in SupportEscalationReadiness.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('severity matrix defines P0 through P3', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final matrix = document['severity_matrix'] as Map<String, dynamic>;
      for (final level in SupportEscalationReadiness.requiredSeverityLevels) {
        expect(
          matrix.containsKey(level),
          isTrue,
          reason: 'Severity level $level must be defined',
        );
        final entry = matrix[level] as Map<String, dynamic>;
        expect(entry.containsKey('definition'), isTrue);
        expect(entry.containsKey('response_target'), isTrue);
      }
    });

    test('response targets include P0 and P1', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final targets = document['response_targets'] as Map<String, dynamic>;
      expect(targets.containsKey('P0'), isTrue);
      expect(targets.containsKey('P1'), isTrue);

      final p0 = targets['P0'] as Map<String, dynamic>;
      expect(p0.containsKey('max_response_hours'), isTrue);
      expect(p0['max_response_hours'], isA<num>());
    });

    test('recovery guides list references existing docs', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final guides = document['recovery_guides'] as List<dynamic>;
      expect(guides.length, greaterThanOrEqualTo(2));

      for (final guide in guides) {
        final map = guide as Map<String, dynamic>;
        expect(map.containsKey('scenario'), isTrue);
        expect(map.containsKey('guide_path'), isTrue);
        expect(map.containsKey('owner'), isTrue);
      }
    });

    test('escalation paths define severity-to-action mapping', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final paths = document['escalation_paths'] as List<dynamic>;
      expect(paths.length, greaterThanOrEqualTo(2));

      for (final path in paths) {
        final map = path as Map<String, dynamic>;
        expect(map.containsKey('trigger'), isTrue);
        expect(map.containsKey('action'), isTrue);
        expect(map.containsKey('owner'), isTrue);
      }
    });

    test('decision and limits are defined', () {
      final file = File(SupportEscalationReadiness.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('decision'), isTrue);
      expect(document['decision'].toString().isNotEmpty, isTrue);
      expect(document.containsKey('limits'), isTrue);
      final limits = document['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
    });

    test('domain validation passes with valid manifest', () {
      final result = SupportEscalationReadiness.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
