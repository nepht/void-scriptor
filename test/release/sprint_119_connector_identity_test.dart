import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_connector_identity.dart';

Map<String, dynamic> _record({
  Map<String, dynamic>? identity,
  Object? extraKey,
}) {
  final record = <String, dynamic>{
    'canonical_step': '119.5',
    'title': 'Connector Identity & Stable IDs',
    'schema_version': 1,
    'unknown_field_policy': 'REJECT',
    'external_gates': 'DEFERRED-EXTERNAL',
    'identity': identity ?? _identity(),
    'invariants': Sprint119ConnectorIdentityContract.requiredInvariants,
  };
  if (extraKey != null) record['unexpected'] = extraKey;
  return record;
}

Map<String, dynamic> _identity({
  String connectorId = 'connector.voidscriptor.local',
  String publisherId = 'publisher.voidscriptor',
  String packageId = 'package.voidscriptor.local',
  String installationId = 'install.01hxyz',
  String accountId = 'account.provider.01hxyz',
  String connectionId = 'connection.01hxyz',
}) {
  return <String, dynamic>{
    'connector_id': connectorId,
    'publisher_id': publisherId,
    'package_id': packageId,
    'installation_id': installationId,
    'account_id': accountId,
    'connection_id': connectionId,
  };
}

void main() {
  group('119.5 Connector Identity & Stable IDs', () {
    test('declares the six required IDs and lifecycle boundaries', () {
      expect(Sprint119ConnectorIdentityContract.canonicalStep, '119.5');
      expect(
        Sprint119ConnectorIdentityContract.requiredIds,
        <String>[
          'connector_id',
          'publisher_id',
          'package_id',
          'installation_id',
          'account_id',
          'connection_id',
        ],
      );
      expect(
        Sprint119ConnectorIdentityContract.requiredInvariants,
        containsAll(<String>[
          'connector_id_stable_across_versions',
          'installation_id_is_local_and_opaque',
          'connection_id_is_revocable',
        ]),
      );
    });

    test('canonical identity contract passes validation', () {
      final report = const Sprint119ConnectorIdentityValidator().evaluate();
      expect(report.state, Sprint119ConnectorIdentityState.pass);
      expect(report.verdict, 'CONNECTOR_IDENTITY_CONTRACT_COMPLETE_LOCAL');
      expect(report.diagnostics, isEmpty);
      expect(report.identity, isNotNull);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('emitted record contains all required definitions', () {
      final file = File(Sprint119ConnectorIdentityContract.contractPath);
      expect(file.existsSync(), isTrue);
      final record = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(record['canonical_step'], '119.5');
      expect(record['identity'], isA<Map<String, dynamic>>());
      expect(record['invariants'], isA<List<dynamic>>());
      for (final id in Sprint119ConnectorIdentityContract.requiredIds) {
        expect(
          (record['identity'] as Map<String, dynamic>)[id],
          isA<Map<String, dynamic>>(),
        );
      }
    });

    test('unknown top-level fields fail closed', () {
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        _record(extraKey: true),
      );
      expect(report.state, Sprint119ConnectorIdentityState.fail);
      expect(report.diagnostics, contains('unknown_field:unexpected'));
    });

    test('missing IDs block the contract', () {
      final identity = _identity()..remove('account_id');
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        _record(identity: identity),
      );
      expect(report.state, Sprint119ConnectorIdentityState.blocked);
      expect(report.diagnostics, contains('missing_id:account_id'));
    });

    test('duplicate ID values fail instead of aliasing scopes', () {
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        _record(
          identity: _identity(
            accountId: 'connection.01hxyz',
          ),
        ),
      );
      expect(report.state, Sprint119ConnectorIdentityState.fail);
      expect(report.diagnostics, contains('duplicate_id_value:connection.01hxyz'));
    });

    test('empty and unsafe ID values fail without exposing input content', () {
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        _record(
          identity: _identity(
            publisherId: 'publisher with spaces',
          )..['package_id'] = '',
        ),
      );
      expect(report.state, Sprint119ConnectorIdentityState.fail);
      expect(report.diagnostics, contains('invalid_id:publisher_id'));
      expect(report.diagnostics, contains('invalid_id:package_id'));
      expect(report.diagnostics.join('|'), isNot(contains('publisher with spaces')));
    });

    test('typed identity keeps opaque values and exposes no secret fields', () {
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        _record(),
      );
      expect(report.identity, isNotNull);
      expect(report.identity!.installationId, 'install.01hxyz');
      expect(report.identity!.connectionId, 'connection.01hxyz');
      expect(report.identity!.toJson().keys, containsAll(<String>[
        'connector_id',
        'publisher_id',
        'package_id',
        'installation_id',
        'account_id',
        'connection_id',
      ]));
      expect(report.identity!.toJson().keys, isNot(contains('token')));
    });

    test('unsupported schema version blocks validation', () {
      final record = _record()..['schema_version'] = 2;
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119ConnectorIdentityState.blocked);
      expect(report.verdict, 'CONNECTOR_IDENTITY_SCHEMA_VERSION_UNSUPPORTED');
    });

    test('invariants are required and cannot be replaced by an empty list', () {
      final record = _record()..['invariants'] = <String>[];
      final report = const Sprint119ConnectorIdentityValidator().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119ConnectorIdentityState.fail);
      expect(report.diagnostics, contains('invariants_incomplete'));
    });
  });
}
