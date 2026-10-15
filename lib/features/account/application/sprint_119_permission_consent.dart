import 'dart:convert';
import 'dart:io';

/// The permission a connector grant may ask for.
enum PermissionScope {
  /// Read data inside the granted boundary.
  read,

  /// Replace data inside the granted boundary.
  write,

  /// Add data inside the granted boundary.
  append,

  /// Remove data inside the granted boundary.
  delete,

  /// Ask the host to perform a declared action.
  execute,

  /// Full control. Never granted to a connector.
  admin,

  /// A scope this build does not know. Always refused.
  unknown,
}

/// A category of data a grant may reach.
enum DataCategory {
  accountIdentity,
  workspaceMetadata,
  novelContent,
  characterContent,
  usageMetrics,
  billingMetadata,
  secretMetadata,
  unknown,
}

/// The canonical wire name of a data category.
extension DataCategoryWireName on DataCategory {
  /// The canonical snake_case name used on the wire and in diagnostics.
  String get wireName => switch (this) {
    DataCategory.accountIdentity => 'account_identity',
    DataCategory.workspaceMetadata => 'workspace_metadata',
    DataCategory.novelContent => 'novel_content',
    DataCategory.characterContent => 'character_content',
    DataCategory.usageMetrics => 'usage_metrics',
    DataCategory.billingMetadata => 'billing_metadata',
    DataCategory.secretMetadata => 'secret_metadata',
    DataCategory.unknown => 'unknown',
  };
}

/// How long a grant stays usable.
enum GrantDuration {
  /// For the life of the current session only.
  session,

  oneHour,
  oneDay,
  sevenDays,
  thirtyDays,

  /// The longest bounded window a connector may hold.
  ninetyDays,

  /// Until revoked. Read-only scopes only.
  untilRevoked,

  /// A duration this build does not know. Always refused.
  unknown,
}

/// Where a grant sends data.
enum DestinationKind {
  /// The device itself. No network destination.
  local,

  /// A first-party host operated for this workspace.
  firstParty,

  /// A third-party host. Requires explicit cross-organisation consent.
  thirdParty,

  /// A destination this build does not know. Always refused.
  unknown,
}

/// The canonical wire name of a destination kind.
extension DestinationKindWireName on DestinationKind {
  /// The canonical snake_case name used on the wire.
  String get wireName => switch (this) {
    DestinationKind.local => 'local',
    DestinationKind.firstParty => 'first_party',
    DestinationKind.thirdParty => 'third_party',
    DestinationKind.unknown => 'unknown',
  };
}

/// The bounded lifetime of a grant.
extension GrantDurationWindow on GrantDuration {
  /// The canonical wire name.
  String get wireName => switch (this) {
    GrantDuration.session => 'session',
    GrantDuration.oneHour => '1h',
    GrantDuration.oneDay => '1d',
    GrantDuration.sevenDays => '7d',
    GrantDuration.thirtyDays => '30d',
    GrantDuration.ninetyDays => '90d',
    GrantDuration.untilRevoked => 'until_revoked',
    GrantDuration.unknown => 'unknown',
  };

  /// The wall-clock window, or null for an unbounded grant.
  Duration? get window => switch (this) {
    GrantDuration.session => const Duration(hours: 8),
    GrantDuration.oneHour => const Duration(hours: 1),
    GrantDuration.oneDay => const Duration(days: 1),
    GrantDuration.sevenDays => const Duration(days: 7),
    GrantDuration.thirtyDays => const Duration(days: 30),
    GrantDuration.ninetyDays => const Duration(days: 90),
    GrantDuration.untilRevoked => null,
    GrantDuration.unknown => Duration.zero,
  };

  /// Whether the grant has a wall-clock end.
  bool get isBounded => window != null;
}

/// How a grant is taken back.
final class RevocationPath {
  const RevocationPath({
    required this.handle,
    required this.immediate,
    required this.graceMinutes,
  });

  /// An opaque handle to the revocation path.
  final String handle;

  /// Whether revocation takes effect at once.
  final bool immediate;

  /// Minutes of grace after a revocation request. Zero or a few minutes only.
  final int graceMinutes;

  /// A projection that redacts the handle.
  Map<String, Object?> toJson() => <String, Object?>{
    'handle': '[REDACTED]',
    'immediate': immediate,
    'grace_minutes': graceMinutes,
  };

  @override
  String toString() =>
      'RevocationPath([REDACTED], immediate: $immediate, grace: $graceMinutes)';
}

/// The attestation that a grant asks for no more than it needs.
final class LeastPrivilegeAttestation {
  const LeastPrivilegeAttestation({
    required this.justification,
    required this.scopeIsMinimal,
    required this.reviewedAt,
  });

