/// Canonical provider-icon registry contract for Sprint 115.8.
///
/// The registry is deliberately data-only: it does not assert that a
/// connector is configured or available. Connector availability belongs to
/// the provider manifest (115.9). When a mark is not bundled or cannot be
/// used under its brand rules, [ProviderIconRegistry.resolve] returns a
/// generic category fallback rather than silently drawing or recoloring it.
library;

import 'account_center_localization_formatting.dart';

enum ProviderIconCategory {
  identity('identity'),
  cloudStorage('cloud_storage'),
  ai('ai'),
  developer('developer'),
  creative('creative'),
  payment('payment');

  const ProviderIconCategory(this.wireName);

  final String wireName;
}

enum ProviderIconFallback {
  identity('identity'),
  cloudStorage('cloud_storage'),
  ai('ai'),
  developer('developer'),
  creative('creative'),
  payment('payment');

  const ProviderIconFallback(this.category);

  final String category;

  static ProviderIconFallback forCategory(ProviderIconCategory category) =>
      switch (category) {
        ProviderIconCategory.identity => ProviderIconFallback.identity,
        ProviderIconCategory.cloudStorage => ProviderIconFallback.cloudStorage,
        ProviderIconCategory.ai => ProviderIconFallback.ai,
        ProviderIconCategory.developer => ProviderIconFallback.developer,
        ProviderIconCategory.creative => ProviderIconFallback.creative,
        ProviderIconCategory.payment => ProviderIconFallback.payment,
      };
}

enum ProviderIconAspectRatio {
  /// Keep the source aspect ratio. Do not crop, stretch, or recolor a mark.
  preserve,
}

enum ProviderIconFit {
  /// Equivalent to Flutter's `BoxFit.contain` without coupling this domain
  /// contract to a concrete widget tree.
  contain,
}

/// Sprint 117.22 — how the bundled mark may be used, recorded per mark instead
/// of as one shared sentence.
///
/// 117.22 requires a `permission` per provider icon. The registry may record a
/// BUNDLED status that the file ships in-repo, but it can never grant a brand
/// licence: approval stays [ProviderIconPermission.unverified] until a human or
/// the provider confirms it, which is why the report marks it an external gate.
enum ProviderIconPermission {
  /// A third-party mark is bundled but its brand/licence permission has not been
  /// confirmed by anyone. Fail-closed default for any real provider mark.
  unverified('UNVERIFIED'),

  /// No third-party mark is used at all: a generic category glyph the project
  /// draws itself. There is nothing to license, so permission is satisfied.
  genericFallback('GENERIC_FALLBACK');

  const ProviderIconPermission(this.wireName);

  final String wireName;
}

/// Intrinsic geometry of the source mark, measured from the asset itself.
///
/// Sprint 117.22 measured that `widthForHeight` returned the height unchanged,
/// so a 1180x320 wordmark was squeezed into a square and stretched. The registry
/// now carries the real source box so aspect preservation is arithmetic rather
/// than a declaration nobody checks.
class ProviderIconIntrinsicSize {
  ProviderIconIntrinsicSize(this.width, this.height) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError.value(
        '$width x $height',
        'intrinsicSize',
        'Intrinsic mark size must be finite and greater than zero.',
      );
    }
  }

  final double width;
  final double height;

  double get aspectRatio => width / height;
}

