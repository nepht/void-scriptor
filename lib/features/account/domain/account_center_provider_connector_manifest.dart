/// Canonical provider and connector manifest contract for Sprint 115.9.
///
/// The manifest is metadata-only. A provider icon or a planned endpoint never
/// implies that a connector is certified, reachable, or available in a region.
/// Live availability, quota, connector execution, and health state stay
/// unverified until separately certified (connector SDK spec).
library;

import 'dart:convert';

import 'account_center_localization_formatting.dart';
import 'account_center_provider_icon_registry.dart';

enum ProviderConnectorCategory {
  identity('identity'),
  cloudStorage('cloud_storage'),
  ai('ai'),
  developer('developer'),
  creative('creative'),
  payment('payment');

  const ProviderConnectorCategory(this.wireName);

  final String wireName;
}

enum ProviderConnectorCapability {
  identity('identity'),
  storage('storage'),
  sync('sync'),
  backup('backup'),
  aiText('ai_text'),
  aiImage('ai_image'),
  aiAudio('ai_audio'),
  aiVideo('ai_video'),
  developer('developer'),
  creative('creative'),
  payment('payment'),
  health('health');

  const ProviderConnectorCapability(this.wireName);

  final String wireName;
}

enum ProviderConnectorAvailability {
  unverified('UNVERIFIED'),
  planned('PLANNED'),
  available('AVAILABLE'),
  unavailable('UNAVAILABLE'),
  unsupportedRegion('UNSUPPORTED_REGION'),
  degraded('DEGRADED'),
  outage('OUTAGE');

  const ProviderConnectorAvailability(this.wireName);

  final String wireName;
}

enum ProviderRegion {
  global('GLOBAL'),
  indonesia('ID'),
  southeastAsia('SEA'),
  europe('EU'),
  northAmerica('NA');

  const ProviderRegion(this.wireName);

  final String wireName;
}

enum ProviderAuthType {
  oauth2Pkce('OAUTH2_PKCE'),
  apiKey('API_KEY'),
  oidc('OIDC'),
  deviceCode('DEVICE_CODE'),
  localBroker('LOCAL_BROKER'),
  none('NONE');

  const ProviderAuthType(this.wireName);

  final String wireName;
}

enum ProviderPermission {
  accountMetadata('account_metadata'),
  providerConnection('provider_connection'),
  usageMetadata('usage_metadata'),
  cloudTransfer('cloud_transfer'),
  backup('backup'),
  billing('billing'),
  novelWorkspace('novel_workspace'),
  characterWorkspace('character_workspace'),

  /// Repository and developer-project access for developer connectors.
  ///
  /// This is metadata only: the standard manifest remains UNVERIFIED and
  /// non-connectable until a connector-specific certification grants access.
  developerRepository('developer_repository');

  const ProviderPermission(this.wireName);

  final String wireName;
}

abstract final class ProviderHealthEndpoint {
  static final Uri unverified = Uri();

  static Uri parse(Object? value) {
    if (value == null) return unverified;
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError.value(value, 'health_endpoint', 'Expected URI text.');
    }
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null ||
        !parsed.hasScheme ||
        (parsed.scheme != 'https' && parsed.scheme != 'http') ||
        parsed.host.isEmpty) {
      throw ArgumentError.value(
        value,
        'health_endpoint',
        'Expected HTTP(S) URI.',
      );
    }
    return parsed;
  }

  static String? encode(Uri value) =>
      value == unverified ? null : value.toString();
}

class ProviderConnectorEntry {
  ProviderConnectorEntry({
    required String providerId,
    required String displayName,
    required this.category,
    required Iterable<ProviderConnectorCapability> capabilities,
    required this.availability,
    required Iterable<ProviderRegion> regions,
    required String connectorVersion,
    required this.authType,
    required Iterable<ProviderPermission> permissions,
    Uri? healthEndpoint,
  }) : providerId = _normalizeProviderId(providerId),
       displayName = AccountCenterLocalizationFormatting.providerDisplayName(
         displayName,
       ),
       capabilities = Set.unmodifiable(capabilities),
       regions = Set.unmodifiable(regions),
       connectorVersion = connectorVersion.trim(),
       permissions = Set.unmodifiable(permissions),
       healthEndpoint = healthEndpoint ?? ProviderHealthEndpoint.unverified {
    if (this.capabilities.isEmpty) {
      throw ArgumentError.value(
        capabilities,
        'capabilities',
        'Provider connector entries require at least one capability.',
      );
    }
    if (this.regions.isEmpty) {
      throw ArgumentError.value(
        regions,
        'regions',
        'Provider connector entries require at least one region.',
      );
    }
    if (this.connectorVersion.isEmpty) {
      throw ArgumentError.value(
        connectorVersion,
        'connectorVersion',
        'Provider connector entries require a non-empty version.',
      );
    }
    if (this.permissions.isEmpty) {
      throw ArgumentError.value(
        permissions,
        'permissions',
        'Provider connector entries require at least one explicit permission.',
      );
    }
  }

