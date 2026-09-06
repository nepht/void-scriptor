enum CameraLens { front, back, external }

enum CameraPermission { granted, denied, unavailable }

extension CameraPermissionX on CameraPermission {
  bool get canCapture => this == CameraPermission.granted;
}

enum CameraCaptureResult { started, unavailable, stopped }

class CameraCapability {
  const CameraCapability({
    required this.id,
    required this.lens,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String id;
  final CameraLens lens;
  final int maxWidth;
  final int maxHeight;

  bool get isValid => id.trim().isNotEmpty && maxWidth > 0 && maxHeight > 0;
}

class CameraFrameMetadata {
  const CameraFrameMetadata({
    required this.width,
    required this.height,
    required this.rotationDegrees,
    required this.timestampMicros,
  });

  final int width;
  final int height;
  final int rotationDegrees;
  final int timestampMicros;

  double get aspectRatio => width / height;
  int get normalizedRotation => ((rotationDegrees % 360) + 360) % 360;
}

abstract interface class CameraCaptureAdapter {
  Future<CameraPermission> requestPermission();
  Future<CameraCaptureResult> start();
  Future<CameraCaptureResult> stop();
}

class UnavailableCameraAdapter implements CameraCaptureAdapter {
  const UnavailableCameraAdapter();

  @override
  Future<CameraPermission> requestPermission() async =>
      CameraPermission.unavailable;

  @override
  Future<CameraCaptureResult> start() async => CameraCaptureResult.unavailable;

  @override
  Future<CameraCaptureResult> stop() async => CameraCaptureResult.stopped;
}
