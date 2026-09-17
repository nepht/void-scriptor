import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.15 manifest freezes shared calendar and clock integration', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_calendar_timeline_world_clock_integration.json',
    );
    expect(file.existsSync(), isTrue);
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(manifest['step'], '112.15');
    expect(manifest['status'], 'VERIFIED-LOCAL');
    expect(manifest['objective'], contains('waktu absolut'));
    expect(manifest['objective'], contains('kalender'));
    expect(manifest['objective'], contains('era'));
    expect(manifest['objective'], contains('season'));
    expect(manifest['objective'], contains('branch'));

    final acceptance = (manifest['acceptance'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      acceptance.map((item) => item['id']),
      containsAll(<String>[
        'shared_clock',
        'calendar_round_trip',
        'era_consistency',
        'season_consistency',
        'branch_awareness',
      ]),
    );
    expect(acceptance, hasLength(5));
    for (final item in acceptance) {
      expect(item['implementationRefs'], isNotEmpty);
      expect(item['testRefs'], isNotEmpty);
      expect(item['evidenceClass'], 'DOMAIN-LOCAL');
    }
    expect(manifest['limitations'], contains('native GUI'));
    expect(manifest['limitations'], contains('hosted CI'));
    expect(manifest['limitations'], contains('release'));
  });
}
