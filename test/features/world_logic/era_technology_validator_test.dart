// Tests for Sprint 110 step 110.41: Era Alignment & Technology Validation.
//
// Detects technologies that appear in scenes without their prerequisites
// discovered, before their canonical discovery tick, or at a production scale
// that exceeds the node documented capacity. Manual exceptions suppress
// specific warnings and retain source evidence.
//
// Domain-only, deterministic, no persistence, UI, wall clock, locale,
// randomness, or network.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/era_technology_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart';

TechnologySource _src(String label) =>
    TechnologySource.validated(revision: 'rev-$label', reason: 'reason-$label');

TechnologyNode _node({
  required String id,
  String name = 'node',
  TechnologyScope scope = TechnologyScope.military,
  List<String> prerequisites = const [],
  String culture = 'generic',
  String branch = 'prime',
  int tier = 1,
  String summary = 'summary',
  TechnologySource? source,
  List<TechnologyInfrastructure>? infrastructure,
}) {
  return TechnologyNode.validated(
    id: id,
    name: name,
    scope: scope,
    prerequisites: prerequisites,
    culture: culture,
    branch: branch,
    tier: tier,
    summary: summary,
    source: source ?? _src(id),
    infrastructure: infrastructure,
  );
}

TechnologyRegistry _registry(List<TechnologyNode> nodes) {
  return TechnologyRegistry.validated(nodes: nodes);
}

TechnologyDiscoveryEvent _discovery({
  required String id,
  required String technologyId,
  required int tick,
  String summary = 'summary',
  String discoveredBy = 'faction',
  TechnologySource? source,
}) {
  return TechnologyDiscoveryEvent.validated(
    id: id,
    technologyId: technologyId,
    tick: tick,
    summary: summary,
    discoveredBy: discoveredBy,
    source: source ?? _src(id),
  );
}

