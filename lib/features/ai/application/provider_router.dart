import '../domain/ai_provider.dart';

/// Resolves the best provider for a target and performs fallback (Step 28.7–28.8).
class ProviderRouter {
  ProviderRouter(Iterable<AiProvider> providers)
    : _providers = List.of(providers);

  final List<AiProvider> _providers;

  /// Returns the first capable provider for the target, preferring the given
  /// provider id when it can serve the target.
  AiProvider? resolve(PromptTarget target, {String? preferred}) {
    if (preferred != null) {
      final candidate = _providers.where((p) => p.id == preferred).firstOrNull;
      if (candidate != null && _supports(candidate, target)) {
        return candidate;
      }
    }
    return _providers.where((p) => _supports(p, target)).firstOrNull;
  }

  bool _supports(AiProvider provider, PromptTarget target) {
    try {
      return provider.validateTarget(target);
    } catch (_) {
      return false;
    }
  }

  /// Returns the cheapest capable provider for the target (Step 28.9). The
  /// [costOf] callback supplies a per-provider cost; lower wins.
  AiProvider? resolveCheapest(
    PromptTarget target, {
    required double Function(AiProvider) costOf,
  }) {
    AiProvider? best;
    var bestCost = double.infinity;
    for (final provider in _providers) {
      if (!_supports(provider, target)) continue;
      final cost = costOf(provider);
      if (cost < bestCost) {
        best = provider;
        bestCost = cost;
      }
    }
    return best;
  }

  /// Attempts generation on the preferred provider, falling back to the next
  /// capable provider on failure. Throws [StateError] if all fail.
  Future<AiGenerationResult> generateWithFallback(
    AiGenerationRequest request, {
    String? preferred,
  }) async => (await generateReportingServingProvider(
    request,
    preferred: preferred,
  )).result;

  /// [generateWithFallback] that also names the provider which served the
  /// request. The fallback chain is unchanged: still preferred-first, still
  /// registry order after it, still first capable provider.
  Future<ServedGeneration> generateReportingServingProvider(
    AiGenerationRequest request, {
    String? preferred,
  }) async {
    final primary = resolve(request.target, preferred: preferred);
    if (primary == null) {
      throw StateError('No provider can serve target ${request.target.name}.');
    }
    final candidates = <AiProvider>[
      primary,
      ..._providers.where((provider) => provider.id != primary.id),
    ];
    Object? lastError;
    for (final provider in candidates) {
      if (!_supports(provider, request.target)) continue;
      try {
        return ServedGeneration(
          provider: provider,
          result: await provider.generate(request),
        );
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('All providers failed: $lastError');
  }
}

/// The provider that actually answered, together with its result.
///
/// A caller that bills or audits a call needs the provider that SERVED it,
/// which is not the one it asked for once a fallback has run. Recording the
/// request instead attributes cost and usage to a provider that produced
/// nothing, so this is a separate return value rather than a field on the
/// result: the router stays free of per-call mutable state.
class ServedGeneration {
  const ServedGeneration({required this.provider, required this.result});

  final AiProvider provider;
  final AiGenerationResult result;

  /// The id callers should book cost and usage against.
  String get providerId => provider.id;
}
