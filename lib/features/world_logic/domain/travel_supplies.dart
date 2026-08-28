/// Sprint 110.11 - Travel Supplies.
//
//
// Domain-only supply system: per-kind consumption policy per travel mode,
// loadout (bundle + party size), and a deterministic planner that consumes
// supplies along a sequence of route segments while a travel mode is in use.
// No persistence, UI, hidden wall clock, locale, or random input. Calculations
// are deterministic and unit-based.
library;

import "route_network.dart";
import "travel_mode_profiles.dart";

/// Kind of supply carried for travel.
enum SupplyKind { rations, water, fodder }

/// One batch of a single supply kind, with explicit quantity and unit.
class SupplyBundle {
  SupplyBundle({
    required this.kind,
    required this.quantity,
    required this.unit,
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        "quantity",
        "supply bundle quantity must be > 0",
      );
    }
    if (unit.isEmpty) {
      throw ArgumentError.value(
        unit,
        "unit",
        "supply bundle unit cannot be empty",
      );
    }
  }

  final SupplyKind kind;
  final double quantity;
  final String unit;

  /// Returns self; constructor already validates eagerly.
  SupplyBundle validated() => this;
}

/// Per-person-per-hour consumption rate for a single (mode, kind) pair.
class SupplyPolicy {
  SupplyPolicy({
    required this.modeId,
    required this.kind,
    required this.perPersonPerHour,
  }) {
    if (modeId.isEmpty) {
      throw ArgumentError.value(
        modeId,
        "modeId",
        "supply policy modeId cannot be empty",
      );
    }
    if (kind == null) {
      throw ArgumentError("supply policy kind cannot be null");
    }
    if (perPersonPerHour < 0) {
      throw ArgumentError.value(
        perPersonPerHour,
        "perPersonPerHour",
        "supply policy rate must be >= 0",
      );
    }
  }

  final String modeId;
  final SupplyKind? kind;
  final double perPersonPerHour;

  /// Returns self; constructor already validates eagerly.
  SupplyPolicy validated() => this;
}

/// Required supply kinds and rates for a given travel mode.
class ModeSupplyRequirement {
  const ModeSupplyRequirement({required this.modeId, required this.policies});

  final String modeId;
  final List<SupplyPolicy> policies;

  Set<SupplyKind> get requiredKinds => policies.map((p) => p.kind!).toSet();

  SupplyPolicy? policyFor(SupplyKind kind) {
    for (final p in policies) {
      if (p.kind == kind) return p;
    }
    return null;
  }
}

/// Standard supply policies for the built-in travel modes.
class SupplyPolicies {
  static final List<ModeSupplyRequirement> _standard = <ModeSupplyRequirement>[
    ModeSupplyRequirement(
      modeId: TravelModes.walk.id,
      policies: [
        SupplyPolicy(
          modeId: TravelModes.walk.id,
          kind: SupplyKind.rations,
          perPersonPerHour: 0.10,
        ),
        SupplyPolicy(
          modeId: TravelModes.walk.id,
          kind: SupplyKind.water,
          perPersonPerHour: 0.20,
        ),
      ],
    ),
    ModeSupplyRequirement(
      modeId: TravelModes.mount.id,
      policies: [
        SupplyPolicy(
          modeId: TravelModes.mount.id,
          kind: SupplyKind.rations,
          perPersonPerHour: 0.08,
        ),
        SupplyPolicy(
          modeId: TravelModes.mount.id,
          kind: SupplyKind.water,
          perPersonPerHour: 0.18,
        ),
        SupplyPolicy(
          modeId: TravelModes.mount.id,
          kind: SupplyKind.fodder,
          perPersonPerHour: 0.30,
        ),
      ],
    ),
    ModeSupplyRequirement(
      modeId: TravelModes.vehicle.id,
      policies: [
        SupplyPolicy(
          modeId: TravelModes.vehicle.id,
          kind: SupplyKind.rations,
          perPersonPerHour: 0.06,
        ),
        SupplyPolicy(
          modeId: TravelModes.vehicle.id,
          kind: SupplyKind.water,
          perPersonPerHour: 0.15,
        ),
        SupplyPolicy(
          modeId: TravelModes.vehicle.id,
          kind: SupplyKind.fodder,
          perPersonPerHour: 0.20,
        ),
      ],
    ),
    ModeSupplyRequirement(
      modeId: TravelModes.ship.id,
      policies: [
        SupplyPolicy(
          modeId: TravelModes.ship.id,
          kind: SupplyKind.rations,
          perPersonPerHour: 0.05,
        ),
        SupplyPolicy(
          modeId: TravelModes.ship.id,
          kind: SupplyKind.water,
          perPersonPerHour: 0.10,
        ),
      ],
    ),
  ];

  static final SupplyPolicies standard = SupplyPolicies._(_standard);

  final List<ModeSupplyRequirement> _entries;
  const SupplyPolicies._(this._entries);

  /// Returns the requirement for [modeId], or null when the mode has no policy.
  ModeSupplyRequirement forMode(String modeId) {
    for (final e in _entries) {
      if (e.modeId == modeId) return e;
    }
    return const ModeSupplyRequirement(modeId: "", policies: []);
  }
}

