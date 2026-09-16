import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.6 defines a complete feature flag and rollout matrix', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_feature_flag_rollout_matrix.json',
    );
    expect(file.existsSync(), isTrue, reason: '112.6 matrix must exist');

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.6');
    expect(document['release_channel'], 'v1.2.0-rc.1');
    expect(
      document['shared_kill_switch'],
      'FeatureFlagRegistry.engageKillSwitch',
    );

    final entries = document['entries'] as List<dynamic>;
    expect(entries, hasLength(29));
    final features = <String>{};
    for (final rawEntry in entries) {
      final entry = rawEntry as Map<String, dynamic>;
      expect(
        entry.keys,
        containsAll(<String>[
          'feature',
          'flag',
          'default',
          'dependencies',
          'audience',
          'rollout_stage',
          'kill_switch',
        ]),
      );
      expect(
        features.add(entry['feature'] as String),
        isTrue,
        reason: 'feature entries must be unique',
      );
      expect(entry['default'], 'OFF');
      expect(entry['dependencies'], isA<List<dynamic>>());
      expect(entry['audience'], isNotEmpty);
      expect(
        entry['rollout_stage'],
        isIn(<String>[
          'internal_only',
          'trusted_preview',
          'limited_rc',
          'deferred',
        ]),
      );
      expect(entry['kill_switch'], document['shared_kill_switch']);
    }

    expect(
      features,
      containsAll(<String>{
        'F1',
        'F2',
        'F3',
        'F4',
        'F5',
        'F6',
        'F7',
        'F8',
        'F9',
        'F10',
        'F11',
        'F12',
        'F13',
        'F14',
        'F15',
        'F16',
        'F17',
        'F18',
        'F19',
        'F20',
        'F21',
        'F22',
        'F23',
        'F24',
        'F25',
        'F26',
        'F27',
        'F28',
        'F29',
      }),
    );
  });
}
