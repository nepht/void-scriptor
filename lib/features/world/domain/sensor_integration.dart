enum SensorModality { camera, depth, lidar, imu, gps }

class SensorHub {
  const SensorHub({required this.modalities});

  final List<SensorModality> modalities;

  bool get isValid => modalities.toSet().length == modalities.length;
  bool get isAvailable => isValid && modalities.isNotEmpty;

  bool supports(SensorModality modality) =>
      isValid && modalities.contains(modality);
}

abstract interface class SensorProvider {
  SensorHub get hub;
}

class UnavailableSensorProvider implements SensorProvider {
  const UnavailableSensorProvider();

  @override
  SensorHub get hub => const SensorHub(modalities: []);
}
