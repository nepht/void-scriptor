import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_typed_settings_schema.dart';

/// Builds a well-formed schema covering every canonical feature.
ConnectorSettingsSchema schema({
  String version = '2.0.0',
  List<ConnectorSettingDefinition>? definitions,
}) {
  return ConnectorSettingsSchema(
    version: version,
    definitions:
        definitions ??
        <ConnectorSettingDefinition>[
          const ConnectorSettingDefinition(
            key: 'enabled',
            type: SettingType.boolean,
            defaultRaw: 'false',
          ),
          const ConnectorSettingDefinition(
            key: 'region',
            type: SettingType.selection,
            allowedValues: <String>['eu', 'us', 'apac'],
            required: true,
          ),
          const ConnectorSettingDefinition(
            key: 'timeout',
            type: SettingType.duration,
            defaultRaw: '30s',
          ),
          const ConnectorSettingDefinition(
            key: 'endpoint',
            type: SettingType.url,
          ),
          const ConnectorSettingDefinition(
            key: 'retries',
            type: SettingType.integer,
            minLength: null,
            maxLength: null,
          ),
          const ConnectorSettingDefinition(
            key: 'label',
            type: SettingType.text,
            minLength: 2,
            maxLength: 32,
          ),
          const ConnectorSettingDefinition(
            key: 'api_handle',
            type: SettingType.secret,
          ),
          const ConnectorSettingDefinition(
            key: 'mirror_endpoint',
            type: SettingType.url,
            dependsOnKey: 'enabled',
            dependsOnValues: <String>['true'],
          ),
          const ConnectorSettingDefinition(
            key: 'mirror_label',
            type: SettingType.text,
            visibleWhenKey: 'enabled',
            visibleWhenValues: <String>['true'],
          ),
          const ConnectorSettingDefinition(
            key: 'theme',
            type: SettingType.selection,
            allowedValues: <String>['light', 'dark'],
            renamedFrom: 'appearance',
          ),
        ],
  );
}

