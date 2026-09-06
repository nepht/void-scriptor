import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/photogrammetry.dart';

void main() {
  test(
    'photogrammetry session validates image coverage and reconstruction bounds',
    () {
      const session = PhotogrammetrySession(
        id: 'scan-1',
        observations: [
          ImageObservation(id: 'front', featureCount: 120, yawDegrees: 0),
          ImageObservation(id: 'side', featureCount: 100, yawDegrees: 90),
          ImageObservation(id: 'back', featureCount: 110, yawDegrees: 180),
        ],
        maxFeaturePoints: 500,
      );

      expect(session.isValid, isTrue);
      expect(session.coverageDegrees, 180);
      expect(session.totalFeatureCount, 330);
      expect(session.canReconstruct, isTrue);
    },
  );

  test(
    'unavailable photogrammetry adapter reports external engine boundary',
    () async {
      const adapter = UnavailablePhotogrammetryAdapter();

      expect(await adapter.reconstruct(), PhotogrammetryResult.unavailable);
    },
  );
}
