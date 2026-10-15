import 'dart:convert';
import 'dart:io';

/// The types a connector setting may declare.
enum SettingType {
  /// Free-form plain text.
  text,

  /// A base-10 integer.
  integer,

  /// A finite decimal number.
  number,

  /// `true` or `false`.
  boolean,

  /// One of a declared closed set of values.
  selection,

  /// An opaque handle to a secret. Never the secret itself.
  secret,

  /// A duration such as `30s`, `15m`, `24h`, or `7d`.
  duration,

  /// An https endpoint.
  url,

  /// A type this build does not know. Always refused.
  unknown,
}

/// One raw setting value as it arrives from a form or the environment.
final class ConnectorSettingValue {
  const ConnectorSettingValue({required this.type, required this.raw});

  /// The declared type.
  final SettingType type;

  /// The raw text. A secret type carries an opaque handle, never a secret.
  final String raw;

  /// A projection that redacts a secret handle.
  Map<String, Object?> toJson() => <String, Object?>{
    'type': type.name,
    'value': type == SettingType.secret ? '[REDACTED]' : raw,
  };

  @override
  String toString() =>
      'ConnectorSettingValue(${type.name}, '
      '${type == SettingType.secret ? '[REDACTED]' : raw})';
}

/// One declared setting.
final class ConnectorSettingDefinition {
  const ConnectorSettingDefinition({
    required this.key,
    required this.type,
    this.required = false,
    this.defaultRaw,
    this.allowedValues = const <String>[],
    this.dependsOnKey,
    this.dependsOnValues = const <String>[],
    this.visibleWhenKey,
    this.visibleWhenValues = const <String>[],
    this.renamedFrom,
    this.minLength,
    this.maxLength,
  });

  /// The stable setting key.
  final String key;

  /// The declared type.
  final SettingType type;

  /// Whether the setting must be supplied.
  final bool required;

  /// The default applied when the setting is absent.
  final String? defaultRaw;

  /// The closed value set for [SettingType.selection].
  final List<String> allowedValues;

  /// A setting this one depends on.
  final String? dependsOnKey;

  /// The values of [dependsOnKey] under which this setting is valid.
  final List<String> dependsOnValues;

  /// A setting that controls whether this one is visible.
  final String? visibleWhenKey;

  /// The values of [visibleWhenKey] under which this setting is visible.
  final List<String> visibleWhenValues;

  /// The previous key this setting was renamed from.
  final String? renamedFrom;

  /// The shortest accepted text length.
  final int? minLength;

  /// The longest accepted text length.
  final int? maxLength;

  @override
  String toString() => 'ConnectorSettingDefinition($key, ${type.name})';
}

/// The deterministic outcome of a schema migration.
final class MigrationResult {
  const MigrationResult({
    required this.config,
    required this.renamed,
    required this.carriedUnknown,
    required this.diagnostics,
  });

  /// The migrated configuration.
  final Map<String, String> config;

  /// Old key to new key, for every rename that was applied.
  final Map<String, String> renamed;

  /// Keys this schema does not declare, carried through untouched.
  final List<String> carriedUnknown;

  /// The diagnostics that failed. A non-empty list means the migration was
  /// refused and [config] must not be applied.
  final List<String> diagnostics;

  /// Whether the migration was refused.
  bool get refused => diagnostics.isNotEmpty;

  /// Whether nothing had to change.
  bool get isNoOp =>
      renamed.isEmpty && carriedUnknown.isEmpty && diagnostics.isEmpty;

  @override
  String toString() =>
      'MigrationResult(refused: $refused, renamed: ${renamed.length})';
}

/// A typed settings schema for one connector.
///
/// The schema is fail-closed in both directions: a structurally broken schema
/// refuses every configuration, and an unknown key, a missing required value, a
/// type mismatch, an unmet dependency, or a value set while hidden is refused
/// rather than coerced.
final class ConnectorSettingsSchema {
  ConnectorSettingsSchema({
    required this.version,
    required List<ConnectorSettingDefinition> definitions,
  }) : definitions = List<ConnectorSettingDefinition>.unmodifiable(definitions);

