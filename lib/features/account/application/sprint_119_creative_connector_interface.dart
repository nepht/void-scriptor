/// Local, fail-closed creative connector interface contract for roadmap step
/// 119.16.
///
/// This file defines opaque asset references, kind-filtered asset listing,
/// locally derived metadata, deny-by-default rights validation, attribution
/// obligations, scope-gated import/export/transform, and append-only lineage.
/// It does not transfer asset bytes, write to an external destination, run any
/// media processing, or assert legal clearance.
///
/// Note: the canonical method named `import` cannot be a Dart identifier
/// (`import` is a reserved word), so it is exposed as [importAsset].
library;

import 'dart:convert';
import 'dart:io';

/// Kind of creative asset addressed by the connector.
enum CreativeAssetKind { image, audio, video, font, model3d, document, unknown }

/// Licence of an asset. An unknown licence denies by default.
enum CreativeLicense { cc0, ccBy, ccBySa, proprietary, publicDomain, unknown }

/// Where an exported asset is going.
enum CreativeDestination { local, published, commercial }

/// Scope a caller must hold for creative operations.
enum CreativeScope { read, import, export, transform }

/// Deterministic health of a creative connection.
enum CreativeHealth { ok, degraded, unavailable }

/// Result of a gated creative operation.
enum CreativeOperationResult {
  ok,
  deniedMissingScope,
  deniedMissingRights,
  deniedUnknownAsset,
  deniedUnknownSource,
  deniedAttributionRequired,
  deniedDerivativesNotPermitted,
}

/// Opaque, non-secret asset handle.
final class AssetRef {
  const AssetRef(this.value);

  static final RegExp _pattern = RegExp(
    r'^assetref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  final String value;

  static AssetRef? tryParse(String raw) =>
      _pattern.hasMatch(raw) ? AssetRef(raw) : null;

  @override
  bool operator ==(Object other) => other is AssetRef && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '[REDACTED]';
}

/// Rights attached to an asset. Deny-by-default when incomplete.
final class CreativeRights {
  const CreativeRights({
    required this.license,
    required this.holder,
    required this.allowsDerivatives,
    required this.allowsCommercial,
    this.expiresAtUtc,
  });

  final CreativeLicense license;
  final String holder;
  final bool allowsDerivatives;
  final bool allowsCommercial;
  final DateTime? expiresAtUtc;

  /// True once the expiry instant has been reached or passed.
  bool isExpired(DateTime now) {
    final expiry = expiresAtUtc?.toUtc();
    if (expiry == null) return false;
    return !expiry.isAfter(now.toUtc());
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'license': license.name,
    'holder': holder,
    'allows_derivatives': allowsDerivatives,
    'allows_commercial': allowsCommercial,
    'expires_at': expiresAtUtc?.toUtc().toIso8601String(),
  };
}

/// Attribution obligation. A required obligation is satisfied only by real
/// text.
final class CreativeAttribution {
  const CreativeAttribution({required this.isRequired, this.text});

  final bool isRequired;
  final String? text;

  bool get isSatisfied {
    if (!isRequired) return true;
    final value = text;
    return value != null && value.trim().isNotEmpty;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'required': isRequired,
    'text_present': isSatisfied && isRequired,
  };
}

/// A creative asset with its rights and attribution obligations.
final class CreativeAsset {
  const CreativeAsset({
    required this.ref,
    required this.kind,
    required this.rights,
    required this.attribution,
  });

  final AssetRef ref;
  final CreativeAssetKind kind;
  final CreativeRights rights;
  final CreativeAttribution attribution;

  Map<String, Object?> toJson() => <String, Object?>{
    'asset_ref': '[REDACTED]',
    'kind': kind.name,
    'rights': rights.toJson(),
    'attribution': attribution.toJson(),
  };
}

/// One recorded transformation step.
final class CreativeTransform {
  const CreativeTransform({
    required this.id,
    required this.operation,
    required this.reversible,
  });

  final String id;
  final String operation;
  final bool reversible;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'operation': operation,
    'reversible': reversible,
  };
}

/// Append-only transformation lineage. Steps cannot be removed or reordered,
/// and a repeated step id makes the lineage unordered.
final class CreativeLineage {
  final List<CreativeTransform> _steps = <CreativeTransform>[];

  List<CreativeTransform> get steps =>
      List<CreativeTransform>.unmodifiable(_steps);

  CreativeTransform record(CreativeTransform transform) {
    _steps.add(transform);
    return transform;
  }

  bool get isOrdered {
    final seen = <String>{};
    for (final step in _steps) {
      if (!seen.add(step.id)) return false;
    }
    return true;
  }
}

/// Manifest validation and fail-closed helpers for the 119.16 contract.
abstract final class CreativeConnectorInterface {
  static const String canonicalStep = '119.16';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_creative_connector_interface.json';

  static const List<String> requiredMethods = <String>[
    'list_assets',
    'metadata',
    'rights',
    'import',
    'export_when_granted',
    'transform_when_granted',
    'health',
  ];