/// Party supply loadout: party size plus a list of bundles, one per kind.
class SupplyLoadout {
  SupplyLoadout({required this.partySize, required List<SupplyBundle> bundles})
    : bundles = List.unmodifiable(bundles) {
    if (partySize <= 0) {
      throw ArgumentError.value(
        partySize,
        "partySize",
        "party size must be > 0",
      );
    }
    final seen = <SupplyKind>{};
    for (final b in bundles) {
      if (!seen.add(b.kind)) {
        throw ArgumentError(
          "loadout has duplicate bundle for kind ${b.kind.name}",
        );
      }
    }
  }

  final int partySize;
  final List<SupplyBundle> bundles;

  /// Returns the quantity of [kind] in this loadout. 0 when absent.
  double totalOf(SupplyKind kind) {
    for (final b in bundles) {
      if (b.kind == kind) return b.quantity;
    }
    return 0.0;
  }

  /// Returns self; constructor already validates eagerly.
  SupplyLoadout validated() => this;
}

/// Outcome of a supply plan.
enum SupplyStatus { sufficient, insufficient }

/// One shortage record for a single supply kind.
class SupplyShortage {
  const SupplyShortage({
    required this.kind,
    required this.shortBy,
    required this.reasonCode,
  });

  final SupplyKind kind;
  final double shortBy;
  final String reasonCode;

  @override
  bool operator ==(Object other) =>
      other is SupplyShortage &&
      other.kind == kind &&
      other.shortBy == shortBy &&
      other.reasonCode == reasonCode;

  @override
  int get hashCode => Object.hash(kind, shortBy, reasonCode);
}

/// One consumption record for a single (segment, kind) pair.
class SupplyConsumption {
  const SupplyConsumption({
    required this.segmentId,
    required this.kind,
    required this.amount,
  });

  final String segmentId;
  final SupplyKind kind;
  final double amount;
}

/// Final result of a travel supply plan.
class SupplyPlanResult {
  const SupplyPlanResult({
    required this.status,
    required this.consumed,
    required this.shortages,
    required this.consumption,
  });

  final SupplyStatus status;
  final Map<SupplyKind, double> consumed;
  final List<SupplyShortage> shortages;
  final List<SupplyConsumption> consumption;
}

/// Deterministic supply planner for travel segments.
class SupplyPlanner {
  const SupplyPlanner();

  SupplyPlanResult plan({
    required RouteGraph graph,
    required List<String> segments,
    required TravelModeProfile mode,
    required Season season,
    required int partySize,
    required SupplyLoadout loadout,
  }) {
    if (segments.isEmpty) {
      throw ArgumentError("segments list cannot be empty");
    }
    if (partySize <= 0) {
      throw ArgumentError.value(
        partySize,
        "partySize",
        "party size must be > 0",
      );
    }
    loadout.validated();

    final requirement = SupplyPolicies.standard.forMode(mode.id);
    final consumed = <SupplyKind, double>{};
    final consumption = <SupplyConsumption>[];
    final shortages = <SupplyShortage>[];

    for (final id in segments) {
      final edge = graph.edge(id);
      final block = edge.blocked;
      if (block != null) {
        throw RouteBlockedException(edgeId: id, reason: block.reason);
      }

      final speed = _effectiveSpeedKmPerHour(mode, edge.terrain, season);
      if (speed <= 0) {
        continue;
      }
      final hours = edge.distance / speed;

      for (final policy in requirement.policies) {
        final kind = policy.kind!;
        final rate = _seasonalRate(
          kind: kind,
          baseRate: policy.perPersonPerHour,
          season: season,
        );
        final amount = rate * partySize * hours;
        consumed[kind] = (consumed[kind] ?? 0.0) + amount;
        consumption.add(
          SupplyConsumption(segmentId: id, kind: kind, amount: amount),
        );
      }
    }

    for (final kind in requirement.requiredKinds) {
      final needed = consumed[kind] ?? 0.0;
      final available = loadout.totalOf(kind);
      if (needed > available) {
        shortages.add(
          SupplyShortage(
            kind: kind,
            shortBy: needed - available,
            reasonCode: _reasonCodeFor(kind),
          ),
        );
      }
    }

    return SupplyPlanResult(
      status: shortages.isEmpty
          ? SupplyStatus.sufficient
          : SupplyStatus.insufficient,
      consumed: consumed,
      shortages: List.unmodifiable(shortages),
      consumption: List.unmodifiable(consumption),
    );
  }

  double _effectiveSpeedKmPerHour(
    TravelModeProfile mode,
    Terrain terrain,
    Season season,
  ) {
    var speed = mode.baseSpeedKmPerHour;
    speed = speed / terrain.baseMultiplier;
    speed = speed / season.accessMultiplier;
    return speed;
  }

  double _seasonalRate({
    required SupplyKind kind,
    required double baseRate,
    required Season season,
  }) {
    if (kind == SupplyKind.water && season == Season.winter) {
      return baseRate * 1.25;
    }
    if (kind == SupplyKind.fodder && season == Season.winter) {
      return baseRate * 1.30;
    }
    if (kind == SupplyKind.rations && season == Season.winter) {
      return baseRate * 1.10;
    }
    return baseRate;
  }

  String _reasonCodeFor(SupplyKind kind) {
    switch (kind) {
      case SupplyKind.rations:
        return "rations_exhausted";
      case SupplyKind.water:
        return "water_exhausted";
      case SupplyKind.fodder:
        return "fodder_exhausted";
    }
  }
}
