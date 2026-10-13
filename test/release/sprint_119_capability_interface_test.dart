import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_capability_interface.dart';

Map<String, dynamic> _manifest() {
  return jsonDecode(
        File(
          Sprint119CapabilityInterfaceContract.manifestPath,
        ).readAsStringSync(),
      )
      as Map<String, dynamic>;
}

Sprint119CapabilityDefinition _definition(String name) {
  return Sprint119CapabilityDefinition(
    name: name,
    purpose: 'local $name contract',
    request: 'typed request envelope',
    response: 'typed response envelope',
    failure: 'typed fail-closed error',
    cancellation: 'cooperative cancellation boundary',
    lifecycle: 'discover, execute, finish, and revoke',
    claimBoundary: 'local contract only; external execution remains deferred',
  );
}

void main() {
  group('119.6 Capability Interface Foundation', () {
    test('declares the canonical seven contracts', () {
      expect(Sprint119CapabilityInterfaceContract.canonicalStep, '119.6');
      expect(
        Sprint119CapabilityInterfaceContract.title,
        'Capability Interface Foundation',
      );
      expect(Sprint119CapabilityInterfaceContract.requiredContracts, <String>[
        'capability_discovery',
        'execution',
        'cancellation',
        'health',
        'usage',
        'errors',
        'lifecycle',
      ]);
    });

    test('canonical manifest passes without making live claims', () {
      final report = const Sprint119CapabilityInterfaceGate().evaluate();
      expect(report.state, Sprint119CapabilityInterfaceState.pass);
      expect(report.verdict, 'CAPABILITY_INTERFACE_CONTRACT_COMPLETE_LOCAL');
      expect(report.missingContracts, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('manifest preserves the seven contracts and claim boundary', () {
      final record = _manifest();
      expect(record['canonical_step'], '119.6');
      expect(record['state'], 'pass');
      expect(record['verdict'], 'CAPABILITY_INTERFACE_CONTRACT_COMPLETE_LOCAL');
      expect(record['external_gates'], 'DEFERRED-EXTERNAL');
      final contracts = record['contracts'] as Map<String, dynamic>;
      expect(
        contracts.keys,
        containsAll(Sprint119CapabilityInterfaceContract.requiredContracts),
      );
      expect(record['claim_boundary'], isA<List<dynamic>>());
      expect(record['claim_boundary'], isNotEmpty);
    });

    test('typed descriptor exposes capability metadata without secrets', () {
      const descriptor = Sprint119CapabilityDescriptor(
        capabilityId: 'storage.list',
        category: 'storage',
        operations: <String>['list'],
        lifecycle: 'available until revoked',
        supportsCancellation: true,
        supportsHealth: true,
        supportsUsage: false,
      );

      expect(descriptor.validate(), isEmpty);
      expect(descriptor.toJson(), <String, Object?>{
        'capability_id': 'storage.list',
        'category': 'storage',
        'operations': <String>['list'],
        'lifecycle': 'available until revoked',
        'supports_cancellation': true,
        'supports_health': true,
        'supports_usage': false,
      });
      expect(descriptor.toJson().keys, isNot(contains('token')));
      expect(descriptor.toJson().keys, isNot(contains('secret')));
    });

    test('missing contract blocks the interface', () {
      final record = _manifest();
      final contracts = Map<String, dynamic>.from(
        record['contracts'] as Map<String, dynamic>,
      )..remove('health');
      record['contracts'] = contracts;

      final report = const Sprint119CapabilityInterfaceGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119CapabilityInterfaceState.blocked);
      expect(report.missingContracts, <String>['health']);
    });

    test('unknown top-level fields fail closed', () {
      final record = _manifest()..['unexpected'] = true;

      final report = const Sprint119CapabilityInterfaceGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119CapabilityInterfaceState.fail);
      expect(report.violations, contains('unknown_field:unexpected'));
    });

    test('incomplete definition fails closed with its contract name', () {
      final record = _manifest();
      final contracts = Map<String, dynamic>.from(
        record['contracts'] as Map<String, dynamic>,
      );
      final health = Map<String, dynamic>.from(
        contracts['health'] as Map<String, dynamic>,
      )..['request'] = '';
      contracts['health'] = health;
      record['contracts'] = contracts;

      final report = const Sprint119CapabilityInterfaceGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119CapabilityInterfaceState.fail);
      expect(
        report.violations,
        contains('contract_field_missing:health:request'),
      );
    });

    test('unsupported schema version is blocked', () {
      final record = _manifest()..['schema_version'] = 99;

      final report = const Sprint119CapabilityInterfaceGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119CapabilityInterfaceState.blocked);
      expect(report.verdict, 'CAPABILITY_INTERFACE_SCHEMA_VERSION_UNSUPPORTED');
    });

    test('unknown contract names fail closed', () {
      final record = _manifest();
      final contracts = Map<String, dynamic>.from(
        record['contracts'] as Map<String, dynamic>,
      )..['telemetry'] = _definition('telemetry').toJson();
      record['contracts'] = contracts;

      final report = const Sprint119CapabilityInterfaceGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119CapabilityInterfaceState.fail);
      expect(report.violations, contains('unknown_contract:telemetry'));
    });

    test('unsafe descriptor values are rejected without echoing content', () {
      const descriptor = Sprint119CapabilityDescriptor(
        capabilityId: 'bad value',
        category: 'storage',
        operations: <String>[],
        lifecycle: '',
        supportsCancellation: false,
        supportsHealth: false,
        supportsUsage: false,
      );

      final diagnostics = descriptor.validate();
      expect(diagnostics, contains('capability_id_invalid'));
      expect(diagnostics, contains('operations_missing'));
      expect(diagnostics, contains('lifecycle_missing'));
      expect(diagnostics.join('|'), isNot(contains('bad value')));
    });
  });
}
