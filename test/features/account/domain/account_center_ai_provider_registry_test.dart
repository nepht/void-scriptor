import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_provider_registry.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
  group('AccountCenterAiProviderRegistry', () {
    test('manifest preserves every canonical 115.24 required field', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_ai_provider_registry.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.24');
      expect(manifest['required_fields'], <String>[
        'provider_id',
        'models',
        'modalities',
        'endpoint',
        'regions',
        'pricing_metadata',
        'privacy_metadata',
        'availability',
      ]);
    });

    test('registers immutable provider metadata with model capabilities', () {
      final entry = _entry();
      final registry = AccountCenterAiProviderRegistry([entry]);

      expect(registry.require(' OPENAI ').providerId, 'openai');
      expect(registry.require('openai').mode, AiProviderMode.cloud);
      expect(registry.require('openai').endpoint.host, 'api.example.test');
      expect(registry.require('openai').models.single.modelId, 'model-1');
      expect(registry.require('openai').models.single.modalities, {
        AiProviderModality.text,
        AiProviderModality.vision,
      });
      expect(() => registry.providers.add(entry), throwsUnsupportedError);
      expect(
        () => registry.require('openai').models.add(entry.models.single),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate providers and model ids', () {
      expect(
        () => AccountCenterAiProviderRegistry([_entry(), _entry()]),
        throwsArgumentError,
      );
      expect(
        () => AiProviderRegistryEntry(
          providerId: 'duplicate-models',
          models: [_model(), _model()],
          modalities: const {AiProviderModality.text},
          endpoint: Uri.parse('https://api.example.test/v1'),
          regions: const {ProviderRegion.global},
          pricingMetadata: AiPricingMetadata.unavailable(),
          privacyMetadata: _privacy(),
          mode: AiProviderMode.cloud,
          availability: ProviderConnectorAvailability.unverified,
        ),
        throwsArgumentError,
      );
    });

    test('requires provider modalities to cover every registered model', () {
      expect(
        () => AiProviderRegistryEntry(
          providerId: 'bad-capabilities',
          models: [_model()],
          modalities: const {AiProviderModality.text},
          endpoint: Uri.parse('https://api.example.test/v1'),
          regions: const {ProviderRegion.global},
          pricingMetadata: AiPricingMetadata.unavailable(),
          privacyMetadata: _privacy(),
          mode: AiProviderMode.cloud,
          availability: ProviderConnectorAvailability.unverified,
        ),
        throwsArgumentError,
      );
    });

    test('keeps unavailable pricing explicit instead of fabricating cost', () {
      final unavailable = AiPricingMetadata.unavailable();
      expect(unavailable.isAvailable, isFalse);
      expect(unavailable.currency, isNull);
      expect(unavailable.inputPerMillionUnits, isNull);
      expect(unavailable.outputPerMillionUnits, isNull);

      expect(
        () => AiPricingMetadata.available(
          currency: 'USD',
          inputPerMillionUnits: -1,
          outputPerMillionUnits: 2,
          measuredAt: DateTime.utc(2026, 9, 26),
        ),
        throwsArgumentError,
      );
    });

    test('requires explicit privacy handling and validates endpoints', () {
      expect(
        () => AiPrivacyMetadata(
          promptRetention: AiPromptRetention.unknown,
          trainingUse: AiTrainingUse.unknown,
          dataResidency: const {},
          policyReference: null,
        ),
        throwsArgumentError,
      );
      expect(
        () => AiProviderRegistryEntry(
          providerId: 'bad-endpoint',
          models: [_model()],
          modalities: const {
            AiProviderModality.text,
            AiProviderModality.vision,
          },
          endpoint: Uri.parse('file:///secret'),
          regions: const {ProviderRegion.global},
          pricingMetadata: AiPricingMetadata.unavailable(),
          privacyMetadata: _privacy(),
          mode: AiProviderMode.cloud,
          availability: ProviderConnectorAvailability.unverified,
        ),
        throwsArgumentError,
      );
    });

    test('availability must match the connector manifest', () {
      final manifest = ProviderConnectorManifest([
        ProviderConnectorEntry.fixture(
          'openai',
          category: ProviderConnectorCategory.ai,
          capabilities: const {ProviderConnectorCapability.aiText},
          availability: ProviderConnectorAvailability.unverified,
        ),
      ]);
      final registry = AccountCenterAiProviderRegistry([_entry()]);

      expect(registry.validateAvailabilityAgainst(manifest), isEmpty);

      final mismatch = AccountCenterAiProviderRegistry([
        _entry(availability: ProviderConnectorAvailability.available),
      ]);
      expect(mismatch.validateAvailabilityAgainst(manifest), ['openai']);
    });
  });
}

AiProviderRegistryEntry _entry({
  ProviderConnectorAvailability availability =
      ProviderConnectorAvailability.unverified,
}) => AiProviderRegistryEntry(
  providerId: ' OpenAI ',
  models: [_model()],
  modalities: const {AiProviderModality.text, AiProviderModality.vision},
  endpoint: Uri.parse('https://api.example.test/v1'),
  regions: const {ProviderRegion.global},
  pricingMetadata: AiPricingMetadata.unavailable(),
  privacyMetadata: _privacy(),
  mode: AiProviderMode.cloud,
  availability: availability,
);

AiProviderModel _model() => AiProviderModel(
  modelId: ' model-1 ',
  displayName: ' Model One ',
  modalities: const {AiProviderModality.text, AiProviderModality.vision},
);

AiPrivacyMetadata _privacy() => AiPrivacyMetadata(
  promptRetention: AiPromptRetention.providerPolicy,
  trainingUse: AiTrainingUse.optOutAvailable,
  dataResidency: const {ProviderRegion.global},
  policyReference: Uri.parse('https://example.test/privacy'),
);
