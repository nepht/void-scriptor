enum KnowledgeScope { session, project, global }

class AgentMemory {
  AgentMemory({required this.scope}) : _items = {};
  final KnowledgeScope scope;
  final Map<String, List<String>> _items;

  void remember(String projectId, String text) {
    if (text.trim().isEmpty) return;
    _items.putIfAbsent(projectId, () => []).add(text);
  }

  List<String> forProject(String projectId) =>
      List.unmodifiable(_items[projectId] ?? const []);
}

class Decision {
  const Decision(this.id, this.text, this.superseded);
  final int id;
  final String text;
  final bool superseded;
}

class DecisionLedger {
  final List<Decision> _decisions = [];
  int _nextId = 0;
  Decision add(String text) {
    final decision = Decision(_nextId++, text, false);
    _decisions.add(decision);
    return decision;
  }

  void supersede(Decision old, String replacement) {
    final index = _decisions.indexWhere((item) => item.id == old.id);
    if (index >= 0) {
      _decisions[index] = Decision(old.id, old.text, true);
    }
    add(replacement);
  }

  List<Decision> get active =>
      _decisions.where((item) => !item.superseded).toList(growable: false);
}

class EvaluationMetrics {
  const EvaluationMetrics({
    required this.quality,
    required this.safety,
    required this.latency,
  });
  final double quality;
  final double safety;
  final double latency;
  double get composite => (quality + safety + latency) / 3;
}

class ModelRouter {
  ModelRouter(Iterable<String> models) : _models = List.unmodifiable(models);
  final List<String> _models;
  String? select({required bool preferLocal}) {
    if (_models.isEmpty) return null;
    if (preferLocal && _models.contains('local')) return 'local';
    return _models.first;
  }
}

class RollbackPolicy {
  final List<String> _versions = [];
  void record(String version) => _versions.add(version);
  String? rollback() =>
      _versions.length < 2 ? null : _versions[_versions.length - 2];
}

class RetryBudget {
  const RetryBudget(this.maxRetries);
  final int maxRetries;
  bool allow(int attempts) => attempts < maxRetries;
}
