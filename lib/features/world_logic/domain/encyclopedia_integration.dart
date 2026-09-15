// Sprint 111.38 — Editor, Graph & Story Integration.
//
// Domain-only contract connecting encyclopedia entries with inline lore
// links, backlinks, story sources, timeline ranges, graph edges, and
// validation hooks.
//
// Consumes without duplicating:
// - LoreEntityRef, InlineLoreLinkParser/Renderer (109.11 story domain) for
//   the `[[Entity]]` syntax and the stable entity identity behind it.
// - LoreLinkClassifier/LoreLinkHealth (109.11) for the resolve/broken/
//   ambiguous vocabulary — the same normalization rules apply.
// - ProjectLoreLinkEditor (109.11) proves retarget keeps the entity id even
//   when the display text changes (stable_links).
// - CrossDomainLinkKind (111.3 shared_encyclopedia_taxonomy.dart) as the
//   edge kind vocabulary in the graph layer.
// - BeliefTimeRange (111.27 encyclopedia_belief_distribution.dart) as the
//   timeline span type; its static compare ordering is reused verbatim.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import 'dart:convert';

import '../../story/domain/inline_lore_links.dart';
import '../../story/domain/lore_backlinks.dart';
import '../../story/domain/lore_link_suggester.dart';
import 'encyclopedia_belief_distribution.dart';
import 'shared_encyclopedia_taxonomy.dart';

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// Registry of catalog entities an encyclopedia link can bind to.
///
/// Wraps the 109.11 [LoreEntityRef] type directly — no parallel entity
/// model — and shares [LoreLinkClassifier.normalize] so link resolution
/// here agrees byte-for-byte with the integrity scanner.
class EncyclopediaLoreCatalog {
  EncyclopediaLoreCatalog.validated({required List<LoreEntityRef> entities})
    : _entities = List.unmodifiable(entities),
      _byNormalized = _index(entities) {
    final ids = <String>{};
    for (final entity in _entities) {
      if (!ids.add(entity.id)) {
        throw StateError('duplicate entity id in catalog: ${entity.id}');
      }
    }
  }

  static Map<String, List<LoreEntityRef>> _index(List<LoreEntityRef> entities) {
    final map = <String, List<LoreEntityRef>>{};
    for (final entity in entities) {
      map
          .putIfAbsent(
            LoreLinkClassifier.normalize(entity.name),
            () => <LoreEntityRef>[],
          )
          .add(entity);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.id.compareTo(b.id));
    }
    return map;
  }

  final List<LoreEntityRef> _entities;
  final Map<String, List<LoreEntityRef>> _byNormalized;

  List<LoreEntityRef> get entities => _entities;

  /// Entity ids present in the catalog, sorted ascending.
  List<String> get entityIds {
    final ids = _entities.map((e) => e.id).toList()..sort();
    return List.unmodifiable(ids);
  }

  LoreEntityRef? byId(String entityId) {
    for (final entity in _entities) {
      if (entity.id == entityId) return entity;
    }
    return null;
  }

  /// Catalog entries whose normalized name matches [rawName].
  ///
  /// Empty when [rawName] normalizes to nothing; multiple entries signal an
  /// ambiguous display text.
  List<LoreEntityRef> refsByName(String rawName) {
    final key = LoreLinkClassifier.normalize(rawName);
    if (key.isEmpty) return const [];
    return List.unmodifiable(_byNormalized[key] ?? const []);
  }
}

/// One `[[Entity]]` occurrence bound to a stable catalog entity id.
///
/// The identity of a link is its [linkId] plus the resolved
/// [targetEntityId]; the display text is cosmetic. Renaming the display text
/// via [renamedTo] (or [StableLoreLink.applyRetarget] on the whole source)
/// never changes the binding, which is what makes editor links stable across
/// entity renames.
class StableLoreLink {
  const StableLoreLink._({
    required this.linkId,
    required this.sourceId,
    required this.displayText,
    required this.health,
    this.targetEntityId,
    this.candidates = const [],
  });