  static const List<String> requiredAcceptance = requiredMethods;

  static final RegExp _opaqueReference = RegExp(
    r'\b(?:assetref|orgref|resref|modelref|storageref|jobref|credref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  /// Assets of [kind] in deterministic reference order.
  static List<CreativeAsset> listAssets(
    Iterable<CreativeAsset> assets, {
    required CreativeAssetKind kind,
  }) {
    final matched = assets.where((asset) => asset.kind == kind).toList();
    matched.sort((a, b) => a.ref.value.compareTo(b.ref.value));
    return List<CreativeAsset>.unmodifiable(matched);
  }

  /// Reports invalid rights. An empty list means valid.
  ///
  /// An unknown licence and a missing holder both deny, so incomplete rights
  /// never pass silently.
  static List<String> validateRights(
    CreativeRights rights, {
    required DateTime now,
  }) {
    final diagnostics = <String>[];
    if (rights.license == CreativeLicense.unknown) {
      diagnostics.add('license_unknown');
    }
    if (rights.holder.trim().isEmpty) {
      diagnostics.add('rights_holder_missing');
    }
    if (rights.isExpired(now)) diagnostics.add('rights_expired');
    return diagnostics;
  }

  /// Rights summary for an asset, including its diagnostics.
  static Map<String, Object?> rights({
    required CreativeAsset asset,
    required DateTime now,
  }) => <String, Object?>{
    'license': asset.rights.license.name,
    'holder': asset.rights.holder,
    'allows_derivatives': asset.rights.allowsDerivatives,
    'allows_commercial': asset.rights.allowsCommercial,
    'expired': asset.rights.isExpired(now),
    'diagnostics': validateRights(asset.rights, now: now),
  };

  /// Locally derived metadata. The asset reference is never echoed.
  static Map<String, Object?> metadata({
    required CreativeAsset asset,
    required DateTime now,
  }) {
    final rightsSummary = rights(asset: asset, now: now);
    return <String, Object?>{
      'asset_ref': '[REDACTED]',
      'kind': asset.kind.name,
      'rights': rightsSummary,
      'rights_diagnostics': rightsSummary['diagnostics'],
      'attribution': asset.attribution.toJson(),
      'attribution_satisfied': asset.attribution.isSatisfied,
    };
  }

  /// Import is denied without a known asset, a declared source, and valid
  /// rights. Exposed as `importAsset` because `import` is a reserved word.
  static CreativeOperationResult importAsset({
    required CreativeAsset? asset,
    required bool sourceDeclared,
    required DateTime now,
  }) {
    if (asset == null) return CreativeOperationResult.deniedUnknownAsset;
    if (!sourceDeclared) return CreativeOperationResult.deniedUnknownSource;
    if (validateRights(asset.rights, now: now).isNotEmpty) {
      return CreativeOperationResult.deniedMissingRights;
    }
    return CreativeOperationResult.ok;
  }

  /// Export requires scope, valid rights, satisfied attribution, and
  /// commercial rights for a commercial destination.
  static CreativeOperationResult exportWhenGranted({
    required CreativeAsset? asset,
    required Set<CreativeScope> callerScopes,
    required CreativeDestination destination,
    required DateTime now,
  }) {
    if (asset == null) return CreativeOperationResult.deniedUnknownAsset;
    if (!callerScopes.contains(CreativeScope.export)) {
      return CreativeOperationResult.deniedMissingScope;
    }
    if (validateRights(asset.rights, now: now).isNotEmpty) {
      return CreativeOperationResult.deniedMissingRights;
    }
    if (!asset.attribution.isSatisfied) {
      return CreativeOperationResult.deniedAttributionRequired;
    }
    if (destination == CreativeDestination.commercial &&
        !asset.rights.allowsCommercial) {
      return CreativeOperationResult.deniedMissingRights;
    }
    return CreativeOperationResult.ok;
  }

  /// Transformation requires scope, valid rights, and derivative rights.
  static CreativeOperationResult transformWhenGranted({
    required CreativeAsset? asset,
    required Set<CreativeScope> callerScopes,
    required DateTime now,
  }) {
    if (asset == null) return CreativeOperationResult.deniedUnknownAsset;
    if (!callerScopes.contains(CreativeScope.transform)) {
      return CreativeOperationResult.deniedMissingScope;
    }
    if (validateRights(asset.rights, now: now).isNotEmpty) {
      return CreativeOperationResult.deniedMissingRights;
    }
    if (!asset.rights.allowsDerivatives) {
      return CreativeOperationResult.deniedDerivativesNotPermitted;
    }
    return CreativeOperationResult.ok;
  }

  /// Deterministic health from caller-supplied local signals.
  static CreativeHealth health({
    required bool reachable,
    required bool authorized,
    required bool rightsResolved,
  }) {
    if (!reachable) return CreativeHealth.unavailable;
    if (!authorized || !rightsResolved) return CreativeHealth.degraded;
    return CreativeHealth.ok;
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
