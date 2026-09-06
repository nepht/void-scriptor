import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/spatial_mapping.dart';

void main() {
  test('spatial map validates cells and indexes walkable surfaces', () {
    const map = SpatialMap(
      cellSizeMeters: 0.5,
      cells: [
        SpatialCell(x: 0, y: 0, surface: SpatialSurface.floor),
        SpatialCell(x: 1, y: 0, surface: SpatialSurface.wall),
        SpatialCell(x: 0, y: 1, surface: SpatialSurface.floor),
      ],
    );

    expect(map.isValid, isTrue);
    expect(map.cellCount, 3);
    expect(map.walkableCells, hasLength(2));
    expect(map.bounds.maxX, 1);
  });

  test('unavailable spatial mapper reports platform boundary', () async {
    const mapper = UnavailableSpatialMapper();

    expect(await mapper.scan(), SpatialMappingResult.unavailable);
  });
}
