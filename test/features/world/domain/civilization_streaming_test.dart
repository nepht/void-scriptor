import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/civilization_streaming.dart';

void main() {
  test('settlement grows into a styled city and preserves landmarks', () {
    final settlement = Settlement(id: 's1', name: 'Kokuen', suitability: .8);
    expect(settlement.grow(population: 1000), isTrue);
    final city = City.fromSettlement(settlement, style: CityStyle.volcanic);
    city.addLandmark(
      const Landmark(id: 'l1', name: 'Crash Site', preserved: true),
    );
    expect(city.population, 1000);
    expect(city.style, CityStyle.volcanic);
    expect(city.landmarks.single.preserved, isTrue);
  });

  test('roads and transport choose lower-cost routes', () {
    final network = RoadNetwork();
    network.add(
      const Road(id: 'slow', from: 'a', to: 'b', type: RoadType.dirt, cost: 4),
    );
    network.add(
      const Road(id: 'fast', from: 'a', to: 'b', type: RoadType.paved, cost: 1),
    );
    expect(network.cheapest('a', 'b')?.id, 'fast');
    expect(TransportSimulation(network).routeCost('a', 'b'), 1);
  });

  test('population migration and territory borders remain explicit', () {
    final population = PopulationDensity();
    population.set('north', 100);
    population.migrate('north', 'south', 20);
    expect(population.at('north'), 80);
    expect(population.at('south'), 20);
    final territory = Territory('t1', owner: 'north');
    territory.changeOwner('south');
    expect(territory.owner, 'south');
    expect(territory.history, contains('north -> south'));
  });

  test('streaming state and LOD derive from distance', () {
    final unit = StreamingUnit('chunk-1');
    unit.update(distanceMeters: 10, radiusMeters: 1000);
    expect(unit.state, ChunkState.active);
    expect(unit.lod, 0);
    unit.update(distanceMeters: 1500, radiusMeters: 1000);
    expect(unit.state, ChunkState.unloaded);
    expect(SeamlessZoom.level(scale: 0.01), 3);
    expect(ObjectLod.forDistance(200), 2);
  });
}