class ProviderIconEntry {
  ProviderIconEntry({
    required String providerId,
    required String displayName,
    required this.category,
    this.assetLight,
    this.assetDark,
    required this.monochromeFallback,
    required String trademarkNotice,
    required String assetVersion,
    this.aspectRatioPolicy = ProviderIconAspectRatio.preserve,
    this.fit = ProviderIconFit.contain,
    this.assetSource,
    this.permission = ProviderIconPermission.unverified,
    this.intrinsicSize,
    this.assetDigest,
    this.clearSpaceRatio,
    this.supportsDarkSurface = true,
  }) : providerId = _normalizeId(providerId),
       displayName = AccountCenterLocalizationFormatting.providerDisplayName(
         displayName,
       ),
       trademarkNotice = trademarkNotice.trim(),
       assetVersion = assetVersion.trim() {
    _validateAssetPath(assetLight, 'assetLight');
    _validateAssetPath(assetDark, 'assetDark');
    if (this.assetVersion.isEmpty) {
      throw ArgumentError.value(
        assetVersion,
        'assetVersion',
        'Provider icon entries require a non-empty asset version.',
      );
    }
    final clearSpace = clearSpaceRatio;
    if (clearSpace != null &&
        (!clearSpace.isFinite || clearSpace <= 0 || clearSpace > 1)) {
      throw ArgumentError.value(
        clearSpaceRatio,
        'clearSpaceRatio',
        'Clear space must be a ratio greater than 0 and at most 1.',
      );
    }
    final digest = assetDigest;
    if (digest != null && !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
      throw ArgumentError.value(
        assetDigest,
        'assetDigest',
        'Asset digest must be a lowercase hex SHA-256.',
      );
    }
  }

  /// Test fixture constructor. Production callers should use [ProviderIconEntry].
  factory ProviderIconEntry.fixture(
    String providerId, {
    String? displayName,
    String? assetLight,
    String? assetDark,
    String? assetVersion,
    String? trademarkNotice,
    String? assetSource,
    ProviderIconPermission? permission,
    ProviderIconIntrinsicSize? intrinsicSize,
    String? assetDigest,
    double? clearSpaceRatio,
    bool? supportsDarkSurface,
  }) => ProviderIconEntry(
    providerId: providerId,
    displayName: displayName ?? providerId,
    category: ProviderIconCategory.developer,
    assetLight: assetLight,
    assetDark: assetDark,
    monochromeFallback: ProviderIconFallback.developer,
    trademarkNotice: trademarkNotice ?? 'Test fixture; not a production mark.',
    assetVersion: assetVersion ?? 'test-fixture-v1',
    assetSource: assetSource ?? 'test fixture',
    permission: permission ?? ProviderIconPermission.genericFallback,
    intrinsicSize: intrinsicSize,
    assetDigest: assetDigest,
    clearSpaceRatio: clearSpaceRatio,
    supportsDarkSurface: supportsDarkSurface ?? true,
  );

  final String providerId;
  final String displayName;
  final ProviderIconCategory category;
  final String? assetLight;
  final String? assetDark;
  final ProviderIconFallback monochromeFallback;
  final String trademarkNotice;
  final String assetVersion;
  final ProviderIconAspectRatio aspectRatioPolicy;
  final ProviderIconFit fit;

  /// Sprint 117.22 — provenance for `asset_source`. Names the concrete bundled
  /// file instead of repeating one shared sentence across every mark.
  final String? assetSource;

  /// Sprint 117.22 — the `permission` evidence item. Default
  /// [ProviderIconPermission.unverified], because shipping a mark in-repo is
  /// not a licence grant.
  final ProviderIconPermission permission;

  /// Sprint 117.22 — measured source geometry backing aspect preservation.
  final ProviderIconIntrinsicSize? intrinsicSize;

  /// Sprint 117.22 — SHA-256 of the bundled file, so `asset_version` pins
  /// content. A recoloured or swapped mark changes this and fails validation.
  final String? assetDigest;

  /// Sprint 117.22 — the `clear_space` evidence item as a checkable ratio of
  /// the mark box that must stay free, instead of one line of prose.
  final double? clearSpaceRatio;

  /// Sprint 117.22 — false for marks whose ink is too dark to read on the dark
  /// chrome surface, so the presentation layer can fall back rather than ship an
  /// invisible mark.
  final bool supportsDarkSurface;

  bool get hasBundledAsset => assetLight != null || assetDark != null;
  bool get isOfficialAsset => hasBundledAsset;
  bool get isKnownProvider => true;
  bool get usesGenericFallback => !isOfficialAsset;

  /// Sprint 117.22 — which theme surfaces this mark is declared usable on.
  List<String> get themeVariants => <String>[
    'light',
    if (supportsDarkSurface) 'dark',
  ];

  String get accessibleName => usesGenericFallback
      ? '$displayName icon unavailable'
      : '$displayName icon';