void main() {
  group('EraTechnologyValidator', () {
    test('clean scene yields no warnings', () {
      final nodeA = _node(id: 'a', tier: 1);
      final nodeB = _node(id: 'b', tier: 2, prerequisites: ['a']);
      final registry = _registry([nodeA, nodeB]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [
          _discovery(id: 'd-a', technologyId: 'a', tick: 10),
          _discovery(id: 'd-b', technologyId: 'b', tick: 20),
        ],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 30,
            technologyId: 'b',
            productionScale: 5,
          ),
        ],
      );
      expect(report.isClean, isTrue);
      expect(report.findings, isEmpty);
    });

    test('missing prerequisite emits prerequisite_warning', () {
      final nodeA = _node(id: 'a', tier: 1);
      final nodeB = _node(id: 'b', tier: 2, prerequisites: ['a']);
      final registry = _registry([nodeA, nodeB]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-b', technologyId: 'b', tick: 20)],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 30,
            technologyId: 'b',
            productionScale: 1,
          ),
        ],
      );
      expect(report.findings, hasLength(1));
      final f = report.findings.single;
      expect(f.kind, EraTechnologyWarningKind.missingPrerequisite);
      expect(f.sceneId, 'scene-1');
      expect(f.technologyId, 'b');
      expect(f.prerequisiteId, 'a');
      expect(f.source.revision, isNotEmpty);
      expect(f.source.reason, isNotEmpty);
    });

    test('use before discovery emits early_use_warning', () {
      final nodeA = _node(id: 'a', tier: 1);
      final registry = _registry([nodeA]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-a', technologyId: 'a', tick: 50)],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 10,
            technologyId: 'a',
            productionScale: 1,
          ),
        ],
      );
      expect(report.findings, hasLength(1));
      expect(report.findings.single.kind, EraTechnologyWarningKind.earlyUse);
      expect(report.findings.single.discoveryTick, 50);
    });

    test('production above capacity emits production_scale_warning', () {
      final nodeA = _node(
        id: 'a',
        tier: 1,
        infrastructure: [
          TechnologyInfrastructure.validated(
            id: 'a-infra',
            kind: 'workshop',
            capacity: 10,
            reason: 'r',
          ),
        ],
      );
      final registry = _registry([nodeA]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-a', technologyId: 'a', tick: 5)],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 20,
            technologyId: 'a',
            productionScale: 50,
          ),
        ],
      );
      expect(report.findings, hasLength(1));
      expect(
        report.findings.single.kind,
        EraTechnologyWarningKind.productionScale,
      );
      expect(report.findings.single.productionScale, 50);
      expect(report.findings.single.productionCapacity, 10);
    });

    test('productionScale equal to capacity is not a violation', () {
      final nodeA = _node(
        id: 'a',
        tier: 1,
        infrastructure: [
          TechnologyInfrastructure.validated(
            id: 'a-infra',
            kind: 'workshop',
            capacity: 10,
            reason: 'r',
          ),
        ],
      );
      final registry = _registry([nodeA]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-a', technologyId: 'a', tick: 5)],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 20,
            technologyId: 'a',
            productionScale: 10,
          ),
        ],
      );
      expect(report.isClean, isTrue);
    });

    test('multiple findings deterministic order by tick then techId', () {
      final nodeA = _node(id: 'a', tier: 1);
      final nodeB = _node(id: 'b', tier: 2, prerequisites: ['a']);
      final nodeC = _node(id: 'c', tier: 1);
      final registry = _registry([nodeA, nodeB, nodeC]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-a', technologyId: 'a', tick: 5)],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-2',
            tick: 20,
            technologyId: 'b',
            productionScale: 1,
          ),
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 10,
            technologyId: 'a',
            productionScale: 1,
          ),
        ],
      );
      expect(report.findings, hasLength(1));
      expect(report.findings[0].sceneId, 'scene-2');
      expect(report.findings[0].technologyId, 'b');
    });

    test('manual exception suppresses finding and records reason', () {
      final nodeA = _node(id: 'a', tier: 1);
      final nodeB = _node(id: 'b', tier: 2, prerequisites: ['a']);
      final registry = _registry([nodeA, nodeB]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-b', technologyId: 'b', tick: 20)],
      );
      final exception = ManualTechnologyException(
        sceneId: 'scene-1',
        technologyId: 'b',
        kind: EraTechnologyWarningKind.missingPrerequisite,
        reason: 'lore: gift from foreign culture',
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
        exceptions: [exception],
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 30,
            technologyId: 'b',
            productionScale: 1,
          ),
        ],
      );
      expect(report.isClean, isTrue);
      expect(report.suppressed, hasLength(1));
      expect(report.suppressed.single.reason, contains('foreign culture'));
    });

    test('unknown technology id emits capability_warning', () {
      final registry = _registry([_node(id: 'a', tier: 1)]);
      final timeline = TechnologyDiscoveryTimeline.validated(events: const []);
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 10,
            technologyId: 'mystery',
            productionScale: 1,
          ),
        ],
      );
      expect(report.findings, hasLength(1));
      expect(
        report.findings.single.kind,
        EraTechnologyWarningKind.unknownTechnology,
      );
    });

    test('reference validates tick non-negative and tech id non-empty', () {
      expect(
        () => SceneTechnologyReference.validated(
          sceneId: 'scene-1',
          tick: -1,
          technologyId: 'a',
          productionScale: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => SceneTechnologyReference.validated(
          sceneId: 'scene-1',
          tick: 10,
          technologyId: '',
          productionScale: 1,
        ),
        throwsArgumentError,
      );
    });

    test('report explain() returns deterministic traceable summary', () {
      final nodeA = _node(id: 'a', tier: 1);
      final nodeB = _node(id: 'b', tier: 2, prerequisites: ['a']);
      final registry = _registry([nodeA, nodeB]);
      final timeline = TechnologyDiscoveryTimeline.validated(
        events: [_discovery(id: 'd-b', technologyId: 'b', tick: 20)],
      );
      final validator = EraTechnologyValidator(
        registry: registry,
        timeline: timeline,
      );
      final report = validator.validate(
        references: [
          SceneTechnologyReference.validated(
            sceneId: 'scene-1',
            tick: 30,
            technologyId: 'b',
            productionScale: 1,
          ),
        ],
      );
      final text = report.explain();
      expect(text, contains('scene-1'));
      expect(text, contains('b'));
      expect(text, contains('missingPrerequisite'));
      expect(text, contains('rev-b'));
    });
  });
}
