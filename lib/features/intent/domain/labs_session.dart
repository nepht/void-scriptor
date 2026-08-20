class LabsAction {
  const LabsAction({required this.id, required this.feature});
  final String id;
  final String feature;
}

class LabsSession {
  LabsSession({required this.sessionId});
  final String sessionId;
  final Set<String> _seen = {};

  void record(LabsAction action) => _seen.add(action.id);
  bool hasSeen(String id) => _seen.contains(id);
  bool replay(String id) => false;
}

class Experiment {
  const Experiment({required this.id, required this.version});
  final String id;
  final String version;
}

class ExperimentRegistry {
  ExperimentRegistry({required this.currentVersion});
  final String currentVersion;
  final Map<String, Experiment> _experiments = {};

  void register(Experiment experiment) =>
      _experiments[experiment.id] = experiment;
  bool isCompatible(String id) => _experiments[id]?.version == currentVersion;
}