  /// Width that preserves the measured source ratio at [height]. Sprint 117.22
  /// measured the previous implementation returning [height] unchanged, which
  /// silently squeezed the 1180x320 OpenAI wordmark into a square.
  double widthForHeight(double height) {
    final size = intrinsicSize;
    if (size == null) return _positiveDimension(height);
    return _positiveDimension(height * size.aspectRatio);
  }

  /// Height that preserves the measured source ratio at [width].
  double heightForWidth(double width) {
    final size = intrinsicSize;
    if (size == null) return _positiveDimension(width);
    return _positiveDimension(width / size.aspectRatio);
  }

  ProviderIconEntry genericForCategory() => ProviderIconEntry(
    providerId: providerId,
    displayName: displayName,
    category: category,
    monochromeFallback: monochromeFallback,
    trademarkNotice: trademarkNotice,
    assetVersion: assetVersion,
    assetSource: assetSource,
    permission: ProviderIconPermission.genericFallback,
    supportsDarkSurface: true,
  );

  bool get hasAssetLight => assetLight != null;
  bool get hasAssetDark => assetDark != null;

  static String _normalizeId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'providerId',
        'Provider icon entries require a non-empty provider id.',
      );
    }
    return normalized;
  }

  static void _validateAssetPath(String? value, String field) {
    if (value == null) return;
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        field,
        'Asset path must be null or a non-empty string.',
      );
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      throw ArgumentError.value(
        normalized,
        field,
        'Remote icon downloads are not a blocking registry dependency.',
      );
    }
  }

  static double _positiveDimension(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        'dimension',
        'Icon dimensions must be finite and greater than zero.',
      );
    }
    return value;
  }
}

class ProviderIconRegistry {
  ProviderIconRegistry(Iterable<ProviderIconEntry> entries) {
    for (final entry in entries) {
      if (_entries.containsKey(entry.providerId)) {
        throw ArgumentError.value(
          entry.providerId,
          'entries',
          'Provider icon ids must be unique.',
        );
      }
      _entries[entry.providerId] = entry;
    }
  }

  static const canonicalAcceptance = <String>[
    'provider_id_lookup',
    'official_asset_policy',
    'aspect_ratio',
    'fallback_icon',
    'accessible_name',
    'asset_version',
  ];

  static const requiredFields = <String>[
    'provider_id',
    'display_name',
    'category',
    'asset_light',
    'asset_dark',
    'monochrome_fallback',
    'trademark_notice',
    'asset_version',
  ];