  /// Why the requested scope is the smallest that works.
  final String justification;

  /// Whether the requester attests the scope is minimal.
  final bool scopeIsMinimal;

  /// When the attestation was reviewed.
  final DateTime reviewedAt;

  /// A projection. A justification is not a secret and is kept.
  Map<String, Object?> toJson() => <String, Object?>{
    'justification': justification,
    'scope_is_minimal': scopeIsMinimal,
    'reviewed_at': reviewedAt.toUtc().toIso8601String(),
  };
}

/// A permission declaration. Every one of the seven canonical fields is bound.
final class PermissionDeclaration {
  const PermissionDeclaration({
    required this.permissionRef,
    required this.scopes,
    required this.purpose,
    required this.dataCategories,
    required this.destination,
    required this.destinationKind,
    required this.crossOrgConsent,
    required this.duration,
    required this.revocation,
    required this.leastPrivilege,
  });

  /// An opaque handle to the permission being requested.
  final String permissionRef;

  /// The scopes being requested. A closed set, never a wildcard.
  final List<PermissionScope> scopes;

  /// Why the permission is needed, in plain words.
  final String purpose;

  /// The data categories the grant may reach.
  final List<DataCategory> dataCategories;

  /// The host the grant sends data to.
  final String destination;

  /// The kind of destination.
  final DestinationKind destinationKind;

  /// Whether cross-organisation consent was given explicitly.
  final bool crossOrgConsent;

  /// How long the grant stays usable.
  final GrantDuration duration;

  /// How the grant is taken back.
  final RevocationPath revocation;

  /// The least-privilege attestation.
  final LeastPrivilegeAttestation leastPrivilege;

  /// Whether any requested scope changes data.
  bool get mutates =>
      scopes.any((PermissionScope scope) => _isMutatingScope(scope));

  /// The canonical field projection, in canonical order. References are
  /// redacted.
  Map<String, Object?> toJson() => <String, Object?>{
    'permission': <String, Object?>{
      'ref': '[REDACTED]',
      'scopes': scopes.map((PermissionScope scope) => scope.name).toList(),
    },
    'purpose': purpose,
    'data_categories': dataCategories
        .map((DataCategory category) => category.wireName)
        .toList(),
    'destination': <String, Object?>{
      'host': destination,
      'kind': destinationKind.wireName,
      'cross_org_consent': crossOrgConsent,
    },
    'duration': duration.wireName,
    'revocation': revocation.toJson(),
    'least_privilege': leastPrivilege.toJson(),
  };

  /// Validates the declaration. An empty list means it may be requested.
  List<String> validate() {
    final diagnostics = <String>[];

    if (!PermissionDeclarationContract.isValidPermissionRef(permissionRef)) {
      diagnostics.add('permission_ref_invalid');
    }

    if (scopes.isEmpty) {
      diagnostics.add('permission_scope_empty');
    }
    for (final scope in scopes) {
      if (scope == PermissionScope.unknown) {
        diagnostics.add('permission_unknown');
      } else if (scope == PermissionScope.admin) {
        diagnostics.add('admin_scope_refused');
      }
    }
    if (scopes.toSet().length != scopes.length) {
      diagnostics.add('permission_scope_duplicate');
    }

    diagnostics.addAll(_validatePurpose());
    diagnostics.addAll(_validateDataCategories());
    diagnostics.addAll(_validateDestination());

    if (duration == GrantDuration.unknown) {
      diagnostics.add('duration_invalid');
    } else if (duration == GrantDuration.untilRevoked && mutates) {
      diagnostics.add('write_requires_bounded_grant');
    }

    if (!revocation.immediate) {
      diagnostics.add('revocation_not_immediate');
    }
    if (revocation.graceMinutes < 0) {
      diagnostics.add('revocation_grace_invalid');
    } else if (revocation.graceMinutes > 5) {
      diagnostics.add('revocation_grace_too_long');
    }
    if (!PermissionDeclarationContract.isValidRevocationRef(
      revocation.handle,
    )) {
      diagnostics.add('revocation_ref_invalid');
    }

    if (!leastPrivilege.scopeIsMinimal) {
      diagnostics.add('least_privilege_not_attested');
    }
    if (leastPrivilege.justification.trim().isEmpty) {
      diagnostics.add('justification_missing');
    } else if (!PermissionDeclarationContract.isPlainText(
      leastPrivilege.justification,
    )) {
      diagnostics.add('justification_not_plain');
    } else if (leastPrivilege.justification.length > 280) {
      diagnostics.add('justification_too_long');
    }

    return diagnostics;
  }

