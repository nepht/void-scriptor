/// Sprint 115.25 — AI Connection & Model Settings.
///
/// Local configuration contract over the manifest-backed AI provider registry.
/// Provider I/O is represented only by an injected health-test seam; this file
/// does not store credentials or claim a successful external connection.
library;

import 'dart:collection';

import 'account_center_ai_provider_registry.dart';
import 'account_center_provider_connector_manifest.dart';

enum AiConnectionStatus { configured }

enum AiQualityPreference { balanced, speed, quality }

enum AiConnectionHealth { healthy, degraded, unavailable }

final class AiBudgetLimit {
  const AiBudgetLimit._({required this.currency, required this.amount});

  factory AiBudgetLimit.unavailable() =>
      const AiBudgetLimit._(currency: null, amount: null);

  factory AiBudgetLimit.monthly({
    required String currency,
    required double amount,
  }) {
    final normalizedCurrency = currency.trim().toUpperCase();
    if (normalizedCurrency.isEmpty) {
      throw ArgumentError.value(currency, 'currency');
    }
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount');
    }
    return AiBudgetLimit._(currency: normalizedCurrency, amount: amount);
  }

  final String? currency;
  final double? amount;

  bool get isAvailable => currency != null;
}

final class AiConnectionRecord {
  const AiConnectionRecord({
    required this.providerId,
    required this.status,
    required this.connectedAt,
  });

  final String providerId;
  final AiConnectionStatus status;

  /// Null until an external connector proves a live connection.
  final DateTime? connectedAt;
}

final class AiModelSettings {
  AiModelSettings({
    required this.providerId,
    required this.defaultModelId,
    required Iterable<String> fallbackModelIds,
    required this.timeout,
    required this.budget,
    required this.quality,
    required this.preferLocal,
  }) : fallbackModelIds = UnmodifiableListView(
         fallbackModelIds.toList(growable: false),
       );

  final String providerId;
  final String defaultModelId;
  final List<String> fallbackModelIds;
  final Duration timeout;
  final AiBudgetLimit budget;
  final AiQualityPreference quality;
  final bool preferLocal;
}

final class AiHealthObservation {
  const AiHealthObservation({
    required this.status,
    required this.latency,
    required this.modelCount,
  }) : assert(modelCount >= 0);

  final AiConnectionHealth status;
  final Duration latency;
  final int modelCount;
}

final class AiHealthTestResult {
  const AiHealthTestResult({
    required this.providerId,
    required this.status,
    required this.checkedAt,
    required this.latency,
    required this.modelCount,
    required this.message,
  });

  final String providerId;
  final AiConnectionHealth status;
  final DateTime checkedAt;
  final Duration? latency;
  final int modelCount;
  final String? message;
}

typedef AiProviderHealthTester =
    Future<AiHealthObservation> Function(AiProviderRegistryEntry provider);

final class AccountCenterAiConnectionSettings {
  const AccountCenterAiConnectionSettings({
    required this.registry,
    required this.connectorManifest,
  });

  final AccountCenterAiProviderRegistry registry;
  final ProviderConnectorManifest connectorManifest;

  AiConnectionRecord connect(String providerId) {
    final provider = _connectableProvider(providerId);
    return AiConnectionRecord(
      providerId: provider.providerId,
      status: AiConnectionStatus.configured,
      connectedAt: null,
    );
  }

  AiModelSettings configure({
    required String providerId,
    required String defaultModelId,
    Iterable<String> fallbackModelIds = const [],
    required Duration timeout,
    AiBudgetLimit? budget,
    AiQualityPreference quality = AiQualityPreference.balanced,
    bool preferLocal = false,
  }) {
    final provider = _connectableProvider(providerId);
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout');
    }

    final defaultId = _required(defaultModelId, 'defaultModelId');
    final availableIds = provider.models.map((model) => model.modelId).toSet();
    if (!availableIds.contains(defaultId)) {
      throw ArgumentError.value(defaultModelId, 'defaultModelId');
    }

    final fallbacks = fallbackModelIds
        .map((modelId) => _required(modelId, 'fallbackModelIds'))
        .toList(growable: false);
    if (fallbacks.toSet().length != fallbacks.length ||
        fallbacks.contains(defaultId) ||
        !availableIds.containsAll(fallbacks)) {
      throw ArgumentError.value(fallbackModelIds, 'fallbackModelIds');
    }

    return AiModelSettings(
      providerId: provider.providerId,
      defaultModelId: defaultId,
      fallbackModelIds: fallbacks,
      timeout: timeout,
      budget: budget ?? AiBudgetLimit.unavailable(),
      quality: quality,
      preferLocal: preferLocal,
    );
  }

  Future<AiHealthTestResult> testHealth(
    String providerId, {
    required AiProviderHealthTester tester,
    DateTime Function()? now,
  }) async {
    final provider = _connectableProvider(providerId);
    final checkedAt = (now ?? DateTime.now)().toUtc();
    try {
      final observation = await tester(provider);
      if (observation.latency < Duration.zero || observation.modelCount < 0) {
        throw StateError('Invalid health observation.');
      }
      return AiHealthTestResult(
        providerId: provider.providerId,
        status: observation.status,
        checkedAt: checkedAt,
        latency: observation.latency,
        modelCount: observation.modelCount,
        message: null,
      );
    } catch (_) {
      return AiHealthTestResult(
        providerId: provider.providerId,
        status: AiConnectionHealth.unavailable,
        checkedAt: checkedAt,
        latency: null,
        modelCount: 0,
        message: 'Provider health test failed.',
      );
    }
  }

  AiProviderRegistryEntry _connectableProvider(String providerId) {
    final provider = registry.require(providerId);
    final connector = connectorManifest.get(provider.providerId);
    if (connector == null ||
        connector.category != ProviderConnectorCategory.ai ||
        connector.availability != ProviderConnectorAvailability.available ||
        provider.availability != ProviderConnectorAvailability.available) {
      throw StateError(
        'AI provider "${provider.providerId}" is not available for connection.',
      );
    }
    return provider;
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}