  static const policyRules = <String>[
    'Use official provider assets only when licensing and brand rules permit.',
    'Do not redraw, recolor, stretch, crop, or combine official marks unless provider rules explicitly allow it.',
    'Preserve aspect ratio and clear space.',
    'Use a generic category icon when an official asset is unavailable or cannot be bundled.',
    'Provider icon is never the only status indicator; include text and accessible status.',
    'Remote icon download must be optional, cached safely, and never block account access.',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  static final ProviderIconRegistry standard = ProviderIconRegistry(
    _standardEntries,
  );

  final Map<String, ProviderIconEntry> _entries = <String, ProviderIconEntry>{};

  ProviderIconEntry? get(String providerId) =>
      _entries[_normalizeId(providerId)];

  ProviderIconEntry require(String providerId) {
    final entry = get(providerId);
    if (entry == null) {
      throw StateError('Provider icon "$providerId" is not registered.');
    }
    return entry;
  }

  List<ProviderIconEntry> get all => List.unmodifiable(_entries.values);

  /// Resolve a provider id to a registered mark or a generic fallback.
  ProviderIconEntry resolve(String providerId) {
    final normalized = _normalizeId(providerId);
    final entry = _entries[normalized];
    if (entry == null) {
      return ProviderIconEntry(
        providerId: normalized,
        displayName: 'Provider',
        category: ProviderIconCategory.identity,
        monochromeFallback: ProviderIconFallback.identity,
        trademarkNotice: 'Generic icon; no provider mark bundled.',
        assetVersion: 'generic-v1',
        assetSource: 'generic identity glyph; no provider mark bundled',
        permission: ProviderIconPermission.genericFallback,
      );
    }
    return entry.hasBundledAsset ? entry : entry.genericForCategory();
  }

  /// Sprint 117.22 — resolve for one concrete theme surface.
  ///
  /// A mark whose ink cannot be read on [isDark] resolves to the approved
  /// generic category glyph *including its accessible name*. Deciding this in
  /// the widget instead would draw the fallback glyph while still announcing
  /// "Anthropic icon", which tells a screen-reader user a mark is present when
  /// it is not.
  ProviderIconEntry resolveForSurface(
    String providerId, {
    required bool isDark,
  }) {
    final entry = resolve(providerId);
    if (isDark && !entry.supportsDarkSurface && entry.hasBundledAsset) {
      return entry.genericForCategory();
    }
    return entry;
  }

  ProviderIconEntry resolveForCategory(ProviderIconCategory category) =>
      ProviderIconEntry(
        providerId: 'generic-${category.wireName}',
        displayName: _categoryDisplayName(category),
        category: category,
        monochromeFallback: ProviderIconFallback.forCategory(category),
        trademarkNotice: 'Generic ${category.wireName} icon.',
        assetVersion: 'generic-v1',
      );

  static String _normalizeId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'providerId',
        'Provider icon lookup requires a non-empty id.',
      );
    }
    return normalized;
  }

  static String _categoryDisplayName(ProviderIconCategory category) =>
      switch (category) {
        ProviderIconCategory.identity => 'Identity',
        ProviderIconCategory.cloudStorage => 'Cloud storage',
        ProviderIconCategory.ai => 'AI',
        ProviderIconCategory.developer => 'Developer',
        ProviderIconCategory.creative => 'Creative',
        ProviderIconCategory.payment => 'Payment',
      };
}

/// Sprint 117.22 — Provider Icon & Brand Validation report.
///
/// The step requires every visible provider to use a certified official asset
/// or an approved fallback, with seven evidence items. This class proves the
/// registry carries all seven per provider. It deliberately does NOT grant
/// approval: [reviewStatus] stays `UNVERIFIED` because a brand licence is
/// confirmed by the provider or a human reviewer, never by the app.
class ProviderIconBrandValidationEntry {
  ProviderIconBrandValidationEntry({
    required this.providerId,
    required this.displayName,
    required this.category,
    required this.assetSource,
    required this.permission,
    required this.assetVersion,
    required this.themeVariants,
    required this.clearSpace,
    required this.fallback,
    required this.accessibleName,
    required this.reviewStatus,
    required this.isOfficialAsset,
  });

  final String providerId;
  final String displayName;
  final String category;
  final String assetSource;
  final ProviderIconPermission permission;
  final String assetVersion;
  final List<String> themeVariants;
  final String clearSpace;
  final String fallback;
  final String accessibleName;

  /// Never `APPROVED` from code. See [ProviderIconBrandValidation.report].
  final String reviewStatus;
  final bool isOfficialAsset;

  /// All seven required evidence items are present and non-empty.
  bool get hasCompleteEvidence =>
      assetSource.isNotEmpty &&
      permission.wireName.isNotEmpty &&
      assetVersion.isNotEmpty &&
      themeVariants.isNotEmpty &&
      clearSpace.isNotEmpty &&
      fallback.isNotEmpty &&
      accessibleName.isNotEmpty;
}

class ProviderIconBrandValidationReport {
  ProviderIconBrandValidationReport({
    required this.entries,
    required this.invalidEntries,
  });

  final List<ProviderIconBrandValidationEntry> entries;
  final List<String> invalidEntries;

  String get externalGates => ProviderIconBrandValidation.externalGates;

  bool get isPass => invalidEntries.isEmpty && entries.isNotEmpty;
}

abstract final class ProviderIconBrandValidation {
  static const String canonicalStep = '117.22';
  static const String title = 'Provider Icon & Brand Validation';

  /// The exact `required_evidence` list of canonical step 117.22.
  static const List<String> requiredEvidence = <String>[
    'asset_source',
    'permission',
    'asset_version',
    'theme_variants',
    'clear_space',
    'fallback',
    'accessible_name',
  ];