  List<String> _validatePurpose() {
    final diagnostics = <String>[];
    final purpose = this.purpose.trim();
    if (purpose.isEmpty) {
      diagnostics.add('purpose_missing');
      return diagnostics;
    }
    if (PermissionDeclarationContract.isVaguePurpose(purpose)) {
      diagnostics.add('purpose_vague');
      return diagnostics;
    }
    if (!PermissionDeclarationContract.isPlainText(purpose)) {
      diagnostics.add('purpose_not_plain');
      return diagnostics;
    }
    if (purpose.length > 280) {
      diagnostics.add('purpose_too_long');
    }
    return diagnostics;
  }

  List<String> _validateDataCategories() {
    final diagnostics = <String>[];
    if (dataCategories.isEmpty) {
      diagnostics.add('data_categories_empty');
      return diagnostics;
    }
    for (final category in dataCategories) {
      if (category == DataCategory.unknown) {
        diagnostics.add('data_category_unknown');
      }
    }
    if (dataCategories.toSet().length != dataCategories.length) {
      diagnostics.add('data_category_duplicate');
    }
    return diagnostics;
  }

  List<String> _validateDestination() {
    final diagnostics = <String>[];
    if (destinationKind == DestinationKind.unknown) {
      diagnostics.add('destination_unknown');
      return diagnostics;
    }
    if (destinationKind != DestinationKind.local) {
      if (destination.startsWith('http://')) {
        diagnostics.add('destination_not_tls');
      } else if (!PermissionDeclarationContract.isValidHost(destination)) {
        diagnostics.add('destination_invalid');
      }
    }
    if (destinationKind == DestinationKind.thirdParty && !crossOrgConsent) {
      diagnostics.add('cross_org_not_declared');
    }
    return diagnostics;
  }

  @override
  String toString() =>
      'PermissionDeclaration([REDACTED], scopes: ${scopes.length}, '
      'duration: ${duration.name})';
}

/// The consent state of one permission handle.
enum ConsentState {
  none,
  requested,
  granted,
  denied,
  revoked,
  expired,
  unknown,
}

/// The consent lifecycle. Fail-closed, and revocation is always possible.
final class ConsentLedger {
  final Map<String, _ConsentEntry> _entries = <String, _ConsentEntry>{};

  /// The state of [permissionRef].
  ConsentState stateOf(String permissionRef, {DateTime? now}) {
    final entry = _entries[permissionRef];
    if (entry == null) {
      return ConsentState.none;
    }
    if (entry.state == ConsentState.granted && now != null) {
      final window = entry.declaration?.duration.window;
      final grantedAt = entry.grantedAt;
      if (window != null &&
          grantedAt != null &&
          !now.isBefore(grantedAt.add(window))) {
        return ConsentState.expired;
      }
    }
    return entry.state;
  }

  /// Whether [permissionRef] may be exercised right now.
  bool isUsable(String permissionRef, {required DateTime now}) =>
      stateOf(permissionRef, now: now) == ConsentState.granted;

  /// Records a consent request. The declaration must validate first.
  List<String> request(
    String permissionRef,
    PermissionDeclaration declaration,
  ) {
    final diagnostics = declaration.validate();
    if (diagnostics.isNotEmpty) {
      return diagnostics;
    }
    _entries[permissionRef] = _ConsentEntry(
      state: ConsentState.requested,
      declaration: declaration,
    );
    return const <String>[];
  }

  /// Grants a requested permission.
  List<String> grant(String permissionRef, {required DateTime now}) {
    final entry = _entries[permissionRef];
    if (entry == null || entry.state == ConsentState.none) {
      return const <String>['consent_not_requested'];
    }
    if (entry.state == ConsentState.revoked ||
        entry.state == ConsentState.denied) {
      return const <String>['regrant_requires_new_request'];
    }
    _entries[permissionRef] = _ConsentEntry(
      state: ConsentState.granted,
      declaration: entry.declaration,
      grantedAt: now,
    );
    return const <String>[];
  }

  /// Denies a requested permission.
  List<String> deny(String permissionRef) {
    final entry = _entries[permissionRef];
    if (entry == null) {
      return const <String>['consent_not_requested'];
    }
    _entries[permissionRef] = _ConsentEntry(
      state: ConsentState.denied,
      declaration: entry.declaration,
    );
    return const <String>[];
  }

  /// Revokes a permission. Always possible, from any state, and idempotent.
  void revoke(String permissionRef) {
    final entry = _entries[permissionRef];
    if (entry == null) {
      _entries[permissionRef] = _ConsentEntry(
        state: ConsentState.revoked,
        declaration: null,
      );
      return;
    }
    _entries[permissionRef] = _ConsentEntry(
      state: ConsentState.revoked,
      declaration: entry.declaration,
    );
  }
}

