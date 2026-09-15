// Sprint 111.28 - Reveal & Foreshadowing Links.
//
// Domain-only contract connecting clues, prophecies, symbols, and reveal
// points to story structure. RevealPoint, SpoilerLevel, and SpoilerPolicy
// are reused from 111.8 (encyclopedia_spoiler_accessibility.dart) and are
// never duplicated here.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';

/// Canonical clue families used across the encyclopedia links.
enum ClueKind {
  physicalTrace('Bekas fisik'),
  testimony('Kesaksian'),
  document('Dokumen'),
  omen('Pertanda'),
  dream('Mimpi'),
  symbol('Simbol berulang'),
  other('Lainnya');

  const ClueKind(this.label);

  final String label;
}

/// How open a prophecy is to interpretation; weight ladder is strictly
/// increasing so "at least X" filters are meaningful.
enum ProphecyAmbiguity {
  literal(1, 'Harfiah'),
  veiled(2, 'Terselubung'),
  cryptic(3, 'Samar'),
  paradoxical(4, 'Paradoksal');

  const ProphecyAmbiguity(this.weight, this.label);

  final int weight;
  final String label;
}

/// Scope at which a symbol is readable by the audience.
enum SymbolReach {
  personal('Pribadi'),
  cultural('Budaya'),
  universal('Universal');

  const SymbolReach(this.label);

  final String label;
}

String _require(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$field must be non-empty');
  }
  return trimmed;
}

String? _optional(String? value, String field) {
  if (value == null) {
    return null;
  }
  return _require(value, field);
}

void _guardUniqueIds(Iterable<String> ids, String what) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw ArgumentError('duplicate $what id: $id');
    }
  }
}

/// A clue planted in a scene that points at (or teases) a hidden fact.
class ClueLink {
  const ClueLink._({
    required this.clueId,
    required this.kind,
    required this.storyLink,
    required this.description,
    required this.targetFactId,
  });

  static ClueLink validated({
    required String clueId,
    ClueKind kind = ClueKind.other,
    required String storyLink,
    required String description,
    String? targetFactId,
  }) {
    return ClueLink._(
      clueId: _require(clueId, 'clueId'),
      kind: kind,
      storyLink: _require(storyLink, 'storyLink'),
      description: _require(description, 'description'),
      targetFactId: _optional(targetFactId, 'targetFactId'),
    );
  }

  final String clueId;
  final ClueKind kind;

  /// Story location (chapter/scene reference) where the clue appears.
  final String storyLink;
  final String description;

  /// Fact this clue supports; null when the clue is deliberately dangling.
  final String? targetFactId;
}

/// A prophecy text plus its optional binding to the reveal that fulfills it.
class Prophecy {
  const Prophecy._({
    required this.prophecyId,
    required this.text,
    required this.ambiguity,
    required this.utterer,
    required this.timeMarker,
    required this.fulfillmentRevealId,
  });

  static Prophecy validated({
    required String prophecyId,
    required String text,
    ProphecyAmbiguity ambiguity = ProphecyAmbiguity.literal,
    String? utterer,
    String? timeMarker,
    String? fulfillmentRevealId,
  }) {
    return Prophecy._(
      prophecyId: _require(prophecyId, 'prophecyId'),
      text: _require(text, 'text'),
      ambiguity: ambiguity,
      utterer: _optional(utterer, 'utterer'),
      timeMarker: _optional(timeMarker, 'timeMarker'),
      fulfillmentRevealId: _optional(
        fulfillmentRevealId,
        'fulfillmentRevealId',
      ),
    );
  }

  final String prophecyId;
  final String text;
  final ProphecyAmbiguity ambiguity;
  final String? utterer;
  final String? timeMarker;

  /// Reveal point (registered in the same record) that fulfills this line.
  final String? fulfillmentRevealId;

  bool get isFulfilled => fulfillmentRevealId != null;
}

/// A recurring symbol and the story locations where it appears.
class ForeshadowSymbol {
  const ForeshadowSymbol._({
    required this.symbolId,
    required this.name,
    required this.appearances,
    required this.meaning,
    required this.reach,
  });

