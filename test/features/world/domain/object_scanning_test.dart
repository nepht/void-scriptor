import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/object_scanning.dart';

void main() {
  test('object scan validates identity, observations, and bounds', () {
    const scan = ObjectScan(
      objectId: 'artifact-1',
      label: 'ancient cube',
      observationCount: 12,
      bounds: ScanBounds(width: 1, height: 2, depth: .5),
    );

    expect(scan.isValid, isTrue);
    expect(scan.volumeCubicMeters, 1);
    expect(scan.isSufficientlyObserved(minimumObservations: 10), isTrue);
  });

  test('unavailable object scanner reports external engine boundary', () async {
    const scanner = UnavailableObjectScanner();

    expect(await scanner.scan(), ObjectScanResult.unavailable);
  });
}
