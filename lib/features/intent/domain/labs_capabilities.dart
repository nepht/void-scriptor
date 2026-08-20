enum LabsFeature { voice, gesture, gaze, stylus, bci }

enum LabsFallback { none, standardInput }

class LabsCapabilities {
  const LabsCapabilities({this.enabled = const {}, this.available = const {}});
  final Set<LabsFeature> enabled;
  final Set<LabsFeature> available;
  String get version => '0.51-experimental';

  bool isEnabled(LabsFeature feature) =>
      enabled.contains(feature) &&
      (available.isEmpty || available.contains(feature));

  LabsFallback fallbackFor(LabsFeature feature) =>
      isEnabled(feature) ? LabsFallback.none : LabsFallback.standardInput;
}