  static ForeshadowSymbol validated({
    required String symbolId,
    required String name,
    List<String> appearances = const [],
    String? meaning,
    SymbolReach reach = SymbolReach.cultural,
  }) {
    final cleaned = <String>[];
    for (final appearance in appearances) {
      final trimmed = _require(appearance, 'appearance');
      if (!cleaned.contains(trimmed)) {
        cleaned.add(trimmed);
      }
    }
    return ForeshadowSymbol._(
      symbolId: _require(symbolId, 'symbolId'),
      name: _require(name, 'name'),
      appearances: List.unmodifiable(cleaned),
      meaning: _optional(meaning, 'meaning'),
      reach: reach,
    );
  }

  final String symbolId;
  final String name;
  final List<String> appearances;
  final String? meaning;
  final SymbolReach reach;

  bool appearsIn(String storyLink) => appearances.contains(storyLink.trim());
}

/// One hidden fact of a story thread and everything foreshadowing it.
class RevealLinkRecord {
  const RevealLinkRecord._({
    required this.recordId,
    required this.factId,
    required this.hiddenFact,
    required this.clueLinks,
    required this.prophecies,
    required this.symbols,
    required this.revealPoints,
  });

  static RevealLinkRecord validated({
    required String recordId,
    required String factId,
    required String hiddenFact,
    List<ClueLink> clueLinks = const [],
    List<Prophecy> prophecies = const [],
    List<ForeshadowSymbol> symbols = const [],
    List<RevealPoint> revealPoints = const [],
  }) {
    final id = _require(recordId, 'recordId');
    final fact = _require(factId, 'factId');
    final hidden = _require(hiddenFact, 'hiddenFact');
    _guardUniqueIds(clueLinks.map((c) => c.clueId), 'clue');
    _guardUniqueIds(prophecies.map((p) => p.prophecyId), 'prophecy');
    _guardUniqueIds(symbols.map((s) => s.symbolId), 'symbol');
    _guardUniqueIds(revealPoints.map((r) => r.revealId), 'reveal');
    for (final clue in clueLinks) {
      final target = clue.targetFactId;
      if (target != null && target != fact) {
        throw ArgumentError(
          'clue ${clue.clueId} targets unknown fact: $target',
        );
      }
    }
    final revealIds = revealPoints.map((r) => r.revealId).toSet();
    for (final prophecy in prophecies) {
      final fulfillment = prophecy.fulfillmentRevealId;
      if (fulfillment != null && !revealIds.contains(fulfillment)) {
        throw ArgumentError(
          'prophecy ${prophecy.prophecyId} fulfills unknown reveal: '
          '$fulfillment',
        );
      }
    }
    return RevealLinkRecord._(
      recordId: id,
      factId: fact,
      hiddenFact: hidden,
      clueLinks: List.unmodifiable(clueLinks),
      prophecies: List.unmodifiable(prophecies),
      symbols: List.unmodifiable(symbols),
      revealPoints: List.unmodifiable(revealPoints),
    );
  }

  final String recordId;

  /// The fact being foreshadowed; clue targets and spoiler overrides key on
  /// this id.
  final String factId;
  final String hiddenFact;
  final List<ClueLink> clueLinks;
  final List<Prophecy> prophecies;
  final List<ForeshadowSymbol> symbols;
  final List<RevealPoint> revealPoints;

  int get clueCount => clueLinks.length;
  int get prophecyCount => prophecies.length;
  int get symbolCount => symbols.length;
  int get revealCount => revealPoints.length;
  int get revealedCount => revealPoints.where((r) => r.revealed).length;
  int get pendingRevealCount => revealCount - revealedCount;

  List<ClueLink> cluesOfKind(ClueKind kind) {
    final hits = clueLinks.where((c) => c.kind == kind).toList()
      ..sort((a, b) => a.clueId.compareTo(b.clueId));
    return List.unmodifiable(hits);
  }

