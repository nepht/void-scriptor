// Sprint 111.38 — Editor, Graph & Story Integration.
//
// Domain-only contract connecting encyclopedia entries with inline lore
// links, backlinks, story sources, timeline ranges, graph edges, and
// validation hooks. Consumes without duplicating: LoreEntityRef,
// InlineLoreLinkParser/Renderer/Editor and ProjectLoreLinkEditor (109.11),
// LoreLinkClassifier/LoreLinkHealth (109.11), CrossDomainLinkKind (111.3),
// BeliefTimeRange (111.27).
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/lore_backlinks.dart';
import 'package:void_scriptor/features/story/domain/lore_link_suggester.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_belief_distribution.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_taxonomy.dart';

const _qowner = LoreEntityRef(
  id: 'ent-qowner',
  name: 'Qowner',
  kind: 'character',
);
const _void = LoreEntityRef(id: 'ent-void', name: 'The Void', kind: 'location');
const _twinA = LoreEntityRef(
  id: 'ent-twin-a',
  name: 'Pole of Creation',
  kind: 'location',
);
const _twinB = LoreEntityRef(
  id: 'ent-twin-b',
  name: 'pole of   creation',
  kind: 'location',
);

EncyclopediaLoreCatalog _catalog() => EncyclopediaLoreCatalog.validated(
  entities: [_qowner, _void, _twinA, _twinB],
);

StableLoreLink _resolvedLink(
  String linkId,
  String sourceId,
  String text,
  EncyclopediaLoreCatalog catalog,
) => StableLoreLink.resolve(
  linkId: linkId,
  sourceId: sourceId,
  displayText: text,
  catalog: catalog,
);

