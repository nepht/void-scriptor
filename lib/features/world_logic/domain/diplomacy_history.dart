// Sprint 110.25 - Treaty, Conflict & Diplomacy History. Domain-only contract.
library;

enum TreatyKind { nonAggression, alliance, tradePact, peace, surrender }

class Treaty {
  const Treaty._({
    required this.id,
    required this.factionAId,
    required this.factionBId,
    required this.kind,
    required this.validFrom,
    required this.validUntil,
    required this.sourceRevision,
    required this.sourceReason,
  });
  factory Treaty.validated({
    required String id,
    required String factionAId,
    required String factionBId,
    required TreatyKind kind,
    required int validFrom,
    int? validUntil,
    required String sourceRevision,
    required String sourceReason,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, "id", "id cannot be empty");
    if (factionAId.isEmpty) {
      throw ArgumentError.value(factionAId, "factionAId", "cannot be empty");
    }
    if (factionBId.isEmpty) {
      throw ArgumentError.value(factionBId, "factionBId", "cannot be empty");
    }
    if (factionAId == factionBId) {
      throw ArgumentError("Treaty requires two distinct factions");
    }
    if (validFrom < 0) {
      throw ArgumentError.value(validFrom, "validFrom", "cannot be negative");
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError("validUntil must be >= validFrom");
    }
    if (sourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        "sourceRevision",
        "cannot be empty",
      );
    }
    if (sourceReason.isEmpty) {
      throw ArgumentError.value(
        sourceReason,
        "sourceReason",
        "cannot be empty",
      );
    }
    return Treaty._(
      id: id,
      factionAId: factionAId,
      factionBId: factionBId,
      kind: kind,
      validFrom: validFrom,
      validUntil: validUntil,
      sourceRevision: sourceRevision,
      sourceReason: sourceReason,
    );
  }
  final String id;
  final String factionAId;
  final String factionBId;
  final TreatyKind kind;
  final int validFrom;
  final int? validUntil;
  final String sourceRevision;
  final String sourceReason;
  bool isActiveAt(int tick) {
    if (tick < validFrom) return false;
    if (validUntil != null && tick > validUntil!) return false;
    return true;
  }
}

enum ConflictKind { skirmish, war, siege, raid, civilWar }

class Conflict {
  const Conflict._({
    required this.id,
    required this.sideAFactionId,
    required this.sideBFactionId,
    required this.kind,
    required this.validFrom,
    required this.validUntil,
    required this.sourceRevision,
    required this.sourceReason,
  });
  factory Conflict.validated({
    required String id,
    required String sideAFactionId,
    required String sideBFactionId,
    required ConflictKind kind,
    required int validFrom,
    int? validUntil,
    required String sourceRevision,
    required String sourceReason,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, "id", "id cannot be empty");
    if (sideAFactionId.isEmpty || sideBFactionId.isEmpty) {
      throw ArgumentError("Conflict requires two factions with non-empty ids");
    }
    if (sideAFactionId == sideBFactionId) {
      throw ArgumentError("Conflict requires two distinct factions");
    }
    if (validFrom < 0) {
      throw ArgumentError.value(validFrom, "validFrom", "cannot be negative");
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError("validUntil must be >= validFrom");
    }
    if (sourceRevision.isEmpty || sourceReason.isEmpty) {
      throw ArgumentError("sourceRevision and sourceReason cannot be empty");
    }
    return Conflict._(
      id: id,
      sideAFactionId: sideAFactionId,
      sideBFactionId: sideBFactionId,
      kind: kind,
      validFrom: validFrom,
      validUntil: validUntil,
      sourceRevision: sourceRevision,
      sourceReason: sourceReason,
    );
  }
  final String id;
  final String sideAFactionId;
  final String sideBFactionId;
  final ConflictKind kind;
  final int validFrom;
  final int? validUntil;
  final String sourceRevision;
  final String sourceReason;
  bool isActiveAt(int tick) {
    if (tick < validFrom) return false;
    if (validUntil != null && tick > validUntil!) return false;
    return true;
  }
}

class TradeLink {
  const TradeLink._({
    required this.id,
    required this.fromFactionId,
    required this.toFactionId,
    required this.commodity,
    required this.rate,
    required this.validFrom,
    required this.validUntil,
    required this.sourceRevision,
    required this.sourceReason,
  });
  factory TradeLink.validated({
    required String id,
    required String fromFactionId,
    required String toFactionId,
    required String commodity,
    required int rate,
    required int validFrom,
    int? validUntil,
    required String sourceRevision,
    required String sourceReason,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, "id", "id cannot be empty");
    if (fromFactionId.isEmpty || toFactionId.isEmpty) {
      throw ArgumentError("Trade link requires non-empty faction ids");
    }
    if (fromFactionId == toFactionId) {
      throw ArgumentError("Trade link requires two distinct factions");
    }
    if (commodity.isEmpty) {
      throw ArgumentError.value(commodity, "commodity", "cannot be empty");
    }
    if (rate <= 0) throw ArgumentError.value(rate, "rate", "must be positive");
    if (validFrom < 0) {
      throw ArgumentError.value(validFrom, "validFrom", "cannot be negative");
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError("validUntil must be >= validFrom");
    }
    if (sourceRevision.isEmpty || sourceReason.isEmpty) {
      throw ArgumentError("sourceRevision and sourceReason cannot be empty");
    }
    return TradeLink._(
      id: id,
      fromFactionId: fromFactionId,
      toFactionId: toFactionId,
      commodity: commodity,
      rate: rate,
      validFrom: validFrom,
      validUntil: validUntil,
      sourceRevision: sourceRevision,
      sourceReason: sourceReason,
    );
  }
  final String id;
  final String fromFactionId;
  final String toFactionId;
  final String commodity;
  final int rate;
  final int validFrom;
  final int? validUntil;
  final String sourceRevision;
  final String sourceReason;
  bool isActiveAt(int tick) {
    if (tick < validFrom) return false;
    if (validUntil != null && tick > validUntil!) return false;
    return true;
  }
}

