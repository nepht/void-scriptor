/// Typed, local-only manifest contract for roadmap step 119.4.
///
/// This contract validates declarations. It does not install, execute,
/// authenticate, certify, publish, or release a connector.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint119ManifestState { pass, fail, blocked }

class Sprint119ManifestIdentity {
  const Sprint119ManifestIdentity({
    required this.connectorId,
    required this.name,
    required this.version,
  });

  final String connectorId;
  final String name;
  final String version;
}

class Sprint119ManifestPublisher {
  const Sprint119ManifestPublisher({
    required this.publisherId,
    required this.name,
    required this.supportOwner,
  });

  final String publisherId;
  final String name;
  final String supportOwner;
}

class Sprint119ManifestCapability {
  const Sprint119ManifestCapability({
    required this.capabilityId,
    required this.description,
  });

  final String capabilityId;
  final String description;
}

class Sprint119ManifestPermission {
  const Sprint119ManifestPermission({
    required this.permissionId,
    required this.capabilityId,
    required this.decision,
  });

  final String permissionId;
  final String capabilityId;
  final String decision;
}

class Sprint119ManifestDestination {
  const Sprint119ManifestDestination({
    required this.host,
    required this.protocol,
  });

  final String host;
  final String protocol;
}

class Sprint119ManifestNetwork {
  const Sprint119ManifestNetwork({
    required this.defaultDecision,
    required this.destinations,
  });

  final String defaultDecision;
  final List<Sprint119ManifestDestination> destinations;
}

class Sprint119ManifestAuth {
  const Sprint119ManifestAuth({
    required this.methods,
    required this.secretMode,
  });

  final List<String> methods;
  final String secretMode;
}

class Sprint119ManifestIcon {
  const Sprint119ManifestIcon({
    required this.source,
    required this.accessibleName,
  });

  final String source;
  final String accessibleName;
}

class Sprint119ManifestLocale {
  const Sprint119ManifestLocale({required this.locale, required this.label});

  final String locale;
  final String label;
}

class Sprint119ManifestSupport {
  const Sprint119ManifestSupport({
    required this.ownerId,
    required this.contact,
  });

  final String ownerId;
  final String contact;
}

class Sprint119ConnectorManifest {
  const Sprint119ConnectorManifest({
    required this.identity,
    required this.publisher,
    required this.capabilities,
    required this.permissions,
    required this.network,
    required this.auth,
    required this.icon,
    required this.locales,
    required this.support,
  });

  final Sprint119ManifestIdentity identity;
  final Sprint119ManifestPublisher publisher;
  final List<Sprint119ManifestCapability> capabilities;
  final List<Sprint119ManifestPermission> permissions;
  final Sprint119ManifestNetwork network;
  final Sprint119ManifestAuth auth;
  final Sprint119ManifestIcon icon;
  final List<Sprint119ManifestLocale> locales;
  final Sprint119ManifestSupport support;
}

class Sprint119ManifestReport {
  const Sprint119ManifestReport({
    required this.state,
    required this.verdict,
    required this.externalGates,
    this.diagnostics = const <String>[],
    this.manifest,
  });

  final Sprint119ManifestState state;
  final String verdict;
  final String externalGates;
  final List<String> diagnostics;
  final Sprint119ConnectorManifest? manifest;
}

class Sprint119ManifestContract {
  const Sprint119ManifestContract._();

  static const String canonicalStep = '119.4';
  static const String title = 'Manifest Schema v1';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_manifest_schema.json';
  static const int supportedSchemaVersion = 1;
  static const String unknownFieldPolicy = 'REJECT';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  static const List<String> requiredSections = <String>[
    'identity',
    'publisher',
    'capabilities',
    'permissions',
    'network',
    'auth',
    'icon',
    'locales',
    'support',
  ];

  static const List<String> forbiddenFields = <String>[
    'password',
    'token',
    'api_key',
    'client_secret',
    'secret',
    'plaintext_secret',
    'private_key',
  ];
}

class Sprint119ManifestValidator {
  const Sprint119ManifestValidator();

