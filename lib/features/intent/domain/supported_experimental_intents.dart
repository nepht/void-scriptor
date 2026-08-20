class ExperimentalIntentRegistry {
  const ExperimentalIntentRegistry();

  static const version = '0.51-experimental';
  static const _supported = {'select', 'openWorkspace', 'next', 'previous'};

  String get version => ExperimentalIntentRegistry.version;

  bool isSupported(String intent) => _supported.contains(intent);

  String resolve(String intent) =>
      isSupported(intent) ? intent : 'standardInput';
}
