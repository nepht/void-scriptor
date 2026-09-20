import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.39 declares every required automated suite with executable evidence',
    () {
      final file = File(
        'docs/planning/v1.2/sprint_112_full_automated_test_matrix.json',
      );
      expect(file.existsSync(), isTrue);
      final matrix =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(matrix['step'], '112.39');
      expect(matrix['status'], 'VERIFIED-LOCAL');

      const required = <String>[
        'unit',
        'property',
        'contract',
        'integration',
        'migration',
        'ui',
        'accessibility',
        'end_to_end',
        'security',
        'regression',
      ];
      final suites = matrix['suites'] as List<dynamic>;
      expect(
        suites.map((suite) => (suite as Map<String, dynamic>)['name']),
        containsAll(required),
      );
      expect(
        suites.map((suite) => (suite as Map<String, dynamic>)['name']).toSet(),
        required.toSet(),
      );

      for (final suite in suites.cast<Map<String, dynamic>>()) {
        expect(suite['command'], isNotEmpty);
        expect(suite['result'], contains('PASS'));
        for (final path
            in (suite['evidence'] as List<dynamic>).cast<String>()) {
          expect(
            File(path).existsSync() || Directory(path).existsSync(),
            isTrue,
            reason: path,
          );
        }
      }
    },
  );
}