  Sprint119ManifestReport evaluate() {
    final file = File(Sprint119ManifestContract.manifestPath);
    if (!file.existsSync()) {
      return _blocked(<String>['manifest_file_missing']);
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        return _blocked(<String>['manifest_root_not_object']);
      }
      return evaluateRecord(decoded);
    } on Object {
      return _blocked(<String>['manifest_json_unreadable']);
    }
  }

  Sprint119ManifestReport evaluateRecord(Map<String, dynamic> record) {
    final diagnostics = <String>[];
    _unknownKeys(
      record,
      const <String>{
        'canonical_step',
        'schema_version',
        'title',
        'unknown_field_policy',
        'forbidden_fields',
        'external_gates',
        'manifest',
        'claim_boundary',
      },
      '',
      diagnostics,
    );
    _scanForbidden(record, '', diagnostics);
    if (diagnostics.any((item) => item.startsWith('forbidden_field:'))) {
      return _fail(diagnostics);
    }
    if (record['schema_version'] !=
        Sprint119ManifestContract.supportedSchemaVersion) {
      return Sprint119ManifestReport(
        state: Sprint119ManifestState.blocked,
        verdict: 'MANIFEST_SCHEMA_VERSION_UNSUPPORTED',
        externalGates: Sprint119ManifestContract.externalGates,
        diagnostics: const <String>['manifest_schema_version_unsupported'],
      );
    }
    if (record['canonical_step'] != Sprint119ManifestContract.canonicalStep) {
      diagnostics.add('canonical_step_mismatch');
    }
    if (record['title'] != Sprint119ManifestContract.title) {
      diagnostics.add('title_mismatch');
    }
    if (record['unknown_field_policy'] !=
        Sprint119ManifestContract.unknownFieldPolicy) {
      diagnostics.add('unknown_field_policy_not_reject');
    }
    if (record['external_gates'] != Sprint119ManifestContract.externalGates) {
      diagnostics.add('external_gates_not_deferred');
    }
    final rawManifest = record['manifest'];
    if (rawManifest is! Map<String, dynamic>) {
      return _blocked(<String>['manifest_section_not_object']);
    }
    for (final section in Sprint119ManifestContract.requiredSections) {
      if (!rawManifest.containsKey(section)) {
        diagnostics.add('missing_section:$section');
      }
    }
    if (diagnostics.any((item) => item.startsWith('missing_section:'))) {
      return _blocked(diagnostics);
    }
    _unknownManifestKeys(rawManifest, diagnostics);
    if (diagnostics.any((item) => item.startsWith('unknown_field:'))) {
      return _fail(diagnostics);
    }

    final parsed = _parseManifest(rawManifest, diagnostics);
    if (parsed == null || diagnostics.isNotEmpty) {
      return _fail(diagnostics);
    }
    return Sprint119ManifestReport(
      state: Sprint119ManifestState.pass,
      verdict: 'MANIFEST_SCHEMA_COMPLETE_LOCAL',
      externalGates: Sprint119ManifestContract.externalGates,
      manifest: parsed,
    );
  }

  Sprint119ManifestReport _blocked(List<String> diagnostics) =>
      Sprint119ManifestReport(
        state: Sprint119ManifestState.blocked,
        verdict: 'MANIFEST_SCHEMA_BLOCKED',
        externalGates: Sprint119ManifestContract.externalGates,
        diagnostics: diagnostics,
      );

  Sprint119ManifestReport _fail(List<String> diagnostics) =>
      Sprint119ManifestReport(
        state: Sprint119ManifestState.fail,
        verdict: 'MANIFEST_SCHEMA_INVALID',
        externalGates: Sprint119ManifestContract.externalGates,
        diagnostics: diagnostics,
      );
}

