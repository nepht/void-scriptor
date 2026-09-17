import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.14 manifest freezes pacing, writing, and snapshot integration', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_pacing_focus_writing_snapshot_integration.json',
    );
    expect(file.existsSync(), isTrue);
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    expect(manifest['step'], '112.14');
    expect(manifest['status'], 'VERIFIED-LOCAL');
    expect(manifest['objective'], contains('statistik sesi'));
    expect(manifest['objective'], contains('snapshot'));
    expect(manifest['objective'], contains('heatmap'));

    final acceptance = (manifest['acceptance'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      acceptance.map((item) => item['id']),
      containsAll(<String>[
        'session_metrics',
        'tension_history',
        'snapshot_diff',
        'safe_restore',
        'heatmap_refresh',
        'no_data_loss',
      ]),
    );
    expect(acceptance, hasLength(6));
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
