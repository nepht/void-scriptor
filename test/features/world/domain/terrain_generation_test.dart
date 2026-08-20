import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/terrain_generation.dart';

void main() {
  test('creates stable hierarchical chunks with deterministic ids', () {
    const tile = SurfaceTile(level: 2, x: 3, y: 4);
    expect(tile.chunkId, '2/3/4');
    expect(tile.parent.chunkId, '1/1/2');
    expect(tile.children, hasLength(4));
  });

  test('heightmap sculpting respects brush scale and bounds', () {
    final map = HeightMap(width: 3, height: 3);
    map.sculpt(
      centerX: 1,
      centerY: 1,
      delta: 2,
      brush: TerrainBrush(radius: 1),
    );
    expect(map.valueAt(1, 1), 2);
    expect(map.valueAt(-1, 1), 0);
    expect(() => TerrainBrush(radius: 0), throwsArgumentError);
  });

  test('procedural generation is seed deterministic and manual edits win', () {
    const terrain = ProceduralTerrain(seed: 42);
    final first = terrain.generate(width: 2, height: 2);
    final second = terrain.generate(width: 2, height: 2);
    expect(first.values, second.values);
    final blended = TerrainComposer().blend(first, {(0, 0): 9});
    expect(blended.valueAt(0, 0), 9);
  });
}
