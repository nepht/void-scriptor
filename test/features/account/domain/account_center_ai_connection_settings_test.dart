import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_connection_settings.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_provider_registry.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
  group('AccountCenterAiConnectionSettings', () {
    test('manifest preserves every canonical 115.25 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.25');
      expect(manifest['acceptance'], <String>[
        'connect',
        'model_select',
        'fallback',
        'timeout',
        'budget',
        'prefer_local',
        'health_test',
      ]);
    });

    test('connects only a manifest-backed available AI provider', () {
      final settings = AccountCenterAiConnectionSettings(
        registry: _registry(),
        connectorManifest: _manifest(),
      );

      final connection = settings.connect(' CLOUD ');

      expect(connection.providerId, 'cloud');
      expect(connection.status, AiConnectionStatus.configured);
      expect(connection.connectedAt, isNull);
      expect(() => settings.connect('local'), throwsStateError);
    });

    test('selects registered defaults and ordered unique fallback models', () {
      final settings = _settings();

      final value = settings.configure(
        providerId: 'cloud',
        defaultModelId: 'quality',
        fallbackModelIds: const ['fast'],
        timeout: const Duration(seconds: 45),
        budget: AiBudgetLimit.monthly(currency: 'usd', amount: 12.5),
        quality: AiQualityPreference.quality,
        preferLocal: true,
      );

      expect(value.defaultModelId, 'quality');
      expect(value.fallbackModelIds, ['fast']);
      expect(value.timeout, const Duration(seconds: 45));
      expect(value.budget.currency, 'USD');
      expect(value.budget.amount, 12.5);
      expect(value.quality, AiQualityPreference.quality);
      expect(value.preferLocal, isTrue);
      expect(
        () => value.fallbackModelIds.add('quality'),
        throwsUnsupportedError,
      );
    });

    test('rejects unknown, duplicate, and default fallback models', () {
      final settings = _settings();

      expect(
        () => settings.configure(
          providerId: 'cloud',
          defaultModelId: 'missing',
          timeout: const Duration(seconds: 30),
        ),
        throwsArgumentError,
      );
      expect(
        () => settings.configure(
          providerId: 'cloud',
          defaultModelId: 'quality',
          fallbackModelIds: const ['fast', 'fast'],
          timeout: const Duration(seconds: 30),
        ),
        throwsArgumentError,
      );
      expect(
        () => settings.configure(
          providerId: 'cloud',
          defaultModelId: 'quality',
          fallbackModelIds: const ['quality'],
          timeout: const Duration(seconds: 30),
        ),
        throwsArgumentError,
      );
    });

    test('requires positive timeout and explicit non-negative budget', () {
      final settings = _settings();

      expect(
        () => settings.configure(
          providerId: 'cloud',
          defaultModelId: 'quality',
          timeout: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => AiBudgetLimit.monthly(currency: 'USD', amount: -1),
        throwsArgumentError,
      );
      expect(AiBudgetLimit.unavailable().isAvailable, isFalse);
    });

    test(
      'health test is injected, timestamped, and never fabricates success',
      () async {
        final settings = _settings();
        final checkedAt = DateTime.utc(2026, 9, 26, 1, 2, 3);

        final healthy = await settings.testHealth(
          'cloud',
          tester: (_) async => const AiHealthObservation(
            status: AiConnectionHealth.healthy,
            latency: Duration(milliseconds: 80),
            modelCount: 2,
          ),
          now: () => checkedAt,
        );
        expect(healthy.status, AiConnectionHealth.healthy);
        expect(healthy.checkedAt, checkedAt);
        expect(healthy.modelCount, 2);

        final unavailable = await settings.testHealth(
          'cloud',
          tester: (_) async => throw StateError('secret upstream detail'),
          now: () => checkedAt,
        );
        expect(unavailable.status, AiConnectionHealth.unavailable);
        expect(unavailable.message, 'Provider health test failed.');
        expect(unavailable.message, isNot(contains('secret')));
      },
    );
  });
}

AccountCenterAiConnectionSettings _settings() =>
    AccountCenterAiConnectionSettings(
      registry: _registry(),
      connectorManifest: _manifest(),
    );

AccountCenterAiProviderRegistry _registry() => AccountCenterAiProviderRegistry([
  _entry(
    providerId: 'cloud',
    mode: AiProviderMode.cloud,
    availability: ProviderConnectorAvailability.available,
  ),
  _entry(
    providerId: 'local',
    mode: AiProviderMode.local,
    availability: ProviderConnectorAvailability.unverified,
  ),
]);

ProviderConnectorManifest _manifest() => ProviderConnectorManifest([
  ProviderConnectorEntry.fixture(
    'cloud',
    category: ProviderConnectorCategory.ai,
    capabilities: const {ProviderConnectorCapability.aiText},
    availability: ProviderConnectorAvailability.available,
  ),
  ProviderConnectorEntry.fixture(
    'local',
    category: ProviderConnectorCategory.ai,
    capabilities: const {ProviderConnectorCapability.aiText},
    availability: ProviderConnectorAvailability.unverified,
  ),
]);

AiProviderRegistryEntry _entry({
  required String providerId,
  required AiProviderMode mode,
  required ProviderConnectorAvailability availability,
}) => AiProviderRegistryEntry(
  providerId: providerId,
  models: [
    AiProviderModel(
      modelId: 'quality',
      displayName: 'Quality',
      modalities: const {AiProviderModality.text},
    ),
    AiProviderModel(
      modelId: 'fast',
      displayName: 'Fast',
      modalities: const {AiProviderModality.text},
    ),
  ],
  modalities: const {AiProviderModality.text},
  endpoint: Uri.parse(
    mode == AiProviderMode.local
        ? 'http://localhost:11434'
        : 'https://api.example.test/v1',
  ),
  regions: const {ProviderRegion.global},
  pricingMetadata: AiPricingMetadata.unavailable(),
  privacyMetadata: AiPrivacyMetadata(
    promptRetention: AiPromptRetention.providerPolicy,
    trainingUse: AiTrainingUse.providerPolicy,
    dataResidency: const {ProviderRegion.global},
    policyReference: Uri.parse('https://example.test/privacy'),
  ),
  mode: mode,
  availability: availability,
);