  factory StableLoreLink.validated({
    required String linkId,
    required String sourceId,
    required String displayText,
    required LoreLinkHealth health,
    String? targetEntityId,
    List<LoreEntityRef> candidates = const [],
  }) {
    final id = _requireTrimmed(linkId, 'linkId');
    final src = _requireTrimmed(sourceId, 'sourceId');
    final text = _requireTrimmed(displayText, 'displayText');
    final resolved = targetEntityId == null
        ? null
        : _requireTrimmed(targetEntityId, 'targetEntityId');
    if (health == LoreLinkHealth.resolved && resolved == null) {
      throw ArgumentError('resolved links must carry a targetEntityId');
    }
    if (health != LoreLinkHealth.resolved && resolved != null) {
      throw ArgumentError(
        '${health.name} links must not carry a targetEntityId',
      );
    }
    return StableLoreLink._(
      linkId: id,
      sourceId: src,
      displayText: text,
      health: health,
      targetEntityId: resolved,
      candidates: List.unmodifiable(candidates),
    );
  }

  /// Resolves [text] against [catalog] using the shared 109.11
  /// normalization: one match resolves, none breaks, many stay ambiguous.
  factory StableLoreLink.resolve({
    required String linkId,
    required String sourceId,
    required String displayText,
    required EncyclopediaLoreCatalog catalog,
  }) {
    final refs = catalog.refsByName(displayText);
    final health = switch (refs.length) {
      0 => LoreLinkHealth.broken,
      1 => LoreLinkHealth.resolved,
      _ => LoreLinkHealth.ambiguous,
    };
    return StableLoreLink.validated(
      linkId: linkId,
      sourceId: sourceId,
      displayText: displayText,
      health: health,
      targetEntityId: health == LoreLinkHealth.resolved ? refs.first.id : null,
      candidates: health == LoreLinkHealth.ambiguous ? refs : const [],
    );
  }

  /// Parses one source text into links, one per `[[...]]` segment, in
  /// document order. Escaped literals, plain text, empty, and multi-line
  /// bracket bodies are skipped by the shared 109.11 parser.
  static List<StableLoreLink> parseInline({
    required String sourceId,
    required String text,
    required EncyclopediaLoreCatalog catalog,
  }) {
    final src = _requireTrimmed(sourceId, 'sourceId');
    final segments = const InlineLoreLinkParser().parse(text);
    final links = <StableLoreLink>[];
    var ordinal = 0;
    for (final segment in segments) {
      if (segment is! LoreLinkSegment) continue;
      links.add(
        StableLoreLink.resolve(
          linkId: '$src#$ordinal',
          sourceId: src,
          displayText: segment.displayName,
          catalog: catalog,
        ),
      );
      ordinal++;
    }
    return List.unmodifiable(links);
  }

  /// Applies a rename across [text] via the 109.11 editor and re-parses the
  /// result, carrying each link's previous binding forward by position: a
  /// link that was resolved keeps its entity id even though its display text
  /// changed (the stable-identity contract of inline links).
  static List<StableLoreLink> applyRetarget({
    required String sourceId,
    required String text,
    required EncyclopediaLoreCatalog catalog,
    required String from,
    required String to,
  }) {
    final src = _requireTrimmed(sourceId, 'sourceId');
    final before = parseInline(sourceId: src, text: text, catalog: catalog);
    final updated = const ProjectLoreLinkEditor().retarget(
      text,
      from: from,
      to: to,
    );
    final after = parseInline(sourceId: src, text: updated, catalog: catalog);
    final result = <StableLoreLink>[];
    for (var i = 0; i < after.length; i++) {
      final link = after[i];
      final prior = i < before.length ? before[i] : null;
      if (link.health != LoreLinkHealth.resolved &&
          prior != null &&
          prior.targetEntityId != null) {
        result.add(
          StableLoreLink.validated(
            linkId: link.linkId,
            sourceId: link.sourceId,
            displayText: link.displayText,
            health: LoreLinkHealth.resolved,
            targetEntityId: prior.targetEntityId,
          ),
        );
      } else {
        result.add(link);
      }
    }
    return List.unmodifiable(result);
  }