  /// Brand/licence approval is confirmed outside the application.
  static const String externalGates = 'DEFERRED-EXTERNAL';

  static const String canonicalSprintSha256 =
      'b7ef2d350916951c52c5b444a01c51d4d1fd254e2569399b4b8b1f21820894d6';
}

class ProviderIconBrandValidationRunner {
  ProviderIconBrandValidationRunner([ProviderIconRegistry? registry])
    : _registry = registry ?? ProviderIconRegistry.standard;

  final ProviderIconRegistry _registry;

  ProviderIconBrandValidationReport call() => evaluate();

  ProviderIconBrandValidationReport evaluate() {
    final entries = <ProviderIconBrandValidationEntry>[];
    final invalid = <String>[];

    for (final entry in _registry.all) {
      final id = entry.providerId;
      final bundled = entry.hasBundledAsset;

      // evidence: asset_source
      final source = entry.assetSource ?? '';
      if (source.isEmpty) invalid.add('asset_source:$id');

      // evidence: permission. A bundled third-party mark must never self-report
      // as approved, so UNVERIFIED is the correct value, not an error.
      final permission = entry.permission;

      // evidence: asset_version, pinned to content when a file is bundled.
      final version = entry.assetVersion.trim();
      if (version.isEmpty) invalid.add('asset_version:$id');
      if (bundled && entry.assetDigest == null) {
        invalid.add('asset_digest:$id');
      }

      // evidence: theme_variants
      final themes = entry.themeVariants;
      if (themes.isEmpty) invalid.add('theme_variants:$id');
      if (bundled && entry.assetDark == null) {
        invalid.add('theme_variant_dark:$id');
      }
      if (bundled && entry.intrinsicSize == null) {
        invalid.add('intrinsic_size:$id');
      }

      // evidence: clear_space, a ratio when bundled and an explicit "not
      // applicable" for generic glyphs instead of a silent empty string.
      final clearSpace = entry.clearSpaceRatio == null
          ? 'not_applicable_generic_glyph'
          : entry.clearSpaceRatio!.toStringAsFixed(4);
      if (entry.clearSpaceRatio != null &&
          (entry.clearSpaceRatio! <= 0 || entry.clearSpaceRatio! > 1)) {
        invalid.add('clear_space:$id');
      }

      // evidence: fallback
      final fallback = entry.monochromeFallback.category;
      if (fallback.isEmpty) invalid.add('fallback:$id');

      // evidence: accessible_name
      final accessibleName = entry.accessibleName.trim();
      if (accessibleName.isEmpty) invalid.add('accessible_name:$id');
      if (!bundled && !accessibleName.endsWith('icon unavailable')) {
        // A generic glyph must announce that the mark is absent.
        invalid.add('accessible_name_honesty:$id');
      }

      entries.add(
        ProviderIconBrandValidationEntry(
          providerId: id,
          displayName: entry.displayName,
          category: entry.category.wireName,
          assetSource: source,
          permission: permission,
          assetVersion: version,
          themeVariants: themes,
          clearSpace: clearSpace,
          fallback: fallback,
          accessibleName: accessibleName,
          // Classification only. Licence approval is an external gate.
          reviewStatus: bundled ? 'UNVERIFIED' : 'NOT_REQUIRED_GENERIC',
          isOfficialAsset: bundled,
        ),
      );
    }

    return ProviderIconBrandValidationReport(
      entries: List.unmodifiable(entries),
      invalidEntries: List.unmodifiable(invalid),
    );
  }
}

const _aiTech = 'assets/brands/ai_tech';
const _apps = 'assets/brands/apps';
const _designTools = 'assets/brands/design_tools';
const _fileFormats = 'assets/brands/file_formats';
const _paymentMethods = 'assets/brands/payment_methods';
const _tech = 'assets/brands/tech';

