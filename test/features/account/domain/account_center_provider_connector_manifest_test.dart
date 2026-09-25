import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('115.9 Provider & Connector Manifest acceptance contract', () {
    test('required fields are pinned to the canonical sprint step', () {
      final sprint = File(ProviderConnectorManifest.canonicalSprintPath);
      expect(sprint.existsSync(), isTrue);
      final json =
          jsonDecode(sprint.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.9');

      expect(step['title'], 'Provider & Connector Manifest');
      expect(step['required_fields'], ProviderConnectorManifest.requiredFields);
      expect(
        ProviderConnectorManifest.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );
    });

    test('manifest registry is the one seam for icon provider metadata', () {
      expect(
        ProviderConnectorManifest.standard.manifestIds,
        ProviderIconRegistry.standard.all
            .map((entry) => entry.providerId)
            .toList(growable: false),
      );
      expect(
        ProviderConnectorManifest.standard.require('openai').icon.providerId,
        'openai',
      );
    });
  });

  group('ProviderConnectorManifest lookup and policy', () {
    test('looks up providers by normalized provider_id', () {
      final entry = ProviderConnectorManifest.standard.require(' OpenAI ');
      expect(entry.providerId, 'openai');
      expect(entry.displayName, 'OpenAI');
      expect(entry.category, ProviderConnectorCategory.ai);
      expect(entry.capabilities, contains(ProviderConnectorCapability.aiText));
      expect(entry.availability, ProviderConnectorAvailability.unverified);
      expect(entry.regions, contains(ProviderRegion.global));
      expect(entry.connectorVersion, 'manifest-v1');
      expect(entry.authType, ProviderAuthType.apiKey);
      expect(entry.permissions, isNotEmpty);
      expect(entry.healthEndpoint, ProviderHealthEndpoint.unverified);
    });

    test('does not infer availability from bundled provider icons', () {
      for (final entry in ProviderConnectorManifest.standard.all) {
        expect(entry.availability, ProviderConnectorAvailability.unverified);
        expect(entry.healthEndpoint, ProviderHealthEndpoint.unverified);
        expect(entry.isConnectable, isFalse);
      }
    });

    test('unknown providers fail closed without inventing connector data', () {
      expect(
        ProviderConnectorManifest.standard.get('missing-provider'),
        isNull,
      );
      expect(
        () => ProviderConnectorManifest.standard.require('missing-provider'),
        throwsStateError,
      );
    });

    test('duplicate and malformed entries are rejected', () {
      final fixture = ProviderConnectorEntry.fixture('duplicate');
      expect(
        () => ProviderConnectorManifest([fixture, fixture]),
        throwsArgumentError,
      );
      expect(
        () => ProviderConnectorEntry.fixture(
          'empty-capability-region',
          capabilities: const <ProviderConnectorCapability>{},
          regions: const <ProviderRegion>{},
        ),
        throwsArgumentError,
      );
      expect(
        () => ProviderHealthEndpoint.parse('not a uri'),
        throwsArgumentError,
      );
    });
  });

  group('ProviderConnectorEntry field contracts', () {
    test('category, capabilities, regions, version, auth, and permissions', () {
      final entry = ProviderConnectorEntry(
        providerId: 'fixture-cloud',
        displayName: 'Fixture Cloud',
        category: ProviderConnectorCategory.cloudStorage,
        capabilities: const {
          ProviderConnectorCapability.storage,
          ProviderConnectorCapability.health,
        },
        availability: ProviderConnectorAvailability.planned,
        regions: const {ProviderRegion.global},
        connectorVersion: '1.2.3',
        authType: ProviderAuthType.oauth2Pkce,
        permissions: const {ProviderPermission.accountMetadata},
        healthEndpoint: Uri.parse('https://status.example.test/health'),
      );

      expect(entry.capabilities, isNotEmpty);
      expect(entry.regions, isNotEmpty);
      expect(entry.connectorVersion, isNot(contains(' ')));
      expect(entry.authType, isNotNull);
      expect(entry.permissions, contains(ProviderPermission.accountMetadata));
      expect(entry.healthEndpoint, isNotNull);
    });

    test('availability stays explicit and is never inferred from a URL', () {
      final endpoint = Uri.parse('https://status.example.test/health');
      final unverified = ProviderConnectorEntry.fixture(
        'unverified',
        healthEndpoint: endpoint,
      );
      final planned = ProviderConnectorEntry.fixture(
        'planned',
        availability: ProviderConnectorAvailability.planned,
        healthEndpoint: endpoint,
      );

      expect(unverified.availability, ProviderConnectorAvailability.unverified);
      expect(unverified.isConnectable, isFalse);
      expect(planned.availability, ProviderConnectorAvailability.planned);
      expect(planned.isConnectable, isFalse);
      expect(unverified.healthEndpoint, planned.healthEndpoint);
    });

    test(
      'permissions default to explicit scopes and workspace access stays denied',
      () {
        final entry = ProviderConnectorEntry(
          providerId: 'fixture',
          displayName: 'Fixture',
          category: ProviderConnectorCategory.identity,
          capabilities: const {
            ProviderConnectorCapability.identity,
            ProviderConnectorCapability.health,
          },
          availability: ProviderConnectorAvailability.unverified,
          regions: const {ProviderRegion.global},
          connectorVersion: '1',
          authType: ProviderAuthType.oauth2Pkce,
          permissions: const {ProviderPermission.providerConnection},
        );

        expect(
          entry.permissions,
          contains(ProviderPermission.providerConnection),
        );
        expect(
          entry.permissions,
          isNot(contains(ProviderPermission.novelWorkspace)),
        );
        expect(
          entry.permissions,
          isNot(contains(ProviderPermission.characterWorkspace)),
        );
      },
    );

    test('every registry entry maps to a canonical icon category', () {
      for (final entry in ProviderConnectorManifest.standard.all) {
        final icon = entry.icon;
        expect(icon.providerId, entry.providerId);
        expect(icon.category, _iconCategory(entry.category));
      }
    });
  });

  group('ProviderConnectorManifest JSON contract', () {
    test(
      'durable manifest provenance matches the standard runtime contract',
      () {
        final manifestFile = File(
          'docs/planning/v1.2/sprint_115_provider_connector_manifest.json',
        );
        expect(manifestFile.existsSync(), isTrue);
        final manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        final requiredFields = (manifest['required_fields'] as List<dynamic>)
            .cast<String>();
        final standardManifest =
            manifest['standard_manifest'] as Map<String, dynamic>;

        expect(manifest['canonical_step'], '115.9');
        expect(
          requiredFields,
          containsAll(ProviderConnectorManifest.requiredFields),
        );
        expect(requiredFields.last, 'health_endpoint');
        expect(
          standardManifest['entry_count'],
          ProviderConnectorManifest.standard.all.length,
        );
        expect(standardManifest['availability'], 'UNVERIFIED');
        expect(standardManifest['connectable'], isFalse);
        expect(standardManifest['health_endpoint'], isNull);
      },
    );

    test('durable manifest round-trips and preserves explicit metadata', () {
      final manifest = ProviderConnectorManifest.standard;
      final encoded = jsonEncode(manifest.toJson());
      final decoded = ProviderConnectorManifest.fromJsonString(encoded);

      expect(decoded.manifestIds, manifest.manifestIds);
      expect(
        decoded.require('local_storage').availability,
        ProviderConnectorAvailability.unverified,
      );
      expect(
        decoded.require('local_storage').healthEndpoint,
        ProviderHealthEndpoint.unverified,
      );
      expect(
        decoded.require('local_storage').permissions,
        contains(ProviderPermission.accountMetadata),
      );
    });

    test('manifests with missing required fields fail closed', () {
      final payload = <String, Object?>{
        'schema_version': 1,
        'entries': [
          <String, Object?>{
            'provider_id': 'missing-fields',
            'display_name': 'Missing fields',
          },
        ],
      };
      expect(
        () => ProviderConnectorManifest.fromJsonString(jsonEncode(payload)),
        throwsArgumentError,
      );
    });
  });
}

ProviderIconCategory _iconCategory(ProviderConnectorCategory category) =>
    switch (category) {
      ProviderConnectorCategory.identity => ProviderIconCategory.identity,
      ProviderConnectorCategory.cloudStorage =>
        ProviderIconCategory.cloudStorage,
      ProviderConnectorCategory.ai => ProviderIconCategory.ai,
      ProviderConnectorCategory.developer => ProviderIconCategory.developer,
      ProviderConnectorCategory.creative => ProviderIconCategory.creative,
      ProviderConnectorCategory.payment => ProviderIconCategory.payment,
    };
