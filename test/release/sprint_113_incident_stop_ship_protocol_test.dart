import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/incident_stop_ship_protocol.dart';

void main() {
  group('113.6 Incident & Stop-Ship Protocol', () {
    test('manifest exists with correct canonical step', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      expect(file.existsSync(), isTrue, reason: '113.6 manifest must exist');

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '113.6');
      expect(document['title'], 'Incident & Stop-Ship Protocol');
    });

    test('manifest has all required top-level keys', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      for (final key in IncidentStopShipProtocol.requiredKeys) {
        expect(
          document.containsKey(key),
          isTrue,
          reason: 'Required key missing: $key',
        );
      }
    });

    test('stop triggers cover all six required categories', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final triggers = document['stop_triggers'] as List<dynamic>;
      expect(
        triggers.length,
        greaterThanOrEqualTo(IncidentStopShipProtocol.minTriggers),
      );

      for (final required in IncidentStopShipProtocol.requiredTriggerIds) {
        final found = triggers.any(
          (t) => (t as Map<String, dynamic>)['id'] == required,
        );
        expect(found, isTrue, reason: 'Trigger $required must be defined');
      }
    });

    test('each trigger has action, severity, and decision_owner', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final triggers = document['stop_triggers'] as List<dynamic>;
      for (final t in triggers) {
        final map = t as Map<String, dynamic>;
        expect(map.containsKey('action'), isTrue);
        expect(map.containsKey('severity'), isTrue);
        expect(map.containsKey('decision_owner'), isTrue);
      }
    });

    test('rollback protocol defines steps and owner', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final rollback = document['rollback_protocol'] as Map<String, dynamic>;
      expect(rollback.containsKey('steps'), isTrue);
      final steps = rollback['steps'] as List<dynamic>;
      expect(steps.length, greaterThanOrEqualTo(2));
      expect(rollback.containsKey('owner'), isTrue);
    });

    test('flag disable protocol is defined', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final flagDisable =
          document['flag_disable_protocol'] as Map<String, dynamic>;
      expect(flagDisable.containsKey('method'), isTrue);
      expect(flagDisable.containsKey('affected_flags'), isTrue);
    });

    test('communication protocol defines notification targets', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final comm = document['communication_protocol'] as Map<String, dynamic>;
      expect(comm.containsKey('internal'), isTrue);
      expect(comm.containsKey('external'), isTrue);
    });

    test('decision and limits are defined', () {
      final file = File(IncidentStopShipProtocol.manifestPath);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document.containsKey('decision'), isTrue);
      expect(document['decision'].toString().isNotEmpty, isTrue);
      expect(document.containsKey('limits'), isTrue);
      final limits = document['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
    });

    test('domain validation passes with valid manifest', () {
      final result = IncidentStopShipProtocol.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });
  });
}