void _unknownManifestKeys(
  Map<String, dynamic> manifest,
  List<String> diagnostics,
) {
  const allowed = <String>{
    'identity',
    'publisher',
    'capabilities',
    'permissions',
    'network',
    'auth',
    'icon',
    'locales',
    'support',
  };
  _unknownKeys(manifest, allowed, 'manifest', diagnostics);
  final maps = <String, Map<String, dynamic>>{};
  for (final section in <String>[
    'identity',
    'publisher',
    'network',
    'auth',
    'icon',
    'support',
  ]) {
    final value = manifest[section];
    if (value is Map<String, dynamic>) maps['manifest.$section'] = value;
  }
  for (final entry in maps.entries) {
    final allowedKeys = switch (entry.key) {
      'manifest.identity' => <String>{'connector_id', 'name', 'version'},
      'manifest.publisher' => <String>{'publisher_id', 'name', 'support_owner'},
      'manifest.network' => <String>{'default_decision', 'destinations'},
      'manifest.auth' => <String>{'methods', 'secret_mode'},
      'manifest.icon' => <String>{'source', 'accessible_name'},
      _ => <String>{'owner_id', 'contact'},
    };
    _unknownKeys(entry.value, allowedKeys, entry.key, diagnostics);
  }
  _validateListMaps(
    manifest['capabilities'],
    <String>{'capability_id', 'description'},
    'manifest.capabilities',
    diagnostics,
  );
  _validateListMaps(
    manifest['permissions'],
    <String>{'permission_id', 'capability_id', 'decision'},
    'manifest.permissions',
    diagnostics,
  );
  _validateListMaps(
    manifest['locales'],
    <String>{'locale', 'label'},
    'manifest.locales',
    diagnostics,
  );
  final destinations = manifest['network'] is Map<String, dynamic>
      ? (manifest['network'] as Map<String, dynamic>)['destinations']
      : null;
  _validateListMaps(
    destinations,
    <String>{'host', 'protocol'},
    'manifest.network.destinations',
    diagnostics,
  );
}