  final String linkId;
  final String sourceId;

  /// Raw display text inside the brackets (trimmed).
  final String displayText;
  final LoreLinkHealth health;

  /// Stable catalog binding; only non-null when [health] is resolved.
  final String? targetEntityId;

  /// Candidate entities when ambiguous; empty otherwise.
  final List<LoreEntityRef> candidates;

  bool get isResolved => health == LoreLinkHealth.resolved;

  /// Returns the same identity with a new display text; binding and health
  /// are preserved untouched (rename never re-resolves).
  StableLoreLink renamedTo(String newDisplayText) {
    return StableLoreLink.validated(
      linkId: linkId,
      sourceId: sourceId,
      displayText: newDisplayText,
      health: health,
      targetEntityId: targetEntityId,
      candidates: candidates,
    );
  }

  /// Re-resolves this link's display text against a (possibly edited)
  /// catalog. Returns a link with the same linkId/sourceId/displayText.
  StableLoreLink rebind(EncyclopediaLoreCatalog catalog) {
    return StableLoreLink.resolve(
      linkId: linkId,
      sourceId: sourceId,
      displayText: displayText,
      catalog: catalog,
    );
  }

  /// The `[[Entity]]` inline form of this link.
  String renderInline() => '[[$displayText]]';

  Map<String, dynamic> toJson() => {
    'linkId': linkId,
    'sourceId': sourceId,
    'displayText': displayText,
    'health': health.name,
    if (targetEntityId != null) 'targetEntityId': targetEntityId,
    'candidates': [
      for (final c in candidates) {'id': c.id, 'name': c.name, 'kind': c.kind},
    ],
  };

