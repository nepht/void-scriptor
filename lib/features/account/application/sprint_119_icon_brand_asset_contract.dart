import 'dart:convert';
import 'dart:io';

/// Where an icon's bytes come from.
///
/// The vocabulary is closed: inline payloads are refused outright rather than
/// inspected, so a connector cannot smuggle bytes through a data URI.
enum IconSource {
  /// Shipped with the application as a relative asset path.
  bundled,

  /// Fetched over TLS from a declared host.
  remoteUrl,

  /// An inline data URI. Always refused.
  dataUri,

  /// A handle into another registry entry.
  registry,

  /// A source this build does not know. Always refused.
  unknown,
}

/// The connector's declared right to ship an icon.
///
/// Only [allowed] is usable; the host never infers a right from the presence of
/// a file.
enum IconPermission {
  /// The connector may ship and display this asset.
  allowed,

  /// Display is limited by an unstated condition; refused.
  restricted,

  /// The connector may not ship this asset; refused.
  denied,

  /// The right was not declared; refused.
  unknown,
}

/// Which theme a variant is rendered for.
enum IconTheme {
  /// The light theme.
  light,

  /// The dark theme.
  dark,

  /// A theme this build does not know. Resolves to the host default.
  unknown,
}

/// What the host renders when an asset cannot be loaded.
enum IconFallback {
  /// The host's own neutral icon.
  hostDefault,

  /// A previously declared fallback asset, named by [IconAsset.fallbackRef].
  declaredRef,

  /// No fallback. Always refused, so a failed load can never leave a blank.
  none,
}

/// One themed rendering of an icon.
final class IconVariant {
  const IconVariant({required this.reference, this.digest});

  /// A safe relative bundled path, an https URL, or a registry handle.
  final String reference;

  /// The lowercase hex SHA-256 of the bytes. Mandatory for a remote source.
  final String? digest;

  /// A serializable projection.
  Map<String, Object?> toJson() => <String, Object?>{
    'reference': reference,
    'digest': digest ?? '[NONE]',
  };

  @override
  String toString() => 'IconVariant($reference)';
}

/// A connector's icon and brand asset declaration.
final class IconAsset {
  const IconAsset({
    required this.iconRef,
    required this.source,
    required this.permission,
    required this.version,
    required this.light,
    required this.dark,
    required this.fallback,
    required this.accessibleName,
    this.fallbackRef,
  });

  /// The opaque `iconref:` handle.
  final String iconRef;

  /// Where the bytes come from.
  final IconSource source;

  /// The declared right to ship the asset.
  final IconPermission permission;

  /// The semantic version core.
  final String version;

  /// The light-theme variant.
  final IconVariant? light;

  /// The dark-theme variant.
  final IconVariant? dark;

  /// What the host renders when loading fails.
  final IconFallback fallback;

  /// The fallback asset handle, required when [fallback] is
  /// [IconFallback.declaredRef].
  final String? fallbackRef;

  /// The human-readable name announced by assistive technology.
  final String accessibleName;

  /// The eight canonical fields, projected for serialization and audit.
  Map<String, Object?> toJson() => <String, Object?>{
    'icon_ref': '[REDACTED]',
    'source': source.name,
    'permission': permission.name,
    'version': version,
    'light': light?.toJson(),
    'dark': dark?.toJson(),
    'fallback': fallback.name,
    'fallback_ref': fallbackRef == null ? '[NONE]' : '[REDACTED]',
    'accessible_name': accessibleName,
  };

  @override
  String toString() => 'IconAsset(${source.name}, version: $version)';
}

/// The local icon and brand asset contract for roadmap step 119.20.
///
/// Every rule is deny-by-default: an unknown source, a denied permission, a
/// floating version, an unsafe path, a missing theme, or a missing fallback is
/// refused rather than guessed at.
abstract final class IconAssetContract {
  /// The manifest describing this step.
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_icon_brand_asset_contract.json';

  /// The canonical step identifier.
  static const String canonicalStep = '119.20';

  /// The eight canonical fields, in canonical order.
  static const List<String> requiredFields = <String>[
    'icon_ref',
    'source',
    'permission',
    'version',
    'light',
    'dark',
    'fallback',
    'accessible_name',
  ];

