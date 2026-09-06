import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/camera_capture.dart';

void main() {
  test('camera capture contract reports capability and permission safely', () {
    const capability = CameraCapability(
      id: 'camera.main',
      lens: CameraLens.back,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    const permission = CameraPermission.denied;
    const frame = CameraFrameMetadata(
      width: 1920,
      height: 1080,
      rotationDegrees: 90,
      timestampMicros: 42,
    );

    expect(capability.isValid, isTrue);
    expect(permission.canCapture, isFalse);
    expect(frame.aspectRatio, closeTo(16 / 9, .001));
    expect(frame.normalizedRotation, 90);
  });

  test('adapter remains explicit when hardware is unavailable', () async {
    const adapter = UnavailableCameraAdapter();

    expect(await adapter.requestPermission(), CameraPermission.unavailable);
    expect(await adapter.start(), CameraCaptureResult.unavailable);
    expect(await adapter.stop(), CameraCaptureResult.stopped);
  });
}
