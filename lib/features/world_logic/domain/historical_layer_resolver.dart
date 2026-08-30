// Sprint 110.21 - Map Time Slider & Historical Layers (resolver).
//
// Domain-only resolver backing the 110.21 widget. Provides:
//   * MapTimeSliderController (time_slider, keyboard_control).
//   * HistoricalLayer snapshots for user-enabled key ticks
//     (historical_layers).
//   * LocationHighlight diff vs previous smaller key tick
//     (change_highlight).
//   * MapLegend keyed by LocationStatus (legend).
//
// All inputs are explicit (TemporalMapState + enabled ticks + initialTick).
// No persistence, UI, locale, network, wall clock, or random input.

import "package:flutter/foundation.dart";

import "temporal_map_state.dart"
    show
        LocationStatus,
        TemporalLocation,
        TemporalLocationSnapshot,
        TemporalMapState;

enum MapTimeKey {
  advanceSmall,
  retreatSmall,
  advanceBig,
  retreatBig,
  jumpStart,
  jumpEnd,
  nextKeyTick,
  prevKeyTick,
}

enum HighlightKind {
  statusChange,
  controlChange,
  boundaryChange,
  appeared,
  gone,
}

@immutable
class LocationHighlight {
  const LocationHighlight({
    required this.kind,
    required this.locationId,
    required this.reason,
    required this.tick,
    required this.previousTick,
  });

  final HighlightKind kind;
  final String locationId;
  final String reason;
  final int tick;
  final int? previousTick;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationHighlight &&
        other.kind == kind &&
        other.locationId == locationId &&
        other.tick == tick &&
        other.previousTick == previousTick &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(kind, locationId, tick, previousTick, reason);
}

@immutable
class HistoricalLayer {
  const HistoricalLayer({
    required this.tick,
    required this.locations,
    required this.highlights,
  });

  final int tick;
  final List<TemporalLocationSnapshot> locations;
  final List<LocationHighlight> highlights;
}

@immutable
class LegendEntry {
  const LegendEntry({
    required this.status,
    required this.label,
    required this.token,
  });

  final LocationStatus status;
  final String label;
  final String token;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LegendEntry &&
        other.status == status &&
        other.label == label &&
        other.token == token;
  }

  @override
  int get hashCode => Object.hash(status, label, token);
}

class MapLegend {
  MapLegend._(this.entries);

  final List<LegendEntry> entries;

  static MapLegend standard() {
    final list = <LegendEntry>[
      const LegendEntry(
        status: LocationStatus.abandoned,
        label: 'Abandoned',
        token: 'abandoned',
      ),
      const LegendEntry(
        status: LocationStatus.active,
        label: 'Active',
        token: 'active',
      ),
      const LegendEntry(
        status: LocationStatus.contested,
        label: 'Contested',
        token: 'contested',
      ),
      const LegendEntry(
        status: LocationStatus.hidden,
        label: 'Hidden',
        token: 'hidden',
      ),
      const LegendEntry(
        status: LocationStatus.ruined,
        label: 'Ruined',
        token: 'ruined',
      ),
    ];
    list.sort((a, b) => a.token.compareTo(b.token));
    return MapLegend._(List<LegendEntry>.unmodifiable(list));
  }

  LegendEntry entryFor(LocationStatus status) {
    for (final entry in entries) {
      if (entry.status == status) return entry;
    }
    return LegendEntry(status: status, label: status.name, token: status.name);
  }
}

class MapTimeSliderController extends ChangeNotifier {
  MapTimeSliderController._({
    required this._prime,
    required this.minTick,
    required this.maxTick,
    required int initialTick,
  }) : _currentTick = initialTick.clamp(minTick, maxTick),
       _enabledTicks = <int>{};

  factory MapTimeSliderController.forState(
    TemporalMapState state, {
    int? initialTick,
  }) {
    if (state.primeLocations.isEmpty) {
      throw ArgumentError.value(
        state,
        'state',
        'TemporalMapState must contain at least one location to build a '
            'time slider.',
      );
    }
    var minTick = 1 << 30;
    var maxTick = -1;
    for (final loc in state.primeLocations) {
      if (loc.validFrom < minTick) minTick = loc.validFrom;
      final upper = loc.validUntil ?? loc.validFrom;
      if (upper > maxTick) maxTick = upper;
    }
    if (maxTick < minTick) {
      throw ArgumentError.value(
        state,
        'state',
        'TemporalMapState has no usable tick range.',
      );
    }
    return MapTimeSliderController._(
      prime: state.primeLocations,
      minTick: minTick,
      maxTick: maxTick,
      initialTick: initialTick ?? minTick,
    );
  }

  final List<TemporalLocation> _prime;
  final int minTick;
  final int maxTick;
  int _currentTick;
  final Set<int> _enabledTicks;

  int get currentTick => _currentTick;
  int get tickRange => (maxTick - minTick) + 1;

  List<int> get keyTicks {
    final anchors = <int>{};
    for (final loc in _prime) {
      anchors.add(loc.validFrom);
      if (loc.validUntil != null) anchors.add(loc.validUntil!);
      for (final bv in loc.boundaries) {
        anchors.add(bv.validFrom);
      }
      for (final cc in loc.controlHistory) {
        anchors.add(cc.validFrom);
      }
      for (final sc in loc.statusHistory) {
        anchors.add(sc.validFrom);
      }
    }
    final sorted = anchors.toList()..sort();
    return List<int>.unmodifiable(sorted);
  }

  bool isLayerEnabledAt(int tick) => _enabledTicks.contains(tick);

  void enableLayerAt(int tick) {
    if (tick < minTick || tick > maxTick) {
      throw ArgumentError.value(
        tick,
        'tick',
        'tick must be inside the controller range.',
      );
    }
    if (_enabledTicks.add(tick)) {
      notifyListeners();
    }
  }