  static StableLoreLink fromJson(Map<String, dynamic> json) {
    final rawHealth = json['health'];
    if (rawHealth is! String) {
      throw ArgumentError('health must be a string');
    }
    final health = LoreLinkHealth.values.firstWhere(
      (h) => h.name == rawHealth,
      orElse: () => throw ArgumentError('unknown health: $rawHealth'),
    );
    final rawCandidates = json['candidates'];
    if (rawCandidates is! List) {
      throw ArgumentError('candidates must be a list');
    }
    return StableLoreLink.validated(
      linkId: json['linkId'] as String,
      sourceId: json['sourceId'] as String,
      displayText: json['displayText'] as String,
      health: health,
      targetEntityId: json['targetEntityId'] as String?,
      candidates: [
        for (final entry in rawCandidates)
          if (entry is Map<String, dynamic>)
            LoreEntityRef(
              id: entry['id'] as String,
              name: entry['name'] as String,
              kind: entry['kind'] as String,
            )
          else
            throw ArgumentError('candidate entries must be objects'),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StableLoreLink &&
          other.linkId == linkId &&
          other.sourceId == sourceId &&
          other.displayText == displayText &&
          other.health == health &&
          other.targetEntityId == targetEntityId &&
          jsonEncode(other.candidates.map((c) => c.id).toList()) ==
              jsonEncode(candidates.map((c) => c.id).toList()));

  @override
  int get hashCode => Object.hash(
    linkId,
    sourceId,
    displayText,
    health,
    targetEntityId,
    Object.hashAll(candidates.map((c) => c.id)),
  );

  @override
  String toString() =>
      'StableLoreLink($linkId: $displayText [$health'
      '${targetEntityId == null ? '' : ' -> $targetEntityId'}])';
}

/// Entity-id -> incoming links index over a set of [StableLoreLink]s.
class EncyclopediaBacklinkIndex {
  factory EncyclopediaBacklinkIndex.fromLinks(List<StableLoreLink> links) {
    final ids = <String>{};
    for (final link in links) {
      if (!ids.add(link.linkId)) {
        throw StateError('duplicate linkId: ${link.linkId}');
      }
    }
    final byEntity = <String, List<StableLoreLink>>{};
    for (final link in links) {
      final target = link.targetEntityId;
      if (target == null) continue;
      byEntity.putIfAbsent(target, () => <StableLoreLink>[]).add(link);
    }
    for (final list in byEntity.values) {
      list.sort((a, b) => a.linkId.compareTo(b.linkId));
    }
    return EncyclopediaBacklinkIndex._(byEntity, links);
  }

  EncyclopediaBacklinkIndex._(
    Map<String, List<StableLoreLink>> byEntity,
    List<StableLoreLink> allLinks,
  ) : _byEntity = {
        for (final entry in byEntity.entries)
          entry.key: List.unmodifiable(entry.value),
      },
      _allLinks = List.unmodifiable(allLinks);

  final Map<String, List<StableLoreLink>> _byEntity;
  final List<StableLoreLink> _allLinks;

  /// Links pointing at [entityId], ordered by linkId.
  List<StableLoreLink> backlinksFor(String entityId) =>
      _byEntity[entityId] ?? const [];

  /// Every entity id that has at least one resolved incoming link, sorted.
  List<String> get entityIds {
    final ids = _byEntity.keys.toList()..sort();
    return List.unmodifiable(ids);
  }

  /// Broken or ambiguous links, ordered by linkId — the editor's "needs
  /// attention" queue.
  List<StableLoreLink> unresolved() {
    final list = <StableLoreLink>[];
    for (final link in _allLinks) {
      if (!link.isResolved) list.add(link);
    }
    list.sort((a, b) => a.linkId.compareTo(b.linkId));
    return List.unmodifiable(list);
  }
}

/// Where a story-side link container lives.
enum StoryLinkSource {
  chapter('chapter'),
  scene('scene'),
  quest('quest'),
  mapRegion('map_region');

  const StoryLinkSource(this.id);

  final String id;
}

/// One story source (chapter/scene/quest/map region) with its inline links.
class StorySourceLinks {
  StorySourceLinks.validated({
    required String sourceId,
    required this.source,
    required String title,
    required List<StableLoreLink> links,
  }) : sourceId = _requireTrimmed(sourceId, 'sourceId'),
       title = _requireTrimmed(title, 'title'),
       links = List.unmodifiable(links) {
    for (final link in links) {
      if (link.sourceId != this.sourceId) {
        throw ArgumentError(
          'link ${link.linkId} belongs to ${link.sourceId}, not $sourceId',
        );
      }
    }
  }

  final String sourceId;
  final StoryLinkSource source;
  final String title;
  final List<StableLoreLink> links;
}

/// Reverse view: story sources that reference each encyclopedia entity.
class StoryLinkIndex {
  StoryLinkIndex.validated({required List<StorySourceLinks> sources})
    : _sources = _sortedUnique(sources) {
    for (final source in _sources) {
      for (final link in source.links) {
        final target = link.targetEntityId;
        if (target == null) continue;
        _byEntity.putIfAbsent(target, () => <String>{}).add(source.sourceId);
      }
    }
  }

  static List<StorySourceLinks> _sortedUnique(List<StorySourceLinks> sources) {
    final seen = <String>{};
    for (final source in sources) {
      if (!seen.add(source.sourceId)) {
        throw StateError('duplicate story source id: ${source.sourceId}');
      }
    }
    final copy = List<StorySourceLinks>.of(sources)
      ..sort((a, b) => a.sourceId.compareTo(b.sourceId));
    return List.unmodifiable(copy);
  }

  final List<StorySourceLinks> _sources;
  final Map<String, Set<String>> _byEntity = {};

  List<String> get sourceIds =>
      List.unmodifiable(_sources.map((s) => s.sourceId));

  StorySourceLinks? sourceOf(String sourceId) {
    for (final source in _sources) {
      if (source.sourceId == sourceId) return source;
    }
    return null;
  }

  String? titleOf(String sourceId) => sourceOf(sourceId)?.title;

  StoryLinkSource? sourceKindOf(String sourceId) => sourceOf(sourceId)?.source;

  /// Resolved entity ids referenced by [sourceId], sorted ascending.
  List<String> entitiesIn(String sourceId) {
    final source = sourceOf(sourceId);
    if (source == null) return const [];
    final ids = <String>{
      for (final link in source.links)
        if (link.targetEntityId != null) link.targetEntityId!,
    }.toList()..sort();
    return List.unmodifiable(ids);
  }

  /// Story sources referencing [entityId], sorted by source id.
  List<String> sourcesFor(String entityId) {
    final ids = (_byEntity[entityId] ?? const <String>{}).toList()..sort();
    return List.unmodifiable(ids);
  }
}

/// Binds an encyclopedia entity to a timeline span.
class EntityTimelineLink {
  EntityTimelineLink.validated({
    required String timelineLinkId,
    required String entityId,
    required this.range,
  }) : timelineLinkId = _requireTrimmed(timelineLinkId, 'timelineLinkId'),
       entityId = _requireTrimmed(entityId, 'entityId');

  final String timelineLinkId;
  final String entityId;

  /// The 111.27 span type reused verbatim (story markers + optional rank).
  final BeliefTimeRange range;

  bool get isOngoing => range.isOngoing;
}

/// Entity -> timeline spans index, ordered by [BeliefTimeRange.compare].
class TimelineLinkIndex {
  TimelineLinkIndex.validated({required List<EntityTimelineLink> links})
    : _links = _sortedUnique(links) {
    for (final link in _links) {
      _byEntity
          .putIfAbsent(link.entityId, () => <EntityTimelineLink>[])
          .add(link);
    }
  }

  static List<EntityTimelineLink> _sortedUnique(
    List<EntityTimelineLink> links,
  ) {
    final ids = <String>{};
    for (final link in links) {
      if (!ids.add(link.timelineLinkId)) {
        throw StateError('duplicate timelineLinkId: ${link.timelineLinkId}');
      }
    }
    final copy = List<EntityTimelineLink>.of(links)
      ..sort((a, b) => BeliefTimeRange.compare(a.range, b.range));
    return List.unmodifiable(copy);
  }

  final List<EntityTimelineLink> _links;
  final Map<String, List<EntityTimelineLink>> _byEntity = {};

  List<EntityTimelineLink> get links => _links;

  /// Spans bound to [entityId] in chronological order (sequence rank first,
  /// unranged links last, then rangeId — the 111.27 ordering).
  List<BeliefTimeRange> rangesFor(String entityId) =>
      List.unmodifiable((_byEntity[entityId] ?? const []).map((l) => l.range));

  /// Links whose span has no end marker, ordered by timelineLinkId.
  List<EntityTimelineLink> get ongoingLinks {
    final list = _links.where((l) => l.isOngoing).toList()
      ..sort((a, b) => a.timelineLinkId.compareTo(b.timelineLinkId));
    return List.unmodifiable(list);
  }

  /// Distinct entity ids that currently hold an ongoing span, sorted.
  List<String> ongoingEntityIds() {
    final ids = <String>{
      for (final link in _links)
        if (link.isOngoing) link.entityId,
    }.toList()..sort();
    return List.unmodifiable(ids);
  }
}

/// One directed, typed edge between two catalog entities.
class EncyclopediaGraphEdge {
  EncyclopediaGraphEdge.validated({
    required String edgeId,
    required String fromId,
    required String toId,
    required this.kind,
  }) : edgeId = _requireTrimmed(edgeId, 'edgeId'),
       fromId = _requireTrimmed(fromId, 'fromId'),
       toId = _requireTrimmed(toId, 'toId') {
    if (fromId == toId) {
      throw ArgumentError('graph edges must not be self-loops: $fromId');
    }
  }

  final String edgeId;
  final String fromId;
  final String toId;

  /// 111.3 vocabulary reused without duplication.
  final CrossDomainLinkKind kind;

  Map<String, dynamic> toJson() => {
    'edgeId': edgeId,
    'fromId': fromId,
    'toId': toId,
    'kind': kind.name,
  };

  static EncyclopediaGraphEdge fromJson(Map<String, dynamic> json) {
    final rawKind = json['kind'];
    if (rawKind is! String) {
      throw ArgumentError('kind must be a string');
    }
    return EncyclopediaGraphEdge.validated(
      edgeId: json['edgeId'] as String,
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      kind: CrossDomainLinkKind.values.firstWhere(
        (k) => k.name == rawKind,
        orElse: () => throw ArgumentError('unknown link kind: $rawKind'),
      ),
    );
  }
}

/// Adjacency graph over encyclopedia entities and cross-domain edges.
class EncyclopediaGraph {
  EncyclopediaGraph._(List<EncyclopediaGraphEdge> edges)
    : _edges = List.unmodifiable(edges) {
    for (final edge in _edges) {
      _out.putIfAbsent(edge.fromId, () => <EncyclopediaGraphEdge>[]).add(edge);
      _in.putIfAbsent(edge.toId, () => <EncyclopediaGraphEdge>[]).add(edge);
      _nodes.add(edge.fromId);
      _nodes.add(edge.toId);
    }
    for (final list in _out.values) {
      list.sort((a, b) => a.edgeId.compareTo(b.edgeId));
    }
    for (final list in _in.values) {
      list.sort((a, b) => a.edgeId.compareTo(b.edgeId));
    }
  }

  factory EncyclopediaGraph.build({
    required List<EncyclopediaGraphEdge> edges,
  }) {
    final ids = <String>{};
    final pairs = <String>{};
    for (final edge in edges) {
      if (!ids.add(edge.edgeId)) {
        throw StateError('duplicate edgeId: ${edge.edgeId}');
      }
      final pair = '${edge.fromId}\u0000${edge.toId}\u0000${edge.kind.name}';
      if (!pairs.add(pair)) {
        throw StateError(
          'duplicate edge ${edge.fromId} -> ${edge.toId} [${edge.kind.name}]',
        );
      }
    }
    final sorted = List<EncyclopediaGraphEdge>.of(edges)
      ..sort((a, b) => a.edgeId.compareTo(b.edgeId));
    return EncyclopediaGraph._(sorted);
  }

  final List<EncyclopediaGraphEdge> _edges;
  final Map<String, List<EncyclopediaGraphEdge>> _out = {};
  final Map<String, List<EncyclopediaGraphEdge>> _in = {};
  final Set<String> _nodes = {};

  List<EncyclopediaGraphEdge> get edges => _edges;

  int get edgeCount => _edges.length;

  List<String> get nodeIds {
    final ids = _nodes.toList()..sort();
    return List.unmodifiable(ids);
  }

  /// Undirected neighbors of [nodeId], sorted.
  List<String> neighbors(String nodeId) {
    final result = <String>{
      for (final edge in _out[nodeId] ?? const <EncyclopediaGraphEdge>[])
        edge.toId,
      for (final edge in _in[nodeId] ?? const <EncyclopediaGraphEdge>[])
        edge.fromId,
    }.toList()..sort();
    return List.unmodifiable(result);
  }

  /// Outgoing targets of [nodeId], sorted.
  List<String> outNeighbors(String nodeId) {
    final result = [
      for (final edge in _out[nodeId] ?? const <EncyclopediaGraphEdge>[])
        edge.toId,
    ]..sort();
    return List.unmodifiable(result);
  }

  /// Incoming sources of [nodeId], sorted.
  List<String> inNeighbors(String nodeId) {
    final result = [
      for (final edge in _in[nodeId] ?? const <EncyclopediaGraphEdge>[])
        edge.fromId,
    ]..sort();
    return List.unmodifiable(result);
  }

  int degree(String nodeId) => neighbors(nodeId).length;

  /// The edge joining [a] and [b] in either direction; ambiguous only in
  /// that direction (first by edgeId when several kinds connect the pair).
  EncyclopediaGraphEdge? edgeBetween(String a, String b) {
    for (final edge in _edges) {
      if (edge.fromId == a && edge.toId == b) return edge;
      if (edge.fromId == b && edge.toId == a) return edge;
    }
    return null;
  }

  /// Entities reachable from [start] following edge direction (transitive,
  /// excluding [start] itself), sorted.
  List<String> reachableFrom(String start) {
    final seen = <String>{};
    final queue = <String>[start];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      for (final next in outNeighbors(current)) {
        if (seen.add(next)) queue.add(next);
      }
    }
    seen.remove(start);
    final list = seen.toList()..sort();
    return List.unmodifiable(list);
  }

  /// True when following edge direction returns to a visited node (white-grey
  /// black DFS, deterministic edge order).
  bool hasDirectedCycle() {
    final color = <String, int>{}; // 0 white, 1 grey, 2 black.
    bool visit(String node) {
      color[node] = 1;
      for (final next in outNeighbors(node)) {
        final state = color[next] ?? 0;
        if (state == 1) return true;
        if (state == 0 && visit(next)) return true;
      }
      color[node] = 2;
      return false;
    }

    for (final node in nodeIds) {
      if ((color[node] ?? 0) == 0 && visit(node)) return true;
    }
    return false;
  }
}

/// Immutable bundle the validation hooks inspect.
class EncyclopediaIntegrationSnapshot {
  EncyclopediaIntegrationSnapshot.validated({
    required this.catalog,
    required List<StableLoreLink> links,
    required this.timeline,
    required this.graph,
  }) : links = List.unmodifiable(_uniqueLinks(links));

