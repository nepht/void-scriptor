import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.13 manifest freezes POV voice and knowledge integration', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_pov_character_voice_knowledge_integration.json',
    );
    expect(file.existsSync(), isTrue);
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(manifest['step'], '112.13');
    expect(manifest['status'], 'VERIFIED-LOCAL');
    expect(manifest['objective'], contains('POV'));
    expect(manifest['objective'], contains('voice'));
    expect(manifest['objective'], contains('spoiler'));

    final acceptance = (manifest['acceptance'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      acceptance.map((item) => item['id']),
      containsAll(<String>[
        'pov_lock',
        'knowledge_at_time',
        'voice_rules',
        'rumor_knowledge',
        'secret_handling',
        'explain_warning',
      ]),
    );
    expect(acceptance, hasLength(6));
    for (final item in acceptance) {
      expect(item['implementationRefs'], isNotEmpty);
      expect(item['testRefs'], isNotEmpty);
      expect(item['evidenceClass'], 'DOMAIN-LOCAL');
    }

    final related = manifest['relatedContracts'] as Map<String, dynamic>;
    expect(related.keys, containsAll(<String>['interview', 'spoiler']));
    expect(manifest['limitations'], contains('native GUI'));
    expect(manifest['limitations'], contains('hosted CI'));
    expect(manifest['limitations'], contains('release'));
  });
}
