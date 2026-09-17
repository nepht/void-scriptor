import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.11 manifest freezes the cross-domain lore integration contract', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_lore_graph_encyclopedia_search_integration.json',
    );
    expect(file.existsSync(), isTrue);
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(manifest['step'], '112.11');
    expect(manifest['status'], 'VERIFIED-LOCAL');
    expect(manifest['objective'], contains('graph'));
    expect(manifest['objective'], contains('spoiler'));

    final acceptance = (manifest['acceptance'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      acceptance.map((item) => item['id']),
      containsAll(<String>[
        'cross_domain_search',
        'graph_consistency',
        'alias_resolution',
        'time_filter',
        'culture_filter',
        'spoiler_filter',
      ]),
    );
    expect(acceptance, hasLength(6));
    for (final item in acceptance) {
      expect(item['implementationRefs'], isNotEmpty);
      expect(item['testRefs'], isNotEmpty);
      expect(item['evidenceClass'], 'DOMAIN-LOCAL');
    }

    expect(manifest['limitations'], contains('native'));
    expect(manifest['limitations'], contains('hosted CI'));
    expect(manifest['limitations'], contains('release'));
  });
}
