/// Local, typed identity contract for roadmap step 119.5.
///
/// These identifiers describe ownership and lifecycle boundaries. They are
/// opaque values; this contract does not authenticate, connect, publish, or
/// claim that a provider is live.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint119ConnectorIdentityState { pass, fail, blocked }

class Sprint119ConnectorIdentity {
  const Sprint119ConnectorIdentity({
    required this.connectorId,
    required this.publisherId,
    required this.packageId,
    required this.installationId,
    required this.accountId,
    required this.connectionId,
  });

  final String connectorId;
  final String publisherId;
  final String packageId;
  final String installationId;
  final String accountId;
  final String connectionId;

  Map<String, String> toJson() => <String, String>{
    'connector_id': connectorId,
    'publisher_id': publisherId,
    'package_id': packageId,
    'installation_id': installationId,
    'account_id': accountId,
    'connection_id': connectionId,
  };
}

class Sprint119ConnectorIdentityReport {
  const Sprint119ConnectorIdentityReport({
    required this.state,
    required this.verdict,
    required this.externalGates,
    this.diagnostics = const <String>[],
    this.identity,
  });

  final Sprint119ConnectorIdentityState state;
  final String verdict;
  final String externalGates;
  final List<String> diagnostics;
  final Sprint119ConnectorIdentity? identity;
}

class Sprint119ConnectorIdentityContract {
  const Sprint119ConnectorIdentityContract._();

  static const String canonicalStep = '119.5';
  static const String title = 'Connector Identity & Stable IDs';
  static const String contractPath =
      'docs/planning/v1.3/sprint_119_connector_identity.json';
  static const int supportedSchemaVersion = 1;
  static const String unknownFieldPolicy = 'REJECT';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  static const List<String> requiredIds = <String>[
    'connector_id',
    'publisher_id',
    'package_id',
    'installation_id',
    'account_id',
    'connection_id',
  ];

  static const List<String> requiredInvariants = <String>[
    'connector_id_stable_across_versions',
    'publisher_id_stable_for_publisher',
    'package_id_stable_across_package_versions',
    'installation_id_is_local_and_opaque',
    'account_id_is_provider_scoped_and_non_pii',
    'connection_id_is_revocable',
  ];

  static const Set<String> definitionFields = <String>{
    'scope',
    'stable_when',
    'source',
    'lifecycle',
    'privacy',
    'example_id',
  };
}

class Sprint119ConnectorIdentityValidator {
  const Sprint119ConnectorIdentityValidator();