  static List<StableLoreLink> _uniqueLinks(List<StableLoreLink> links) {
    final ids = <String>{};
    for (final link in links) {
      if (!ids.add(link.linkId)) {
        throw StateError('duplicate linkId: ${link.linkId}');
      }
    }
    return links;
  }

  final EncyclopediaLoreCatalog catalog;
  final List<StableLoreLink> links;
  final TimelineLinkIndex timeline;
  final EncyclopediaGraph graph;
}

/// One problem found by a validation hook.
class EncyclopediaIntegrationIssue {
  const EncyclopediaIntegrationIssue._({
    required this.issueId,
    required this.hookId,
    required this.index,
    required this.message,
  });

  EncyclopediaIntegrationIssue.validated({
    required String hookId,
    required int index,
    required String message,
  }) : this._(
         issueId: '$hookId#$index',
         hookId: hookId,
         index: index,
         message: _requireTrimmed(message, 'message'),
       );

  final String issueId;
  final String hookId;
  final int index;
  final String message;
}

/// Deterministic report over all hook findings.
class EncyclopediaIntegrationReport {
  EncyclopediaIntegrationReport.of(List<EncyclopediaIntegrationIssue> issues)
    : _issues = List.unmodifiable(
        List<EncyclopediaIntegrationIssue>.of(issues)
          ..sort((a, b) => a.issueId.compareTo(b.issueId)),
      );

