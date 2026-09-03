/// Sprint 110.20 - Territorial Control State (Temporal World Map).
///
/// Domain-only model describing who controls which location during
/// which validity range. Records combine a stable [controllerId] with
/// a [locationId] and a [ValidityRange] borrowed from the genealogy
/// contract (110.17). The [TerritorialControlRegistry] resolves the
/// active controller at an as-of tick, rejects overlapping ranges for
/// the same (location, controller) pair, and exposes a layered
/// history ordered by [ValidityRange.fromTick]. Provenance is attached
/// via [ResultOrigin] from the derived result contract (110.7).
///
/// Deterministic, no persistence, UI, wall clock, locale, or random
/// input. Intended for the F11 temporal world map starting at
/// Sprint 110.20.
library;

import "derived_result_provenance.dart";
import "genealogy_relationship_rules.dart" show ValidityRange;

/// Thrown when a territorial control record would overlap an existing
/// record for the same (location, controller) pair.
class TerritorialControlOverlap implements Exception {
  const TerritorialControlOverlap({
    required this.controllerId,
    required this.locationId,
    required this.conflictingFromTick,
    required this.conflictingToTick,
  });

  final String controllerId;
  final String locationId;
  final int conflictingFromTick;
  final int? conflictingToTick;

  @override
  String toString() =>
      "TerritorialControlOverlap(controller=\$controllerId, location=\$locationId, "
      "conflicting=[\$conflictingFromTick..\$conflictingToTick])";
}

/// Immutable record expressing that [controllerId] controls
/// [locationId] during [validity].
class TerritorialControl {
  const TerritorialControl({
    required this.controllerId,
    required this.locationId,
    required this.validity,
    this.provenance,
  });

  final String controllerId;
  final String locationId;
  final ValidityRange validity;

  /// Optional origin (110.7) attached when the active record at a
  /// given tick is queried through a derivation pipeline.
  final ResultOrigin? provenance;

  /// True if this record is active at [tick] according to its
  /// [ValidityRange]. Mirrors [ValidityRange.contains] without the
  /// as-of escape hatch so deterministic callers can rely on the
  /// simple interval semantics.
  bool activeAt(int tick) {
    if (tick < validity.fromTick) return false;
    final upper = validity.toTick;
    if (upper == null) return true;
    return tick <= upper;
  }
}

/// Registry of [TerritorialControl] records. Lookups resolve the
/// active controller for a location at an as-of tick; insertions are
/// validated against overlapping ranges.
class TerritorialControlRegistry {
  TerritorialControlRegistry(Iterable<TerritorialControl> seed)
    : _records = List<TerritorialControl>.of(seed);

  final List<TerritorialControl> _records;

  List<TerritorialControl> get records =>
      List<TerritorialControl>.unmodifiable(_records);

  /// Adds [record] or replaces the existing record for the same
  /// (controller, location) pair. Throws [TerritorialControlOverlap]
  /// when the new record would conflict with a *different* (controller,
  /// location) record on the same location.
  void upsert(TerritorialControl record) {
    // Validate against every other record; allow replacing the prior
    // record for the same (controller, location) pair, but reject
    // overlap with any *different* (controller, location) pair on the
    // same location.
    for (final existing in List.of(_records)) {
      final sameKey =
          existing.controllerId == record.controllerId &&
          existing.locationId == record.locationId;
      if (sameKey) continue;
      if (existing.locationId != record.locationId) continue;
      if (_overlaps(existing.validity, record.validity)) {
        throw TerritorialControlOverlap(
          controllerId: record.controllerId,
          locationId: record.locationId,
          conflictingFromTick: existing.validity.fromTick,
          conflictingToTick: existing.validity.toTick,
        );
      }
    }
    _records
      ..removeWhere(
        (r) =>
            r.controllerId == record.controllerId &&
            r.locationId == record.locationId,
      )
      ..add(record);
  }

  static bool _overlaps(ValidityRange a, ValidityRange b) {
    const far = 1 << 62;
    final hiA = a.toTick ?? far;
    final hiB = b.toTick ?? far;
    final lo = a.fromTick > b.fromTick ? a.fromTick : b.fromTick;
    final hi = hiA < hiB ? hiA : hiB;
    return lo <= hi;
  }

  /// Returns the active [controllerId] for [locationId] at [atTick],
  /// or `null` when the location has no record that covers the tick.
  String? controllerOf(String locationId, {required int atTick}) {
    final rec = activeRecord(locationId, atTick: atTick);
    return rec?.controllerId;
  }

  /// Returns the active [TerritorialControl] for [locationId] at
  /// [atTick], or `null` if no record covers the tick.
  TerritorialControl? activeRecord(String locationId, {required int atTick}) {
    TerritorialControl? best;
    int? bestFrom;
    for (final rec in _records) {
      if (rec.locationId != locationId) continue;
      if (!rec.activeAt(atTick)) continue;
      if (bestFrom == null || rec.validity.fromTick > bestFrom) {
        bestFrom = rec.validity.fromTick;
        best = rec;
      }
    }
    return best;
  }

  /// Returns every record for [locationId] ordered by
  /// [ValidityRange.fromTick] ascending. Used for the historical
  /// layer view of F11.
  List<TerritorialControl> historyOf(String locationId) {
    final result = _records.where((r) => r.locationId == locationId).toList()
      ..sort((a, b) => a.validity.fromTick.compareTo(b.validity.fromTick));
    return List<TerritorialControl>.unmodifiable(result);
  }

  /// Attaches [origin] to the active record of [locationId] at
  /// [atTick]. Silently no-ops when no record is active. Returns the
  /// updated record, or `null` if nothing matched.
  TerritorialControl? attachProvenance(
    String locationId, {
    required int atTick,
    required ResultOrigin origin,
  }) {
    final active = activeRecord(locationId, atTick: atTick);
    if (active == null) return null;
    final updated = TerritorialControl(
      controllerId: active.controllerId,
      locationId: active.locationId,
      validity: active.validity,
      provenance: origin,
    );
    upsert(updated);
    return updated;
  }
}
