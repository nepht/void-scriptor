class StudioCloseoutContract {
  const StudioCloseoutContract();

  static const _suiteNames = [
    'organization',
    'delegation',
    'governance',
    'failure',
    'adversarial',
  ];

  List<String> get requiredSuites => StudioCloseoutContract._suiteNames;

  bool isCovered(Set<String> completedSuites) =>
      requiredSuites.every(completedSuites.contains);
}

class QownerEpisode {
  QownerEpisode(this.departments);

  final List<String> departments;
  bool requiresHumanGate = true;
  final Set<String> _approvedActions = {};

  bool humanGate(String action) =>
      !requiresHumanGate || _approvedActions.contains(action);

  void approve(String action) => _approvedActions.add(action);
}

class QownerEpisodeTemplate {
  static QownerEpisode create() => QownerEpisode([
    'Character',
    'Environment',
    'Cinematography',
    'Storyboard',
    'QC',
  ]);
}
