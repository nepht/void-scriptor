import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/environment_reconstruction.dart';

void main() {
  test('reconstruction aggregates bounded spatial inputs', () {
    const result = EnvironmentReconstruction(
      id: 'env-1',
      mappedCellCount: 20,
      scannedObjectCount: 3,
      coverageRatio: .75,
    );

    expect(result.isValid, isTrue);
    expect(result.totalElementCount, 23);
    expect(result.isSufficientlyCovered, isTrue);
  });

  test(
    'unavailable reconstruction adapter reports external boundary',
    () async {
      const adapter = UnavailableEnvironmentReconstructor();
      expect(
        await adapter.reconstruct(),
        EnvironmentReconstructionResult.unavailable,
      );
    },
  );
}
