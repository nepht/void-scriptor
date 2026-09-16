import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.3 inventory accounts for every frozen feature with live evidence',
    () {
      final file = File(
        'docs/planning/v1.2/sprint_112_feature_evidence_inventory.json',
      );
      expect(file.existsSync(), isTrue, reason: '112.3 inventory must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.3');
      expect(document['claim_boundary'], contains('inventory'));

      final features = (document['features'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(features, hasLength(29));
      expect(
        features.map((entry) => entry['feature']),
        orderedEquals(List<String>.generate(29, (index) => 'F${index + 1}')),
      );

      for (final feature in features) {
        for (final field in const <String>[
          'feature',
          'implementation_refs',
          'test_refs',
          'documentation_refs',
          'feature_flag',
          'owner',
          'known_issues',
          'status',
        ]) {
          expect(
            feature.containsKey(field),
            isTrue,
            reason: '${feature['feature']}.$field',
          );
        }

        for (final field in const <String>[
          'implementation_refs',
          'test_refs',
          'documentation_refs',
        ]) {
          final refs = (feature[field] as List<dynamic>).cast<String>();
          expect(refs, isNotEmpty, reason: '${feature['feature']}.$field');
          for (final path in refs) {
            expect(
              File(path).existsSync(),
              isTrue,
              reason: '${feature['feature']} references missing $path',
            );
          }
        }

        final flag = feature['feature_flag'] as Map<String, dynamic>;
        expect(flag['default'], 'OFF');
        expect(
          flag['mode'],
          isIn(<String>['dedicated', 'shared_kill_switch_only']),
        );
        if (flag['mode'] == 'shared_kill_switch_only') {
          expect(
            (feature['known_issues'] as List<dynamic>).join(' '),
            contains('dedicated per-feature flag'),
          );
        }
        expect(feature['status'], isIn(<String>['EVIDENCED_LOCAL', 'PARTIAL']));
      }

      final alias = document['alias'] as Map<String, dynamic>;
      expect(alias['feature'], 'F30');
      expect(alias['canonical_feature'], 'F24');
      expect(alias['separate_inventory_entry'], isFalse);
    },
  );
}
