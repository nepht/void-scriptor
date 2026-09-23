import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/observation_charter.dart';

void main() {
  group('114.2 Observation Charter', () {
    test('manifest records a delayed local corrective observation window', () {
      final file = File(ObservationCharter.manifestPath);
      expect(file.existsSync(), isTrue);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '114.2');
      expect(manifest['path'], 'DELAYED');
      expect(manifest['window']['type'], 'LOCAL_CORRECTIVE');
      expect(manifest['signals'], isA<List<dynamic>>());
      expect(manifest['owners'], isA<List<dynamic>>());
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test(
      'validation rejects a charter that fabricates production telemetry',
      () {
        final result = ObservationCharter.validate(<String, dynamic>{
          'canonical_step': '114.2',
          'path': 'RELEASED',
          'window': <String, dynamic>{'type': 'PRODUCTION_TELEMETRY'},
          'questions': <String>[],
          'signals': <String>[],
          'owners': <String>[],
          'escalation': <String, dynamic>{},
          'stop_conditions': <String>[],
          'exit_criteria': <String>[],
          'external_gates': 'PASS',
        });
        expect(result.isValid, isFalse);
        expect(result.errors, contains('production telemetry is unavailable'));
      },
    );

    test('validation accepts the local delayed charter', () {
      final manifest =
          jsonDecode(File(ObservationCharter.manifestPath).readAsStringSync())
              as Map<String, dynamic>;
      final result = ObservationCharter.validate(manifest);
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
