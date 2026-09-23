import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/release_health_baseline.dart';

void main() {
  group('114.3 Release Health Baseline', () {
    test('manifest freezes local corrective baseline fields', () {
      final file = File(ReleaseHealthBaseline.manifestPath);
      expect(file.existsSync(), isTrue);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '114.3');
      expect(manifest['path'], 'DELAYED');
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      final signals = manifest['signals'] as List<dynamic>;
      expect(signals, hasLength(7));
      for (final entry in signals) {
        final signal = entry as Map<String, dynamic>;
        for (final key in <String>[
          'signal',
          'baseline',
          'threshold',
          'source',
          'window',
          'limitations',
        ]) {
          expect(signal[key], isNotNull, reason: key);
          expect(signal[key].toString().trim(), isNotEmpty, reason: key);
        }
      }
    });

    test('validation rejects fabricated production observations', () {
      final result = ReleaseHealthBaseline.validate(<String, dynamic>{
        'canonical_step': '114.3',
        'path': 'RELEASED',
        'external_gates': 'PASS',
        'signals': <Map<String, dynamic>>[
          <String, dynamic>{
            'signal': 'install_success',
            'baseline': '99%',
            'threshold': '>= 99%',
            'source': 'production telemetry',
            'window': '24h',
            'limitations': 'none',
            'observed': '99%',
          },
        ],
      });
      expect(result.isValid, isFalse);
      expect(result.errors, contains('path must remain DELAYED'));
    });

    test('validation accepts the complete local baseline', () {
      final result = ReleaseHealthBaseline.validateManifest();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
