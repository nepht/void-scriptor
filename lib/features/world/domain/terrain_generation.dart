class SurfaceTile {
  const SurfaceTile({required this.level, required this.x, required this.y});
  final int level;
  final int x;
  final int y;

  String get chunkId => '$level/$x/$y';
  SurfaceTile get parent => SurfaceTile(level: level - 1, x: x ~/ 2, y: y ~/ 2);
  List<SurfaceTile> get children => [
    SurfaceTile(level: level + 1, x: x * 2, y: y * 2),
    SurfaceTile(level: level + 1, x: x * 2 + 1, y: y * 2),
    SurfaceTile(level: level + 1, x: x * 2, y: y * 2 + 1),
    SurfaceTile(level: level + 1, x: x * 2 + 1, y: y * 2 + 1),
  ];
}

class TerrainBrush {
  TerrainBrush({required this.radius}) {
    if (radius <= 0) throw ArgumentError.value(radius, 'radius');
  }

  final int radius;
}

class HeightMap {
  HeightMap({required this.width, required this.height})
    : _values = List.filled(width * height, 0);
  final int width;
  final int height;
  final List<int> _values;
  List<int> get values => List.unmodifiable(_values);
  int valueAt(int x, int y) =>
      x < 0 || x >= width || y < 0 || y >= height ? 0 : _values[y * width + x];

  void sculpt({
    required int centerX,
    required int centerY,
    required int delta,
    required TerrainBrush brush,
  }) {
    for (
      var y = centerY - brush.radius + 1;
      y <= centerY + brush.radius - 1;
      y++
    ) {
      for (
        var x = centerX - brush.radius + 1;
        x <= centerX + brush.radius - 1;
        x++
      ) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          _values[y * width + x] += delta;
        }
      }
    }
  }
}

class ProceduralTerrain {
  const ProceduralTerrain({required this.seed});
  final int seed;
  HeightMap generate({required int width, required int height}) {
    final map = HeightMap(width: width, height: height);
    var value = seed;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        value = (value * 1103515245 + 12345) & 0x7fffffff;
        map.sculpt(
          centerX: x,
          centerY: y,
          delta: value % 10,
          brush: TerrainBrush(radius: 1),
        );
      }
    }
    return map;
  }
}

class TerrainComposer {
  HeightMap blend(HeightMap source, Map<(int, int), int> manualEdits) {
    final result = HeightMap(width: source.width, height: source.height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final value = manualEdits[(x, y)] ?? source.valueAt(x, y);
        result.sculpt(
          centerX: x,
          centerY: y,
          delta: value,
          brush: TerrainBrush(radius: 1),
        );
      }
    }
    return result;
  }
}
