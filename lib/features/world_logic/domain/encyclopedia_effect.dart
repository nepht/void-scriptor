// Sprint 111.11 - Effect, Toxicity and Interaction Model.
//
// Domain-only contract for ingredient/substance effects: effect entries,
// dose ranges, onset and duration windows, toxicity profile, fictional
// substance interactions, and a deterministic query over an effect catalog.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

String _requireTrimmed(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return value.trim();
}

/// Broad category of an effect for filtering and validation.
enum EffectKind {
  restorative('Restorative'),
  harmful('Harmful'),
  sensory('Sensory'),
  transformative('Transformative'),
  conditional('Conditional');

  const EffectKind(this.label);

  final String label;
}

/// A single effect entry with an optional intensity on a 1..5 scale.
class EffectEntry {
  const EffectEntry._({
    required this.effectId,
    required this.description,
    required this.kind,
    this.intensity,
  });

  factory EffectEntry.validated({
    required String effectId,
    required String description,
    required EffectKind kind,
    int? intensity,
  }) {
    final i = intensity;
    if (i != null && (i < 1 || i > 5)) {
      throw ArgumentError.value(
        intensity,
        'intensity',
        'intensity must be within 1..5 when provided',
      );
    }
    return EffectEntry._(
      effectId: _requireTrimmed(effectId, 'effectId'),
      description: _requireTrimmed(description, 'description'),
      kind: kind,
      intensity: i,
    );
  }

  final String effectId;
  final String description;
  final EffectKind kind;
  final int? intensity;
}

/// A dose range expressed in a unit. At least one numeric bound is required.
class DoseRange {
  const DoseRange._({required this.unit, this.minAmount, this.maxAmount});

  factory DoseRange.validated({
    required String unit,
    double? minAmount,
    double? maxAmount,
  }) {
    if (minAmount == null && maxAmount == null) {
      throw ArgumentError('DoseRange requires at least one numeric bound');
    }
    final min = minAmount;
    final max = maxAmount;
    if (min != null && max != null && max < min) {
      throw ArgumentError('maxAmount must not be below minAmount');
    }
    return DoseRange._(
      unit: _requireTrimmed(unit, 'unit'),
      minAmount: min,
      maxAmount: max,
    );
  }

  final String unit;
  final double? minAmount;
  final double? maxAmount;
}

/// How quickly an effect takes hold, with optional minute bounds.
class OnsetWindow {
  const OnsetWindow._({
    required this.description,
    this.minMinutes,
    this.maxMinutes,
  });

  factory OnsetWindow.validated({
    required String description,
    int? minMinutes,
    int? maxMinutes,
  }) {
    final min = minMinutes;
    final max = maxMinutes;
    if (min != null && max != null && max < min) {
      throw ArgumentError('maxMinutes must not be below minMinutes');
    }
    return OnsetWindow._(
      description: _requireTrimmed(description, 'description'),
      minMinutes: min,
      maxMinutes: max,
    );
  }

  final String description;
  final int? minMinutes;
  final int? maxMinutes;
}

/// How long an effect lasts, with optional minute bounds.
class DurationWindow {
  const DurationWindow._({
    required this.description,
    this.minMinutes,
    this.maxMinutes,
  });

  factory DurationWindow.validated({
    required String description,
    int? minMinutes,
    int? maxMinutes,
  }) {
    final min = minMinutes;
    final max = maxMinutes;
    if (min != null && max != null && max < min) {
      throw ArgumentError('maxMinutes must not be below minMinutes');
    }
    return DurationWindow._(
      description: _requireTrimmed(description, 'description'),
      minMinutes: min,
      maxMinutes: max,
    );
  }

  final String description;
  final int? minMinutes;
  final int? maxMinutes;
}

/// Toxicity ladder with labels.
enum ToxicityLevel {
  none('None'),
  low('Low'),
  moderate('Moderate'),
  high('High'),
  extreme('Extreme');

  const ToxicityLevel(this.label);

  final String label;
}

/// Toxicity profile with optional symptoms and a threshold dose.
class ToxicityProfile {
  const ToxicityProfile._({
    required this.level,
    this.symptoms,
    this.thresholdDose,
  });

  factory ToxicityProfile.validated({
    required ToxicityLevel level,
    String? symptoms,
    String? thresholdDose,
  }) {
    final trimmedSymptoms = symptoms?.trim();
    if (trimmedSymptoms != null && trimmedSymptoms.isEmpty) {
      throw ArgumentError('symptoms must be non-empty when provided');
    }
    final trimmedThreshold = thresholdDose?.trim();
    if (trimmedThreshold != null && trimmedThreshold.isEmpty) {
      throw ArgumentError('thresholdDose must be non-empty when provided');
    }
    return ToxicityProfile._(
      level: level,
      symptoms: trimmedSymptoms,
      thresholdDose: trimmedThreshold,
    );
  }

  final ToxicityLevel level;
  final String? symptoms;
  final String? thresholdDose;
}

/// How a fictional substance interacts with another substance.
enum InteractionKind {
  synergistic('Synergistic'),
  antagonistic('Antagonistic'),
  neutral('Neutral'),
  toxic('Toxic');

  const InteractionKind(this.label);

  final String label;
}

/// A single interaction with another substance, with optional severity.
class SubstanceInteraction {
  const SubstanceInteraction._({
    required this.interactionId,
    required this.targetId,
    required this.description,
    required this.kind,
    this.severity,
  });

