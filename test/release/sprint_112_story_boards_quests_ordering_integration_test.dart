import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.12 manifest freezes story ordering and quest integration', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_story_boards_quests_ordering_integration.json',
    );
    expect(file.existsSync(), isTrue);
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(manifest['step'], '112.12');
    expect(manifest['status'], 'VERIFIED-LOCAL');
    expect(manifest['objective'], contains('bab'));
    expect(manifest['objective'], contains('quest'));

    final acceptance = (manifest['acceptance'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      acceptance.map((item) => item['id']),
      containsAll(<String>[
        'story_order',
        'board_order',
        'quest_links',
        'dependency_warning',
        'unresolved_report',
        'undo',
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
