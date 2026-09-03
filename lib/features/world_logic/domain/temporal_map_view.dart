/// Sprint 110.21 -- Map Time Slider and Historical Layers
/// (Temporal World Map).
///
/// Domain-only view atop [TerritorialControlRegistry] that derives
/// a snapshot of the world at an as-of tick. The view exposes the
/// closed slider bounds, a current [asOfTick] cursor, the list of
/// [TemporalLayer] entries active at that tick, the set of
/// locations whose active controller changed at the boundary
/// (compared against the previous tick), a stable legend of
/// distinct controllers with their assigned color, and a keyboard
/// control helper for left/right advance within bounds.
///
/// Deterministic, no persistence, UI, wall clock, locale, or
/// random input. Intended for the F11 temporal world map layer
/// at Sprint 110.21.
library;

import "territorial_control.dart";
import "genealogy_relationship_rules.dart" show ValidityRange;

enum TemporalSliderStep { left, right }

class TemporalLayer {
  const TemporalLayer({
    required this.locationId,
    required this.controllerId,
    required this.validity,
  });

  final String locationId;
  final String controllerId;
  final ValidityRange validity;
}

class TemporalMapView {
  TemporalMapView({
    required this.registry,
    required this.asOfTick,
    required this.sliderMin,
    required this.sliderMax,
    this.step = 1,
    required this.palette,
  }) : assert(palette.isNotEmpty, "palette must not be empty") {
    if (sliderMin > sliderMax) {
      throw ArgumentError.value(
        sliderMin,
        "sliderMin",
        "sliderMin must be less than or equal to sliderMax",
      );
    }
    if (asOfTick < sliderMin || asOfTick > sliderMax) {
      throw ArgumentError.value(
        asOfTick,
        "asOfTick",
        "asOfTick must be within [sliderMin, sliderMax]",
      );
    }
    if (step < 0) {
      throw ArgumentError.value(step, "step", "step must be non-negative");
    }
  }

  final TerritorialControlRegistry registry;
  final int asOfTick;
  final int sliderMin;
  final int sliderMax;
  final int step;
  final Map<String, String> palette;

  int get sliderRange => sliderMax - sliderMin;

  List<TemporalLayer> get historicalLayers {
    final out = <TemporalLayer>[];
    for (final rec in registry.records) {
      if (!rec.activeAt(asOfTick)) continue;
      out.add(
        TemporalLayer(
          locationId: rec.locationId,
          controllerId: rec.controllerId,
          validity: rec.validity,
        ),
      );
    }
    out.sort((a, b) => a.locationId.compareTo(b.locationId));
    return List<TemporalLayer>.unmodifiable(out);
  }

  List<String> get changedLocations {
    if (asOfTick <= sliderMin) return const <String>[];
    final prevTick = asOfTick - 1;
    final current = _activeMapAt(asOfTick);
    final previous = _activeMapAt(prevTick);
    final changed = <String>[];
    for (final entry in current.entries) {
      final prev = previous[entry.key];
      if (prev != entry.value) {
        changed.add(entry.key);
      }
    }
    changed.sort();
    return List<String>.unmodifiable(changed);
  }

  Map<String, String> _activeMapAt(int tick) {
    final out = <String, String>{};
    for (final rec in registry.records) {
      if (!rec.activeAt(tick)) continue;
      out[rec.locationId] = rec.controllerId;
    }
    return out;
  }

  Map<String, String> get legend {
    final out = <String, String>{};
    for (final layer in historicalLayers) {
      if (out.containsKey(layer.controllerId)) continue;
      final color = palette[layer.controllerId];
      if (color == null) continue;
      out[layer.controllerId] = color;
    }
    return Map<String, String>.unmodifiable(out);
  }

  int keyboardAdvance(TemporalSliderStep direction) {
    final delta = direction == TemporalSliderStep.right ? step : -step;
    final next = asOfTick + delta;
    if (next < sliderMin) return sliderMin;
    if (next > sliderMax) return sliderMax;
    return next;
  }

  TemporalMapView withTick(int next) {
    return TemporalMapView(
      registry: registry,
      asOfTick: next,
      sliderMin: sliderMin,
      sliderMax: sliderMax,
      step: step,
      palette: palette,
    );
  }
}