class DiplomacyChangeEvent {
  const DiplomacyChangeEvent._({
    required this.id,
    required this.tick,
    required this.treatyId,
    required this.summary,
    required this.sourceRevision,
    required this.sourceReason,
  });
  factory DiplomacyChangeEvent.validated({
    required String id,
    required int tick,
    required String treatyId,
    required String summary,
    required String sourceRevision,
    required String sourceReason,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, "id", "id cannot be empty");
    if (tick < 0) throw ArgumentError.value(tick, "tick", "cannot be negative");
    if (treatyId.isEmpty) {
      throw ArgumentError.value(treatyId, "treatyId", "cannot be empty");
    }
    if (summary.isEmpty) {
      throw ArgumentError.value(summary, "summary", "cannot be empty");
    }
    if (sourceRevision.isEmpty || sourceReason.isEmpty) {
      throw ArgumentError("sourceRevision and sourceReason cannot be empty");
    }
    return DiplomacyChangeEvent._(
      id: id,
      tick: tick,
      treatyId: treatyId,
      summary: summary,
      sourceRevision: sourceRevision,
      sourceReason: sourceReason,
    );
  }
  final String id;
  final int tick;
  final String treatyId;
  final String summary;
  final String sourceRevision;
  final String sourceReason;
}

class DiplomacyHistory {
  const DiplomacyHistory._({
    required this.treaties,
    required this.conflicts,
    required this.tradeLinks,
    required this.changeEvents,
  });
  factory DiplomacyHistory.validated({
    required List<Treaty> treaties,
    required List<Conflict> conflicts,
    required List<TradeLink> tradeLinks,
    required List<DiplomacyChangeEvent> changeEvents,
  }) {
    for (final t in treaties) {
      if (t.id.isEmpty) {
        throw ArgumentError.value("", "treaty.id", "cannot be empty");
      }
    }
    for (final c in conflicts) {
      if (c.id.isEmpty) {
        throw ArgumentError.value("", "conflict.id", "cannot be empty");
      }
    }
    for (final l in tradeLinks) {
      if (l.id.isEmpty) {
        throw ArgumentError.value("", "tradeLink.id", "cannot be empty");
      }
    }
    for (final e in changeEvents) {
      if (e.id.isEmpty) {
        throw ArgumentError.value("", "event.id", "cannot be empty");
      }
    }
    return DiplomacyHistory._(
      treaties: List.unmodifiable(treaties),
      conflicts: List.unmodifiable(conflicts),
      tradeLinks: List.unmodifiable(tradeLinks),
      changeEvents: List.unmodifiable(changeEvents),
    );
  }
  final List<Treaty> treaties;
  final List<Conflict> conflicts;
  final List<TradeLink> tradeLinks;
  final List<DiplomacyChangeEvent> changeEvents;
}

class DiplomacyTimelineEntry {
  const DiplomacyTimelineEntry({required this.event, required this.treaty});
  final DiplomacyChangeEvent event;
  final Treaty? treaty;
  String get summary => event.summary;
  int get tick => event.tick;
}

class DiplomacyTimelineView {
  const DiplomacyTimelineView._({
    required this.entries,
    required this.explainNote,
  });
  factory DiplomacyTimelineView.of({
    required DiplomacyHistory history,
    required int fromTick,
    required int toTick,
  }) {
    final sorted = [...history.changeEvents]
      ..sort((a, b) => a.tick.compareTo(b.tick));
    final filtered = <DiplomacyTimelineEntry>[];
    var dropped = 0;
    for (final ev in sorted) {
      if (ev.tick < fromTick || ev.tick > toTick) {
        dropped += 1;
        continue;
      }
      Treaty? treaty;
      for (final t in history.treaties) {
        if (t.id == ev.treatyId) {
          treaty = t;
          break;
        }
      }
      filtered.add(DiplomacyTimelineEntry(event: ev, treaty: treaty));
    }
    final note = StringBuffer("timeline_view shows ");
    note.write(filtered.length);
    note.write(" of ");
    note.write(sorted.length);
    note.write(" change events within range [");
    note.write(fromTick);
    note.write(", ");
    note.write(toTick);
    note.write("B ");
    note.write(dropped);
    note.write(" events filtered out");
    return DiplomacyTimelineView._(
      entries: List.unmodifiable(filtered),
      explainNote: note.toString(),
    );
  }
  final List<DiplomacyTimelineEntry> entries;
  final String explainNote;
}
