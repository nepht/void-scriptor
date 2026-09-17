import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.31 records every round-trip acceptance with live evidence', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_import_export_round_trip_validation.json',
    );
    expect(file.existsSync(), isTrue, reason: '112.31 manifest must exist');

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.31');
    expect(document['title'], 'Import & Export Round-Trip Validation');
    expect(document['production_data'], isFalse);

    final acceptance = (document['acceptance'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(acceptance, hasLength(6));
    expect(
      acceptance.map((entry) => entry['id']),
      orderedEquals(const <String>[
        'schema_validation',
        'round_trip',
        'media_manifest',
        'stable_ids',
        'sanitized_share',
        'deterministic_output',
      ]),
    );

    for (final entry in acceptance) {
      expect(entry['implementationRefs'], isNotEmpty, reason: entry['id']);
      expect(entry['testRefs'], isNotEmpty, reason: entry['id']);
      expect(entry['evidenceClass'], 'LOCAL-CONTRACT');
      for (final path in (entry['implementationRefs'] as List<dynamic>)) {
        expect(File(path as String).existsSync(), isTrue, reason: path);
      }
      for (final path in (entry['testRefs'] as List<dynamic>)) {
        expect(File(path as String).existsSync(), isTrue, reason: path);
      }
    }

    final limits = (document['limits'] as List<dynamic>).cast<String>().join(
      ' ',
    );
    expect(limits, contains('Native GUI'));
    expect(limits, contains('hosted CI'));
  });
}