void main() {
  group('119.21 typed settings schema contract', () {
    test('declares the seven canonical features in canonical order', () {
      expect(TypedSettingsSchemaContract.canonicalStep, '119.21');
      expect(TypedSettingsSchemaContract.requiredFeatures, <String>[
        'typed_values',
        'validation',
        'defaults',
        'secret_refs',
        'dependencies',
        'conditional_visibility',
        'migration',
      ]);
      expect(TypedSettingsSchemaContract.requiredMethods, isEmpty);
    });

    test('canonical manifest satisfies the contract', () {
      expect(TypedSettingsSchemaContract.validateCanonicalManifest(), isEmpty);
    });

    test('manifest missing a feature is refused', () {
      final manifest = <String, dynamic>{
        'canonical_step': '119.21',
        'unknown_field_policy': 'REJECT',
        'required_features': <String, dynamic>{
          'typed_values': <String, dynamic>{},
          'validation': <String, dynamic>{},
          'defaults': <String, dynamic>{},
          'secret_refs': <String, dynamic>{},
          'dependencies': <String, dynamic>{},
          'conditional_visibility': <String, dynamic>{},
        },
      };
      expect(TypedSettingsSchemaContract.validateManifest(manifest), <String>[
        'feature_missing:migration',
      ]);
    });

    test('a value of the wrong type is refused, not coerced', () {
      final diagnostics = schema().validate(<String, String>{
        'region': 'eu',
        'retries': 'many',
        'enabled': 'yes',
        'timeout': '30',
      });

      expect(diagnostics, contains('type_mismatch:retries'));
      expect(diagnostics, contains('type_mismatch:enabled'));
      expect(diagnostics, contains('type_mismatch:timeout'));
    });

    test('typed values of the right shape are accepted', () {
      final diagnostics = schema().validate(<String, String>{
        'region': 'apac',
        'retries': '3',
        'enabled': 'true',
        'timeout': '15m',
        'endpoint': 'https://api.alpha.example/v1',
      });

      expect(diagnostics, isEmpty);
    });

    test('a selection value outside the closed set is refused', () {
      final diagnostics = schema().validate(<String, String>{
        'region': 'antarctica',
      });

      expect(diagnostics, contains('value_not_allowed:region'));
    });

    test('a non-tls url is refused and a non-url is a type mismatch', () {
      final diagnostics = schema().validate(<String, String>{
        'region': 'eu',
        'endpoint': 'http://api.alpha.example/v1',
        'mirror_endpoint': 'api.alpha.example',
      });

      expect(diagnostics, contains('url_not_tls:endpoint'));
      expect(diagnostics, contains('type_mismatch:mirror_endpoint'));
    });

    test('text bounds and markup are refused', () {
      final diagnostics = schema().validate(<String, String>{
        'region': 'eu',
        'label': '<b>hi</b>',
      });

      expect(diagnostics, contains('value_not_plain:label'));
      expect(
        schema().validate(<String, String>{'region': 'eu', 'label': 'x'}),
        contains('value_too_short:label'),
      );
      expect(
        schema().validate(<String, String>{
          'region': 'eu',
          'label': List<String>.filled(40, 'a').join(),
        }),
        contains('value_too_long:label'),
      );
    });

    test('a literal secret is refused outright and a handle is accepted', () {
      expect(
        TypedSettingsSchemaContract.looksLikeSecret('sk_live_9f2c7a41b8de'),
        isTrue,
      );
      expect(
        TypedSettingsSchemaContract.looksLikeSecret(
          List<String>.filled(64, 'a').join(),
        ),
        isTrue,
      );
      expect(
        TypedSettingsSchemaContract.looksLikeSecret(
          'secretref:vault:alpha-api',
        ),
        isFalse,
      );

      expect(
        schema().validate(<String, String>{
          'region': 'eu',
          'api_handle': 'sk_live_9f2c7a41b8de',
        }),
        contains('secret_literal_refused:api_handle'),
      );
      expect(
        schema().validate(<String, String>{
          'region': 'eu',
          'api_handle': 'alpha-api',
        }),
        contains('secret_ref_invalid:api_handle'),
      );
      expect(
        schema().validate(<String, String>{
          'region': 'eu',
          'api_handle': 'secretref:vault:alpha-api',
        }),
        isEmpty,
      );
    });

    test(
      'a secret value is never rendered and a secret default is forbidden',
      () {
        const value = ConnectorSettingValue(
          type: SettingType.secret,
          raw: 'secretref:vault:alpha-api',
        );
        expect(value.toJson()['value'], '[REDACTED]');
        expect(value.toString(), isNot(contains('secretref:vault:alpha-api')));
        expect(
          TypedSettingsSchemaContract.redact(
            'failed secretref:vault:alpha-api',
          ),
          'failed [REDACTED]',
        );

        final withSecretDefault = schema(
          definitions: const <ConnectorSettingDefinition>[
            ConnectorSettingDefinition(
              key: 'api_handle',
              type: SettingType.secret,
              defaultRaw: 'secretref:vault:alpha-api',
            ),
          ],
        );
        expect(
          withSecretDefault.schemaDiagnostics(),
          contains('schema_secret_default_forbidden:api_handle'),
        );
        expect(
          withSecretDefault.validate(<String, String>{}),
          contains('schema_secret_default_forbidden:api_handle'),
        );
      },
    );

    test('defaults are applied and an invalid default breaks the schema', () {
      final resolved = schema().effectiveValues(<String, String>{
        'region': 'eu',
      });
      expect(resolved['enabled'], 'false');
      expect(resolved['timeout'], '30s');
      expect(resolved['region'], 'eu');

      final withBadDefault = schema(
        definitions: const <ConnectorSettingDefinition>[
          ConnectorSettingDefinition(
            key: 'retries',
            type: SettingType.integer,
            defaultRaw: 'many',
          ),
        ],
      );
      expect(
        withBadDefault.schemaDiagnostics(),
        contains('schema_default_invalid:retries'),
      );
      expect(withBadDefault.validate(<String, String>{}), isNotEmpty);
    });

    test(
      'unknown keys are rejected and missing required keys are reported',
      () {
        final diagnostics = schema().validate(<String, String>{
          'region': 'eu',
          'api_token': 'x',
        });

        expect(diagnostics, contains('unknown_setting:api_token'));
        expect(
          schema().validate(<String, String>{}),
          contains('missing_required:region'),
        );
      },
    );

    test('an unmet dependency is refused and a met one is accepted', () {
      expect(
        schema().validate(<String, String>{
          'region': 'eu',
          'enabled': 'false',
          'mirror_endpoint': 'https://mirror.alpha.example',
        }),
        contains('dependency_unmet:mirror_endpoint'),
      );
      expect(
        schema().validate(<String, String>{
          'region': 'eu',
          'enabled': 'true',
          'mirror_endpoint': 'https://mirror.alpha.example',
        }),
        isEmpty,
      );
    });

    test(
      'a value set while hidden is refused and a cycle breaks the schema',
      () {
        expect(
          schema().validate(<String, String>{
            'region': 'eu',
            'enabled': 'false',
            'mirror_label': 'mirror',
          }),
          contains('set_while_hidden:mirror_label'),
        );

        final cyclic = schema(
          definitions: const <ConnectorSettingDefinition>[
            ConnectorSettingDefinition(
              key: 'a',
              type: SettingType.text,
              dependsOnKey: 'b',
              dependsOnValues: <String>['true'],
            ),
            ConnectorSettingDefinition(
              key: 'b',
              type: SettingType.text,
              dependsOnKey: 'a',
              dependsOnValues: <String>['true'],
            ),
          ],
        );
        expect(cyclic.schemaDiagnostics(), contains('schema_dependency_cycle'));

        final dangling = schema(
          definitions: const <ConnectorSettingDefinition>[
            ConnectorSettingDefinition(
              key: 'a',
              type: SettingType.text,
              dependsOnKey: 'missing',
            ),
          ],
        );
        expect(
          dangling.schemaDiagnostics(),
          contains('schema_dependency_unknown:a'),
        );
      },
    );

    test(
      'migration renames deterministically and refuses an unknown version',
      () {
        final result = schema().migrate(
          config: <String, String>{'appearance': 'dark', 'legacy': 'kept'},
          fromVersion: '1.0.0',
        );

        expect(result.refused, isFalse);
        expect(result.config['theme'], 'dark');
        expect(result.config.containsKey('appearance'), isFalse);
        expect(result.renamed, <String, String>{'appearance': 'theme'});
        expect(result.carriedUnknown, <String>['legacy']);
        expect(result.config['legacy'], 'kept');

        final refused = schema().migrate(
          config: <String, String>{'appearance': 'dark'},
          fromVersion: '0.9.0',
        );
        expect(refused.refused, isTrue);
        expect(
          refused.diagnostics,
          contains('migration_version_unknown:0.9.0'),
        );
        expect(refused.config, isEmpty);

        final noOp = schema().migrate(
          config: <String, String>{'region': 'eu'},
          fromVersion: '2.0.0',
        );
        expect(noOp.isNoOp, isTrue);
      },
    );
  });
}