  List<ClueLink> cluesForStoryLink(String storyLink) {
    final target = storyLink.trim();
    final hits = clueLinks.where((c) => c.storyLink == target).toList()
      ..sort((a, b) => a.clueId.compareTo(b.clueId));
    return List.unmodifiable(hits);
  }

  List<Prophecy> propheciesUnfulfilled() {
    final hits = prophecies.where((p) => !p.isFulfilled).toList()
      ..sort((a, b) => a.prophecyId.compareTo(b.prophecyId));
    return List.unmodifiable(hits);
  }

  List<Prophecy> propheciesAtAmbiguityAtLeast(ProphecyAmbiguity level) {
    final hits =
        prophecies.where((p) => p.ambiguity.weight >= level.weight).toList()
          ..sort((a, b) => a.prophecyId.compareTo(b.prophecyId));
    return List.unmodifiable(hits);
  }

  List<ForeshadowSymbol> symbolsAppearingIn(String storyLink) {
    final target = storyLink.trim();
    final hits = symbols.where((s) => s.appearsIn(target)).toList()
      ..sort((a, b) => a.symbolId.compareTo(b.symbolId));
    return List.unmodifiable(hits);
  }

  /// Union of every story location touched by a clue, symbol appearance,
  /// or reveal point, sorted for deterministic rendering.
  List<String> get linkedStoryLinks {
    final links = <String>{
      ...clueLinks.map((c) => c.storyLink),
      ...symbols.expand((s) => s.appearances),
      ...revealPoints.map((r) => r.storyLink),
    };
    final sorted = links.toList()..sort();
    return List.unmodifiable(sorted);
  }

  /// Pending reveals ordered by story tick (earliest first, ties by id).
  List<RevealPoint> get pendingRevealPoints {
    final pending = revealPoints.where((r) => !r.revealed).toList()
      ..sort((a, b) {
        final byTick = a.tick.compareTo(b.tick);
        return byTick != 0 ? byTick : a.revealId.compareTo(b.revealId);
      });
    return List.unmodifiable(pending);
  }

  int? get firstPendingRevealTick {
    final pending = pendingRevealPoints;
    return pending.isEmpty ? null : pending.first.tick;
  }

  ClueLink? clueFor(String clueId) {
    final target = clueId.trim();
    for (final clue in clueLinks) {
      if (clue.clueId == target) {
        return clue;
      }
    }
    return null;
  }

  RevealPoint? revealFor(String revealId) {
    final target = revealId.trim();
    for (final point in revealPoints) {
      if (point.revealId == target) {
        return point;
      }
    }
    return null;
  }

  /// Immutable copy with [revealId] marked revealed; rejects unknown ids.
  RevealLinkRecord withRevealMarked(String revealId) {
    final target = _require(revealId, 'revealId');
    if (revealFor(target) == null) {
      throw ArgumentError('unknown revealId: $target');
    }
    return RevealLinkRecord._(
      recordId: recordId,
      factId: factId,
      hiddenFact: hiddenFact,
      clueLinks: clueLinks,
      prophecies: prophecies,
      symbols: symbols,
      revealPoints: revealPoints
          .map((r) => r.revealId == target ? r.markRevealed() : r)
          .toList(),
    );
  }

  /// A thread earns the label once it plants at least one clue and gates at
  /// least one reveal point.
  bool get isFullyForeshadowed => clueCount > 0 && revealCount > 0;

  /// spoiler_preview: safe rendering of the hidden fact for [policy]. The
  /// record key for override lookup is [factId] (111.8 override semantics).
  String spoilerPreview(SpoilerPolicy policy) {
    return policy.allows(SpoilerLevel.ending, recordKey: factId)
        ? hiddenFact
        : '[Fakta tersembunyi: TERSEMBUNYI]';
  }

  /// spoiler_preview state of one reveal point under [policy]:
  /// REVEALED when it already fired, VISIBLE when the audience may see it,
  /// MASKED otherwise.
  String revealPreview(SpoilerPolicy policy, String revealId) {
    final point = revealFor(revealId);
    if (point == null) {
      throw ArgumentError('unknown revealId: ${revealId.trim()}');
    }
    if (point.revealed) {
      return 'REVEALED';
    }
    return policy.allows(point.level, recordKey: factId) ? 'VISIBLE' : 'MASKED';
  }
}