final List<ProviderIconEntry> _standardEntries = <ProviderIconEntry>[
  _entry('email', 'Email', ProviderIconCategory.identity, 'generic'),
  _entry('google', 'Google', ProviderIconCategory.identity, 'generic'),
  _entry('microsoft', 'Microsoft', ProviderIconCategory.identity, 'generic'),
  _entry('apple', 'Apple', ProviderIconCategory.identity, 'generic'),
  _entry(
    'github',
    'GitHub',
    ProviderIconCategory.developer,
    '$_aiTech/github_0.webp',
    intrinsicSize: ProviderIconIntrinsicSize(768, 768),
    assetDigest:
        'e6179ab0cd4207bde5cc6dccfa3c2f5bc0f8838a0d8355974037da76fb001935',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry('discord', 'Discord', ProviderIconCategory.identity, 'generic'),
  _entry('x', 'X', ProviderIconCategory.identity, 'generic'),
  _entry('facebook', 'Facebook', ProviderIconCategory.identity, 'generic'),
  _entry(
    'google_drive',
    'Google Drive',
    ProviderIconCategory.cloudStorage,
    '$_fileFormats/google_drive_0.webp',
    intrinsicSize: ProviderIconIntrinsicSize(768, 768),
    assetDigest:
        'beb7adb52efbcb4eef0ac10466ef0e90f7ab33038aefb916ec37c00d15381479',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry('onedrive', 'OneDrive', ProviderIconCategory.cloudStorage, 'generic'),
  _entry(
    'dropbox',
    'Dropbox',
    ProviderIconCategory.cloudStorage,
    '$_fileFormats/dropbox_0.webp',
    intrinsicSize: ProviderIconIntrinsicSize(768, 768),
    assetDigest:
        '89bc620ad30be08d69990920b73e06b97953f28872c4f138eab96f903db10590',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry('mega', 'Mega', ProviderIconCategory.cloudStorage, 'generic'),
  _entry(
    'local_storage',
    'Local storage',
    ProviderIconCategory.cloudStorage,
    'generic',
  ),
  _entry(
    'openai',
    'OpenAI',
    ProviderIconCategory.ai,
    '$_aiTech/openai.svg',
    intrinsicSize: ProviderIconIntrinsicSize(1180, 320),
    assetDigest:
        '5a28b637ffcde9e25fcac5790b7ac24fbaa3fd591f955062ec2c6021618e400a',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry(
    'gemini',
    'Gemini',
    ProviderIconCategory.ai,
    '$_aiTech/google_gemini.svg',
    intrinsicSize: ProviderIconIntrinsicSize(288, 65),
    assetDigest:
        '61dc0083657d5620d6bff22f11cdc9d99d96bd5fc7d1200405f025f343da982a',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry(
    'anthropic',
    'Anthropic',
    ProviderIconCategory.ai,
    '$_aiTech/anthropic.svg',
    intrinsicSize: ProviderIconIntrinsicSize(1024.2, 115),
    assetDigest:
        'c89653a9edd5cb712368cde82196cd50914fb9e28a77cb5723a7f71a60ac5fc0',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry('flux', 'Flux', ProviderIconCategory.ai, 'generic'),
  _entry('openrouter', 'OpenRouter', ProviderIconCategory.ai, 'generic'),
  _entry('local_ai', 'Local AI', ProviderIconCategory.ai, 'generic'),
  _entry(
    'gitlab',
    'GitLab',
    ProviderIconCategory.developer,
    '$_tech/gitlab.svg',
    intrinsicSize: ProviderIconIntrinsicSize(24, 24),
    assetDigest:
        '3bbfcd2707b9cd5bc6d68d561da605c520a707ceaecf3912aede560bb0990e27',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry(
    'bitbucket',
    'Bitbucket',
    ProviderIconCategory.developer,
    '$_tech/bitbucket.svg',
    intrinsicSize: ProviderIconIntrinsicSize(24, 24),
    assetDigest:
        'cbefef6f884299fdded5aedcde3c6fa3164702a24ecdfe11549374b03eaaddb0',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry(
    'azure_devops',
    'Azure DevOps',
    ProviderIconCategory.developer,
    'generic',
  ),
  _entry(
    'figma',
    'Figma',
    ProviderIconCategory.creative,
    '$_designTools/figma.svg',
    intrinsicSize: ProviderIconIntrinsicSize(24, 24),
    assetDigest:
        'b9171110637bb953781a04044d9957478ae84f6a7ac597a25c0bfdfb3292a45e',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry(
    'adobe',
    'Adobe',
    ProviderIconCategory.creative,
    '$_designTools/adobeillustrator.svg',
    intrinsicSize: ProviderIconIntrinsicSize(250, 250),
    assetDigest:
        'ab1872dea99df849b65ba14ec8761723e62b2d017515276b22b2572f717ad915',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry(
    'canva',
    'Canva',
    ProviderIconCategory.creative,
    '$_apps/canva.svg',
    intrinsicSize: ProviderIconIntrinsicSize(80, 30),
    assetDigest:
        '5e48f562e0092f87465bba3c3b54f3334a5c2dc442c16c0639c1a95951a79622',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry(
    'blender_cloud',
    'Blender Cloud',
    ProviderIconCategory.creative,
    'generic',
  ),
  _entry('sketchfab', 'Sketchfab', ProviderIconCategory.creative, 'generic'),
  _entry(
    'paypal',
    'PayPal',
    ProviderIconCategory.payment,
    '$_paymentMethods/paypal.svg',
    intrinsicSize: ProviderIconIntrinsicSize(24, 24),
    assetDigest:
        'fcca30a1996602ba4afb550174e2f3a44273194191a9476f16133c76f9028319',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry(
    'stripe',
    'Stripe',
    ProviderIconCategory.payment,
    '$_paymentMethods/stripe.svg',
    intrinsicSize: ProviderIconIntrinsicSize(24, 24),
    assetDigest:
        '7576775bf9915b696bbb9162268f5c56147d2b4221a76ac6a9ca92835239b7e9',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: true,
  ),
  _entry(
    'midtrans',
    'Midtrans',
    ProviderIconCategory.payment,
    '$_paymentMethods/midtrans_0.webp',
    intrinsicSize: ProviderIconIntrinsicSize(768, 768),
    assetDigest:
        '6ac42238f9ab597c8b8bcc0455dc15e40c525f7947ae9229b1ef2d50eb7ebb17',
    clearSpaceRatio: 0.25,
    supportsDarkSurface: false,
  ),
  _entry('saweria', 'Saweria', ProviderIconCategory.payment, 'generic'),
  _entry('kofi', 'Ko-fi', ProviderIconCategory.payment, 'generic'),
];

ProviderIconEntry _entry(
  String id,
  String displayName,
  ProviderIconCategory category,
  String asset, {
  String? assetDark,
  ProviderIconIntrinsicSize? intrinsicSize,
  String? assetDigest,
  double? clearSpaceRatio,
  bool supportsDarkSurface = true,
}) {
  final path = asset == 'generic' ? null : asset;
  final dark = assetDark ?? path;
  final bundled = path != null;
  return ProviderIconEntry(
    providerId: id,
    displayName: displayName,
    category: category,
    assetLight: path,
    assetDark: dark,
    monochromeFallback: ProviderIconFallback.forCategory(category),
    trademarkNotice:
        'Bundled mark is used only as an official provider asset; connector availability is not implied.',
    // Sprint 117.22: `asset_version` now pins content via the digest, so a
    // swapped or recoloured file is detectable instead of certifying itself.
    assetVersion: assetDigest == null
        ? (bundled ? 'bundled-v1' : 'generic-v1')
        : 'bundled-sha256-${assetDigest.substring(0, 12)}',
    // `asset_source` names the concrete file; one shared sentence reused for
    // every mark proved nothing about which asset was certified.
    assetSource: bundled
        ? 'bundled repo asset $path'
        : 'generic ${category.wireName} glyph; no provider mark bundled',
    // Fail closed: shipping a mark in-repo is not a licence grant.
    permission: bundled
        ? ProviderIconPermission.unverified
        : ProviderIconPermission.genericFallback,
    intrinsicSize: intrinsicSize,
    assetDigest: assetDigest,
    clearSpaceRatio: clearSpaceRatio,
    supportsDarkSurface: supportsDarkSurface,
  );
}