  /// This step declares no named methods.
  static const List<String> requiredMethods = <String>[];

  /// This step declares no acceptance map.
  static const List<String> requiredAcceptance = <String>[];

  /// What the host renders when nothing else is available.
  static const String hostDefaultFallback = 'host-default';

  /// The longest accepted accessible name.
  static const int accessibleNameMaxLength = 80;

  /// The icon formats the host can render.
  static const Set<String> allowedExtensions = <String>{
    '.svg',
    '.png',
    '.webp',
  };

  static final RegExp _iconRef = RegExp(
    r'^iconref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _semver = RegExp(r'^\d+\.\d+\.\d+$');

  static final RegExp _digest = RegExp(r'^[0-9a-f]{64}$');

  static final RegExp _bundledPath = RegExp(r'^[a-z0-9][a-z0-9._/-]*$');

  static final RegExp _httpsUrl = RegExp(
    r'^https://[a-z0-9]([a-z0-9.-]*[a-z0-9])?(\.[a-z]{2,})+'
    r'(/[A-Za-z0-9._~%/-]*)?$',
  );

  static final RegExp _unsafeText = RegExp(
    r'[<>&`\\{}]|\$|[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]',
  );

  static final RegExp _secretRef = RegExp(
    r'\b(?:iconref|provref|actionref|evtref|idemref|payref|chkref|invref|'
    r'modelref|assetref|orgref|resref|jobref|whsec|sk_live|pk_live)'
    r':[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}\b',
    caseSensitive: false,
  );

  /// Whether [value] is plain text with no markup or interpolation.
  static bool isPlainText(String value) {
    if (_unsafeText.hasMatch(value)) {
      return false;
    }
    return !value.contains('://');
  }

  /// Whether [value] is a well-formed opaque icon reference.
  static bool isValidIconRef(String value) => _iconRef.hasMatch(value);

  /// Whether [asset] passes every gate and may therefore be displayed.
  static bool isUsable(IconAsset asset) => validateAsset(asset).isEmpty;

  /// Validates [asset] and returns the diagnostics that failed.
  static List<String> validateAsset(IconAsset asset) {
    final diagnostics = <String>[];

    if (!isValidIconRef(asset.iconRef)) {
      diagnostics.add('icon_ref_invalid');
    }

    diagnostics.addAll(switch (asset.source) {
      IconSource.bundled ||
      IconSource.remoteUrl ||
      IconSource.registry => const <String>[],
      IconSource.dataUri => const <String>['source_refused'],
      IconSource.unknown => const <String>['source_unknown'],
    });

    if (asset.permission != IconPermission.allowed) {
      diagnostics.add('permission_not_allowed');
    }

    if (!_semver.hasMatch(asset.version)) {
      diagnostics.add('version_invalid');
    }

    if (asset.light == null) {
      diagnostics.add('theme_missing:light');
    } else {
      diagnostics.addAll(_validateVariant(asset.source, asset.light!));
    }
    if (asset.dark == null) {
      diagnostics.add('theme_missing:dark');
    } else {
      diagnostics.addAll(_validateVariant(asset.source, asset.dark!));
    }

    if (asset.fallback == IconFallback.none) {
      diagnostics.add('fallback_missing');
    } else if (asset.fallback == IconFallback.declaredRef) {
      final fallbackRef = asset.fallbackRef;
      if (fallbackRef == null || !isValidIconRef(fallbackRef)) {
        diagnostics.add('fallback_ref_invalid');
      }
    }

    if (asset.accessibleName.isEmpty) {
      diagnostics.add('accessible_name_empty');
    } else if (asset.accessibleName.length > accessibleNameMaxLength) {
      diagnostics.add('accessible_name_too_long');
    } else if (!isPlainText(asset.accessibleName)) {
      diagnostics.add('accessible_name_not_plain');
    } else if (asset.accessibleName == asset.iconRef ||
        _iconRef.hasMatch(asset.accessibleName)) {
      diagnostics.add('accessible_name_is_ref');
    }

    return diagnostics;
  }

  /// Replaces opaque references in [text] so a diagnostic cannot leak one.
  static String redact(String text) =>
      text.replaceAll(_secretRef, '[REDACTED]');

  /// Validates a manifest against this step's contract.
  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];

    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final fields = manifest['required_fields'];
    final declared = fields is Map
        ? fields.keys.map((Object? key) => '$key').toSet()
        : fields is List
        ? fields.map((Object? field) => '$field').toSet()
        : const <String>{};
    for (final required in requiredFields) {
      if (!declared.contains(required)) {
        diagnostics.add('field_missing:$required');
      }
    }