  final List<EncyclopediaIntegrationIssue> _issues;

  List<EncyclopediaIntegrationIssue> get issues => _issues;

  bool get hasIssues => _issues.isNotEmpty;

  int get issueCount => _issues.length;

  List<EncyclopediaIntegrationIssue> issuesOf(String hookId) =>
      List.unmodifiable(_issues.where((i) => i.hookId == hookId));

  String describe() {
    if (_issues.isEmpty) return 'No integration warnings.';
    final buffer = StringBuffer('Encyclopedia integration warnings:');
    for (final issue in _issues) {
      buffer.write(' [${issue.issueId}] ${issue.message}');
    }
    return buffer.toString();
  }
}

/// Extension point for integration checks (contradiction detectors, etc.).
///
/// Hooks must be pure over the snapshot; the validator catches any hook that
/// throws and records it as a `hook failed` issue so one broken detector can
/// never hide the others (fail-closed).
abstract class EncyclopediaValidationHook {
  const EncyclopediaValidationHook(this.hookId);

  final String hookId;

  /// Human-readable findings, in deterministic order.
  List<String> inspect(EncyclopediaIntegrationSnapshot snapshot);
}

/// Reports broken and ambiguous inline links.
class BrokenLinkValidationHook extends EncyclopediaValidationHook {
  const BrokenLinkValidationHook() : super('broken-links');

