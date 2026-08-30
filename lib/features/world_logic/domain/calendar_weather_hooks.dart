// Sprint 110.16 - Calendar Weather Hooks (Wave 2 F5).
//
// Domain-only binding between a deterministic WeatherCalendarSampler (110.13)
// and world-builder manual overrides. Produces WeatherSample values with a
// rewritten provenance origin ("calendar" for sampler path, "manual" for
// override path) plus a free-form note for forecast windows. No persistence,
// no UI, no wall clock, no network.
import "custom_calendar.dart";
import "travel_mode_profiles.dart" show WeatherCondition;

/// Manual override declared by a world-builder for a specific tick.
class WeatherOverride {
  WeatherOverride({
    required this.tick,
    required this.condition,
    required this.reason,
  }) {
    if (tick < 0) {
      throw ArgumentError("override tick must be >= 0, got $tick");
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError("override reason must be non-empty");
    }
  }

  final int tick;
  final WeatherCondition condition;
  final String reason;
}

/// One entry in a forecast window produced by [CalendarWeatherHooks].
class WeatherForecastEntry {
  const WeatherForecastEntry({
    required this.tick,
    required this.condition,
    required this.provenance,
    required this.note,
  });

  final int tick;
  final WeatherCondition condition;
  final CalendarWeatherProvenance provenance;
  final String note;
}

/// Result of [CalendarWeatherHooks.forecastWindow].
class WeatherForecast {
  const WeatherForecast({
    required this.start,
    required this.length,
    required this.entries,
  });

  final int start;
  final int length;
  final List<WeatherForecastEntry> entries;
}

/// Stateful binding that prefers manual overrides over the deterministic
/// sampler for matching ticks. Same inputs always yield the same outputs.
class CalendarWeatherHooks {
  CalendarWeatherHooks({required this.sampler});

  final WeatherCalendarSampler sampler;
  final Map<int, WeatherOverride> _overrides = <int, WeatherOverride>{};

  /// Register a manual override for [WeatherOverride.tick]. Tick must be
  /// non-negative and [WeatherOverride.reason] non-empty.
  void setOverride(WeatherOverride override) {
    // Constructor already validates the override.
    _overrides[override.tick] = override;
  }

  /// Resolve the weather for [tick], preferring any registered manual
  /// override over the deterministic sampler.
  WeatherSample resolveAt(int tick) {
    final override = _overrides[tick];
    if (override != null) {
      return WeatherSample(
        condition: override.condition,
        tick: tick,
        provenance: CalendarWeatherProvenance(
          origin: "manual",
          sourceId: "override#tick:$tick",
          reason: override.reason,
        ),
      );
    }
    final raw = sampler.sampleAt(tick);
    return WeatherSample(
      condition: raw.condition,
      tick: raw.tick,
      provenance: CalendarWeatherProvenance(
        origin: "calendar",
        sourceId: raw.provenance.sourceId,
        reason: raw.provenance.reason,
      ),
    );
  }

  /// Build a contiguous forecast window of [length] entries starting at
  /// [start]. Each entry carries its resolved condition, provenance, and
  /// a human-readable note explaining the source.
  WeatherForecast forecastWindow({required int start, required int length}) {
    if (length <= 0) {
      throw ArgumentError("forecast length must be > 0, got $length");
    }
    final entries = <WeatherForecastEntry>[];
    for (var i = 0; i < length; i++) {
      final tick = start + i;
      final sample = resolveAt(tick);
      final note = sample.provenance.origin == "manual"
          ? "manual override tick=$tick reason=${sample.provenance.reason}"
          : "calendar weather seed=${sampler.seed} tick=$tick "
                "(${sample.provenance.reason})";
      entries.add(
        WeatherForecastEntry(
          tick: tick,
          condition: sample.condition,
          provenance: sample.provenance,
          note: note,
        ),
      );
    }
    return WeatherForecast(start: start, length: length, entries: entries);
  }
}
