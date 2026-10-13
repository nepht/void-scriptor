/// Local, redacted authentication-broker contract for roadmap step 119.7.
///
/// This contract describes OAuth/OIDC registration and lifecycle intent only.
/// It never stores or transports access tokens, refresh tokens, or client
/// secrets. Live provider authorization and credential-store integration remain
/// outside this local contract.
library;

import 'dart:convert';
import 'dart:io';

enum AuthenticationProtocol { oauth2, oidc }

enum AuthenticationBrokerOperationKind {
  authorize,
  refresh,
  reauthenticate,
  revoke,
}

final class AuthenticationBrokerRegistration {
  const AuthenticationBrokerRegistration({
    required this.providerId,
    required this.protocol,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.redirectUris,
    required this.credentialReference,
    required this.scopes,
    required this.supportsRefresh,
    required this.supportsReauthentication,
    required this.supportsRevocation,
    this.pkceRequired = false,
    this.pkceMethod = 'S256',
  });

  final String providerId;
  final AuthenticationProtocol protocol;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final List<String> redirectUris;
  final String credentialReference;
  final List<String> scopes;
  final bool supportsRefresh;
  final bool supportsReauthentication;
  final bool supportsRevocation;
  final bool pkceRequired;
  final String pkceMethod;

  List<String> validate() {
    final diagnostics = <String>[];
    final providerPattern = RegExp(r'^[a-z][a-z0-9._-]{2,63}$');
    final referencePattern = RegExp(
      r'^credref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
    );
    if (!providerPattern.hasMatch(providerId)) {
      diagnostics.add('provider_id_invalid');
    }
    if (!_https(authorizationEndpoint)) {
      diagnostics.add('authorization_endpoint_must_use_https');
    }
    if (!_https(tokenEndpoint)) {
      diagnostics.add('token_endpoint_must_use_https');
    }
    if (redirectUris.isEmpty) {
      diagnostics.add('redirect_uris_missing');
    } else {
      for (final uri in redirectUris) {
        if (!_https(uri)) diagnostics.add('redirect_uri_must_use_https');
      }
    }
    if (!referencePattern.hasMatch(credentialReference)) {
      diagnostics.add('credential_reference_invalid');
    }
    if (scopes.isEmpty) diagnostics.add('scopes_missing');
    if (scopes.any((scope) => scope.trim().isEmpty)) {
      diagnostics.add('scope_invalid');
    }
    if (pkceRequired && pkceMethod != 'S256') {
      diagnostics.add('pkce_method_must_be_s256');
    }
    return diagnostics.toSet().toList(growable: false);
  }

  Map<String, Object?> toRedactedJson() => <String, Object?>{
    'provider_id': providerId,
    'protocol': protocol.name,
    'authorization_endpoint': authorizationEndpoint,
    'token_endpoint': tokenEndpoint,
    'redirect_uris': List<String>.unmodifiable(redirectUris),
    'credential_reference': credentialReference,
    'scopes': List<String>.unmodifiable(scopes),
    'supports_refresh': supportsRefresh,
    'supports_reauthentication': supportsReauthentication,
    'supports_revocation': supportsRevocation,
    'pkce_required': pkceRequired,
    'pkce_method': pkceMethod,
  };

  static bool _https(String value) => Uri.tryParse(value)?.scheme == 'https';
}

final class AuthenticationBrokerOperation {
  const AuthenticationBrokerOperation({
    required this.providerId,
    required this.credentialReference,
    required this.operation,
    required this.redirectUri,
  });

  final String providerId;
  final String credentialReference;
  final AuthenticationBrokerOperationKind operation;
  final String redirectUri;

  List<String> validate() {
    final diagnostics = <String>[];
    if (!RegExp(r'^[a-z][a-z0-9._-]{2,63}$').hasMatch(providerId)) {
      diagnostics.add('provider_id_invalid');
    }
    if (!RegExp(
      r'^credref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
    ).hasMatch(credentialReference)) {
      diagnostics.add('credential_reference_invalid');
    }
    if (Uri.tryParse(redirectUri)?.scheme != 'https') {
      diagnostics.add('redirect_uri_must_use_https');
    }
    return diagnostics.toSet().toList(growable: false);
  }

