class RegionBoundary {
  const RegionBoundary({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
  bool overlaps(RegionBoundary other) =>
      minX < other.maxX &&
      maxX > other.minX &&
      minY < other.maxY &&
      maxY > other.minY;
}

class Region {
  const Region({required this.id, required this.name, required this.boundary});
  final String id;
  final String name;
  final RegionBoundary boundary;
}

class Continent {
  Continent({required this.id, required this.name, required this.areaKm2})
    : _regions = [];
  final String id;
  final String name;
  final double areaKm2;
  final List<Region> _regions;

  Region addRegion({
    required String id,
    required String name,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
  }) {
    if (maxX <= minX || maxY <= minY) {
      throw ArgumentError('Invalid region boundary');
    }
    final boundary = RegionBoundary(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
    if (_regions.any((region) => region.boundary.overlaps(boundary))) {
      throw ArgumentError('Region boundary overlaps an existing region');
    }
    final region = Region(id: id, name: name, boundary: boundary);
    _regions.add(region);
    return region;
  }

  Region? region(String id) => _regions.cast<Region?>().firstWhere(
    (item) => item?.id == id,
    orElse: () => null,
  );
}

class OceanSystem {
  const OceanSystem({required this.maxLod});
  final int maxLod;
  int lodFor({required double distanceKm}) {
    if (distanceKm < 100) return 0;
    if (distanceKm < 1000) return 1;
    if (distanceKm < 5000) return 2;
    if (distanceKm < 10000) return 3;
    return maxLod;
  }
}

class CurrentVector {
  const CurrentVector({required this.dx, required this.dy});
  final int dx;
  final int dy;

  @override
  bool operator ==(Object other) =>
      other is CurrentVector && other.dx == dx && other.dy == dy;
  @override
  int get hashCode => Object.hash(dx, dy);
}

class OceanCurrentMap {
  const OceanCurrentMap();
  CurrentVector directionAt({required int x, required int y}) =>
      const CurrentVector(dx: 1, dy: 0);
}

class RiverSegment {
  const RiverSegment({
    required this.id,
    required this.fromHeight,
    required this.toHeight,
  });
  final String id;
  final double fromHeight;
  final double toHeight;
}

class Hydrology {
  final List<RiverSegment> _segments = [];
  List<RiverSegment> get segments => List.unmodifiable(_segments);
  void addRiver(RiverSegment segment) {
    if (segment.fromHeight <= segment.toHeight) {
      throw ArgumentError('River must flow downhill');
    }
    _segments.add(segment);
  }
}
