class SceneEnvironmentContext {
  const SceneEnvironmentContext({
    required this.environmentId,
    this.zoneId,
    this.lightingProfileId,
    this.weatherProfileId,
    this.continuityStateId,
  });

  final String environmentId;
  final String? zoneId;
  final String? lightingProfileId;
  final String? weatherProfileId;
  final String? continuityStateId;
}