  Map<String, Object?> toRedactedJson() => <String, Object?>{
    'provider_id': providerId,
    'credential_reference': credentialReference,
    'operation': operation.name,
    'redirect_uri': redirectUri,
  };
}

enum Sprint119AuthenticationBrokerState { pass, fail, blocked }

class Sprint119AuthenticationBrokerReport {
  const Sprint119AuthenticationBrokerReport({
    required this.state,
    required this.verdict,
    required this.externalGates,
    this.diagnostics = const <String>[],
    this.acceptance = const <String>[],
  });

  final Sprint119AuthenticationBrokerState state;
  final String verdict;
  final String externalGates;
  final List<String> diagnostics;
  final List<String> acceptance;
}

class Sprint119AuthenticationBrokerContract {
  const Sprint119AuthenticationBrokerContract._();

  static const String canonicalStep = '119.7';
  static const String title = 'Authentication Broker';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_authentication_broker.json';
  static const int supportedSchemaVersion = 1;
  static const String unknownFieldPolicy = 'REJECT';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const String completeVerdict =
      'AUTHENTICATION_BROKER_CONTRACT_COMPLETE_LOCAL';

  static const List<String> requiredAcceptance = <String>[
    'oauth_pkce',
    'oidc',
    'secret_reference',
    'redirect_validation',
    'refresh',
    'reauth',
    'revoke',
  ];

  static const List<String> requiredRegistrationFields = <String>[
    'provider_id',
    'protocol',
    'authorization_endpoint',
    'token_endpoint',
    'redirect_uris',
    'credential_reference',
    'scopes',
    'supports_refresh',
    'supports_reauthentication',
    'supports_revocation',
    'pkce_required',
    'pkce_method',
  ];
}

class Sprint119AuthenticationBrokerGate {
  const Sprint119AuthenticationBrokerGate();