  @override
  List<String> inspect(EncyclopediaIntegrationSnapshot snapshot) {
    final ordered = snapshot.links.toList()
      ..sort((a, b) => a.linkId.compareTo(b.linkId));
    return [
      for (final link in ordered)
        if (link.health == LoreLinkHealth.broken)
          'Link "${link.displayText}" in ${link.sourceId} (${link.linkId}) '
              'matches no catalog entity'
        else if (link.health == LoreLinkHealth.ambiguous)
          'Link "${link.displayText}" in ${link.sourceId} (${link.linkId}) '
              'is ambiguous across '
              '${link.candidates.map((c) => c.id).join(', ')}',
    ];
  }
}

/// Reports timeline links bound to entities missing from the catalog.
class TimelineUnknownEntityHook extends EncyclopediaValidationHook {
  const TimelineUnknownEntityHook() : super('timeline-entities');

  @override
  List<String> inspect(EncyclopediaIntegrationSnapshot snapshot) {
    return [
      for (final link in snapshot.timeline.links)
        if (snapshot.catalog.byId(link.entityId) == null)
          'Timeline link ${link.timelineLinkId} points at unknown entity '
              '"${link.entityId}"',
    ];
  }
}

/// Reports graph edges touching unknown entities and directed cycles.
class GraphIntegrityHook extends EncyclopediaValidationHook {
  const GraphIntegrityHook() : super('graph-integrity');

