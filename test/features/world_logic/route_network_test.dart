import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/route_network.dart';

void main() {
  group('route_graph', () {
    test('graph menyimpan node dan edge dengan jarak eksplisit', () {
      final graph = RouteGraph(
        nodes: {
          'a': const RouteNode(id: 'a', name: 'A'),
          'b': const RouteNode(id: 'b', name: 'B'),
          'c': const RouteNode(id: 'c', name: 'C'),
        },
        edges: [
          RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: 10),
          RouteEdge(id: 'e2', fromId: 'b', toId: 'c', distance: 7),
        ],
      );

      expect(graph.node('a').name, 'A');
      expect(graph.neighbors('a').map((e) => e.toId), ['b']);
      expect(graph.neighbors('b').map((e) => e.toId), ['c']);
    });

    test(
      'graph menolak node rujukan yang tidak ada dan edge dengan jarak negatif',
      () {
        expect(
          () => RouteGraph(
            nodes: {
              'a': const RouteNode(id: 'a', name: 'A'),
              'b': const RouteNode(id: 'b', name: 'B'),
            },
            edges: [
              RouteEdge(id: 'e1', fromId: 'a', toId: 'ghost', distance: 5),
            ],
          ),
          throwsArgumentError,
        );

        expect(
          () => RouteGraph(
            nodes: {
              'a': const RouteNode(id: 'a', name: 'A'),
              'b': const RouteNode(id: 'b', name: 'B'),
            },
            edges: [RouteEdge(id: 'e1', fromId: 'a', toId: 'b', distance: -1)],
          ),
          throwsArgumentError,
        );
      },
    );
  });

  group('terrain_cost', () {
    test('biaya akhir = jarak dikalikan terrain multiplier per segmen', () {
      final graph = RouteGraph(
        nodes: {
          'a': const RouteNode(id: 'a', name: 'A'),
          'b': const RouteNode(id: 'b', name: 'B'),
          'c': const RouteNode(id: 'c', name: 'C'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 10,
            terrain: Terrain.forest,
          ),
          RouteEdge(
            id: 'e2',
            fromId: 'b',
            toId: 'c',
            distance: 5,
            terrain: Terrain.swamp,
          ),
        ],
      );

      final cost = graph.totalCost(
        segments: const ['e1', 'e2'],
        season: Season.summer,
      );

      // forest x1.5 + swamp x2.0 = 15 + 10
      expect(cost, 25);
    });

    test('biaya deterministik untuk input dan musim yang sama', () {
      final graph = RouteGraph(
        nodes: {
          'a': const RouteNode(id: 'a', name: 'A'),
          'b': const RouteNode(id: 'b', name: 'B'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 8,
            terrain: Terrain.plain,
          ),
        ],
      );

      final a = graph.totalCost(segments: const ['e1'], season: Season.winter);
      final b = graph.totalCost(segments: const ['e1'], season: Season.winter);
      expect(a, b);
    });
  });

  group('seasonal_access', () {
    test('musim yang berbeda menghasilkan multiplier berbeda', () {
      final graph = RouteGraph(
        nodes: {
          'a': const RouteNode(id: 'a', name: 'A'),
          'b': const RouteNode(id: 'b', name: 'B'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 4,
            terrain: Terrain.mountain,
          ),
        ],
      );

      final summer = graph.totalCost(
        segments: const ['e1'],
        season: Season.summer,
      );
      final winter = graph.totalCost(
        segments: const ['e1'],
        season: Season.winter,
      );

      expect(summer, isNot(winter));
    });
  });

  group('blocked_routes', () {
    test(
      'segmen yang diblokir menolak kalkulasi dan menjelaskan alasannya',
      () {
        final graph = RouteGraph(
          nodes: {
            'a': const RouteNode(id: 'a', name: 'A'),
            'b': const RouteNode(id: 'b', name: 'B'),
          },
          edges: [
            RouteEdge(
              id: 'e1',
              fromId: 'a',
              toId: 'b',
              distance: 3,
              blocked: const BlockedRoute(reason: 'jembatan runtuh'),
            ),
          ],
        );

        expect(
          () => graph.totalCost(segments: const ['e1'], season: Season.summer),
          throwsA(
            isA<RouteBlockedException>()
                .having((e) => e.edgeId, 'edgeId', 'e1')
                .having((e) => e.reason, 'reason', 'jembatan runtuh'),
          ),
        );
      },
    );
  });

  group('source_navigation', () {
    test('segmen membawa source revision dan reason untuk provenance', () {
      const source = RouteSource(
        revision: 'world.v3',
        reason: 'Peta musim dingin yang disetujui editor',
      );
      final graph = RouteGraph(
        nodes: {
          'a': const RouteNode(id: 'a', name: 'A'),
          'b': const RouteNode(id: 'b', name: 'B'),
        },
        edges: [
          RouteEdge(
            id: 'e1',
            fromId: 'a',
            toId: 'b',
            distance: 6,
            source: source,
          ),
        ],
      );

      final resolved = graph.edge('e1');
      expect(resolved.source.revision, 'world.v3');
      expect(resolved.source.reason, 'Peta musim dingin yang disetujui editor');
    });
  });
}
