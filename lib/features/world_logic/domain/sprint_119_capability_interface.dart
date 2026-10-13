/// Local, fail-closed capability interface contracts for roadmap step 119.6.
///
/// This file defines discovery, execution, cancellation, health, usage,
/// errors, and lifecycle boundaries. It does not execute a provider, expose a
/// connector, access credentials, certify an integration, or publish a
/// capability.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint119CapabilityInterfaceState { pass, fail, blocked }

class Sprint119CapabilityDefinition {
  const Sprint119CapabilityDefinition({
    required this.name,
    required this.purpose,
    required this.request,
    required this.response,
    required this.failure,
    required this.cancellation,
    required this.lifecycle,
    required this.claimBoundary,
  });

  final String name;
  final String purpose;
  final String request;
  final String response;
  final String failure;
  final String cancellation;
  final String lifecycle;
  final String claimBoundary;

  Map<String, String> toJson() => <String, String>{
    'name': name,
    'purpose': purpose,
    'request': request,
    'response': response,
    'failure': failure,
    'cancellation': cancellation,
    'lifecycle': lifecycle,
    'claim_boundary': claimBoundary,
  };
}

class Sprint119CapabilityDescriptor {
  const Sprint119CapabilityDescriptor({
    required this.capabilityId,
    required this.category,
    required this.operations,
    required this.lifecycle,
    required this.supportsCancellation,
    required this.supportsHealth,
    required this.supportsUsage,
  });

  final String capabilityId;
  final String category;
  final List<String> operations;
  final String lifecycle;
  final bool supportsCancellation;
  final bool supportsHealth;
  final bool supportsUsage;

  Map<String, Object?> toJson() => <String, Object?>{
    'capability_id': capabilityId,
    'category': category,
    'operations': List<String>.unmodifiable(operations),
    'lifecycle': lifecycle,
    'supports_cancellation': supportsCancellation,
    'supports_health': supportsHealth,
    'supports_usage': supportsUsage,
  };

  List<String> validate() {
    final diagnostics = <String>[];
    final idPattern = RegExp(r'^[a-z][a-z0-9._-]{2,127}$');
    final categoryPattern = RegExp(r'^[a-z][a-z0-9._-]{1,63}$');
    if (!idPattern.hasMatch(capabilityId)) {
      diagnostics.add('capability_id_invalid');
    }
    if (!categoryPattern.hasMatch(category)) {
      diagnostics.add('category_invalid');
    }
    if (operations.isEmpty) {
      diagnostics.add('operations_missing');
    } else if (operations.any((operation) => !idPattern.hasMatch(operation))) {
      diagnostics.add('operation_invalid');
    }
    if (lifecycle.trim().isEmpty) {
      diagnostics.add('lifecycle_missing');
    }
    return diagnostics;
  }
}

class Sprint119CapabilityInterfaceReport {
  const Sprint119CapabilityInterfaceReport({
    required this.state,
    required this.verdict,
    required this.externalGates,
    this.missingContracts = const <String>[],
    this.violations = const <String>[],
    this.contracts = const <String>[],
  });

  final Sprint119CapabilityInterfaceState state;
  final String verdict;
  final String externalGates;
  final List<String> missingContracts;
  final List<String> violations;
  final List<String> contracts;
}

class Sprint119CapabilityInterfaceContract {
  const Sprint119CapabilityInterfaceContract._();

  static const String canonicalStep = '119.6';
  static const String title = 'Capability Interface Foundation';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_capability_interface.json';
  static const int supportedSchemaVersion = 1;
  static const String unknownFieldPolicy = 'REJECT';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const String completeVerdict =
      'CAPABILITY_INTERFACE_CONTRACT_COMPLETE_LOCAL';

  static const List<String> requiredContracts = <String>[
    'capability_discovery',
    'execution',
    'cancellation',
    'health',
    'usage',
    'errors',
    'lifecycle',
  ];

  static const List<String> requiredDefinitionFields = <String>[
    'name',
    'purpose',
    'request',
    'response',
    'failure',
    'cancellation',
    'lifecycle',
    'claim_boundary',
  ];
}

class Sprint119CapabilityInterfaceGate {
  const Sprint119CapabilityInterfaceGate();