  factory ProviderConnectorEntry.fixture(
    String providerId, {
    String? displayName,
    ProviderConnectorCategory category = ProviderConnectorCategory.identity,
    Iterable<ProviderConnectorCapability>? capabilities,
    ProviderConnectorAvailability availability =
        ProviderConnectorAvailability.unverified,
    Iterable<ProviderRegion>? regions,
    String? connectorVersion,
    ProviderAuthType authType = ProviderAuthType.localBroker,
    Iterable<ProviderPermission>? permissions,
    Uri? healthEndpoint,
  }) => ProviderConnectorEntry(
    providerId: providerId,
    displayName: displayName ?? providerId,
    category: category,
    capabilities: capabilities ?? const {ProviderConnectorCapability.health},
    availability: availability,
    regions: regions ?? const {ProviderRegion.global},
    connectorVersion: connectorVersion ?? 'fixture-v1',
    authType: authType,
    permissions: permissions ?? const {ProviderPermission.accountMetadata},
    healthEndpoint: healthEndpoint,
  );

  factory ProviderConnectorEntry.fromJson(Map<String, Object?> json) {
    final providerId = _requiredString(json, 'provider_id');
    final displayName = _requiredString(json, 'display_name');
    final category = _requiredEnumByWireName(
      ProviderConnectorCategory.values,
      json['category'],
      'category',
    );
    final capabilities = _requiredEnumSet<ProviderConnectorCapability>(
      ProviderConnectorCapability.values,
      json['capabilities'],
      'capabilities',
    );
    final availability = _requiredEnumByWireName(
      ProviderConnectorAvailability.values,
      json['availability'],
      'availability',
    );
    final regions = _requiredEnumSet<ProviderRegion>(
      ProviderRegion.values,
      json['regions'],
      'regions',
    );
    final connectorVersion = _requiredString(json, 'connector_version');
    final authType = _requiredEnumByWireName(
      ProviderAuthType.values,
      json['auth_type'],
      'auth_type',
    );
    final permissions = _requiredEnumSet<ProviderPermission>(
      ProviderPermission.values,
      json['permissions'],
      'permissions',
    );
    return ProviderConnectorEntry(
      providerId: providerId,
      displayName: displayName,
      category: category,
      capabilities: capabilities,
      availability: availability,
      regions: regions,
      connectorVersion: connectorVersion,
      authType: authType,
      permissions: permissions,
      healthEndpoint: ProviderHealthEndpoint.parse(json['health_endpoint']),
    );
  }

  final String providerId;
  final String displayName;
  final ProviderConnectorCategory category;
  final Set<ProviderConnectorCapability> capabilities;
  final ProviderConnectorAvailability availability;
  final Set<ProviderRegion> regions;
  final String connectorVersion;
  final ProviderAuthType authType;
  final Set<ProviderPermission> permissions;
  final Uri healthEndpoint;

  /// Only explicit live certification can expose a connect action. A URL,
  /// bundled icon, or planned declaration is insufficient.
  bool get isConnectable =>
      availability == ProviderConnectorAvailability.available;

  ProviderIconEntry get icon =>
      ProviderIconRegistry.standard.require(providerId);

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'display_name': displayName,
    'category': category.wireName,
    'capabilities':
        capabilities.map((value) => value.wireName).toList(growable: false)
          ..sort(),
    'availability': availability.wireName,
    'regions': regions.map((value) => value.wireName).toList(growable: false)
      ..sort(),
    'connector_version': connectorVersion,
    'auth_type': authType.wireName,
    'permissions':
        permissions.map((value) => value.wireName).toList(growable: false)
          ..sort(),
    'health_endpoint': ProviderHealthEndpoint.encode(healthEndpoint),
  };

  static String _normalizeProviderId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'providerId',
        'Provider connector entries require a non-empty provider id.',
      );
    }
    return normalized;
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw ArgumentError.value(value, key, 'Required non-empty string.');
    }
    return value;
  }

  static T _requiredEnumByWireName<T extends Enum>(
    List<T> values,
    Object? wireName,
    String field,
  ) {
    if (wireName is! String) {
      throw ArgumentError.value(wireName, field, 'Expected enum wire name.');
    }
    for (final value in values) {
      if ((value as dynamic).wireName == wireName) return value;
    }
    throw ArgumentError.value(wireName, field, 'Unknown enum wire name.');
  }
}

class ProviderConnectorManifest {
  ProviderConnectorManifest(Iterable<ProviderConnectorEntry> entries) {
    for (final entry in entries) {
      if (_entries.containsKey(entry.providerId)) {
        throw ArgumentError.value(
          entry.providerId,
          'entries',
          'Provider connector ids must be unique.',
        );
      }
      _entries[entry.providerId] = entry;
    }
  }

