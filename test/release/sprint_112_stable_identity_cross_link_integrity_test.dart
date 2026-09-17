import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.9 maps stable identity and cross-link lifecycle evidence', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_stable_identity_cross_link_integrity.json',
    );
    expect(file.existsSync(), isTrue);

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.9');
    expect(document['claim_boundary'], isNotEmpty);

    final acceptance = document['acceptance'] as Map<String, dynamic>;
    expect(
      acceptance.keys,
      containsAll(<String>[
        'distinct_workspace_ids',
        'stable_character_refs',
        'rename_safe',
        'unlink_does_not_delete_source',
        'novel_delete_does_not_delete_character',
        'character_delete_reviews_affected_novels',
        'restore_links',
        'branch_scope',
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
