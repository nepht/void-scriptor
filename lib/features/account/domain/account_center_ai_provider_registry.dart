/// Sprint 115.24 — AI Provider Registry.
///
/// Metadata-only Account Center contract. It describes models, modalities,
/// endpoint, region, pricing, privacy, execution mode, and manifest-backed
/// availability without probing a provider or storing credentials.
library;

import 'dart:collection';

import 'account_center_provider_connector_manifest.dart';

enum AiProviderModality { text, image, audio, video, vision }

enum AiProviderMode { local, cloud }

enum AiPromptRetention { none, providerPolicy, unknown }

enum AiTrainingUse { prohibited, optOutAvailable, providerPolicy, unknown }

final class AiProviderModel {
  AiProviderModel({
    required String modelId,
    required String displayName,
    required Iterable<AiProviderModality> modalities,
  }) : modelId = _required(modelId, 'modelId'),
       displayName = _required(displayName, 'displayName'),
       modalities = Set.unmodifiable(modalities) {
    if (this.modalities.isEmpty) {
      throw ArgumentError.value(modalities, 'modalities');
    }
  }

  final String modelId;
  final String displayName;
  final Set<AiProviderModality> modalities;
}

final class AiPricingMetadata {
  AiPricingMetadata._({
    required this.currency,
    required this.inputPerMillionUnits,
    required this.outputPerMillionUnits,
    required this.measuredAt,
  });

  factory AiPricingMetadata.unavailable() => AiPricingMetadata._(
    currency: null,
    inputPerMillionUnits: null,
    outputPerMillionUnits: null,
    measuredAt: null,
  );

  factory AiPricingMetadata.available({
    required String currency,
    required double inputPerMillionUnits,
    required double outputPerMillionUnits,
    required DateTime measuredAt,
  }) {
    if (!inputPerMillionUnits.isFinite || inputPerMillionUnits < 0) {
      throw ArgumentError.value(inputPerMillionUnits, 'inputPerMillionUnits');
    }
    if (!outputPerMillionUnits.isFinite || outputPerMillionUnits < 0) {
      throw ArgumentError.value(outputPerMillionUnits, 'outputPerMillionUnits');
    }
    return AiPricingMetadata._(
      currency: _required(currency, 'currency').toUpperCase(),
      inputPerMillionUnits: inputPerMillionUnits,
      outputPerMillionUnits: outputPerMillionUnits,
      measuredAt: measuredAt.toUtc(),
    );
  }

  final String? currency;
  final double? inputPerMillionUnits;
  final double? outputPerMillionUnits;
  final DateTime? measuredAt;

  bool get isAvailable => currency != null;
}

final class AiPrivacyMetadata {
  AiPrivacyMetadata({
    required this.promptRetention,
    required this.trainingUse,
    required Iterable<ProviderRegion> dataResidency,
    required this.policyReference,
  }) : dataResidency = Set.unmodifiable(dataResidency) {
    if (this.dataResidency.isEmpty) {
      throw ArgumentError.value(dataResidency, 'dataResidency');
    }
    if (promptRetention == AiPromptRetention.unknown &&
        trainingUse == AiTrainingUse.unknown &&
        policyReference == null) {
      throw ArgumentError(
        'Unknown privacy metadata requires an explicit policy reference.',
      );
    }
    if (policyReference != null &&
        (!_isHttpEndpoint(policyReference!) || policyReference!.host.isEmpty)) {
      throw ArgumentError.value(policyReference, 'policyReference');
    }
  }

  final AiPromptRetention promptRetention;
  final AiTrainingUse trainingUse;
  final Set<ProviderRegion> dataResidency;
  final Uri? policyReference;
}

final class AiProviderRegistryEntry {
  AiProviderRegistryEntry({
    required String providerId,
    required Iterable<AiProviderModel> models,
    required Iterable<AiProviderModality> modalities,
    required this.endpoint,
    required Iterable<ProviderRegion> regions,
    required this.pricingMetadata,
    required this.privacyMetadata,
    required this.mode,
    required this.availability,
  }) : providerId = _required(providerId, 'providerId').toLowerCase(),
       models = UnmodifiableListView(models.toList(growable: false)),
       modalities = Set.unmodifiable(modalities),
       regions = Set.unmodifiable(regions) {
    if (this.models.isEmpty) throw ArgumentError.value(models, 'models');
    if (this.modalities.isEmpty) {
      throw ArgumentError.value(modalities, 'modalities');
    }
    if (this.regions.isEmpty) throw ArgumentError.value(regions, 'regions');
    if (!_validEndpoint(endpoint, mode)) {
      throw ArgumentError.value(endpoint, 'endpoint');
    }
    final ids = this.models.map((model) => model.modelId).toSet();
    if (ids.length != this.models.length) {
      throw ArgumentError('AI model ids must be unique per provider.');
    }
    for (final model in this.models) {
      if (!this.modalities.containsAll(model.modalities)) {
        throw ArgumentError(
          'Provider modalities must cover model ${model.modelId}.',
        );
      }
    }
  }

  final String providerId;
  final List<AiProviderModel> models;
  final Set<AiProviderModality> modalities;
  final Uri endpoint;
  final Set<ProviderRegion> regions;
  final AiPricingMetadata pricingMetadata;
  final AiPrivacyMetadata privacyMetadata;
  final AiProviderMode mode;
  final ProviderConnectorAvailability availability;
}

final class AccountCenterAiProviderRegistry {
  AccountCenterAiProviderRegistry(Iterable<AiProviderRegistryEntry> providers)
    : _providers = Map.unmodifiable({
        for (final provider in providers) provider.providerId: provider,
      }) {
    if (_providers.length != providers.length) {
      throw ArgumentError('AI provider ids must be unique.');
    }
  }

  final Map<String, AiProviderRegistryEntry> _providers;

  List<AiProviderRegistryEntry> get providers =>
      UnmodifiableListView(_providers.values.toList(growable: false));

  AiProviderRegistryEntry require(String providerId) {
    final normalized = _required(providerId, 'providerId').toLowerCase();
    return _providers[normalized] ??
        (throw StateError('AI provider "$normalized" is not registered.'));
  }

  List<String> validateAvailabilityAgainst(
    ProviderConnectorManifest manifest,
  ) => UnmodifiableListView(
    _providers.values
        .where((provider) {
          final connector = manifest.get(provider.providerId);
          return connector == null ||
              connector.category != ProviderConnectorCategory.ai ||
              connector.availability != provider.availability;
        })
        .map((provider) => provider.providerId)
        .toList(growable: false),
  );
}

bool _validEndpoint(Uri endpoint, AiProviderMode mode) {
  if (!endpoint.hasScheme || endpoint.host.isEmpty) return false;
  if (mode == AiProviderMode.cloud) return endpoint.scheme == 'https';
  return endpoint.scheme == 'http' || endpoint.scheme == 'https';
}

bool _isHttpEndpoint(Uri endpoint) =>
    endpoint.hasScheme &&
    (endpoint.scheme == 'http' || endpoint.scheme == 'https');

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}