  Sprint119ConnectorIdentityReport evaluate() {
    final file = File(Sprint119ConnectorIdentityContract.contractPath);
    if (!file.existsSync()) {
      return _blocked(<String>['identity_contract_file_missing']);
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return _blocked(<String>['identity_contract_root_not_object']);
      }
      return evaluateRecord(decoded);
    } on Object {
      return _blocked(<String>['identity_contract_json_unreadable']);
    }
  }

  Sprint119ConnectorIdentityReport evaluateRecord(
    Map<String, dynamic> record,
  ) {
    final diagnostics = <String>[];
    _unknownKeys(
      record,
      const <String>{
        'canonical_step',
        'title',
        'schema_version',
        'unknown_field_policy',
        'external_gates',
        'identity',
        'invariants',
        'claim_boundary',
      },
      '',
      diagnostics,
    );
    if (diagnostics.any((item) => item.startsWith('unknown_field:'))) {
      return _fail(diagnostics);
    }
    if (record['schema_version'] !=
        Sprint119ConnectorIdentityContract.supportedSchemaVersion) {
      return Sprint119ConnectorIdentityReport(
        state: Sprint119ConnectorIdentityState.blocked,
        verdict: 'CONNECTOR_IDENTITY_SCHEMA_VERSION_UNSUPPORTED',
        externalGates: Sprint119ConnectorIdentityContract.externalGates,
        diagnostics: const <String>['identity_schema_version_unsupported'],
      );
    }
    if (record['canonical_step'] !=
        Sprint119ConnectorIdentityContract.canonicalStep) {
      diagnostics.add('canonical_step_mismatch');
    }
    if (record['title'] != Sprint119ConnectorIdentityContract.title) {
      diagnostics.add('title_mismatch');
    }
    if (record['unknown_field_policy'] !=
        Sprint119ConnectorIdentityContract.unknownFieldPolicy) {
      diagnostics.add('unknown_field_policy_not_reject');
    }
    if (record['external_gates'] !=
        Sprint119ConnectorIdentityContract.externalGates) {
      diagnostics.add('external_gates_not_deferred');
    }
    final rawInvariants = record['invariants'];
    if (rawInvariants is! List<Object?> ||
        !Sprint119ConnectorIdentityContract.requiredInvariants.every(
          rawInvariants.contains,
        )) {
      diagnostics.add('invariants_incomplete');
    }
    final rawIdentity = _map(record['identity']);
    if (rawIdentity == null) {
      return _blocked(<String>['identity_section_not_object']);
    }

    final values = _readIdentity(rawIdentity, diagnostics);
    if (values == null) {
      if (diagnostics.any((item) => item.startsWith('missing_id:'))) {
        return _blocked(diagnostics);
      }
      return _fail(diagnostics);
    }
    _validateValues(values, diagnostics);
    if (diagnostics.isNotEmpty) {
      return _fail(diagnostics);
    }
    return Sprint119ConnectorIdentityReport(
      state: Sprint119ConnectorIdentityState.pass,
      verdict: 'CONNECTOR_IDENTITY_CONTRACT_COMPLETE_LOCAL',
      externalGates: Sprint119ConnectorIdentityContract.externalGates,
      identity: Sprint119ConnectorIdentity(
        connectorId: values['connector_id']!,
        publisherId: values['publisher_id']!,
        packageId: values['package_id']!,
        installationId: values['installation_id']!,
        accountId: values['account_id']!,
        connectionId: values['connection_id']!,
      ),
    );
  }

  Sprint119ConnectorIdentityReport _blocked(List<String> diagnostics) =>
      Sprint119ConnectorIdentityReport(
        state: Sprint119ConnectorIdentityState.blocked,
        verdict: 'CONNECTOR_IDENTITY_CONTRACT_BLOCKED',
        externalGates: Sprint119ConnectorIdentityContract.externalGates,
        diagnostics: diagnostics,
      );

  Sprint119ConnectorIdentityReport _fail(List<String> diagnostics) =>
      Sprint119ConnectorIdentityReport(
        state: Sprint119ConnectorIdentityState.fail,
        verdict: 'CONNECTOR_IDENTITY_CONTRACT_INVALID',
        externalGates: Sprint119ConnectorIdentityContract.externalGates,
        diagnostics: diagnostics,
      );
}

Map<String, String>? _readIdentity(
  Map<String, dynamic> raw,
  List<String> diagnostics,
) {
  final values = <String, String>{};
  var missing = false;
  var definitionMode = false;
  for (final id in Sprint119ConnectorIdentityContract.requiredIds) {
    final value = raw[id];
    if (value == null) {
      diagnostics.add('missing_id:$id');
      missing = true;
    } else if (value is Map<String, dynamic>) {
      definitionMode = true;
    }
  }
  if (missing) return null;

  for (final id in Sprint119ConnectorIdentityContract.requiredIds) {
    final value = raw[id];
    if (definitionMode) {
      if (value is! Map<String, dynamic>) {
        diagnostics.add('identity_definition_not_object:$id');
        continue;
      }
      _unknownKeys(value, Sprint119ConnectorIdentityContract.definitionFields,
          'identity.$id', diagnostics);
      final example = value['example_id'];
      if (example is! String || example.trim().isEmpty) {
        diagnostics.add('identity_definition_example_missing:$id');
      } else {
        values[id] = example;
      }
    } else if (value is String) {
      values[id] = value;
    } else {
      diagnostics.add('identity_value_not_string:$id');
    }
  }
  return values.length == Sprint119ConnectorIdentityContract.requiredIds.length
      ? values
      : null;
}

void _validateValues(Map<String, String> values, List<String> diagnostics) {
  final seen = <String>{};
  final pattern = RegExp(r'^[a-z][a-z0-9._-]{2,127}$');
  for (final id in Sprint119ConnectorIdentityContract.requiredIds) {
    final value = values[id]!;
    if (!pattern.hasMatch(value)) diagnostics.add('invalid_id:$id');
    if (!seen.add(value)) diagnostics.add('duplicate_id_value:$value');
  }
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map<String, dynamic> ? value : null;

void _unknownKeys(
  Map<String, dynamic> value,
  Set<String> allowed,
  String path,
  List<String> diagnostics,
) {
  for (final key in value.keys) {
    if (!allowed.contains(key)) {
      diagnostics.add('unknown_field:${path.isEmpty ? key : '$path.$key'}');
    }
  }
}
