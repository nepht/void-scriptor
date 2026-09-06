import '../domain/ai_provider.dart';

class AiProviderCostPolicy {
  AiProviderCostPolicy(Map<AiProvider, double> costs) {
    for (final entry in costs.entries) {
      final cost = entry.value;
      if (!cost.isFinite || cost < 0) {
        throw ArgumentError.value(
          cost,
          entry.key.id,
          'Cost must be finite and non-negative.',
        );
      }
      _costs[entry.key] = cost;
    }
  }

  final Map<AiProvider, double> _costs = {};

  AiProvider? resolve(PromptTarget target) {
    AiProvider? selected;
    var selectedCost = double.infinity;
    for (final entry in _costs.entries) {
      if (!_supports(entry.key, target)) continue;
      if (entry.value < selectedCost) {
        selected = entry.key;
        selectedCost = entry.value;
      }
    }
    return selected;
  }

  bool _supports(AiProvider provider, PromptTarget target) {
    try {
      return provider.validateTarget(target);
    } catch (_) {
      return false;
    }
  }
}