void _validateListMaps(
  Object? value,
  Set<String> allowed,
  String path,
  List<String> diagnostics,
) {
  if (value is! List<Object?>) return;
  for (var index = 0; index < value.length; index++) {
    final item = value[index];
    if (item is Map<String, dynamic>) {
      _unknownKeys(item, allowed, '$path[$index]', diagnostics);
    }
  }
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

void _scanForbidden(Object? value, String path, List<String> diagnostics) {
  if (value is Map<String, dynamic>) {
    for (final entry in value.entries) {
      final current = path.isEmpty ? entry.key : '$path.${entry.key}';
      if (Sprint119ManifestContract.forbiddenFields.contains(entry.key)) {
        diagnostics.add('forbidden_field:$current');
      }
      _scanForbidden(entry.value, current, diagnostics);
    }
  } else if (value is List<Object?>) {
    for (var index = 0; index < value.length; index++) {
      _scanForbidden(value[index], '$path[$index]', diagnostics);
    }
  }
}

Sprint119ConnectorManifest? _parseManifest(
  Map<String, dynamic> raw,
  List<String> diagnostics,
) {
  final identity = _map(raw['identity']);
  final publisher = _map(raw['publisher']);
  final network = _map(raw['network']);
  final auth = _map(raw['auth']);
  final icon = _map(raw['icon']);
  final support = _map(raw['support']);
  final capabilities = _listMaps(raw['capabilities']);
  final permissions = _listMaps(raw['permissions']);
  final locales = _listMaps(raw['locales']);
  final destinations = _listMaps(network?['destinations']);
  if ([identity, publisher, network, auth, icon, support].contains(null) ||
      capabilities == null ||
      permissions == null ||
      locales == null ||
      destinations == null) {
    diagnostics.add('typed_section_shape_invalid');
    return null;
  }
  final identityValue = Sprint119ManifestIdentity(
    connectorId: _required(identity, 'connector_id', 'identity', diagnostics),
    name: _required(identity, 'name', 'identity', diagnostics),
    version: _required(identity, 'version', 'identity', diagnostics),
  );
  final publisherValue = Sprint119ManifestPublisher(
    publisherId: _required(publisher, 'publisher_id', 'publisher', diagnostics),
    name: _required(publisher, 'name', 'publisher', diagnostics),
    supportOwner: _required(
      publisher,
      'support_owner',
      'publisher',
      diagnostics,
    ),
  );
  final capabilityValues = <Sprint119ManifestCapability>[];
  final capabilityIds = <String>{};
  for (final item in capabilities) {
    final id = _required(item, 'capability_id', 'capabilities', diagnostics);
    final description = _required(
      item,
      'description',
      'capabilities',
      diagnostics,
    );
    if (!capabilityIds.add(id)) diagnostics.add('duplicate_capability_id:$id');
    capabilityValues.add(
      Sprint119ManifestCapability(capabilityId: id, description: description),
    );
  }
  final permissionValues = <Sprint119ManifestPermission>[];
  final permissionIds = <String>{};
  for (final item in permissions) {
    final id = _required(item, 'permission_id', 'permissions', diagnostics);
    final capabilityId = _required(
      item,
      'capability_id',
      'permissions',
      diagnostics,
    );
    final decision = _required(item, 'decision', 'permissions', diagnostics);
    if (!permissionIds.add(id)) diagnostics.add('duplicate_permission_id:$id');
    if (!capabilityIds.contains(capabilityId)) {
      diagnostics.add('permission_capability_missing:$capabilityId');
    }
    permissionValues.add(
      Sprint119ManifestPermission(
        permissionId: id,
        capabilityId: capabilityId,
        decision: decision,
      ),
    );
  }
  final defaultDecision = _required(
    network,
    'default_decision',
    'network',
    diagnostics,
  );
  if (defaultDecision != 'DENY') diagnostics.add('network_default_not_deny');
  final destinationValues = <Sprint119ManifestDestination>[];
  for (final item in destinations) {
    destinationValues.add(
      Sprint119ManifestDestination(
        host: _required(item, 'host', 'network.destinations', diagnostics),
        protocol: _required(
          item,
          'protocol',
          'network.destinations',
          diagnostics,
        ),
      ),
    );
  }
  final methods = _stringList(auth?['methods'], 'auth.methods', diagnostics);
  final secretMode = _required(auth, 'secret_mode', 'auth', diagnostics);
  if (secretMode != 'opaque_reference') {
    diagnostics.add('auth_secret_mode_not_opaque');
  }
  final localeValues = <Sprint119ManifestLocale>[];
  for (final item in locales) {
    localeValues.add(
      Sprint119ManifestLocale(
        locale: _required(item, 'locale', 'locales', diagnostics),
        label: _required(item, 'label', 'locales', diagnostics),
      ),
    );
  }
  return Sprint119ConnectorManifest(
    identity: identityValue,
    publisher: publisherValue,
    capabilities: capabilityValues,
    permissions: permissionValues,
    network: Sprint119ManifestNetwork(
      defaultDecision: defaultDecision,
      destinations: destinationValues,
    ),
    auth: Sprint119ManifestAuth(methods: methods, secretMode: secretMode),
    icon: Sprint119ManifestIcon(
      source: _required(icon, 'source', 'icon', diagnostics),
      accessibleName: _required(icon, 'accessible_name', 'icon', diagnostics),
    ),
    locales: localeValues,
    support: Sprint119ManifestSupport(
      ownerId: _required(support, 'owner_id', 'support', diagnostics),
      contact: _required(support, 'contact', 'support', diagnostics),
    ),
  );
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map<String, dynamic> ? value : null;

List<Map<String, dynamic>>? _listMaps(Object? value) {
  if (value is! List<Object?>) return null;
  final result = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is! Map<String, dynamic>) return null;
    result.add(item);
  }
  return result;
}

String _required(
  Map<String, dynamic>? value,
  String key,
  String path,
  List<String> diagnostics,
) {
  final result = value?[key];
  if (result is! String || result.trim().isEmpty) {
    diagnostics.add('required_field_missing:$path.$key');
    return '';
  }
  return result;
}

List<String> _stringList(Object? value, String path, List<String> diagnostics) {
  if (value is! List<Object?> || value.isEmpty) {
    diagnostics.add('required_list_missing:$path');
    return const <String>[];
  }
  final result = <String>[];
  for (final item in value) {
    if (item is! String || item.trim().isEmpty) {
      diagnostics.add('required_list_value_missing:$path');
    } else {
      result.add(item);
    }
  }
  return result;
}