  factory SubstanceInteraction.validated({
    required String interactionId,
    required String targetId,
    required String description,
    required InteractionKind kind,
    int? severity,
  }) {
    final s = severity;
    if (s != null && (s < 1 || s > 5)) {
      throw ArgumentError.value(
        severity,
        'severity',
        'severity must be within 1..5 when provided',
      );
    }
    return SubstanceInteraction._(
      interactionId: _requireTrimmed(interactionId, 'interactionId'),
      targetId: _requireTrimmed(targetId, 'targetId'),
      description: _requireTrimmed(description, 'description'),
      kind: kind,
      severity: s,
    );
  }

  final String interactionId;
  final String targetId;
  final String description;
  final InteractionKind kind;
  final int? severity;
}

/// Immutable effect record for an ingredient. Optional collections are
/// guarded against duplicate identity keys.
class EffectRecord {
  const EffectRecord._({
    required this.ingredientId,
    required this.effects,
    required this.interactions,
    this.doseRange,
    this.onset,
    this.duration,
    this.toxicity,
  });

  factory EffectRecord.validated({
    required String ingredientId,
    List<EffectEntry> effects = const [],
    List<SubstanceInteraction> interactions = const [],
    DoseRange? doseRange,
    OnsetWindow? onset,
    DurationWindow? duration,
    ToxicityProfile? toxicity,
  }) {
    final effectIds = <String, String>{};
    for (final e in effects) {
      if (effectIds.containsKey(e.effectId)) {
        throw ArgumentError('duplicate effectId: ${e.effectId}');
      }
      effectIds[e.effectId] = e.effectId;
    }
    final interactionIds = <String, String>{};
    for (final i in interactions) {
      if (interactionIds.containsKey(i.interactionId)) {
        throw ArgumentError('duplicate interactionId: ${i.interactionId}');
      }
      interactionIds[i.interactionId] = i.interactionId;
    }
    return EffectRecord._(
      ingredientId: _requireTrimmed(ingredientId, 'ingredientId'),
      effects: List.unmodifiable(effects),
      interactions: List.unmodifiable(interactions),
      doseRange: doseRange,
      onset: onset,
      duration: duration,
      toxicity: toxicity,
    );
  }

  final String ingredientId;
  final List<EffectEntry> effects;
  final List<SubstanceInteraction> interactions;
  final DoseRange? doseRange;
  final OnsetWindow? onset;
  final DurationWindow? duration;
  final ToxicityProfile? toxicity;

  bool hasKind(EffectKind kind) => effects.any((e) => e.kind == kind);

  bool hasHarmfulEffect() => hasKind(EffectKind.harmful);

  /// True when a toxicity profile is declared and its level is at least
  /// [level] on the ladder.
  bool isToxicAtLeast(ToxicityLevel level) {
    final t = toxicity;
    if (t == null) return false;
    return t.level.index >= level.index;
  }

  bool interactsWith(String targetId) =>
      interactions.any((i) => i.targetId == targetId);
}

/// Immutable query over [EffectRecord]s. All filters are optional; a blank
/// query matches every record.
class EffectQuery {
  const EffectQuery({
    this.kind,
    this.minIntensity,
    this.minToxicity,
    this.interactsWith,
  });

  final EffectKind? kind;
  final int? minIntensity;
  final ToxicityLevel? minToxicity;
  final String? interactsWith;

  bool matches(EffectRecord record) {
    if (kind != null && !record.hasKind(kind!)) return false;
    final min = minIntensity;
    if (min != null) {
      var found = false;
      for (final e in record.effects) {
        final intensity = e.intensity;
        if (intensity != null && intensity >= min) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    if (minToxicity != null && !record.isToxicAtLeast(minToxicity!)) {
      return false;
    }
    if (interactsWith != null && !record.interactsWith(interactsWith!)) {
      return false;
    }
    return true;
  }

  /// A human-readable description of the active filters.
  String describe() {
    final parts = <String>[];
    if (kind != null) parts.add('kind: ${kind!.label}');
    if (minIntensity != null) parts.add('intensity >= $minIntensity');
    if (minToxicity != null) parts.add('toxicity >= ${minToxicity!.label}');
    if (interactsWith != null) parts.add('interacts with: $interactsWith');
    if (parts.isEmpty) return 'no filters';
    return parts.join(', ');
  }
}

/// Immutable catalog of effect records with deterministic query support.
class EffectCatalog {
  const EffectCatalog._(this._records);

  factory EffectCatalog.empty() => const EffectCatalog._([]);

  factory EffectCatalog.withRecords(List<EffectRecord> records) {
    final ids = <String, String>{};
    for (final r in records) {
      if (ids.containsKey(r.ingredientId)) {
        throw ArgumentError('duplicate ingredientId: ${r.ingredientId}');
      }
      ids[r.ingredientId] = r.ingredientId;
    }
    // Sort by ingredientId for deterministic query order.
    final sorted = List<EffectRecord>.of(records)
      ..sort((a, b) => a.ingredientId.compareTo(b.ingredientId));
    return EffectCatalog._(List.unmodifiable(sorted));
  }

  final List<EffectRecord> _records;

  int get length => _records.length;

  EffectRecord? recordFor(String ingredientId) {
    for (final r in _records) {
      if (r.ingredientId == ingredientId) return r;
    }
    return null;
  }

  List<EffectRecord> query(EffectQuery q) {
    return _records.where((r) => q.matches(r)).toList();
  }
}