    if (requiredMethods.isNotEmpty) {
      final methods = manifest['required_methods'];
      final declaredMethods = methods is List
          ? methods.map((Object? method) => '$method').toSet()
          : const <String>{};
      for (final required in requiredMethods) {
        if (!declaredMethods.contains(required)) {
          diagnostics.add('method_missing:$required');
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

  static List<String> _validateVariant(IconSource source, IconVariant variant) {
    final diagnostics = <String>[];
    final reference = variant.reference;

    diagnostics.addAll(switch (source) {
      IconSource.bundled =>
        !_bundledPath.hasMatch(reference) ||
                reference.contains('..') ||
                reference.startsWith('/') ||
                reference.contains('\\')
            ? const <String>['variant_reference_unsafe']
            : _hasAllowedExtension(reference)
            ? const <String>[]
            : const <String>['variant_extension_unsupported'],
      IconSource.registry =>
        isValidIconRef(reference)
            ? const <String>[]
            : const <String>['variant_reference_unsafe'],
      IconSource.remoteUrl =>
        _httpsUrl.hasMatch(reference)
            ? const <String>[]
            : const <String>['transport_not_tls'],
      IconSource.dataUri || IconSource.unknown => const <String>[],
    });

    final digest = variant.digest;
    if (source == IconSource.remoteUrl) {
      if (digest == null) {
        diagnostics.add('digest_missing');
      } else if (!_digest.hasMatch(digest)) {
        diagnostics.add('digest_invalid');
      }
    } else if (digest != null && !_digest.hasMatch(digest)) {
      diagnostics.add('digest_invalid');
    }

    return diagnostics;
  }

  static bool _hasAllowedExtension(String reference) {
    final dot = reference.lastIndexOf('.');
    if (dot < 0) {
      return false;
    }
    return allowedExtensions.contains(reference.substring(dot).toLowerCase());
  }
}

/// An append-only, local registry of declared icon assets.
///
/// Registration validates first: an asset that fails any gate is never stored,
/// so a denied or malformed asset can never be resolved into a rendered icon.
final class ProviderIconRegistry {
  final Map<String, IconAsset> _assets = <String, IconAsset>{};

  /// The registered assets, in insertion order. Not modifiable.
  List<IconAsset> get assets => List<IconAsset>.unmodifiable(_assets.values);

  /// How many assets are registered.
  int get count => _assets.length;

  /// Whether [iconRef] is registered.
  bool contains(String iconRef) => _assets.containsKey(iconRef);

  /// Validates and registers [asset], returning the diagnostics that failed.
  List<String> register(IconAsset asset) {
    if (_assets.containsKey(asset.iconRef)) {
      return <String>['icon_ref_duplicate'];
    }
    final diagnostics = IconAssetContract.validateAsset(asset);
    if (diagnostics.isEmpty) {
      _assets[asset.iconRef] = asset;
    }
    return diagnostics;
  }

  /// Resolves the reference the host should render for [iconRef] in [theme].
  ///
  /// An unknown reference, an unknown theme, or an asset that is not usable
  /// resolves to the host default rather than to anything connector-supplied.
  String resolve({required String iconRef, required IconTheme theme}) {
    final asset = _assets[iconRef];
    if (asset == null) {
      return IconAssetContract.hostDefaultFallback;
    }
    if (!IconAssetContract.isUsable(asset)) {
      return IconAssetContract.hostDefaultFallback;
    }
    switch (theme) {
      case IconTheme.light:
        return asset.light!.reference;
      case IconTheme.dark:
        return asset.dark!.reference;
      case IconTheme.unknown:
        return IconAssetContract.hostDefaultFallback;
    }
  }
}