final class _ConsentEntry {
  const _ConsentEntry({
    required this.state,
    required this.declaration,
    this.grantedAt,
  });

  final ConsentState state;
  final PermissionDeclaration? declaration;
  final DateTime? grantedAt;
}

bool _isMutatingScope(PermissionScope scope) =>
    scope == PermissionScope.write ||
    scope == PermissionScope.append ||
    scope == PermissionScope.delete;

/// The local permission declaration and consent contract for step 119.22.
abstract final class PermissionDeclarationContract {
  /// The manifest describing this step.
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_permission_consent.json';

  /// The canonical step identifier.
  static const String canonicalStep = '119.22';

  /// The seven canonical fields, in canonical order.
  static const List<String> requiredFields = <String>[
    'permission',
    'purpose',
    'data_categories',
    'destination',
    'duration',
    'revocation',
    'least_privilege',
  ];

  /// This step declares no named methods.
  static const List<String> requiredMethods = <String>[];

  static final RegExp _permissionRef = RegExp(
    r'^permref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _revocationRef = RegExp(
    r'^revokeref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _host = RegExp(
    r'^[a-z0-9]([a-z0-9.-]{0,251})\.[a-z]{2,}$',
  );

  static final RegExp _unsafeText = RegExp(
    r'[<>&`\\{}]|\$|[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]',
  );

  static final RegExp _redactRef = RegExp(
    r'\b(?:permref|revokeref|secretref|provref|actionref|evtref|idemref|'
    r'payref|chkref|invref|modelref|assetref|orgref|resref|jobref|iconref)'
    r':[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}\b',
    caseSensitive: false,
  );

  static const Set<String> _vaguePurposes = <String>{
    'all',
    'any',
    'anything',
    'everything',
    'general',
    'misc',
    'n/a',
    'tbd',
    'unspecified',
  };

  /// Whether [value] is a well-formed opaque permission handle.
  static bool isValidPermissionRef(String value) =>
      _permissionRef.hasMatch(value);

  /// Whether [value] is a well-formed opaque revocation handle.
  static bool isValidRevocationRef(String value) =>
      _revocationRef.hasMatch(value);

  /// Whether [value] is a plausible bare host.
  static bool isValidHost(String value) => _host.hasMatch(value);

  /// Whether [value] is plain text with no markup or interpolation.
  static bool isPlainText(String value) {
    if (_unsafeText.hasMatch(value)) {
      return false;
    }
    return !value.contains('://');
  }

  /// Whether [value] states no real purpose.
  static bool isVaguePurpose(String value) =>
      _vaguePurposes.contains(value.trim().toLowerCase());

  /// Replaces opaque references in [text] so a diagnostic cannot leak one.
  static String redact(String text) =>
      text.replaceAll(_redactRef, '[REDACTED]');

  /// Validates a manifest against this step's contract.
  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];

    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final declared = _declaredNames(manifest['required_fields']);
    for (final field in requiredFields) {
      if (!declared.contains(field)) {
        diagnostics.add('field_missing:$field');
      }
    }
    final declaredOrder = _declaredOrder(manifest['required_fields']);
    if (declaredOrder.isNotEmpty &&
        declared.length == requiredFields.length &&
        !_sameOrder(declaredOrder, requiredFields)) {
      diagnostics.add('field_order_invalid');
    }

    if (requiredMethods.isNotEmpty) {
      final methods = _declaredNames(manifest['required_methods']);
      for (final method in requiredMethods) {
        if (!methods.contains(method)) {
          diagnostics.add('method_missing:$method');
        }
      }
    }

    return diagnostics;
  }

  /// Validates the committed canonical manifest for this step.
  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return <String>['manifest_missing:$manifestPath'];
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return <String>['manifest_not_an_object:$manifestPath'];
    }
    return validateManifest(decoded);
  }

  static Set<String> _declaredNames(Object? declared) {
    if (declared is Map) {
      return declared.keys.map((Object? key) => '$key').toSet();
    }
    if (declared is List) {
      return declared.map((Object? entry) => '$entry').toSet();
    }
    return const <String>{};
  }

  static List<String> _declaredOrder(Object? declared) {
    if (declared is Map) {
      return declared.keys.map((Object? key) => '$key').toList();
    }
    if (declared is List) {
      return declared.map((Object? entry) => '$entry').toList();
    }
    return const <String>[];
  }

  static bool _sameOrder(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }
}