  @override
  List<String> inspect(EncyclopediaIntegrationSnapshot snapshot) {
    final findings = <String>[];
    for (final edge in snapshot.graph.edges) {
      if (snapshot.catalog.byId(edge.fromId) == null) {
        findings.add(
          'Edge ${edge.edgeId} starts at unknown entity "${edge.fromId}"',
        );
      }
      if (snapshot.catalog.byId(edge.toId) == null) {
        findings.add(
          'Edge ${edge.edgeId} ends at unknown entity "${edge.toId}"',
        );
      }
    }
    if (snapshot.graph.hasDirectedCycle()) {
      findings.add('Graph contains a directed cycle across domains');
    }
    return findings;
  }
}

/// Runs the registered hooks over one snapshot.
class EncyclopediaIntegrationValidator {
  EncyclopediaIntegrationValidator({
    required List<EncyclopediaValidationHook> hooks,
  }) : hooks = List.unmodifiable(_guardUnique(hooks));

  static List<EncyclopediaValidationHook> _guardUnique(
    List<EncyclopediaValidationHook> hooks,
  ) {
    final ids = <String>{};
    for (final hook in hooks) {
      if (!ids.add(hook.hookId)) {
        throw StateError('duplicate hook id: ${hook.hookId}');
      }
    }
    return hooks;
  }

  final List<EncyclopediaValidationHook> hooks;

  EncyclopediaIntegrationReport run(EncyclopediaIntegrationSnapshot snapshot) {
    final issues = <EncyclopediaIntegrationIssue>[];
    for (final hook in hooks) {
      List<String> findings;
      try {
        findings = hook.inspect(snapshot);
      } catch (error) {
        findings = ['hook "${hook.hookId}" failed: $error'];
      }
      for (var i = 0; i < findings.length; i++) {
        issues.add(
          EncyclopediaIntegrationIssue.validated(
            hookId: hook.hookId,
            index: i,
            message: findings[i],
          ),
        );
      }
    }
    return EncyclopediaIntegrationReport.of(issues);
  }
}