  /// The schema version.
  final String version;

  /// The declared settings, in declaration order.
  final List<ConnectorSettingDefinition> definitions;

  static final RegExp _duration = RegExp(r'^\d+(s|m|h|d)$');

  /// Whether the schema itself is well formed.
  ///
  /// A schema that declares a secret default, an unknown dependency, a
  /// duplicate key, an invalid default, or a dependency cycle is refused.
  List<String> schemaDiagnostics() {
    final diagnostics = <String>[];
    final byKey = <String, ConnectorSettingDefinition>{};

    for (final definition in definitions) {
      if (byKey.containsKey(definition.key)) {
        diagnostics.add('schema_duplicate_key:${definition.key}');
      } else {
        byKey[definition.key] = definition;
      }

      if (definition.type == SettingType.unknown) {
        diagnostics.add('schema_type_unknown:${definition.key}');
      }

      if (definition.defaultRaw != null) {
        if (definition.type == SettingType.secret) {
          diagnostics.add('schema_secret_default_forbidden:${definition.key}');
        } else if (_validateRaw(
          definition,
          definition.defaultRaw!,
          const <String, String>{},
          checkRelations: false,
        ).isNotEmpty) {
          diagnostics.add('schema_default_invalid:${definition.key}');
        }
      }

      final dependsOn = definition.dependsOnKey;
      if (dependsOn != null && _definitionByKey(dependsOn) == null) {
        diagnostics.add('schema_dependency_unknown:${definition.key}');
      }

      final visibleWhen = definition.visibleWhenKey;
      if (visibleWhen != null && _definitionByKey(visibleWhen) == null) {
        diagnostics.add('schema_dependency_unknown:${definition.key}');
      }
    }

    if (_hasDependencyCycle()) {
      diagnostics.add('schema_dependency_cycle');
    }

    return diagnostics;
  }

  ConnectorSettingDefinition? _definitionByKey(String key) {
    for (final definition in definitions) {
      if (definition.key == key) {
        return definition;
      }
    }
    return null;
  }

  ConnectorSettingDefinition? _definitionRenamedFrom(String key) {
    for (final definition in definitions) {
      if (definition.renamedFrom == key) {
        return definition;
      }
    }
    return null;
  }

  /// Validates [config] against this schema.
  List<String> validate(Map<String, String> config) {
    final schemaDiagnostics = this.schemaDiagnostics();
    if (schemaDiagnostics.isNotEmpty) {
      return schemaDiagnostics;
    }

    final diagnostics = <String>[];
    final byKey = <String, ConnectorSettingDefinition>{
      for (final definition in definitions) definition.key: definition,
    };

    for (final key in config.keys) {
      if (!byKey.containsKey(key)) {
        diagnostics.add('unknown_setting:$key');
      }
    }

    final effective = effectiveValues(config);
    for (final definition in definitions) {
      if (!config.containsKey(definition.key)) {
        continue;
      }
      diagnostics.addAll(
        _validateRaw(
          definition,
          config[definition.key]!,
          effective,
          checkRelations: true,
        ),
      );
    }

    for (final definition in definitions) {
      if (definition.required &&
          !config.containsKey(definition.key) &&
          definition.defaultRaw == null) {
        diagnostics.add('missing_required:${definition.key}');
      }
    }

    return diagnostics;
  }

  /// The configuration with defaults applied. Only meaningful when [validate]
  /// returned an empty list.
  Map<String, String> effectiveValues(Map<String, String> config) {
    final effective = <String, String>{};
    for (final definition in definitions) {
      if (config.containsKey(definition.key)) {
        effective[definition.key] = config[definition.key]!;
      } else if (definition.defaultRaw != null) {
        effective[definition.key] = definition.defaultRaw!;
      }
    }
    return effective;
  }

