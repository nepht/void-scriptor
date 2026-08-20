import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/geography_hydrology.dart';

void main() {
  test('builds continent regions with non-overlapping bounded boundaries', () {
    final continent = Continent(id: 'c1', name: 'Kokuen', areaKm2: 1000);
    final north = continent.addRegion(
      id: 'r1',
      name: 'North',
      minX: 0,
      minY: 0,
      maxX: 10,
      maxY: 10,
    );
    expect(continent.region('r1'), same(north));
    expect(
      () => continent.addRegion(
        id: 'r2',
        name: 'Overlap',
        minX: 5,
        minY: 5,
        maxX: 12,
        maxY: 12,
      ),
      throwsArgumentError,
    );
  });

  test('ocean LOD and current map expose stable levels', () {
    const ocean = OceanSystem(maxLod: 4);
    expect(ocean.lodFor(distanceKm: 10), 0);
    expect(ocean.lodFor(distanceKm: 10000), 4);
    const currents = OceanCurrentMap();
    expect(currents.directionAt(x: 2, y: 3), const CurrentVector(dx: 1, dy: 0));
  });

  test('hydrology creates directed river network from high to low terrain', () {
    final network = Hydrology();
    network.addRiver(
      const RiverSegment(id: 'r1', fromHeight: 100, toHeight: 20),
    );
    expect(network.segments, hasLength(1));
    expect(
      () => network.addRiver(
        const RiverSegment(id: 'bad', fromHeight: 2, toHeight: 8),
      ),
      throwsArgumentError,
    );
  });
}
