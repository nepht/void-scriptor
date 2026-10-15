/// Opaque, fail-closed secret-reference operations for roadmap step 119.8.
library;

import 'dart:convert';
import 'dart:io';

enum SecretReferenceResult {
  ok,
  deniedReauthentication,
  invalidReference,
  unknownOperation,
}

final class OpaqueSecretReference {
  const OpaqueSecretReference(this.value);

  final String value;

  static OpaqueSecretReference? tryParse(String value) {
    final valid = RegExp(
      r'^credref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
    ).hasMatch(value);
    return valid ? OpaqueSecretReference(value) : null;
  }

  @override
  String toString() => '[REDACTED]';
}

final class SecretReferenceApi {
  const SecretReferenceApi();

  static const requiredAcceptance = <String>[
    'opaque_ref',
    'brokered_use',
    'rotation',
    'delete',
    'redaction',
    'reauth',
  ];
  static const manifestPath =
      'docs/planning/v1.3/sprint_119_secret_reference_api.json';

  List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != '119.8') {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }
    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      return <String>['acceptance_missing'];
    }
    for (final name in requiredAcceptance) {
      if (!acceptance.containsKey(name)) {
        diagnostics.add('acceptance_missing:$name');
      }
    }
    return diagnostics;
  }

  List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }

  static final RegExp _credentialAssignment = RegExp(
    r"""([A-Za-z0-9_.-]*(?:token|secret|password|passwd|key))"""
    r"""(\s*["']?\s*[=:]\s*["']?)"""
    r"""([^\s,;"']+)""",
    caseSensitive: false,
  );

  static final RegExp _authorizationScheme = RegExp(
    r'\b(Bearer|Basic)\s+[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );

  static final RegExp _opaqueReference = RegExp(
    r'credref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  String redact(String message) {
    final replaced = message
        .replaceAllMapped(
          _credentialAssignment,
          (match) => '${match.group(1)}${match.group(2)}[REDACTED]',
        )
        .replaceAllMapped(
          _authorizationScheme,
          (match) => '${match.group(1)} [REDACTED]',
        );
    return replaced.replaceAll(_opaqueReference, '[REDACTED]');
  }

  Future<SecretReferenceResult> rotate(
    OpaqueSecretReference reference, {
    required bool reauthenticated,
  }) async {
    if (!reauthenticated) return SecretReferenceResult.deniedReauthentication;
    return _valid(reference)
        ? SecretReferenceResult.ok
        : SecretReferenceResult.invalidReference;
  }

  Future<SecretReferenceResult> delete(
    OpaqueSecretReference reference, {
    required bool reauthenticated,
  }) async {
    if (!reauthenticated) return SecretReferenceResult.deniedReauthentication;
    return _valid(reference)
        ? SecretReferenceResult.ok
        : SecretReferenceResult.invalidReference;
  }

  Future<T> use<T>(
    OpaqueSecretReference reference,
    Future<T> Function(String brokeredValue) operation,
  ) {
    if (!_valid(reference)) {
      throw ArgumentError.value(reference.value, 'reference');
    }
    return operation('[BROKERED_SECRET]');
  }

  SecretReferenceResult evaluateOperation(String operation) =>
      switch (operation) {
        'rotate' || 'delete' => SecretReferenceResult.deniedReauthentication,
        'use' => SecretReferenceResult.ok,
        _ => SecretReferenceResult.unknownOperation,
      };

  static bool _valid(OpaqueSecretReference reference) =>
      OpaqueSecretReference.tryParse(reference.value) != null;
}