  /// Migrates [config] from [fromVersion] to this schema's version.
  ///
  /// Only a declared previous version is accepted. Renames are applied and
  /// reported; keys this schema does not declare are carried through untouched
  /// and reported, never silently dropped.
  MigrationResult migrate({
    required Map<String, String> config,
    required String fromVersion,
  }) {
    if (fromVersion == version) {
      return MigrationResult(
        config: Map<String, String>.unmodifiable(config),
        renamed: const <String, String>{},
        carriedUnknown: const <String>[],
        diagnostics: const <String>[],
      );
    }

    final previous = <String>{'1.0.0', '2.0.0'};
    if (!previous.contains(fromVersion)) {
      return MigrationResult(
        config: const <String, String>{},
        renamed: const <String, String>{},
        carriedUnknown: const <String>[],
        diagnostics: <String>['migration_version_unknown:$fromVersion'],
      );
    }

    final migrated = <String, String>{};
    final renamed = <String, String>{};
    final byKey = <String, ConnectorSettingDefinition>{
      for (final definition in definitions) definition.key: definition,
    };

    config.forEach((String key, String value) {
      final target = byKey[key]?.key;
      if (target != null) {
        migrated[target] = value;
        return;
      }
      final renamedDefinition = _definitionRenamedFrom(key);
      if (renamedDefinition != null) {
        migrated[renamedDefinition.key] = value;
        renamed[key] = renamedDefinition.key;
        return;
      }
      migrated[key] = value;
    });

    final carriedUnknown =
        migrated.keys.where((String key) => !byKey.containsKey(key)).toList()
          ..sort();

    return MigrationResult(
      config: Map<String, String>.unmodifiable(migrated),
      renamed: Map<String, String>.unmodifiable(renamed),
      carriedUnknown: List<String>.unmodifiable(carriedUnknown),
      diagnostics: const <String>[],
    );
  }

  List<String> _validateRaw(
    ConnectorSettingDefinition definition,
    String raw,
    Map<String, String> effective, {
    required bool checkRelations,
  }) {
    final key = definition.key;
    final diagnostics = <String>[];

    switch (definition.type) {
      case SettingType.text:
        if (raw.isNotEmpty && !TypedSettingsSchemaContract.isPlainText(raw)) {
          diagnostics.add('value_not_plain:$key');
        }
        break;
      case SettingType.integer:
        if (int.tryParse(raw) == null) {
          diagnostics.add('type_mismatch:$key');
        }
        break;
      case SettingType.number:
        final parsed = double.tryParse(raw);
        if (parsed == null || !parsed.isFinite) {
          diagnostics.add('type_mismatch:$key');
        }
        break;
      case SettingType.boolean:
        if (raw != 'true' && raw != 'false') {
          diagnostics.add('type_mismatch:$key');
        }
        break;
      case SettingType.duration:
        if (!_duration.hasMatch(raw)) {
          diagnostics.add('type_mismatch:$key');
        }
        break;
      case SettingType.url:
        if (!raw.contains('://')) {
          diagnostics.add('type_mismatch:$key');
        } else if (!raw.startsWith('https://')) {
          diagnostics.add('url_not_tls:$key');
        }
        break;
      case SettingType.selection:
        if (!definition.allowedValues.contains(raw)) {
          diagnostics.add('value_not_allowed:$key');
        }
        break;
      case SettingType.secret:
        if (TypedSettingsSchemaContract.looksLikeSecret(raw)) {
          diagnostics.add('secret_literal_refused:$key');
        } else if (!TypedSettingsSchemaContract.isValidSecretRef(raw)) {
          diagnostics.add('secret_ref_invalid:$key');
        }
        break;
      case SettingType.unknown:
        diagnostics.add('type_unknown:$key');
        break;
    }

    final minLength = definition.minLength;
    if (minLength != null && raw.length < minLength) {
      diagnostics.add('value_too_short:$key');
    }
    final maxLength = definition.maxLength;
    if (maxLength != null && raw.length > maxLength) {
      diagnostics.add('value_too_long:$key');
    }

    if (!checkRelations) {
      return diagnostics;
    }

    final dependsOn = definition.dependsOnKey;
    if (dependsOn != null) {
      final dependencyValue = effective[dependsOn];
      if (dependencyValue == null ||
          !definition.dependsOnValues.contains(dependencyValue)) {
        diagnostics.add('dependency_unmet:$key');
      }
    }

    final visibleWhen = definition.visibleWhenKey;
    if (visibleWhen != null) {
      final visibilityValue = effective[visibleWhen];
      if (visibilityValue == null ||
          !definition.visibleWhenValues.contains(visibilityValue)) {
        diagnostics.add('set_while_hidden:$key');
      }
    }

    return diagnostics;
  }

