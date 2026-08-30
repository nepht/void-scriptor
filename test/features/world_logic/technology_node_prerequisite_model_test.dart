import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart';

void main() {
  group('TechnologyNodePrerequisiteModel - 110.39', () {
    test(
      'technology_nodes validated stores id name culture scope branch tier summary source',
      () {
        final node = TechnologyNode.validated(
          id: 't-black-powder',
          name: 'Black Powder',
          culture: 'han',
          scope: TechnologyScope.military,
          branch: 'prime',
          tier: 2,
          summary: 'flammable powder for propulsion',
          source: TechnologySource.validated(
            revision: 'rev-1',
            reason: 'han codex',
          ),
        );
        expect(node.id, 't-black-powder');
        expect(node.name, 'Black Powder');
        expect(node.culture, 'han');
        expect(node.scope, TechnologyScope.military);
        expect(node.branch, 'prime');
        expect(node.tier, 2);
        expect(node.summary, 'flammable powder for propulsion');
        expect(node.source.revision, 'rev-1');
        expect(node.source.reason, 'han codex');
      },
    );

    test('prerequisites accepts list and defaults to empty', () {
      final node = TechnologyNode.validated(
        id: 't-gun',
        name: 'Firearm',
        prerequisites: ['t-black-powder', 't-metallurgy'],
        source: TechnologySource.validated(revision: 'rev-2', reason: 'forge'),
      );
      expect(node.prerequisites, ['t-black-powder', 't-metallurgy']);

      final standalone = TechnologyNode.validated(
        id: 't-wheel',
        name: 'Wheel',
        source: TechnologySource.validated(revision: 'rev-3', reason: 'origin'),
      );
      expect(standalone.prerequisites, isEmpty);
    });

    test(
      'resources validated rejects empty id kind reason and amount non-positive',
      () {
        expect(
          () => TechnologyResource.validated(
            id: '',
            kind: 'ore',
            amount: 1,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyResource.validated(
            id: 'r-1',
            kind: '',
            amount: 1,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyResource.validated(
            id: 'r-1',
            kind: 'ore',
            amount: 0,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyResource.validated(
            id: 'r-1',
            kind: 'ore',
            amount: -2,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyResource.validated(
            id: 'r-1',
            kind: 'ore',
            amount: 1,
            reason: '',
          ),
          throwsArgumentError,
        );

        final r = TechnologyResource.validated(
          id: 'r-iron',
          kind: 'ore',
          amount: 5,
          reason: 'mining',
        );
        expect(r.amount, 5);
        expect(r.kind, 'ore');
      },
    );

    test(
      'infrastructure validated rejects empty kind capacity non-positive empty reason',
      () {
        expect(
          () => TechnologyInfrastructure.validated(
            id: 'i-1',
            kind: '',
            capacity: 1,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyInfrastructure.validated(
            id: 'i-1',
            kind: 'forge',
            capacity: 0,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyInfrastructure.validated(
            id: 'i-1',
            kind: 'forge',
            capacity: -2,
            reason: 'r',
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyInfrastructure.validated(
            id: 'i-1',
            kind: 'forge',
            capacity: 3,
            reason: '',
          ),
          throwsArgumentError,
        );

        final i = TechnologyInfrastructure.validated(
          id: 'i-foundry',
          kind: 'forge',
          capacity: 3,
          reason: 'smelting',
        );
        expect(i.capacity, 3);
      },
    );

    test(
      'discovery_events validated rejects negative tick empty summary empty source fields',
      () {
        expect(
          () => TechnologyDiscoveryEvent.validated(
            id: 'd-1',
            technologyId: 't-wheel',
            tick: -1,
            summary: 's',
            source: TechnologySource.validated(revision: 'r', reason: 'r'),
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyDiscoveryEvent.validated(
            id: 'd-1',
            technologyId: 't-wheel',
            tick: 0,
            summary: '',
            source: TechnologySource.validated(revision: 'r', reason: 'r'),
          ),
          throwsArgumentError,
        );
        expect(
          () => TechnologyDiscoveryEvent.validated(
            id: 'd-1',
            technologyId: 't-wheel',
            tick: 0,
            summary: 's',
            source: TechnologySource.validated(revision: '', reason: 'r'),
          ),
          throwsArgumentError,
        );

        final ev = TechnologyDiscoveryEvent.validated(
          id: 'd-wheel-0',
          technologyId: 't-wheel',
          tick: 12,
          summary: 'first wheel carved',
          discoveredBy: 'p-smith',
          source: TechnologySource.validated(
            revision: 'rev-4',
            reason: 'origin',
          ),
        );
        expect(ev.discoveredBy, 'p-smith');
      },
    );

    test(
      'registry rejects duplicate ids and exposes nodeById with unmodifiable nodes',
      () {
        final node = TechnologyNode.validated(
          id: 't-wheel',
          name: 'Wheel',
          source: TechnologySource.validated(revision: 'r', reason: 'r'),
        );
        final dup = TechnologyNode.validated(
          id: 't-wheel',
          name: 'Wheel v2',
          source: TechnologySource.validated(revision: 'r2', reason: 'r2'),
        );
        expect(
          () => TechnologyRegistry.validated(nodes: [node, dup]),
          throwsArgumentError,
        );

        final reg = TechnologyRegistry.validated(nodes: [node]);
        expect(reg.nodeById('t-wheel'), same(node));
        expect(reg.nodeById('missing'), isNull);
        expect(() => reg.nodes.clear(), throwsUnsupportedError);
      },
    );

    test(
      'discovery timeline sorts ascending by tick and filters by tick range',
      () {
        final e1 = TechnologyDiscoveryEvent.validated(
          id: 'd-x-1',
          technologyId: 't-x',
          tick: 100,
          summary: 'later',
          source: TechnologySource.validated(revision: 'r', reason: 'r'),
        );
        final e2 = TechnologyDiscoveryEvent.validated(
          id: 'd-x-2',
          technologyId: 't-x',
          tick: 5,
          summary: 'earlier',
          source: TechnologySource.validated(revision: 'r', reason: 'r'),
        );
        final e3 = TechnologyDiscoveryEvent.validated(
          id: 'd-x-3',
          technologyId: 't-x',
          tick: 50,
          summary: 'middle',
          source: TechnologySource.validated(revision: 'r', reason: 'r'),
        );

        final timeline = TechnologyDiscoveryTimeline.validated(
          events: [e1, e2, e3],
        );
        expect(timeline.events.map((e) => e.tick).toList(), [5, 50, 100]);

        final ranged = timeline.eventsBetween(startTick: 10, endTick: 200);
        expect(ranged.map((e) => e.tick).toList(), [50, 100]);

        expect(timeline.events.length, 3);
        expect(() => timeline.events.clear(), throwsUnsupportedError);
      },
    );

    test(
      'registry rejects duplicate prerequisite ids within a single node',
      () {
        final a = TechnologyNode.validated(
          id: 't-a',
          name: 'A',
          source: TechnologySource.validated(revision: 'r', reason: 'r'),
        );
        final b = TechnologyNode.validated(
          id: 't-b',
          name: 'B',
          prerequisites: ['t-a', 't-a'],
          source: TechnologySource.validated(revision: 'r', reason: 'r'),
        );
        expect(
          () => TechnologyRegistry.validated(nodes: [a, b]),
          throwsArgumentError,
        );
      },
    );
  });
}
