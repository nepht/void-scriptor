/// Local, fail-closed developer connector interface contract for roadmap step
/// 119.15.
///
/// This file defines opaque organization and resource references, scope-gated
/// reads, write-when-granted semantics that never escalate from read, validated
/// rate limits, and an append-only audit trail. It does not call a provider
/// API, enumerate a real directory, or store an access token.
library;

import 'dart:convert';
import 'dart:io';

/// Access scope a caller may hold and a resource may declare.
enum DeveloperScope { read, write, admin }

/// Kind of developer resource addressed by the connector.
enum DeveloperResourceKind {
  repository,
  project,
  package,
  issue,
  pipeline,
  unknown,
}

/// Deterministic health of a developer connection.
enum DeveloperHealth { ok, degraded, unavailable }

/// Result of a scope-gated developer operation.
enum DeveloperOperationResult {
  ok,
  deniedMissingScope,
  deniedUnknownResource,
  deniedUnknownOrganization,
  deniedAdminRequired,
}

/// Opaque, non-secret organization handle.
final class OrgRef {
  const OrgRef(this.value);

  static final RegExp _pattern = RegExp(
    r'^orgref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  final String value;

  static OrgRef? tryParse(String raw) =>
      _pattern.hasMatch(raw) ? OrgRef(raw) : null;

  @override
  bool operator ==(Object other) => other is OrgRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '[REDACTED]';
}

/// Opaque, non-secret resource handle.
final class ResourceRef {
  const ResourceRef(this.value);

  static final RegExp _pattern = RegExp(
    r'^resref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  final String value;

  static ResourceRef? tryParse(String raw) =>
      _pattern.hasMatch(raw) ? ResourceRef(raw) : null;

  @override
  bool operator ==(Object other) =>
      other is ResourceRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '[REDACTED]';
}

/// An organization the caller may address.
final class DeveloperOrganization {
  const DeveloperOrganization({required this.ref, required this.tier});

  final OrgRef ref;
  final String tier;

  Map<String, Object?> toJson() => <String, Object?>{
    'organization_ref': '[REDACTED]',
    'tier': tier,
  };
}

/// A resource with the scopes it declares for its own organization.
final class DeveloperResource {
  const DeveloperResource({
    required this.ref,
    required this.kind,
    required this.organization,
    required this.declaredScopes,
  });

  final ResourceRef ref;
  final DeveloperResourceKind kind;
  final OrgRef organization;
  final Set<DeveloperScope> declaredScopes;

  Map<String, Object?> toJson() => <String, Object?>{
    'resource_ref': '[REDACTED]',
    'organization_ref': '[REDACTED]',
    'kind': kind.name,
    'declared_scopes': declaredScopes.map((scope) => scope.name).toList()
      ..sort(),
  };
}

/// Declared rate limits. Estimates are flagged, never presented as exact.
final class DeveloperLimits {
  const DeveloperLimits({
    required this.requestsPerMinute,
    required this.requestsPerPeriod,
    required this.period,
    required this.isEstimate,
  });

  final int requestsPerMinute;
  final int requestsPerPeriod;
  final Duration period;
  final bool isEstimate;

  Map<String, Object?> toJson() => <String, Object?>{
    'requests_per_minute': requestsPerMinute,
    'requests_per_period': requestsPerPeriod,
    'period_seconds': period.inSeconds,
    'is_estimate': isEstimate,
  };
}

/// One append-only audit record. Targets are never echoed in serialized form.
final class DeveloperAuditEntry {
  const DeveloperAuditEntry({
    required this.sequence,
    required this.action,
    required this.target,
    required this.allowed,
    required this.atUtc,
  });

  final int sequence;
  final String action;
  final Object target;
  final bool allowed;
  final DateTime atUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'sequence': sequence,
    'action': action,
    'target': '[REDACTED]',
    'allowed': allowed,
    'at': atUtc.toUtc().toIso8601String(),
  };
}

/// Append-only audit trail. Entries cannot be removed or reordered.
final class DeveloperAuditTrail {
  final List<DeveloperAuditEntry> _entries = <DeveloperAuditEntry>[];

  List<DeveloperAuditEntry> get entries =>
      List<DeveloperAuditEntry>.unmodifiable(_entries);

  DeveloperAuditEntry append({
    required String action,
    required Object target,
    required bool allowed,
    required DateTime at,
  }) {
    final entry = DeveloperAuditEntry(
      sequence: _entries.length + 1,
      action: action,
      target: target,
      allowed: allowed,
      atUtc: at.toUtc(),
    );
    _entries.add(entry);
    return entry;
  }

  bool get isOrdered {
    var previous = 0;
    for (final entry in _entries) {
      if (entry.sequence <= previous) return false;
      previous = entry.sequence;
    }
    return true;
  }
}

/// Manifest validation and fail-closed helpers for the 119.15 contract.
abstract final class DeveloperConnectorInterface {
  static const String canonicalStep = '119.15';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_developer_connector_interface.json';

