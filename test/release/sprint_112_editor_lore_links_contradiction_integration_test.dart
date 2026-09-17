import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.10 maps editor, lore-link, canon, and contradiction evidence', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_editor_lore_links_contradiction_integration.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: '112.10 integration manifest must exist',
    );

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.10');
    expect(document['claim_boundary'], isNotEmpty);

    final acceptance = document['acceptance'] as Map<String, dynamic>;
    expect(
      acceptance.keys,
      containsAll(<String>[
        'link_round_trip',
        'backlink_consistency',
        'source_citations',
        'incremental_analysis',
        'repair_flow',
      ]),
    );

    for (final entry in acceptance.entries) {
      final evidence = entry.value as Map<String, dynamic>;
      expect(evidence['status'], 'VERIFIED-LOCAL', reason: entry.key);
      for (final path in evidence['paths'] as List<dynamic>) {
        expect(File(path as String).existsSync(), isTrue, reason: entry.key);
      }
    }
  });
}