  Sprint119AuthenticationBrokerReport evaluate() {
    final file = File(Sprint119AuthenticationBrokerContract.manifestPath);
    if (!file.existsSync()) {
      return _blocked(<String>['authentication_broker_manifest_missing']);
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return _blocked(<String>['authentication_broker_root_not_object']);
      }
      return evaluateRecord(decoded);
    } on Object {
      return _blocked(<String>['authentication_broker_manifest_unreadable']);
    }
  }

  Sprint119AuthenticationBrokerReport evaluateRecord(
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
        'state',
        'verdict',
        'acceptance',
        'registration_fields',
        'operations',
        'claim_boundary',
      },
      '',
      diagnostics,
    );
    if (diagnostics.any((item) => item.startsWith('unknown_field:'))) {
      return _fail(diagnostics);
    }
    if (record['schema_version'] !=
        Sprint119AuthenticationBrokerContract.supportedSchemaVersion) {
      return _blocked(<String>[
        'authentication_broker_schema_version_unsupported',
      ], verdict: 'AUTHENTICATION_BROKER_SCHEMA_VERSION_UNSUPPORTED');
    }
    if (record['canonical_step'] !=
        Sprint119AuthenticationBrokerContract.canonicalStep) {
      diagnostics.add('canonical_step_mismatch');
    }
    if (record['title'] != Sprint119AuthenticationBrokerContract.title) {
      diagnostics.add('title_mismatch');
    }
    if (record['unknown_field_policy'] !=
        Sprint119AuthenticationBrokerContract.unknownFieldPolicy) {
      diagnostics.add('unknown_field_policy_not_reject');
    }
    if (record['external_gates'] !=
        Sprint119AuthenticationBrokerContract.externalGates) {
      diagnostics.add('external_gates_not_deferred');
    }
    if (record['state'] != 'pass') diagnostics.add('state_not_pass');
    if (record['verdict'] !=
        Sprint119AuthenticationBrokerContract.completeVerdict) {
      diagnostics.add('verdict_mismatch');
    }

    final claimBoundary = _stringList(record['claim_boundary']);
    if (claimBoundary == null || claimBoundary.isEmpty) {
      diagnostics.add('claim_boundary_missing');
    } else if (!claimBoundary.any(
      (item) => item.toUpperCase().contains('DEFERRED-EXTERNAL'),
    )) {
      diagnostics.add('claim_boundary_not_deferred');
    }

    final rawAcceptance = record['acceptance'];
    if (rawAcceptance is! Map<String, dynamic>) {
      return _blocked(<String>['acceptance_section_not_object']);
    }
    for (final key in rawAcceptance.keys) {
      if (!Sprint119AuthenticationBrokerContract.requiredAcceptance.contains(
        key,
      )) {
        diagnostics.add('unknown_acceptance:$key');
      }
    }
    if (diagnostics.isNotEmpty) return _fail(diagnostics);

    final missing = Sprint119AuthenticationBrokerContract.requiredAcceptance
        .where((name) => !rawAcceptance.containsKey(name))
        .toList();
    if (missing.isNotEmpty) {
      return _blocked(
        missing.map((name) => 'acceptance_missing:$name').toList(),
        verdict: 'AUTHENTICATION_BROKER_CONTRACT_BLOCKED',
      );
    }

    for (final name
        in Sprint119AuthenticationBrokerContract.requiredAcceptance) {
      final raw = rawAcceptance[name];
      if (raw is! Map<String, dynamic>) {
        diagnostics.add('acceptance_not_object:$name');
        continue;
      }
      final desc = raw['description'];
      if (desc is! String || desc.trim().isEmpty) {
        diagnostics.add('acceptance_description_missing:$name');
      }
      final boundary = raw['claim_boundary'];
      if (boundary is String &&
          !boundary.toUpperCase().contains('DEFERRED-EXTERNAL')) {
        diagnostics.add('acceptance_claim_not_deferred:$name');
      }
    }

    final rawRegFields = record['registration_fields'];
    if (rawRegFields is! List<Object?>) {
      diagnostics.add('registration_fields_not_list');
    } else {
      for (final field
          in Sprint119AuthenticationBrokerContract.requiredRegistrationFields) {
        if (!rawRegFields.contains(field)) {
          diagnostics.add('registration_field_missing:$field');
        }
      }
    }

    final rawOperations = record['operations'];
    if (rawOperations is! List<Object?>) {
      diagnostics.add('operations_not_list');
    } else {
      for (final kind in AuthenticationBrokerOperationKind.values) {
        if (!rawOperations.contains(kind.name)) {
          diagnostics.add('operation_missing:${kind.name}');
        }
      }
    }

    if (diagnostics.isNotEmpty) return _fail(diagnostics);
    return Sprint119AuthenticationBrokerReport(
      state: Sprint119AuthenticationBrokerState.pass,
      verdict: Sprint119AuthenticationBrokerContract.completeVerdict,
      externalGates: Sprint119AuthenticationBrokerContract.externalGates,
      acceptance: List<String>.unmodifiable(
        Sprint119AuthenticationBrokerContract.requiredAcceptance,
      ),
    );
  }

  Sprint119AuthenticationBrokerReport _blocked(
    List<String> values, {
    String verdict = 'AUTHENTICATION_BROKER_CONTRACT_BLOCKED',
  }) => Sprint119AuthenticationBrokerReport(
    state: Sprint119AuthenticationBrokerState.blocked,
    verdict: verdict,
    externalGates: Sprint119AuthenticationBrokerContract.externalGates,
    diagnostics: values,
  );

  Sprint119AuthenticationBrokerReport _fail(List<String> diagnostics) =>
      Sprint119AuthenticationBrokerReport(
        state: Sprint119AuthenticationBrokerState.fail,
        verdict: 'AUTHENTICATION_BROKER_CONTRACT_INVALID',
        externalGates: Sprint119AuthenticationBrokerContract.externalGates,
        diagnostics: List<String>.unmodifiable(diagnostics),
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
