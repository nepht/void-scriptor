import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.8 declares deterministic non-production reference datasets', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_reference_projects_golden_data.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: '112.8 reference dataset manifest must exist',
    );

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.8');
    expect(document['production_data'], isFalse);
    expect(document['golden_policy'], isNotEmpty);

    final datasets = document['datasets'] as List<dynamic>;
    expect(datasets, hasLength(6));
    final ids = <String>{};
    final requiredKinds = <String>{
      'small_project',
      'large_project',
      'long_timeline',
      'multilingual_project',
      'branched_world',
      'media_heavy_project',
    };
    for (final rawDataset in datasets) {
      final dataset = rawDataset as Map<String, dynamic>;
      expect(ids.add(dataset['id'] as String), isTrue);
      expect(requiredKinds.remove(dataset['kind'] as String), isTrue);
      expect(dataset['seed'], isA<int>());
      expect(dataset['record_counts'], isA<Map<String, dynamic>>());
      expect(dataset['golden_results'], isA<Map<String, dynamic>>());
      expect(dataset['fixture_policy'], isNotEmpty);
    }
    expect(requiredKinds, isEmpty);
  });
}
