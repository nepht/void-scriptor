import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_manifest_schema.dart';

Map<String, dynamic> _record({
  Map<String, dynamic>? manifest,
  int schemaVersion = 1,
  Object? extraKey,
}) {
  final record = <String, dynamic>{
    'canonical_step': '119.4',
    'schema_version': schemaVersion,
    'title': 'Manifest Schema v1',
    'unknown_field_policy': 'REJECT',
    'forbidden_fields': Sprint119ManifestContract.forbiddenFields,
    'external_gates': 'DEFERRED-EXTERNAL',
    'manifest': manifest ?? _manifest(),
  };
  if (extraKey != null) record['unexpected'] = extraKey;
  return record;
}

Map<String, dynamic> _manifest({
  List<Object?>? capabilities,
  List<Object?>? permissions,
  Map<String, dynamic>? auth,
}) {
  return <String, dynamic>{
    'identity': <String, dynamic>{
      'connector_id': 'voidscriptor.local',
      'name': 'Void Scriptor Local Connector',
      'version': '1.0.0',
    },
    'publisher': <String, dynamic>{
      'publisher_id': 'voidscriptor',
      'name': 'Void Scriptor Studio',
      'support_owner': 'connector_support_owner',
    },
    'capabilities':
        capabilities ??
        <Object?>[
          <String, dynamic>{
            'capability_id': 'health',
            'description': 'Read local connector health.',
          },
        ],
    'permissions':
        permissions ??
        <Object?>[
          <String, dynamic>{
            'permission_id': 'health.read',
            'capability_id': 'health',
            'decision': 'DENY',
          },
        ],
    'network': <String, dynamic>{
      'default_decision': 'DENY',
      'destinations': <Object?>[
        <String, dynamic>{'host': 'api.example.test', 'protocol': 'https'},
      ],
    },
    'auth':
        auth ??
        <String, dynamic>{
          'methods': <Object?>['oauth_oidc'],
          'secret_mode': 'opaque_reference',
        },
    'icon': <String, dynamic>{
      'source': 'assets/connectors/voidscriptor.svg',
      'accessible_name': 'Void Scriptor connector',
    },
    'locales': <Object?>[
      <String, dynamic>{'locale': 'en', 'label': 'Void Scriptor'},
    ],
    'support': <String, dynamic>{
      'owner_id': 'connector_support_owner',
      'contact': 'local_support',
    },
  };
}

void main() {
  group('119.4 Manifest Schema v1', () {
    test('declares the canonical sections and fail-closed vocabulary', () {
      expect(Sprint119ManifestContract.canonicalStep, '119.4');
      expect(Sprint119ManifestContract.title, 'Manifest Schema v1');
      expect(Sprint119ManifestContract.requiredSections, <String>[
        'identity',
        'publisher',
        'capabilities',
        'permissions',
        'network',
        'auth',
        'icon',
        'locales',
        'support',
      ]);
      expect(Sprint119ManifestContract.unknownFieldPolicy, 'REJECT');
      expect(
        Sprint119ManifestContract.forbiddenFields,
        containsAll(<String>['password', 'token', 'client_secret']),
      );
    });

    test('canonical manifest passes validation', () {
      final report = const Sprint119ManifestValidator().evaluate();
      expect(report.state, Sprint119ManifestState.pass);
      expect(report.verdict, 'MANIFEST_SCHEMA_COMPLETE_LOCAL');
      expect(report.diagnostics, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('emitted manifest records the typed sections and claim boundary', () {
      final file = File(Sprint119ManifestContract.manifestPath);
      expect(file.existsSync(), isTrue);
      final record =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(record['canonical_step'], '119.4');
      expect(record['schema_version'], 1);
      expect(record['unknown_field_policy'], 'REJECT');
      expect(record['manifest'], isA<Map<String, dynamic>>());
      for (final section in Sprint119ManifestContract.requiredSections) {
        expect(
          (record['manifest'] as Map<String, dynamic>)[section],
          isNotNull,
        );
      }
      expect(record['claim_boundary'], isA<List<dynamic>>());
    });

    test('unknown top-level fields are rejected with a path diagnostic', () {
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(extraKey: true),
      );
      expect(report.state, Sprint119ManifestState.fail);
      expect(report.diagnostics, contains('unknown_field:unexpected'));
    });

    test('forbidden credential fields are rejected recursively', () {
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(
          manifest: _manifest(
            auth: <String, dynamic>{
              'methods': <Object?>['oauth_oidc'],
              'secret_mode': 'opaque_reference',
              'client_secret': '[REDACTED]',
            },
          ),
        ),
      );
      expect(report.state, Sprint119ManifestState.fail);
      expect(
        report.diagnostics,
        contains('forbidden_field:manifest.auth.client_secret'),
      );
    });

    test('unsupported schema versions block validation', () {
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(schemaVersion: 2),
      );
      expect(report.state, Sprint119ManifestState.blocked);
      expect(report.verdict, 'MANIFEST_SCHEMA_VERSION_UNSUPPORTED');
    });

    test('missing typed section blocks validation', () {
      final invalid = _manifest()..remove('network');
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(manifest: invalid),
      );
      expect(report.state, Sprint119ManifestState.blocked);
      expect(report.diagnostics, contains('missing_section:network'));
    });

    test('duplicate capability IDs fail validation', () {
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(
          manifest: _manifest(
            capabilities: <Object?>[
              <String, dynamic>{
                'capability_id': 'health',
                'description': 'first',
              },
              <String, dynamic>{
                'capability_id': 'health',
                'description': 'second',
              },
            ],
          ),
        ),
      );
      expect(report.state, Sprint119ManifestState.fail);
      expect(report.diagnostics, contains('duplicate_capability_id:health'));
    });

    test('network and permission defaults remain deny-by-default', () {
      final manifest = _manifest();
      (manifest['network'] as Map<String, dynamic>)['default_decision'] =
          'ALLOW';
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(manifest: manifest),
      );
      expect(report.state, Sprint119ManifestState.fail);
      expect(report.diagnostics, contains('network_default_not_deny'));
    });

    test('typed loader never exposes plaintext secret values', () {
      final report = const Sprint119ManifestValidator().evaluateRecord(
        _record(
          manifest: _manifest(
            auth: <String, dynamic>{
              'methods': <Object?>['api_key_reference'],
              'secret_mode': 'opaque_reference',
            },
          ),
        ),
      );
      expect(report.state, Sprint119ManifestState.pass);
      expect(report.manifest, isNotNull);
      expect(report.manifest!.auth.secretMode, 'opaque_reference');
    });
  });
}