  static const List<String> requiredMethods = <String>[
    'list_organizations',
    'list_resources',
    'read',
    'write_when_granted',
    'limits',
    'health',
  ];

  static const List<String> requiredAcceptance = requiredMethods;

  static final RegExp _opaqueReference = RegExp(
    r'\b(?:orgref|resref|modelref|storageref|jobref|credref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  /// Deduplicated organizations in deterministic reference order.
  static List<DeveloperOrganization> listOrganizations(
    Iterable<DeveloperOrganization> organizations,
  ) {
    final seen = <String, DeveloperOrganization>{};
    for (final organization in organizations) {
      seen.putIfAbsent(organization.ref.value, () => organization);
    }
    final refs = seen.keys.toList()..sort();
    return refs.map((ref) => seen[ref]!).toList(growable: false);
  }

  /// Resources inside [organization] that declare [scope], in reference order.
  static List<DeveloperResource> listResources(
    Iterable<DeveloperResource> resources, {
    required OrgRef organization,
    required DeveloperScope scope,
  }) {
    final matched = resources
        .where(
          (resource) =>
              resource.organization == organization &&
              resource.declaredScopes.contains(scope),
        )
        .toList();
    matched.sort((a, b) => a.ref.value.compareTo(b.ref.value));
    return List<DeveloperResource>.unmodifiable(matched);
  }

  /// Read requires caller read scope, the requested organization, and the
  /// resource's own read declaration.
  static DeveloperOperationResult read({
    required DeveloperResource? resource,
    required OrgRef organization,
    required Set<DeveloperScope> callerScopes,
  }) => _gated(
    resource: resource,
    organization: organization,
    callerScopes: callerScopes,
    scope: DeveloperScope.read,
  );

  /// Write requires caller write scope and the resource's own write
  /// declaration. Read scope never implies write.
  static DeveloperOperationResult writeWhenGranted({
    required DeveloperResource? resource,
    required OrgRef organization,
    required Set<DeveloperScope> callerScopes,
  }) => _gated(
    resource: resource,
    organization: organization,
    callerScopes: callerScopes,
    scope: DeveloperScope.write,
  );

  static DeveloperOperationResult _gated({
    required DeveloperResource? resource,
    required OrgRef organization,
    required Set<DeveloperScope> callerScopes,
    required DeveloperScope scope,
  }) {
    if (resource == null) return DeveloperOperationResult.deniedUnknownResource;
    if (resource.organization != organization) {
      return DeveloperOperationResult.deniedUnknownOrganization;
    }
    if (!callerScopes.contains(scope)) {
      return DeveloperOperationResult.deniedMissingScope;
    }
    if (!resource.declaredScopes.contains(scope)) {
      return DeveloperOperationResult.deniedMissingScope;
    }
    return DeveloperOperationResult.ok;
  }

  /// Reports invalid limits. An empty list means valid.
  static List<String> validateLimits(DeveloperLimits limits) {
    final diagnostics = <String>[];
    if (limits.requestsPerMinute < 0) {
      diagnostics.add('requests_per_minute_negative');
    }
    if (limits.requestsPerPeriod < 0) {
      diagnostics.add('requests_per_period_negative');
    }
    if (limits.period <= Duration.zero) diagnostics.add('period_not_positive');
    return diagnostics;
  }

  /// Fails closed on negative usage, a non-positive limit, or an exhausted
  /// limit (usage equal to the limit is already exhausted).
  static bool isWithinLimits({required int used, required int limit}) {
    if (used < 0) return false;
    if (limit <= 0) return false;
    return used < limit;
  }

  /// Deterministic health from caller-supplied local signals.
  static DeveloperHealth health({
    required bool reachable,
    required bool authorized,
    required bool withinLimits,
  }) {
    if (!reachable) return DeveloperHealth.unavailable;
    if (!authorized || !withinLimits) return DeveloperHealth.degraded;
    return DeveloperHealth.ok;
  }

  /// Redacts opaque references from diagnostics.
  static String redact(String message) =>
      message.replaceAll(_opaqueReference, '[REDACTED]');

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final declared = manifest['required_methods'];
    final declaredSet = declared is List
        ? declared.whereType<String>().toSet()
        : <String>{};
    for (final method in requiredMethods) {
      if (!declaredSet.contains(method)) {
        diagnostics.add('method_missing:$method');
      }
    }

    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      for (final key in requiredAcceptance) {
        diagnostics.add('acceptance_missing:$key');
      }
      return diagnostics;
    }
    for (final key in requiredAcceptance) {
      if (!acceptance.containsKey(key)) {
        diagnostics.add('acceptance_missing:$key');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
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
}