/// Deterministic filter over reveal-link records. Runtime validation lives
/// in the constructor body, so the constructor is intentionally NOT const.
class ForeshadowQuery {
  ForeshadowQuery({
    this.kind,
    this.storyLink,
    this.minAmbiguity,
    this.pendingOnly = false,
  }) {
    if (storyLink != null && storyLink!.trim().isEmpty) {
      throw ArgumentError('storyLink must be non-empty when given');
    }
  }

  final ClueKind? kind;
  final String? storyLink;
  final ProphecyAmbiguity? minAmbiguity;
  final bool pendingOnly;

  bool get isEmpty =>
      kind == null && storyLink == null && minAmbiguity == null && !pendingOnly;

  bool matches(RevealLinkRecord record) {
    if (kind != null && !record.clueLinks.any((c) => c.kind == kind)) {
      return false;
    }
    if (storyLink != null) {
      if (!record.linkedStoryLinks.contains(storyLink!.trim())) {
        return false;
      }
    }
    if (minAmbiguity != null) {
      if (record.propheciesAtAmbiguityAtLeast(minAmbiguity!).isEmpty) {
        return false;
      }
    }
    if (pendingOnly && record.pendingRevealCount == 0) {
      return false;
    }
    return true;
  }

  String describe() {
    final parts = <String>[
      if (kind != null) 'kind=${kind!.name}',
      if (storyLink != null) 'storyLink=${storyLink!.trim()}',
      if (minAmbiguity != null) 'minAmbiguity=${minAmbiguity!.name}',
      if (pendingOnly) 'pendingOnly',
    ];
    return parts.isEmpty ? 'match-all' : parts.join(' ');
  }
}

/// Registry of reveal-link records with cross-record aggregate indices.
class ForeshadowCatalog {
  const ForeshadowCatalog._(this._records);

  static ForeshadowCatalog empty() => const ForeshadowCatalog._([]);

  static ForeshadowCatalog withRecords(List<RevealLinkRecord> records) {
    _guardUniqueIds(records.map((r) => r.recordId), 'record');
    final sorted = [...records]
      ..sort((a, b) => a.recordId.compareTo(b.recordId));
    return ForeshadowCatalog._(List.unmodifiable(sorted));
  }

  final List<RevealLinkRecord> _records;

  List<RevealLinkRecord> get records => _records;
  List<String> get recordIds =>
      List.unmodifiable(_records.map((r) => r.recordId));

  int get totalClueCount => _records.fold(0, (sum, r) => sum + r.clueCount);
  int get totalProphecyCount =>
      _records.fold(0, (sum, r) => sum + r.prophecyCount);
  int get totalSymbolCount => _records.fold(0, (sum, r) => sum + r.symbolCount);
  int get totalPendingRevealCount =>
      _records.fold(0, (sum, r) => sum + r.pendingRevealCount);

  RevealLinkRecord? recordFor(String recordId) {
    final target = recordId.trim();
    for (final record in _records) {
      if (record.recordId == target) {
        return record;
      }
    }
    return null;
  }

  /// Records holding at least one prophecy with no fulfillment binding.
  List<String> get recordIdsWithUnboundProphecy {
    final hits = _records
        .where((r) => r.propheciesUnfulfilled().isNotEmpty)
        .map((r) => r.recordId)
        .toList();
    return List.unmodifiable(hits);
  }

  /// Records touching [storyLink] through any link family, sorted by id.
  List<String> recordIdsForStoryLink(String storyLink) {
    final target = storyLink.trim();
    final hits = _records
        .where((r) => r.linkedStoryLinks.contains(target))
        .map((r) => r.recordId)
        .toList();
    return List.unmodifiable(hits);
  }

  List<RevealLinkRecord> query(ForeshadowQuery q) {
    final hits = _records.where(q.matches).toList();
    return List.unmodifiable(hits);
  }
}