  void disableLayerAt(int tick) {
    if (_enabledTicks.remove(tick)) {
      notifyListeners();
    }
  }

  void seekTo(int tick) {
    final clamped = tick.clamp(minTick, maxTick);
    if (clamped == _currentTick) return;
    _currentTick = clamped;
    notifyListeners();
  }

  void applyKey(MapTimeKey key) {
    switch (key) {
      case MapTimeKey.advanceSmall:
        seekTo(_currentTick + 1);
        break;
      case MapTimeKey.retreatSmall:
        seekTo(_currentTick - 1);
        break;
      case MapTimeKey.advanceBig:
        seekTo(_currentTick + 10);
        break;
      case MapTimeKey.retreatBig:
        seekTo(_currentTick - 10);
        break;
      case MapTimeKey.jumpStart:
        seekTo(minTick);
        break;
      case MapTimeKey.jumpEnd:
        seekTo(maxTick);
        break;
      case MapTimeKey.nextKeyTick:
        final next = keyTicks.firstWhere(
          (t) => t > _currentTick,
          orElse: () => _currentTick,
        );
        seekTo(next);
        break;
      case MapTimeKey.prevKeyTick:
        final candidates = keyTicks.where((t) => t < _currentTick).toList();
        if (candidates.isEmpty) {
          seekTo(_currentTick);
        } else {
          seekTo(candidates.last);
        }
        break;
    }
  }

  List<HistoricalLayer> get activeLayers {
    final ticks = _enabledTicks.toList()..sort();
    return List<HistoricalLayer>.unmodifiable(ticks.map(_layerFor));
  }

  HistoricalLayer? activeLayerForTick(int tick) {
    if (!_enabledTicks.contains(tick)) return null;
    return _layerFor(tick);
  }

  HistoricalLayer _layerFor(int tick) {
    final active = <TemporalLocationSnapshot>[];
    final locationById = <String, TemporalLocation>{};
    for (final loc in _prime) {
      if (!loc.isActiveAt(tick)) continue;
      locationById[loc.id] = loc;
      active.add(
        TemporalLocationSnapshot(
          id: loc.id,
          name: loc.name,
          controllingFactionId: loc.controllingFactionAt(tick),
          status: loc.statusAt(tick),
          activeBoundary: loc.boundaryAt(tick),
        ),
      );
    }
    return HistoricalLayer(
      tick: tick,
      locations: List<TemporalLocationSnapshot>.unmodifiable(active),
      highlights: List<LocationHighlight>.unmodifiable(
        _deltas(tick, locationById),
      ),
    );
  }

  List<LocationHighlight> _deltas(
    int tick,
    Map<String, TemporalLocation> activeById,
  ) {
    final previousTick = _previousKeyTick(tick);
    final highlights = <LocationHighlight>[];

    final activeIds = activeById.keys.toSet();
    final previousIds = <String>{};
    if (previousTick != null) {
      for (final loc in _prime) {
        if (loc.isActiveAt(previousTick)) {
          previousIds.add(loc.id);
        }
      }
    }

    for (final id in activeIds) {
      if (previousTick == null || !previousIds.contains(id)) {
        final loc = activeById[id]!;
        if (loc.validFrom == tick) {
          highlights.add(
            LocationHighlight(
              kind: HighlightKind.appeared,
              locationId: id,
              reason: "${loc.name} appeared at tick $tick",
              tick: tick,
              previousTick: previousTick,
            ),
          );
        }
        continue;
      }
      final loc = activeById[id]!;
      final status = loc.statusAt(tick);
      final prevStatus = loc.statusAt(previousTick);
      if (prevStatus != status &&
          loc.statusHistory.any((sc) => sc.validFrom == tick)) {
        highlights.add(
          LocationHighlight(
            kind: HighlightKind.statusChange,
            locationId: id,
            reason: "${loc.name} status changed to ${status.name}",
            tick: tick,
            previousTick: previousTick,
          ),
        );
      }

      final faction = loc.controllingFactionAt(tick);
      final prevFaction = loc.controllingFactionAt(previousTick);
      if (faction != prevFaction &&
          loc.controlHistory.any((cc) => cc.validFrom == tick)) {
        highlights.add(
          LocationHighlight(
            kind: HighlightKind.controlChange,
            locationId: id,
            reason: faction == null
                ? "${loc.name} lost controlling faction"
                : "${loc.name} control changed to $faction",
            tick: tick,
            previousTick: previousTick,
          ),
        );
      }

      final boundary = loc.boundaryAt(tick);
      final prevBoundary = loc.boundaryAt(previousTick);
      if (boundary != prevBoundary &&
          loc.boundaries.any((bv) => bv.validFrom == tick)) {
        highlights.add(
          LocationHighlight(
            kind: HighlightKind.boundaryChange,
            locationId: id,
            reason: "${loc.name} boundary revised",
            tick: tick,
            previousTick: previousTick,
          ),
        );
      }
    }

    for (final loc in _prime) {
      if (activeIds.contains(loc.id)) continue;
      if (previousTick == null) continue;
      if (!previousIds.contains(loc.id)) continue;
      if (loc.validUntil != null && loc.validUntil == tick) {
        highlights.add(
          LocationHighlight(
            kind: HighlightKind.gone,
            locationId: loc.id,
            reason: "${loc.name} ended at tick $tick",
            tick: tick,
            previousTick: previousTick,
          ),
        );
      }
    }

    return highlights;
  }

  int? _previousKeyTick(int tick) {
    int? pick;
    for (final t in keyTicks) {
      if (t >= tick) break;
      pick = t;
    }
    return pick;
  }
}
