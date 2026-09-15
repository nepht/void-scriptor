// Sprint 111.25 - Public Belief vs Historical Truth.
//
// Domain-only contract separating what the public believes (one shared
// narrative plus per-group variants) from the canon historical truth behind
// it (claims with bounded confidence and source links), while a spoiler
// policy decides when the truth may be revealed without leaking secrets.
//
// Consumes GroupStance from 111.24 (encyclopedia_myth) and SpoilerLevel /
// SpoilerPolicy from 111.8 (encyclopedia_spoiler_accessibility).
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_myth.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

String? _optionalTrimmed(String? value, String fieldName) {
  final trimmed = value?.trim();
  if (trimmed != null && trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty when provided');
  }
  return trimmed;
}

void _requireUniqueIds(
  Iterable<String> ids,
  String collectionName,
  String idField,
) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) {
      throw ArgumentError('Duplicate $idField in $collectionName: $id');
    }
  }
}

/// Coarse reading of a truth-claim confidence in [0, 1]. Bands let the UI
/// say "how sure are we" without exposing the raw number everywhere.
enum TruthConfidenceBand {
  unattested('Unattested'),
  rumorLike('Rumor-like'),
  supported('Supported'),
  attested('Attested'),
  certain('Certain');

  const TruthConfidenceBand(this.label);

  final String label;

  /// Deterministic band mapping: [0, 0.2) unattested, [0.2, 0.5)
  /// rumor-like, [0.5, 0.8) supported, [0.8, 1) attested, 1 certain.
  static TruthConfidenceBand bandFor(double confidence) {
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'confidence must be in [0, 1]',
      );
    }
    if (confidence >= 1) return TruthConfidenceBand.certain;
    if (confidence >= 0.8) return TruthConfidenceBand.attested;
    if (confidence >= 0.5) return TruthConfidenceBand.supported;
    if (confidence >= 0.2) return TruthConfidenceBand.rumorLike;
    return TruthConfidenceBand.unattested;
  }
}

/// A source link backing a historical truth claim (chronicle, oral record,
/// artifact catalogue entry, ...).
class BeliefSourceLink {
  const BeliefSourceLink._({
    required this.sourceId,
    required this.kind,
    this.note,
  });

