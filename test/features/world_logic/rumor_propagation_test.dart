// Rumor Propagation Simulation - Sprint 110.37.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/rumor_propagation.dart';

void main() {
  group('Rumor Propagation Simulation (110.37)', () {
    group('seed_event', () {
      test('rejects empty id / summary / origin', () {
        expect(
          () => RumorSeed.validated(
            id: '',
            summary: 's',
            origin: const RumorOrigin(locationId: 'town-a'),
            tick: 0,
            source: const RumorSource(revision: 'r1', reason: 'librarian'),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => RumorSeed.validated(
            id: 'r1',
            summary: '',
            origin: const RumorOrigin(locationId: 'town-a'),
            tick: 0,
            source: const RumorSource(revision: 'r1', reason: 'librarian'),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => RumorSeed.validated(
            id: 'r1',
            summary: 's',
            origin: const RumorOrigin(),
            tick: 0,
            source: const RumorSource(revision: 'r1', reason: 'librarian'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('rejects negative tick', () {
        expect(
          () => RumorSeed.validated(
            id: 'r1',
            summary: 's',
            origin: const RumorOrigin(locationId: 'town-a'),
            tick: -1,
            source: const RumorSource(revision: 'r1', reason: 'librarian'),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
      test('origin exposes ids', () {
        const o = RumorOrigin(
          locationId: 'town-a',
          personId: 'alice',
          factionId: 'guild',
        );
        expect(o.locationId, 'town-a');
        expect(o.personId, 'alice');
        expect(o.factionId, 'guild');
      });
    });

    group('network_spread', () {
      test('reaches every reachable recipient', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol', 'dave'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
            RumorEdge(from: 'alice', to: 'dave'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'a dragon was seen',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'town crier'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(),
          upToTick: 100,
        );
        expect(
          result.recipients.map((e) => e.personId),
          containsAll(<String>{'bob', 'carol', 'dave'}),
        );
        expect(result.recipients.any((e) => e.personId == 'alice'), isFalse);
      });
      test('unreachable persons excluded', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'eve'},
          edges: const [RumorEdge(from: 'alice', to: 'bob')],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'hidden',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'spy'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(),
          upToTick: 50,
        );
        final ids = result.recipients.map((e) => e.personId).toSet();
        expect(ids, isNot(contains('eve')));
        expect(ids, contains('bob'));
      });
    });

    group('delay', () {
      test('arrival tick sums latencyTicks across hops', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol', 'dave'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
            RumorEdge(from: 'carol', to: 'dave'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'long road',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 10,
          source: const RumorSource(revision: 'r1', reason: 'traveler'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(propagationDelayTicks: 4),
          upToTick: 100,
        );
        RumorReach reachFor(String id) =>
            result.recipients.firstWhere((e) => e.personId == id);
        expect(reachFor('bob').arrivalTick, 14);
        expect(reachFor('carol').arrivalTick, 18);
        expect(reachFor('dave').arrivalTick, 22);
      });
      test('recipients beyond upToTick dropped', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob'},
          edges: const [RumorEdge(from: 'alice', to: 'bob')],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'late',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'wanderer'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(propagationDelayTicks: 10),
          upToTick: 5,
        );
        expect(result.recipients, isEmpty);
      });
    });

    group('reliability', () {
      test('confidence bounded and decreasing across hops', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol', 'dave'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
            RumorEdge(from: 'carol', to: 'dave'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'reliability',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'baker'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(reliability: 5),
          upToTick: 100,
        );
        double conf(String id) =>
            result.recipients.firstWhere((e) => e.personId == id).confidence;
        final cb = conf('bob');
        final cc = conf('carol');
        final cd = conf('dave');
        expect(cb, inInclusiveRange(0.0, 1.0));
        expect(cc, inInclusiveRange(0.0, 1.0));
        expect(cd, inInclusiveRange(0.0, 1.0));
        expect(cb, greaterThan(cc));
        expect(cc, greaterThan(cd));
      });
      test('reliability=10 keeps confidence 1.0 for short path', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob'},
          edges: const [RumorEdge(from: 'alice', to: 'bob')],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'trust',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'courier'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(reliability: 10),
          upToTick: 10,
        );
        expect(result.recipients.first.confidence, 1.0);
      });
    });

    group('distortion', () {
      test('accumulates across hops, bounded', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol', 'dave'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
            RumorEdge(from: 'carol', to: 'dave'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'distortion',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'sailor'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(distortionFactor: 0.2),
          upToTick: 100,
        );
        double dist(String id) =>
            result.recipients.firstWhere((e) => e.personId == id).distortion;
        final db = dist('bob');
        final dc = dist('carol');
        final dd = dist('dave');
        expect(db, inInclusiveRange(0.0, 1.0));
        expect(dc, greaterThanOrEqualTo(db));
        expect(dd, greaterThanOrEqualTo(dc));
      });
      test('distortion=0 keeps summary intact', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'exact',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'herald'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(distortionFactor: 0),
          upToTick: 100,
        );
        for (final r in result.recipients) {
          expect(r.distortion, 0.0);
          expect(r.distortedSummary, 'exact');
        }
      });
    });

    group('source_chain', () {
      test('chain lists every intermediate rumor id in order', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol', 'dave'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
            RumorEdge(from: 'carol', to: 'dave'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'chain',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'minstrel'),
        );
        final result = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: const RumorTraits(),
          upToTick: 100,
        );
        RumorReach reachFor(String id) =>
            result.recipients.firstWhere((e) => e.personId == id);
        expect(reachFor('bob').sourceChain, ['r1', 'r1>bob']);
        expect(reachFor('carol').sourceChain, ['r1', 'r1>bob', 'r1>bob>carol']);
        expect(reachFor('dave').sourceChain, [
          'r1',
          'r1>bob',
          'r1>bob>carol',
          'r1>bob>carol>dave',
        ]);
      });
    });

    group('replayable_seed', () {
      test('identical inputs produce identical result', () {
        final network = RumorNetwork(
          persons: const {'alice', 'bob', 'carol'},
          edges: const [
            RumorEdge(from: 'alice', to: 'bob'),
            RumorEdge(from: 'bob', to: 'carol'),
          ],
        );
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'replay',
          origin: const RumorOrigin(personId: 'alice'),
          tick: 0,
          source: const RumorSource(revision: 'r1', reason: 'bard'),
        );
        const traits = RumorTraits();
        final a = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: traits,
          upToTick: 100,
        );
        final b = const RumorPropagationSimulator().simulate(
          seed: seed,
          network: network,
          traits: traits,
          upToTick: 100,
        );
        expect(a.recipients.length, b.recipients.length);
        for (var i = 0; i < a.recipients.length; i++) {
          expect(a.recipients[i].personId, b.recipients[i].personId);
          expect(a.recipients[i].arrivalTick, b.recipients[i].arrivalTick);
          expect(a.recipients[i].confidence, b.recipients[i].confidence);
          expect(a.recipients[i].distortion, b.recipients[i].distortion);
          expect(
            a.recipients[i].distortedSummary,
            b.recipients[i].distortedSummary,
          );
          expect(a.recipients[i].sourceChain, b.recipients[i].sourceChain);
        }
      });
    });
  });
}
