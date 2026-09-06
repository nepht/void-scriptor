enum SpatialSurface { floor, wall, ceiling, unknown }

enum SpatialMappingResult { mapped, unavailable }

class SpatialCell {
  const SpatialCell({required this.x, required this.y, required this.surface});

  final int x;
  final int y;
  final SpatialSurface surface;

  bool get isWalkable => surface == SpatialSurface.floor;
}

class SpatialBounds {
  const SpatialBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
}

class SpatialMap {
  const SpatialMap({required this.cellSizeMeters, required this.cells});

  final double cellSizeMeters;
  final List<SpatialCell> cells;

  bool get isValid =>
      cellSizeMeters > 0 &&
      cells.every((cell) => cell.surface != SpatialSurface.unknown);

  int get cellCount => cells.length;

  List<SpatialCell> get walkableCells =>
      List.unmodifiable(cells.where((cell) => cell.isWalkable));

  SpatialBounds get bounds {
    if (cells.isEmpty) {
      return const SpatialBounds(minX: 0, maxX: 0, minY: 0, maxY: 0);
    }
    var minX = cells.first.x;
    var maxX = cells.first.x;
    var minY = cells.first.y;
    var maxY = cells.first.y;
    for (final cell in cells.skip(1)) {
      if (cell.x < minX) minX = cell.x;
      if (cell.x > maxX) maxX = cell.x;
      if (cell.y < minY) minY = cell.y;
      if (cell.y > maxY) maxY = cell.y;
    }
    return SpatialBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }
}

abstract interface class SpatialMapper {
  Future<SpatialMappingResult> scan();
}

class UnavailableSpatialMapper implements SpatialMapper {
  const UnavailableSpatialMapper();

  @override
  Future<SpatialMappingResult> scan() async => SpatialMappingResult.unavailable;
}