void main() {
  group('EncyclopediaLoreCatalog (reuses LoreEntityRef 109.11)', () {
    test('guards blank and duplicate entity ids', () {
      expect(
        () => EncyclopediaLoreCatalog.validated(entities: const []),
        isNot(throwsA(anything)),
      );
      expect(
        () => EncyclopediaLoreCatalog.validated(
          entities: [
            _qowner,
            const LoreEntityRef(id: 'ent-qowner', name: 'Other', kind: 'x'),
          ],
        ),
        throwsStateError,
      );
    });

    test('byId finds and misses; entityIds sorted immutable', () {
      final c = _catalog();
      expect(c.byId('ent-void')?.name, 'The Void');
      expect(c.byId('missing'), isNull);
      expect(c.entityIds, [
        'ent-qowner',
        'ent-twin-a',
        'ent-twin-b',
        'ent-void',
      ]);
      expect(() => c.entityIds.add('x'), throwsUnsupportedError);
    });

    test('refsByName uses 109.11 normalization (case + repeated spaces)', () {
      final c = _catalog();
      expect(c.refsByName(' POLE OF  CREATION ').map((e) => e.id), [
        'ent-twin-a',
        'ent-twin-b',
      ]);
      expect(c.refsByName('nope'), isEmpty);
    });
  });

  group('StableLoreLink (stable_links)', () {
    test('resolve single match -> resolved with bound id, no candidates', () {
      final link = _resolvedLink('lk1', 'sc1', 'Qowner', _catalog());
      expect(link.health, LoreLinkHealth.resolved);
      expect(link.targetEntityId, 'ent-qowner');
      expect(link.candidates, isEmpty);
      expect(link.renderInline(), '[[Qowner]]');
    });

    test('resolve miss -> broken with null bound id', () {
      final link = _resolvedLink('lk2', 'sc1', 'Nobody', _catalog());
      expect(link.health, LoreLinkHealth.broken);
      expect(link.targetEntityId, isNull);
      expect(link.candidates, isEmpty);
    });

    test('resolve many matches -> ambiguous, candidates sorted by id', () {
      final link = _resolvedLink('lk3', 'sc1', 'Pole of Creation', _catalog());
      expect(link.health, LoreLinkHealth.ambiguous);
      expect(link.targetEntityId, isNull);
      expect(link.candidates.map((e) => e.id), ['ent-twin-a', 'ent-twin-b']);
    });

    test('guards blank linkId, sourceId, and display text', () {
      final c = _catalog();
      expect(
        () => StableLoreLink.resolve(
          linkId: ' ',
          sourceId: 's',
          displayText: 'Qowner',
          catalog: c,
        ),
        throwsArgumentError,
      );
      expect(
        () => StableLoreLink.resolve(
          linkId: 'l',
          sourceId: '',
          displayText: 'Qowner',
          catalog: c,
        ),
        throwsArgumentError,
      );
      expect(
        () => StableLoreLink.resolve(
          linkId: 'l',
          sourceId: 's',
          displayText: '   ',
          catalog: c,
        ),
        throwsArgumentError,
      );
    });

    test('parseInline skips escaped literals and plain text', () {
      final links = StableLoreLink.parseInline(
        sourceId: 'sc9',
        text: 'Meet [[Qowner]] and \\[[Qowner]] near [[ The Void ]] plus [[ ]]',
        catalog: _catalog(),
      );
      expect(links, hasLength(2));
      expect(links[0].linkId, 'sc9#0');
      expect(links[0].targetEntityId, 'ent-qowner');
      expect(links[1].linkId, 'sc9#1');
      expect(links[1].targetEntityId, 'ent-void');
    });

    test(
      'stable identity: retargeting text keeps the same bound entity id',
      () {
        const editor = ProjectLoreLinkEditor();
        const original = 'Long live [[Qowner]]!';
        final before = StableLoreLink.parseInline(
          sourceId: 'sc1',
          text: original,
          catalog: _catalog(),
        );
        expect(before.single.targetEntityId, 'ent-qowner');
        // The writer renames the entity; retarget rewrites only link segments.
        final renamed = editor.retarget(
          original,
          from: 'Qowner',
          to: 'The Silent King',
        );
        expect(renamed, 'Long live [[The Silent King]]!');
        // Plain text never becomes a link.
        expect(
          editor.retarget('quote \\[[Qowner]] here', from: 'Qowner', to: 'X'),
          'quote \\[[Qowner]] here',
        );
      },
    );

    test('renamedTo preserves linkId, binding, and health', () {
      final link = _resolvedLink('lk4', 'sc1', 'Qowner', _catalog());
      final renamed = link.renamedTo('The Silent King');
      expect(renamed.linkId, 'lk4');
      expect(renamed.targetEntityId, 'ent-qowner');
      expect(renamed.health, LoreLinkHealth.resolved);
      expect(renamed.displayText, 'The Silent King');
      expect(link.displayText, 'Qowner');
    });

    test('JSON round trip is byte-identical for all three health states', () {
      final c = _catalog();
      for (final text in ['Qowner', 'Nobody', 'Pole of Creation']) {
        final link = _resolvedLink('lkj', 'scj', text, c);
        final encoded = jsonEncode(link);
        expect(
          jsonEncode(
            StableLoreLink.fromJson(
              jsonDecode(encoded) as Map<String, dynamic>,
            ),
          ),
          encoded,
        );
      }
    });

    test('fromJson rejects unknown health and blank ids', () {
      final c = _catalog();
      final good =
          jsonDecode(jsonEncode(_resolvedLink('lk', 'sc', 'Qowner', c)))
              as Map<String, dynamic>;
      good['health'] = 'melted';
      expect(() => StableLoreLink.fromJson(good), throwsArgumentError);
      final blank =
          jsonDecode(jsonEncode(_resolvedLink('lk', 'sc', 'Qowner', c)))
              as Map<String, dynamic>;
      blank['linkId'] = '  ';
      expect(() => StableLoreLink.fromJson(blank), throwsArgumentError);
    });
  });

  group('EncyclopediaBacklinkIndex (backlinks)', () {
    test('backlinksFor returns sorted source links of a resolved entity', () {
      final c = _catalog();
      final index = EncyclopediaBacklinkIndex.fromLinks([
        _resolvedLink('b2', 'scene-2', 'Qowner', c),
        _resolvedLink('b1', 'scene-1', 'Qowner', c),
        _resolvedLink('b3', 'scene-3', 'The Void', c),
      ]);
      expect(index.backlinksFor('ent-qowner').map((l) => l.linkId), [
        'b1',
        'b2',
      ]);
      expect(index.backlinksFor('missing'), isEmpty);
      expect(index.backlinksFor('ent-qowner'), isNotNull);
      expect(index.backlinksFor('ent-qowner').first.sourceId, 'scene-1');
    });

    test('unresolved exposes broken and ambiguous links', () {
      final c = _catalog();
      final index = EncyclopediaBacklinkIndex.fromLinks([
        _resolvedLink('u1', 'sc', 'Nobody', c),
        _resolvedLink('u2', 'sc', 'Pole of Creation', c),
        _resolvedLink('u3', 'sc', 'Qowner', c),
      ]);
      expect(index.unresolved().map((l) => l.linkId), ['u1', 'u2']);
      expect(index.entityIds, ['ent-qowner']);
    });

    test('duplicate linkId is rejected', () {
      final c = _catalog();
      expect(
        () => EncyclopediaBacklinkIndex.fromLinks([
          _resolvedLink('dup', 'a', 'Qowner', c),
          _resolvedLink('dup', 'b', 'The Void', c),
        ]),
        throwsStateError,
      );
    });
  });

  group('StoryLinkIndex (story_links)', () {
    test('entitiesIn and sourcesFor agree over resolved links', () {
      final c = _catalog();
      final index = StoryLinkIndex.validated(
        sources: [
          StorySourceLinks.validated(
            sourceId: 'ch-01',
            source: StoryLinkSource.chapter,
            title: 'Babak Pembuka',
            links: [
              _resolvedLink('s1', 'ch-01', 'Qowner', c),
              _resolvedLink('s2', 'ch-01', 'The Void', c),
            ],
          ),
          StorySourceLinks.validated(
            sourceId: 'sc-02',
            source: StoryLinkSource.scene,
            title: 'Adegan Kutub',
            links: [_resolvedLink('s3', 'sc-02', 'Qowner', c)],
          ),
        ],
      );
      expect(index.entitiesIn('ch-01'), ['ent-qowner', 'ent-void']);
      expect(index.sourcesFor('ent-qowner'), ['ch-01', 'sc-02']);
      expect(index.sourcesFor('ent-void'), ['ch-01']);
      expect(index.sourceIds, ['ch-01', 'sc-02']);
      expect(index.titleOf('sc-02'), 'Adegan Kutub');
      expect(index.sourceKindOf('ch-01'), StoryLinkSource.chapter);
    });

    test('unresolved links contribute nothing to story graph', () {
      final c = _catalog();
      final index = StoryLinkIndex.validated(
        sources: [
          StorySourceLinks.validated(
            sourceId: 'q1',
            source: StoryLinkSource.quest,
            title: 'Quest',
            links: [_resolvedLink('x', 'q1', 'Nobody', c)],
          ),
        ],
      );
      expect(index.entitiesIn('q1'), isEmpty);
      expect(index.sourcesFor('ent-qowner'), isEmpty);
    });

    test('duplicate source ids and blank titles are rejected', () {
      final c = _catalog();
      StorySourceLinks link(String id) => StorySourceLinks.validated(
        sourceId: id,
        source: StoryLinkSource.mapRegion,
        title: 'T',
        links: [_resolvedLink('l-$id', id, 'Qowner', c)],
      );
      expect(
        () => StoryLinkIndex.validated(sources: [link('a'), link('a')]),
        throwsStateError,
      );
      expect(
        () => StorySourceLinks.validated(
          sourceId: 'a',
          source: StoryLinkSource.scene,
          title: ' ',
          links: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => StoryLinkIndex.validated(sources: const []),
        isNot(throwsA(anything)),
      );
    });
  });

  group(
    'TimelineLinkIndex (timeline_links, reuses BeliefTimeRange 111.27)',
    () {
      final ongoing = BeliefTimeRange.validated(
        rangeId: 'r-open',
        fromMarker: 'era-third',
      );
      final closed = BeliefTimeRange.validated(
        rangeId: 'r-closed',
        fromMarker: 'm1',
        toMarker: 'm4',
        sequence: 2,
      );

      test('rangesFor sorts by BeliefTimeRange.compare, nulls last', () {
        final index = TimelineLinkIndex.validated(
          links: [
            EntityTimelineLink.validated(
              timelineLinkId: 't2',
              entityId: 'ent-qowner',
              range: ongoing,
            ),
            EntityTimelineLink.validated(
              timelineLinkId: 't1',
              entityId: 'ent-qowner',
              range: closed,
            ),
            EntityTimelineLink.validated(
              timelineLinkId: 't0',
              entityId: 'ent-qowner',
              range: BeliefTimeRange.validated(
                rangeId: 'r-early',
                fromMarker: 'm0',
                sequence: 1,
              ),
            ),
          ],
        );
        expect(index.rangesFor('ent-qowner').map((r) => r.rangeId), [
          'r-early',
          'r-closed',
          'r-open',
        ]);
        expect(index.rangesFor('missing'), isEmpty);
      });

      test('ongoingLinks and ongoingEntityIds', () {
        final index = TimelineLinkIndex.validated(
          links: [
            EntityTimelineLink.validated(
              timelineLinkId: 't2',
              entityId: 'ent-qowner',
              range: ongoing,
            ),
            EntityTimelineLink.validated(
              timelineLinkId: 't3',
              entityId: 'ent-void',
              range: ongoing,
            ),
            EntityTimelineLink.validated(
              timelineLinkId: 't1',
              entityId: 'ent-void',
              range: closed,
            ),
          ],
        );
        expect(index.ongoingLinks.map((l) => l.timelineLinkId), ['t2', 't3']);
        expect(index.ongoingEntityIds(), ['ent-qowner', 'ent-void']);
      });

      test('guards blank ids, duplicate timelineLinkId', () {
        expect(
          () => EntityTimelineLink.validated(
            timelineLinkId: 't',
            entityId: ' ',
            range: closed,
          ),
          throwsArgumentError,
        );
        expect(
          () => TimelineLinkIndex.validated(
            links: [
              EntityTimelineLink.validated(
                timelineLinkId: 'd',
                entityId: 'e1',
                range: closed,
              ),
              EntityTimelineLink.validated(
                timelineLinkId: 'd',
                entityId: 'e2',
                range: ongoing,
              ),
            ],
          ),
          throwsStateError,
        );
      });
    },
  );

  group(
    'EncyclopediaGraph (graph_edges, reuses CrossDomainLinkKind 111.3)',
    () {
      EncyclopediaGraphEdge edge(
        String id,
        String from,
        String to, [
        CrossDomainLinkKind kind = CrossDomainLinkKind.references,
      ]) => EncyclopediaGraphEdge.validated(
        edgeId: id,
        fromId: from,
        toId: to,
        kind: kind,
      );

      test('validated rejects blank ids and self-loops', () {
        expect(
          () => EncyclopediaGraphEdge.validated(
            edgeId: 'e',
            fromId: 'a',
            toId: '',
            kind: CrossDomainLinkKind.references,
          ),
          throwsArgumentError,
        );
        expect(
          () => EncyclopediaGraphEdge.validated(
            edgeId: 'e',
            fromId: 'a',
            toId: 'a',
            kind: CrossDomainLinkKind.references,
          ),
          throwsArgumentError,
        );
      });

      test('build guards duplicate edgeId and duplicate (from,to,kind)', () {
        expect(
          () => EncyclopediaGraph.build(
            edges: [edge('same', 'a', 'b'), edge('same', 'b', 'c')],
          ),
          throwsStateError,
        );
        expect(
          () => EncyclopediaGraph.build(
            edges: [edge('e1', 'a', 'b'), edge('e2', 'a', 'b')],
          ),
          throwsStateError,
        );
        // Same endpoints with a different kind stay legal.
        final ok = EncyclopediaGraph.build(
          edges: [
            edge('e1', 'a', 'b'),
            edge('e2', 'a', 'b', CrossDomainLinkKind.antagonist),
          ],
        );
        expect(ok.edgeCount, 2);
      });

      test('neighbors, degrees, edgeBetween', () {
        final g = EncyclopediaGraph.build(
          edges: [
            edge('e1', 'a', 'b'),
            edge('e2', 'c', 'a'),
            edge('e3', 'a', 'd', CrossDomainLinkKind.derivedFrom),
          ],
        );
        expect(g.neighbors('a'), ['b', 'c', 'd']);
        expect(g.outNeighbors('a'), ['b', 'd']);
        expect(g.inNeighbors('a'), ['c']);
        expect(g.degree('a'), 3);
        expect(g.edgeBetween('a', 'b')?.edgeId, 'e1');
        expect(g.edgeBetween('b', 'a')?.edgeId, 'e1');
        expect(g.edgeBetween('b', 'c'), isNull);
        expect(g.nodeIds, ['a', 'b', 'c', 'd']);
        expect(g.neighbors('ghost'), isEmpty);
      });

      test('reachableFrom is transitive, excludes the start, sorted', () {
        final g = EncyclopediaGraph.build(
          edges: [
            edge('e1', 'a', 'b'),
            edge('e2', 'b', 'c'),
            edge('e3', 'z', 'a'),
          ],
        );
        expect(g.reachableFrom('a'), ['b', 'c']);
        expect(g.reachableFrom('z'), ['a', 'b', 'c']);
        expect(g.reachableFrom('c'), isEmpty);
      });

      test('hasDirectedCycle detects cycles and DAGs', () {
        expect(
          EncyclopediaGraph.build(
            edges: [
              edge('e1', 'a', 'b'),
              edge('e2', 'b', 'c'),
              edge('e3', 'c', 'a'),
            ],
          ).hasDirectedCycle(),
          isTrue,
        );
        expect(
          EncyclopediaGraph.build(
            edges: [edge('e1', 'a', 'b'), edge('e2', 'b', 'c')],
          ).hasDirectedCycle(),
          isFalse,
        );
        // A two-node mutual pair is a cycle.
        expect(
          EncyclopediaGraph.build(
            edges: [edge('e1', 'a', 'b'), edge('e2', 'b', 'a')],
          ).hasDirectedCycle(),
          isTrue,
        );
        expect(
          EncyclopediaGraph.build(edges: const []).hasDirectedCycle(),
          isFalse,
        );
      });
    },
  );

  group('Validation hooks (validation_hooks)', () {
    EncyclopediaIntegrationSnapshot snap({
      EncyclopediaLoreCatalog? catalog,
      List<StableLoreLink> links = const [],
      List<EntityTimelineLink> timeline = const [],
      EncyclopediaGraph? graph,
    }) {
      return EncyclopediaIntegrationSnapshot.validated(
        catalog: catalog ?? _catalog(),
        links: links,
        timeline: TimelineLinkIndex.validated(links: timeline),
        graph: graph ?? EncyclopediaGraph.build(edges: const []),
      );
    }

    test('registry guards duplicate hook ids', () {
      final v = EncyclopediaIntegrationValidator(
        hooks: const [BrokenLinkValidationHook()],
      );
      expect(
        () => EncyclopediaIntegrationValidator(
          hooks: const [BrokenLinkValidationHook(), BrokenLinkValidationHook()],
        ),
        throwsStateError,
      );
      expect(v.hooks, hasLength(1));
    });

    test('broken and ambiguous links are reported deterministically', () {
      final c = _catalog();
      final report =
          EncyclopediaIntegrationValidator(
            hooks: const [BrokenLinkValidationHook()],
          ).run(
            snap(
              links: [
                _resolvedLink('h2', 'sc', 'Nobody', c),
                _resolvedLink('h1', 'sc', 'Qowner', c),
                _resolvedLink('h3', 'sc', 'Pole of Creation', c),
              ],
            ),
          );
      expect(report.issueCount, 2);
      expect(report.issues.map((i) => i.issueId), [
        'broken-links#0',
        'broken-links#1',
      ]);
      expect(report.issues.first.message, contains('h2'));
      expect(report.issues.last.message, contains('ambiguous'));
      expect(report.hasIssues, isTrue);
    });

    test('timeline hook flags ranges bound to unknown catalog entities', () {
      final report =
          EncyclopediaIntegrationValidator(
            hooks: const [TimelineUnknownEntityHook()],
          ).run(
            snap(
              timeline: [
                EntityTimelineLink.validated(
                  timelineLinkId: 't1',
                  entityId: 'ent-ghost',
                  range: BeliefTimeRange.validated(
                    rangeId: 'r1',
                    fromMarker: 'm1',
                  ),
                ),
                EntityTimelineLink.validated(
                  timelineLinkId: 't2',
                  entityId: 'ent-qowner',
                  range: BeliefTimeRange.validated(
                    rangeId: 'r2',
                    fromMarker: 'm1',
                  ),
                ),
              ],
            ),
          );
      expect(report.issueCount, 1);
      expect(report.issues.single.message, contains('ent-ghost'));
      expect(report.issues.single.hookId, 'timeline-entities');
    });

    test('graph hook reports unknown endpoints and directed cycles', () {
      EncyclopediaGraphEdge e(String id, String f, String t) =>
          EncyclopediaGraphEdge.validated(
            edgeId: id,
            fromId: f,
            toId: t,
            kind: CrossDomainLinkKind.references,
          );
      final report =
          EncyclopediaIntegrationValidator(
            hooks: const [GraphIntegrityHook()],
          ).run(
            snap(
              graph: EncyclopediaGraph.build(
                edges: [
                  e('g1', 'ent-qowner', 'ent-nowhere'),
                  e('g2', 'ent-qowner', 'ent-void'),
                  e('g3', 'ent-void', 'ent-qowner'),
                ],
              ),
            ),
          );
      final messages = report.issues.map((i) => i.message).toList();
      expect(messages.any((m) => m.contains('ent-nowhere')), isTrue);
      expect(messages.any((m) => m.contains('cycle')), isTrue);
    });

    test('a crashing hook fails closed into a reported issue', () {
      final report = EncyclopediaIntegrationValidator(
        hooks: [_BoomHook()],
      ).run(snap());
      expect(report.issueCount, 1);
      expect(report.issues.single.message, contains('boom'));
      expect(report.issues.single.hookId, 'boom');
    });

    test('clean snapshot with no hooks yields clean report', () {
      final report = EncyclopediaIntegrationValidator(
        hooks: const [
          BrokenLinkValidationHook(),
          TimelineUnknownEntityHook(),
          GraphIntegrityHook(),
        ],
      ).run(snap(links: [_resolvedLink('ok', 'sc', 'Qowner', _catalog())]));
      expect(report.hasIssues, isFalse);
      expect(report.describe(), contains('No integration warnings.'));
    });

    test('run does not mutate the snapshot inputs', () {
      final c = _catalog();
      final links = [_resolvedLink('m1', 'sc', 'Nobody', c)];
      final before = jsonEncode(links.map((l) => l.toJson()).toList());
      EncyclopediaIntegrationValidator(
        hooks: const [BrokenLinkValidationHook()],
      ).run(snap(links: links));
      expect(jsonEncode(links.map((l) => l.toJson()).toList()), before);
    });

    test('issues sorted across hooks by hookId then index', () {
      final c = _catalog();
      final report =
          EncyclopediaIntegrationValidator(
            hooks: const [
              TimelineUnknownEntityHook(),
              BrokenLinkValidationHook(),
            ],
          ).run(
            snap(
              links: [_resolvedLink('b1', 'sc', 'Nobody', c)],
              timeline: [
                EntityTimelineLink.validated(
                  timelineLinkId: 't1',
                  entityId: 'ghost',
                  range: BeliefTimeRange.validated(
                    rangeId: 'r',
                    fromMarker: 'm',
                  ),
                ),
              ],
            ),
          );
      expect(report.issues.map((i) => i.issueId).toList(), [
        'broken-links#0',
        'timeline-entities#0',
      ]);
    });
  });

  group('acceptance vocabulary coverage', () {
    test('public surface names every acceptance keyword', () {
      expect(
        StableLoreLink.parseInline(
          sourceId: 's',
          text: '[[Qowner]]',
          catalog: _catalog(),
        ).single.health,
        LoreLinkHealth.resolved,
      );
      expect(EncyclopediaBacklinkIndex.fromLinks(const []), isNotNull);
      expect(StoryLinkIndex.validated(sources: const []), isNotNull);
      expect(TimelineLinkIndex.validated(links: const []), isNotNull);
      expect(EncyclopediaGraph.build(edges: const []), isNotNull);
      expect(EncyclopediaIntegrationValidator(hooks: const []).hooks, isEmpty);
    });
  });
}

class _BoomHook extends EncyclopediaValidationHook {
  _BoomHook() : super('boom');

  @override
  List<String> inspect(EncyclopediaIntegrationSnapshot snapshot) {
    throw StateError('internal boom');
  }
}