  bool _hasDependencyCycle() {
    final edges = <String, List<String>>{};
    for (final definition in definitions) {
      final targets = <String>[];
      if (definition.dependsOnKey != null) {
        targets.add(definition.dependsOnKey!);
      }
      if (definition.visibleWhenKey != null) {
        targets.add(definition.visibleWhenKey!);
      }
      edges[definition.key] = targets;
    }

    final visiting = <String>{};
    final visited = <String>{};

    bool visit(String key) {
      if (visited.contains(key)) {
        return false;
      }
      if (visiting.contains(key)) {
        return true;
      }
      visiting.add(key);
      for (final target in edges[key] ?? const <String>[]) {
        if (visit(target)) {
          return true;
        }
      }
      visiting.remove(key);
      visited.add(key);
      return false;
    }

    for (final definition in definitions) {
      if (visit(definition.key)) {
        return true;
      }
    }
    return false;
  }
}

/// The local typed settings schema contract for roadmap step 119.21.
abstract final class TypedSettingsSchemaContract {
  /// The manifest describing this step.
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_typed_settings_schema.json';

  /// The canonical step identifier.
  static const String canonicalStep = '119.21';

  /// The seven canonical features, in canonical order.
  static const List<String> requiredFeatures = <String>[
    'typed_values',
    'validation',
    'defaults',
    'secret_refs',
    'dependencies',
    'conditional_visibility',
    'migration',
  ];

  /// This step declares no named methods.
  static const List<String> requiredMethods = <String>[];

  /// This step declares no acceptance map.
  static const List<String> requiredAcceptance = <String>[];

  static final RegExp _secretRef = RegExp(
    r'^secretref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _secretLike = RegExp(
    r'^(?:sk|pk|rk|whsec|xox[baprs])[-_][A-Za-z0-9_\-]{16,}$',
  );

  static final RegExp _longToken = RegExp(r'^[A-Za-z0-9+/=_\-]{32,}$');

  static final RegExp _unsafeText = RegExp(
    r'[<>&`\\{}]|\$|[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]',
  );

  static final RegExp _redactRef = RegExp(
    r'\b(?:secretref|iconref|provref|actionref|evtref|idemref|payref|chkref|'
    r'invref|modelref|assetref|orgref|resref|jobref|whsec|sk_live|pk_live)'
    r':[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}\b',
    caseSensitive: false,
  );

  /// Whether [value] is a well-formed opaque secret handle.
  static bool isValidSecretRef(String value) => _secretRef.hasMatch(value);

  /// Whether [value] looks like a literal secret rather than a handle.
  ///
  /// A recognized key prefix, or a long unbroken token, is treated as a secret
  /// and refused outright: a secret is never stored, returned, or logged.
  static bool looksLikeSecret(String value) {
    if (_secretLike.hasMatch(value)) {
      return true;
    }
    return _longToken.hasMatch(value) && !isValidSecretRef(value);
  }

  /// Whether [value] is plain text with no markup or interpolation.
  static bool isPlainText(String value) {
    if (_unsafeText.hasMatch(value)) {
      return false;
    }
    return !value.contains('://');
  }

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

    final features = manifest['required_features'];
    final declared = features is Map
        ? features.keys.map((Object? key) => '$key').toSet()
        : features is List
        ? features.map((Object? feature) => '$feature').toSet()
        : const <String>{};
    for (final required in requiredFeatures) {
      if (!declared.contains(required)) {
        diagnostics.add('feature_missing:$required');
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
}