  Sprint119CapabilityInterfaceReport evaluate() {
    final file = File(Sprint119CapabilityInterfaceContract.manifestPath);
    if (!file.existsSync()) {
      return _blocked(<String>['capability_interface_manifest_missing']);
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return _blocked(<String>['capability_interface_root_not_object']);
      }
      return evaluateRecord(decoded);
    } on Object {
      return _blocked(<String>['capability_interface_manifest_unreadable']);
    }
  }

  Sprint119CapabilityInterfaceReport evaluateRecord(
    Map<String, dynamic> record,
  ) {
    final violations = <String>[];
    _unknownKeys(
      record,
      const <String>{
        'canonical_step',
        'title',
        'schema_version',
        'unknown_field_policy',
        'external_gates',
        'state',
        'verdict',
        'contracts',
        'claim_boundary',
      },
      '',
      violations,
    );
    if (violations.any((item) => item.startsWith('unknown_field:'))) {
      return _fail(violations);
    }
    if (record['schema_version'] !=
        Sprint119CapabilityInterfaceContract.supportedSchemaVersion) {
      return _blocked(<String>[
        'capability_interface_schema_version_unsupported',
      ], verdict: 'CAPABILITY_INTERFACE_SCHEMA_VERSION_UNSUPPORTED');
    }
    if (record['canonical_step'] !=
        Sprint119CapabilityInterfaceContract.canonicalStep) {
      violations.add('canonical_step_mismatch');
    }
    if (record['title'] != Sprint119CapabilityInterfaceContract.title) {
      violations.add('title_mismatch');
    }
    if (record['unknown_field_policy'] !=
        Sprint119CapabilityInterfaceContract.unknownFieldPolicy) {
      violations.add('unknown_field_policy_not_reject');
    }
    if (record['external_gates'] !=
        Sprint119CapabilityInterfaceContract.externalGates) {
      violations.add('external_gates_not_deferred');
    }
    if (record['state'] != 'pass') violations.add('state_not_pass');
    if (record['verdict'] !=
        Sprint119CapabilityInterfaceContract.completeVerdict) {
      violations.add('verdict_mismatch');
    }

    final claimBoundary = _stringList(record['claim_boundary']);
    if (claimBoundary == null || claimBoundary.isEmpty) {
      violations.add('claim_boundary_missing');
    } else if (!claimBoundary.any(
      (item) => item.toUpperCase().contains('DEFERRED-EXTERNAL'),
    )) {
      violations.add('claim_boundary_not_deferred');
    }

    final rawContracts = record['contracts'];
    if (rawContracts is! Map<String, dynamic>) {
      return _blocked(<String>['contracts_section_not_object']);
    }
    for (final name in rawContracts.keys) {
      if (!Sprint119CapabilityInterfaceContract.requiredContracts.contains(
        name,
      )) {
        violations.add('unknown_contract:$name');
      }
    }
    if (violations.isNotEmpty) return _fail(violations);

    final missing = Sprint119CapabilityInterfaceContract.requiredContracts
        .where((name) => !rawContracts.containsKey(name))
        .toList();
    if (missing.isNotEmpty) {
      return _blocked(
        missing,
        verdict: 'CAPABILITY_INTERFACE_CONTRACT_BLOCKED',
      );
    }

    for (final name in Sprint119CapabilityInterfaceContract.requiredContracts) {
      final rawDefinition = rawContracts[name];
      if (rawDefinition is! Map<String, dynamic>) {
        violations.add('contract_not_object:$name');
        continue;
      }
      _unknownKeys(
        rawDefinition,
        Sprint119CapabilityInterfaceContract.requiredDefinitionFields.toSet(),
        'contracts.$name',
        violations,
      );
      if (rawDefinition['name'] != name) {
        violations.add('contract_name_mismatch:$name');
      }
      for (final field
          in Sprint119CapabilityInterfaceContract.requiredDefinitionFields) {
        final value = rawDefinition[field];
        if (value is! String || value.trim().isEmpty) {
          violations.add('contract_field_missing:$name:$field');
        }
      }
      final claim = rawDefinition['claim_boundary'];
      if (claim is String &&
          !claim.toUpperCase().contains('DEFERRED-EXTERNAL')) {
        violations.add('contract_claim_not_deferred:$name');
      }
    }
    if (violations.isNotEmpty) return _fail(violations);
    return Sprint119CapabilityInterfaceReport(
      state: Sprint119CapabilityInterfaceState.pass,
      verdict: Sprint119CapabilityInterfaceContract.completeVerdict,
      externalGates: Sprint119CapabilityInterfaceContract.externalGates,
      contracts: List<String>.unmodifiable(
        Sprint119CapabilityInterfaceContract.requiredContracts,
      ),
    );
  }

  Sprint119CapabilityInterfaceReport _blocked(
    List<String> values, {
    String verdict = 'CAPABILITY_INTERFACE_CONTRACT_BLOCKED',
  }) {
    final missing = verdict == 'CAPABILITY_INTERFACE_CONTRACT_BLOCKED'
        ? values
        : const <String>[];
    return Sprint119CapabilityInterfaceReport(
      state: Sprint119CapabilityInterfaceState.blocked,
      verdict: verdict,
      externalGates: Sprint119CapabilityInterfaceContract.externalGates,
      missingContracts: missing,
      violations: verdict == 'CAPABILITY_INTERFACE_CONTRACT_BLOCKED'
          ? const <String>[]
          : values,
    );
  }

  Sprint119CapabilityInterfaceReport _fail(List<String> violations) =>
      Sprint119CapabilityInterfaceReport(
        state: Sprint119CapabilityInterfaceState.fail,
        verdict: 'CAPABILITY_INTERFACE_CONTRACT_INVALID',
        externalGates: Sprint119CapabilityInterfaceContract.externalGates,
        violations: List<String>.unmodifiable(violations),
      );
}

List<String>? _stringList(Object? value) {
  if (value is! List<Object?>) return null;
  if (value.any((item) => item is! String)) return null;
  return value.cast<String>();
}

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
