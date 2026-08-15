import 'token_estimator.dart';

class ContextBudgetResult {
  const ContextBudgetResult({
    required this.keptSections,
    required this.truncated,
  });
  final Map<String, String> keptSections;
  final bool truncated;
}

/// Enforces a context-window budget by dropping low-priority sections first
/// (Step 28.5). Priority: canon > preservation > identity > environment >
/// sceneAssets.
class ContextBudgeter {
  const ContextBudgeter({this.estimator = const TokenEstimator()});

  final TokenEstimator estimator;

  static const priorityOrder = [
    'canon',
    'preservation',
    'identity',
    'environment',
    'sceneAssets',
  ];

  ContextBudgetResult budget({
    required Map<String, String> sections,
    required int maxTokens,
    double headroomFraction = 0.2,
  }) {
    final available = (maxTokens * (1 - headroomFraction)).round().clamp(
      1,
      maxTokens,
    );
    final kept = <String, String>{};
    var used = 0;
    var truncated = false;

    for (final key in priorityOrder) {
      final content = sections[key];
      if (content == null) continue;
      final tokens = estimator.estimate(content);
      if (used + tokens <= available) {
        kept[key] = content;
        used += tokens;
      } else {
        truncated = true;
      }
    }
    // Any sections not in the priority order are appended if room remains.
    for (final entry in sections.entries) {
      if (kept.containsKey(entry.key)) continue;
      final tokens = estimator.estimate(entry.value);
      if (used + tokens <= available) {
        kept[entry.key] = entry.value;
        used += tokens;
      } else {
        truncated = true;
      }
    }
    return ContextBudgetResult(keptSections: kept, truncated: truncated);
  }
}
