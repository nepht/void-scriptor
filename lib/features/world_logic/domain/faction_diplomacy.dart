import 'package:void_scriptor/features/world_logic/domain/faction_relationship_matrix.dart';

/// Public, secret, and perceived diplomacy stance for a single directed pair.
class DiplomacyStance {
  final FactionRelationKind kind;
  final double intensity;
  final String reason;

  const DiplomacyStance({
    required this.kind,
    required this.intensity,
    required this.reason,
  });
}

enum DiplomacyPerspective { writer, reader }

/// Holds public + secret + perceived relations between two factions,
/// with temporal range and knowledge access.
class FactionDiplomacyEntry {
  final String id;
  final String fromFactionId;
  final String toFactionId;

  final FactionRelationKind publicKind;
  final double publicIntensity;

  final FactionRelationKind secretKind;
  final double secretIntensity;

  final int validFrom;
  final int? validUntil;
  final List<String> secretKnownBy;
  final Map<String, DiplomacyStance> perceivedBy;

  final String sourceRevision;
  final String sourceReason;

  const FactionDiplomacyEntry._({
    required this.id,
    required this.fromFactionId,
    required this.toFactionId,
    required this.publicKind,
    required this.publicIntensity,
    required this.secretKind,
    required this.secretIntensity,
    required this.validFrom,
    required this.validUntil,
    required this.secretKnownBy,
    required this.perceivedBy,
    required this.sourceRevision,
    required this.sourceReason,
  });

  factory FactionDiplomacyEntry.validated({
    required String id,
    required String fromFactionId,
    required String toFactionId,
    required FactionRelationKind publicKind,
    required double publicIntensity,
    required FactionRelationKind secretKind,
    required double secretIntensity,
    required int validFrom,
    required int? validUntil,
    required List<String> secretKnownBy,
    Map<String, DiplomacyStance> perceivedBy = const {},
    required String sourceRevision,
    required String sourceReason,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id must be non-empty');
    }
    if (fromFactionId.isEmpty) {
      throw ArgumentError.value(
        fromFactionId,
        'fromFactionId',
        'must be non-empty',
      );
    }
    if (toFactionId.isEmpty) {
      throw ArgumentError.value(
        toFactionId,
        'toFactionId',
        'must be non-empty',
      );
    }
    if (validFrom < 0) {
      throw ArgumentError.value(validFrom, 'validFrom', 'must be >= 0');
    }
    final end = validUntil;
    if (end != null && end < validFrom) {
      throw ArgumentError.value(end, 'validUntil', 'must be >= validFrom');
    }
    if (publicIntensity < 0.0 || publicIntensity > 10.0) {
      throw ArgumentError.value(
        publicIntensity,
        'publicIntensity',
        'must be in [0,10]',
      );
    }
    if (secretIntensity < 0.0 || secretIntensity > 10.0) {
      throw ArgumentError.value(
        secretIntensity,
        'secretIntensity',
        'must be in [0,10]',
      );
    }
    if (sourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'must be non-empty',
      );
    }
    if (sourceReason.isEmpty) {
      throw ArgumentError.value(
        sourceReason,
        'sourceReason',
        'must be non-empty',
      );
    }
    return FactionDiplomacyEntry._(
      id: id,
      fromFactionId: fromFactionId,
      toFactionId: toFactionId,
      publicKind: publicKind,
      publicIntensity: publicIntensity,
      secretKind: secretKind,
      secretIntensity: secretIntensity,
      validFrom: validFrom,
      validUntil: validUntil,
      secretKnownBy: List.unmodifiable(secretKnownBy),
      perceivedBy: Map.unmodifiable(perceivedBy),
      sourceRevision: sourceRevision,
      sourceReason: sourceReason,
    );
  }

  bool isActiveAt(int tick) {
    if (tick < validFrom) return false;
    final end = validUntil;
    if (end != null && tick > end) return false;
    return true;
  }

  DiplomacyStance publicStance({required String forFaction}) {
    return DiplomacyStance(
      kind: publicKind,
      intensity: publicIntensity,
      reason: sourceReason,
    );
  }

  DiplomacyStance? secretStance() {
    return DiplomacyStance(
      kind: secretKind,
      intensity: secretIntensity,
      reason: sourceReason,
    );
  }

  bool canObserverSeeSecret(String observer) {
    if (secretKnownBy.contains(observer)) return true;
    if (observer == fromFactionId || observer == toFactionId) {
      // Faction parties implicitly know their own secret stances.
      return true;
    }
    return false;
  }

  DiplomacyStance? perceivedStance({
    required String forObserver,
    DiplomacyPerspective perspective = DiplomacyPerspective.writer,
  }) {
    // Reader perspective never sees secret kinds, even via perceivedBy map.
    if (perspective == DiplomacyPerspective.reader) {
      final explicit = perceivedBy[forObserver];
      if (explicit != null) return explicit;
      return publicStance(forFaction: forObserver);
    }

    // Writer perspective.
    if (canObserverSeeSecret(forObserver)) {
      return secretStance();
    }
    final explicit = perceivedBy[forObserver];
    if (explicit != null) return explicit;
    return publicStance(forFaction: forObserver);
  }
}

/// View that filters entries by tick + perspective (writer vs reader).
class DiplomacyView {
  final int tick;
  final DiplomacyPerspective perspective;

  const DiplomacyView._({required this.tick, required this.perspective});

  factory DiplomacyView.writer({int tick = 0}) {
    return const DiplomacyView._(
      tick: 0,
      perspective: DiplomacyPerspective.writer,
    ).._setTick(tick);
  }

  factory DiplomacyView.reader({required int tick}) {
    return DiplomacyView._(
      tick: tick,
      perspective: DiplomacyPerspective.reader,
    );
  }

  void _setTick(int t) {
    // No-op: writer view ignores tick (always sees history); kept for parity.
  }

  bool get isWriter => perspective == DiplomacyPerspective.writer;

  List<FactionDiplomacyEntry> visibleStances(
    List<FactionDiplomacyEntry> entries, {
    required String forObserver,
  }) {
    return entries
        .where((e) {
          if (!isWriter && !e.isActiveAt(tick)) return false;
          return true;
        })
        .toList(growable: false);
  }
}
