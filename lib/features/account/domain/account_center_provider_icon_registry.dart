/// Canonical provider-icon registry contract for Sprint 115.8.
///
/// The registry is deliberately data-only: it does not assert that a
/// connector is configured or available. Connector availability belongs to
/// the provider manifest (115.9). When a mark is not bundled or cannot be
/// used under its brand rules, [ProviderIconRegistry.resolve] returns a
/// generic category fallback rather than silently drawing or recoloring it.
library;

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
  }) : providerId = _normalizeId(providerId),
       displayName = _normalizeDisplayName(displayName),
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
  }

  /// Test fixture constructor. Production callers should use [ProviderIconEntry].
  factory ProviderIconEntry.fixture(
    String providerId, {
    String? displayName,
    String? assetLight,
    String? assetDark,
    String? assetVersion,
    String? trademarkNotice,
  }) => ProviderIconEntry(
    providerId: providerId,
    displayName: displayName ?? providerId,
    category: ProviderIconCategory.developer,
    assetLight: assetLight,
    assetDark: assetDark,
    monochromeFallback: ProviderIconFallback.developer,
    trademarkNotice: trademarkNotice ?? 'Test fixture; not a production mark.',
    assetVersion: assetVersion ?? 'test-fixture-v1',
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

  bool get hasBundledAsset => assetLight != null || assetDark != null;
  bool get isOfficialAsset => hasBundledAsset;
  bool get isKnownProvider => true;
  bool get usesGenericFallback => !isOfficialAsset;

  String get accessibleName => usesGenericFallback
      ? '$displayName icon unavailable'
      : '$displayName icon';

  double widthForHeight(double height) => _positiveDimension(height);
  double heightForWidth(double width) => _positiveDimension(width);

  ProviderIconEntry genericForCategory() => ProviderIconEntry(
    providerId: providerId,
    displayName: displayName,
    category: category,
    monochromeFallback: monochromeFallback,
    trademarkNotice: trademarkNotice,
    assetVersion: assetVersion,
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

  static String _normalizeDisplayName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'displayName',
        'Provider icon entries require a non-empty display name.',
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
      );
    }
    return entry.hasBundledAsset ? entry : entry.genericForCategory();
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
  ),
  _entry('discord', 'Discord', ProviderIconCategory.identity, 'generic'),
  _entry('x', 'X', ProviderIconCategory.identity, 'generic'),
  _entry('facebook', 'Facebook', ProviderIconCategory.identity, 'generic'),
  _entry(
    'google_drive',
    'Google Drive',
    ProviderIconCategory.cloudStorage,
    '$_fileFormats/google_drive_0.webp',
  ),
  _entry('onedrive', 'OneDrive', ProviderIconCategory.cloudStorage, 'generic'),
  _entry(
    'dropbox',
    'Dropbox',
    ProviderIconCategory.cloudStorage,
    '$_fileFormats/dropbox_0.webp',
  ),
  _entry('mega', 'Mega', ProviderIconCategory.cloudStorage, 'generic'),
  _entry(
    'local_storage',
    'Local storage',
    ProviderIconCategory.cloudStorage,
    'generic',
  ),
  _entry('openai', 'OpenAI', ProviderIconCategory.ai, '$_aiTech/openai.svg'),
  _entry(
    'gemini',
    'Gemini',
    ProviderIconCategory.ai,
    '$_aiTech/google_gemini.svg',
  ),
  _entry(
    'anthropic',
    'Anthropic',
    ProviderIconCategory.ai,
    '$_aiTech/anthropic.svg',
  ),
  _entry('flux', 'Flux', ProviderIconCategory.ai, 'generic'),
  _entry('openrouter', 'OpenRouter', ProviderIconCategory.ai, 'generic'),
  _entry('local_ai', 'Local AI', ProviderIconCategory.ai, 'generic'),
  _entry(
    'gitlab',
    'GitLab',
    ProviderIconCategory.developer,
    '$_tech/gitlab.svg',
  ),
  _entry(
    'bitbucket',
    'Bitbucket',
    ProviderIconCategory.developer,
    '$_tech/bitbucket.svg',
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
  ),
  _entry(
    'adobe',
    'Adobe',
    ProviderIconCategory.creative,
    '$_designTools/adobeillustrator.svg',
  ),
  _entry('canva', 'Canva', ProviderIconCategory.creative, '$_apps/canva.svg'),
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
  ),
  _entry(
    'stripe',
    'Stripe',
    ProviderIconCategory.payment,
    '$_paymentMethods/stripe.svg',
  ),
  _entry(
    'midtrans',
    'Midtrans',
    ProviderIconCategory.payment,
    '$_paymentMethods/midtrans_0.webp',
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
}) {
  final path = asset == 'generic' ? null : asset;
  final dark = assetDark ?? path;
  return ProviderIconEntry(
    providerId: id,
    displayName: displayName,
    category: category,
    assetLight: path,
    assetDark: dark,
    monochromeFallback: ProviderIconFallback.forCategory(category),
    trademarkNotice:
        'Bundled mark is used only as an official provider asset; connector availability is not implied.',
    assetVersion: 'bundled-v1',
  );
}