  factory BeliefSourceLink.validated({
    required String sourceId,
    required String kind,
    String? note,
  }) {
    return BeliefSourceLink._(
      sourceId: _requireTrimmed(sourceId, 'sourceId'),
      kind: _requireTrimmed(kind, 'kind'),
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String sourceId;
  final String kind;
  final String? note;
}

/// The narrative a myth tells in public — what most people repeat.
class PublicNarrative {
  const PublicNarrative._({
    required this.narrativeId,
    required this.text,
    required this.spoilerLevel,
  });

  factory PublicNarrative.validated({
    required String narrativeId,
    required String text,
    SpoilerLevel spoilerLevel = SpoilerLevel.safe,
  }) {
    return PublicNarrative._(
      narrativeId: _requireTrimmed(narrativeId, 'narrativeId'),
      text: _requireTrimmed(text, 'text'),
      spoilerLevel: spoilerLevel,
    );
  }

  final String narrativeId;
  final String text;
  final SpoilerLevel spoilerLevel;
}

/// One community's version of the public narrative.
class GroupBeliefVariant {
  const GroupBeliefVariant._({
    required this.groupId,
    required this.text,
    required this.stance,
    this.region,
  });

  factory GroupBeliefVariant.validated({
    required String groupId,
    required String text,
    GroupStance stance = GroupStance.devout,
    String? region,
  }) {
    return GroupBeliefVariant._(
      groupId: _requireTrimmed(groupId, 'groupId'),
      text: _requireTrimmed(text, 'text'),
      stance: stance,
      region: _optionalTrimmed(region, 'region'),
    );
  }

  final String groupId;
  final String text;
  final GroupStance stance;
  final String? region;

  String get stanceLabel => stance.label;
}

/// A canon-level statement of what most likely actually happened, kept
/// separate from the public narrative and carrying its own confidence.
class HistoricalTruthClaim {
  const HistoricalTruthClaim._({
    required this.truthId,
    required this.statement,
    required this.confidence,
    this.note,
  });

  factory HistoricalTruthClaim.validated({
    required String truthId,
    required String statement,
    required double confidence,
    String? note,
  }) {
    if (confidence < 0 || confidence > 1) {
      throw ArgumentError.value(
        confidence,
        'confidence',
        'confidence must be in [0, 1]',
      );
    }
    return HistoricalTruthClaim._(
      truthId: _requireTrimmed(truthId, 'truthId'),
      statement: _requireTrimmed(statement, 'statement'),
      confidence: confidence,
      note: _optionalTrimmed(note, 'note'),
    );
  }

  final String truthId;
  final String statement;
  final double confidence;
  final String? note;

  TruthConfidenceBand get confidenceBand =>
      TruthConfidenceBand.bandFor(confidence);
}

/// One myth's belief/truth split: what is told publicly, how groups vary,
/// what the canon record considers true, and which sources back that.
class BeliefTruthRecord {
  const BeliefTruthRecord._({
    required this.mythId,
    required this.publicNarrative,
    required this.groupVariants,
    required this.truths,
    required this.sourceLinks,
    required this.spoilerLevel,
  });

  factory BeliefTruthRecord.validated({
    required String mythId,
    required PublicNarrative? publicNarrative,
    List<GroupBeliefVariant> groupVariants = const [],
    List<HistoricalTruthClaim> truths = const [],
    List<BeliefSourceLink> sourceLinks = const [],
    SpoilerLevel spoilerLevel = SpoilerLevel.safe,
  }) {
    _requireUniqueIds(
      groupVariants.map((v) => v.groupId),
      'groupVariants',
      'groupId',
    );
    _requireUniqueIds(truths.map((t) => t.truthId), 'truths', 'truthId');
    _requireUniqueIds(
      sourceLinks.map((s) => s.sourceId),
      'sourceLinks',
      'sourceId',
    );
    if (publicNarrative == null) {
      throw ArgumentError('publicNarrative must be provided');
    }
    return BeliefTruthRecord._(
      mythId: _requireTrimmed(mythId, 'mythId'),
      publicNarrative: publicNarrative,
      groupVariants: List.unmodifiable(groupVariants),
      truths: List.unmodifiable(truths),
      sourceLinks: List.unmodifiable(sourceLinks),
      spoilerLevel: spoilerLevel,
    );
  }

  final String mythId;
  final PublicNarrative publicNarrative;
  final List<GroupBeliefVariant> groupVariants;
  final List<HistoricalTruthClaim> truths;
  final List<BeliefSourceLink> sourceLinks;

  /// Spoiler tier of the truth content itself; the public narrative stays
  /// visible, the truths are gated by this level.
  final SpoilerLevel spoilerLevel;

  int get variantCount => groupVariants.length;
  int get truthCount => truths.length;
  int get sourceLinkCount => sourceLinks.length;

  /// Group ids of the belief variants, sorted ascending, immutable.
  List<String> get groupIds =>
      List.unmodifiable((groupVariants.map((v) => v.groupId).toList()..sort()));

  /// Truth claim ids, sorted ascending, immutable.
  List<String> get truthIds =>
      List.unmodifiable((truths.map((t) => t.truthId).toList()..sort()));

  /// Source ids backing the truth, sorted ascending, immutable.
  List<String> get sourceIds =>
      List.unmodifiable((sourceLinks.map((s) => s.sourceId).toList()..sort()));

  /// Mean confidence across truth claims; 0 when there are none.
  double get averageConfidence {
    if (truths.isEmpty) return 0;
    final sum = truths.fold<double>(0, (acc, t) => acc + t.confidence);
    return sum / truths.length;
  }

  /// Highest-confidence truth; ties break on truthId ascending. Null when
  /// no truth claims exist.
  HistoricalTruthClaim? get strongestTruth {
    if (truths.isEmpty) return null;
    final sorted = truths.toList()
      ..sort((a, b) {
        final byConfidence = b.confidence.compareTo(a.confidence);
        if (byConfidence != 0) return byConfidence;
        return a.truthId.compareTo(b.truthId);
      });
    return sorted.first;
  }

  GroupBeliefVariant? groupVariantFor(String groupId) {
    final trimmed = groupId.trim();
    for (final variant in groupVariants) {
      if (variant.groupId == trimmed) return variant;
    }
    return null;
  }

  /// Whether the truth content may be shown to an audience under [policy].
  /// A per-record override always beats the policy default.
  bool isTruthSafeFor(SpoilerPolicy policy) =>
      policy.allows(spoilerLevel, recordKey: mythId);
}

/// Read-only catalogue of belief/truth records keyed by myth id.
class BeliefTruthCatalog {
  const BeliefTruthCatalog._(this._records);

  factory BeliefTruthCatalog.empty() =>
      const BeliefTruthCatalog._(<BeliefTruthRecord>[]);

  factory BeliefTruthCatalog.withRecords(List<BeliefTruthRecord> records) {
    _requireUniqueIds(records.map((r) => r.mythId), 'records', 'mythId');
    final sorted = records.toList()
      ..sort((a, b) => a.mythId.compareTo(b.mythId));
    return BeliefTruthCatalog._(List.unmodifiable(sorted));
  }

  final List<BeliefTruthRecord> _records;

  List<BeliefTruthRecord> get records => _records;

  List<String> get mythIds => List.unmodifiable(_records.map((r) => r.mythId));

  BeliefTruthRecord? recordFor(String mythId) {
    final trimmed = mythId.trim();
    for (final record in _records) {
      if (record.mythId == trimmed) return record;
    }
    return null;
  }

  /// Myth ids whose truth content is still above the audience threshold of
  /// [policy] — revealing them would spoil. Sorted ascending.
  List<String> secretsPendingReveal(SpoilerPolicy policy) => List.unmodifiable(
    _records
        .where((r) => !r.isTruthSafeFor(policy))
        .map((r) => r.mythId)
        .toList()
      ..sort(),
  );

  /// Myth ids whose strongest truth claim falls into [band], sorted.
  List<String> mythIdsWithBand(TruthConfidenceBand band) => List.unmodifiable(
    _records
        .where((r) => r.strongestTruth?.confidenceBand == band)
        .map((r) => r.mythId)
        .toList()
      ..sort(),
  );

  /// Myth ids holding a belief variant for [groupId], sorted ascending.
  List<String> mythIdsForGroup(String groupId) {
    final trimmed = groupId.trim();
    return List.unmodifiable(
      _records
          .where((r) => r.groupVariantFor(trimmed) != null)
          .map((r) => r.mythId)
          .toList()
        ..sort(),
    );
  }

  /// Mean of every truth claim's confidence across the catalog; null when
  /// no truth claims exist at all.
  double? get meanConfidence {
    var count = 0;
    var sum = 0.0;
    for (final record in _records) {
      for (final truth in record.truths) {
        sum += truth.confidence;
        count++;
      }
    }
    if (count == 0) return null;
    return sum / count;
  }
}