  static const requiredFields = <String>[
    'provider_id',
    'category',
    'capabilities',
    'availability',
    'regions',
    'connector_version',
    'auth_type',
    'permissions',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  static final ProviderConnectorManifest standard = ProviderConnectorManifest(
    ProviderIconRegistry.standard.all.map((icon) => _entryForIcon(icon)),
  );

  final Map<String, ProviderConnectorEntry> _entries =
      <String, ProviderConnectorEntry>{};

  List<String> get manifestIds => _entries.keys.toList(growable: false);

  List<ProviderConnectorEntry> get all =>
      List<ProviderConnectorEntry>.unmodifiable(_entries.values);

  ProviderConnectorEntry? get(String providerId) =>
      _entries[ProviderConnectorEntry._normalizeProviderId(providerId)];

  ProviderConnectorEntry require(String providerId) {
    final entry = get(providerId);
    if (entry == null) {
      throw StateError(
        'Provider connector "$providerId" is not registered in the manifest.',
      );
    }
    return entry;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schema_version': 1,
    'entries': all.map((entry) => entry.toJson()).toList(growable: false),
  };

  factory ProviderConnectorManifest.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Provider connector manifest must be an object.',
      );
    }
    final entries = decoded['entries'];
    if (entries is! List<dynamic>) {
      throw const FormatException(
        'Provider connector manifest entries must be a list.',
      );
    }
    return ProviderConnectorManifest(
      entries.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException(
            'Provider connector entry must be an object.',
          );
        }
        return ProviderConnectorEntry.fromJson(entry);
      }),
    );
  }
}

Set<T> _requiredEnumSet<T extends Enum>(
  List<T> values,
  Object? wireNames,
  String field,
) {
  if (wireNames is! List<dynamic> || wireNames.isEmpty) {
    throw ArgumentError.value(
      wireNames,
      field,
      'Expected a non-empty enum list.',
    );
  }
  return wireNames
      .map((wireName) => _requiredEnumByWireName<T>(values, wireName, field))
      .toSet();
}

T _requiredEnumByWireName<T extends Enum>(
  List<T> values,
  Object? wireName,
  String field,
) {
  if (wireName is! String) {
    throw ArgumentError.value(wireName, field, 'Expected enum wire name.');
  }
  for (final value in values) {
    if ((value as dynamic).wireName == wireName) return value;
  }
  throw ArgumentError.value(wireName, field, 'Unknown enum wire name.');
}

ProviderConnectorEntry _entryForIcon(ProviderIconEntry icon) {
  final category = switch (icon.category) {
    ProviderIconCategory.identity => ProviderConnectorCategory.identity,
    ProviderIconCategory.cloudStorage => ProviderConnectorCategory.cloudStorage,
    ProviderIconCategory.ai => ProviderConnectorCategory.ai,
    ProviderIconCategory.developer => ProviderConnectorCategory.developer,
    ProviderIconCategory.creative => ProviderConnectorCategory.creative,
    ProviderIconCategory.payment => ProviderConnectorCategory.payment,
  };
  final capabilities = <ProviderConnectorCapability>{
    switch (category) {
      ProviderConnectorCategory.identity =>
        ProviderConnectorCapability.identity,
      ProviderConnectorCategory.cloudStorage =>
        ProviderConnectorCapability.storage,
      ProviderConnectorCategory.ai => ProviderConnectorCapability.aiText,
      ProviderConnectorCategory.developer =>
        ProviderConnectorCapability.developer,
      ProviderConnectorCategory.creative =>
        ProviderConnectorCapability.creative,
      ProviderConnectorCategory.payment => ProviderConnectorCapability.payment,
    },
    ProviderConnectorCapability.health,
  };
  final authType = switch (category) {
    ProviderConnectorCategory.identity => ProviderAuthType.oauth2Pkce,
    ProviderConnectorCategory.cloudStorage => ProviderAuthType.oauth2Pkce,
    ProviderConnectorCategory.ai => ProviderAuthType.apiKey,
    ProviderConnectorCategory.developer => ProviderAuthType.oauth2Pkce,
    ProviderConnectorCategory.creative => ProviderAuthType.oauth2Pkce,
    ProviderConnectorCategory.payment => ProviderAuthType.oauth2Pkce,
  };
  final permissions = <ProviderPermission>{
    ProviderPermission.accountMetadata,
    ProviderPermission.providerConnection,
    switch (category) {
      ProviderConnectorCategory.identity => ProviderPermission.usageMetadata,
      ProviderConnectorCategory.cloudStorage =>
        ProviderPermission.cloudTransfer,
      ProviderConnectorCategory.ai => ProviderPermission.usageMetadata,
      ProviderConnectorCategory.developer => ProviderPermission.usageMetadata,
      ProviderConnectorCategory.creative => ProviderPermission.usageMetadata,
      ProviderConnectorCategory.payment => ProviderPermission.billing,
    },
  };
  if (category == ProviderConnectorCategory.developer) {
    permissions.add(ProviderPermission.developerRepository);
  }
  return ProviderConnectorEntry(
    providerId: icon.providerId,
    displayName: icon.displayName,
    category: category,
    capabilities: capabilities,
    availability: ProviderConnectorAvailability.unverified,
    regions: const {ProviderRegion.global},
    connectorVersion: 'manifest-v1',
    authType: authType,
    permissions: permissions,
  );
}
