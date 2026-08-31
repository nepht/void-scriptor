// Sprint 111.8 - Spoiler, Feature Flags & Accessibility Baseline.
//
// Domain-only contract for reveal state, safe rollout flags, keyboard
// navigation mapping, screen reader labels, and nonvisual fallbacks.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

/// Spoiler escalation order for encyclopedia records. The index defines
/// the audience threshold: content at or below the audience level is
/// allowed, everything above is hidden.
enum SpoilerLevel { safe, mild, major, ending }

/// Immutable spoiler policy: a default audience level plus optional
/// per-record overrides that always beat the default.
class SpoilerPolicy {
  SpoilerPolicy({
    this.defaultLevel = SpoilerLevel.safe,
    Map<String, SpoilerLevel> overrides = const {},
  }) : _overrides = Map.unmodifiable(overrides) {
    for (final key in _overrides.keys) {
      if (key.trim().isEmpty || key.trim() != key) {
        throw ArgumentError('override keys must be trimmed and non-empty');
      }
    }
  }

  final SpoilerLevel defaultLevel;
  final Map<String, SpoilerLevel> _overrides;

  Map<String, SpoilerLevel> get overrides => _overrides;

  /// Whether content at [level] is allowed for [recordKey]. An override for
  /// the record beats the default audience level.
  bool allows(SpoilerLevel level, {String? recordKey}) {
    final threshold =
        (recordKey != null ? overrides[recordKey] : null) ?? defaultLevel;
    return level.index <= threshold.index;
  }
}

/// A single reveal point in a story, gated by a spoiler level. Reveals stay
/// hidden until explicitly marked as revealed.
class RevealPoint {
  const RevealPoint._({
    required this.revealId,
    required this.storyLink,
    required this.tick,
    required this.level,
    required this.revealed,
  });

  static RevealPoint validated({
    required String revealId,
    required String storyLink,
    int tick = 0,
    SpoilerLevel level = SpoilerLevel.safe,
  }) {
    if (revealId.trim().isEmpty) {
      throw ArgumentError('revealId must be non-empty');
    }
    if (storyLink.trim().isEmpty) {
      throw ArgumentError('storyLink must be non-empty');
    }
    if (tick < 0) {
      throw ArgumentError('tick must be non-negative');
    }
    return RevealPoint._(
      revealId: revealId,
      storyLink: storyLink,
      tick: tick,
      level: level,
      revealed: false,
    );
  }

  final String revealId;
  final String storyLink;
  final int tick;
  final SpoilerLevel level;
  final bool revealed;

  RevealPoint markRevealed() => RevealPoint._(
    revealId: revealId,
    storyLink: storyLink,
    tick: tick,
    level: level,
    revealed: true,
  );
}

/// Registry of reveal points with a uniqueness guard on reveal id and a
/// stable, order-preserving list of pending (not yet revealed) ids.
class RevealRegistry {
  final List<RevealPoint> _points = [];

  void register(RevealPoint point) {
    if (_points.any((p) => p.revealId == point.revealId)) {
      throw ArgumentError('duplicate revealId: ${point.revealId}');
    }
    _points.add(point);
  }

  List<String> get pendingIds =>
      _points.where((p) => !p.revealed).map((p) => p.revealId).toList();
}

/// Safe-rollout catalog of Wave 3 encyclopedia feature flags. Unknown ids
/// are rejected; flags default to disabled so a release ships non-invasive.
class EncyclopediaFeatureFlags {
  const EncyclopediaFeatureFlags._(this._enabled);

  const EncyclopediaFeatureFlags() : _enabled = const {};

  static const List<String> wave3Catalog = [
    'F23',
    'F24',
    'F26',
    'F27',
    'F28',
    'F29',
  ];

  final Set<String> _enabled;

  bool isEnabled(String id) {
    if (!wave3Catalog.contains(id)) {
      throw ArgumentError('unknown feature id: $id');
    }
    return _enabled.contains(id);
  }

  EncyclopediaFeatureFlags withFlag(String id, bool value) {
    if (!wave3Catalog.contains(id)) {
      throw ArgumentError('unknown feature id: $id');
    }
    if (value == isEnabled(id)) {
      return this;
    }
    final next = {..._enabled};
    if (value) {
      next.add(id);
    } else {
      next.remove(id);
    }
    return EncyclopediaFeatureFlags._(next);
  }
}

/// A resolvable keyboard shortcut with an action name and human description.
class KeyboardShortcut {
  const KeyboardShortcut({
    required this.action,
    required this.key,
    this.control = false,
    this.shift = false,
    this.alt = false,
    this.meta = false,
  });

  final String action;
  final String key;
  final bool control;
  final bool shift;
  final bool alt;
  final bool meta;

  String describe() {
    final modifiers = <String>[
      if (control) 'Ctrl',
      if (shift) 'Shift',
      if (alt) 'Alt',
      if (meta) 'Meta',
    ];
    return [...modifiers, key].join('+');
  }

  @override
  bool operator ==(Object other) =>
      other is KeyboardShortcut &&
      other.action == action &&
      other.key == key &&
      other.control == control &&
      other.shift == shift &&
      other.alt == alt &&
      other.meta == meta;

  @override
  int get hashCode => Object.hash(action, key, control, shift, alt, meta);
}

/// Navigation map for keyboard access. Rejects empty actions/keys, duplicate
/// actions, and bindings that collide on the same modifier+key set.
class KeyboardNavigationMap {
  final List<KeyboardShortcut> _shortcuts = [];

  KeyboardNavigationMap add(KeyboardShortcut shortcut) {
    if (shortcut.action.trim().isEmpty) {
      throw ArgumentError('action must be non-empty');
    }
    if (shortcut.key.trim().isEmpty) {
      throw ArgumentError('key must be non-empty');
    }
    if (_shortcuts.any((s) => s.action == shortcut.action)) {
      throw ArgumentError('duplicate action: ${shortcut.action}');
    }
    if (_shortcuts.any(
      (s) =>
          s.key == shortcut.key &&
          s.control == shortcut.control &&
          s.shift == shortcut.shift &&
          s.alt == shortcut.alt &&
          s.meta == shortcut.meta,
    )) {
      throw ArgumentError('conflicting binding for ${shortcut.describe()}');
    }
    _shortcuts.add(shortcut);
    return this;
  }

  List<KeyboardShortcut> get shortcuts => List.unmodifiable(_shortcuts);

  KeyboardShortcut? bindingFor(String action) {
    for (final s in _shortcuts) {
      if (s.action == action) {
        return s;
      }
    }
    return null;
  }
}

/// Explicit accessibility labels with a configurable fallback for missing keys.
class ScreenReaderLabels {
  const ScreenReaderLabels({this.fallback = ''}) : _labels = const {};

  const ScreenReaderLabels._(this._labels, this.fallback);

  final Map<String, String> _labels;
  final String fallback;

  ScreenReaderLabels add(String elementKey, String label) {
    if (elementKey.trim().isEmpty) {
      throw ArgumentError('elementKey must be non-empty');
    }
    if (label.trim().isEmpty) {
      throw ArgumentError('label must be non-empty');
    }
    return ScreenReaderLabels._({..._labels, elementKey: label}, fallback);
  }

  String labelFor(String elementKey) => _labels[elementKey] ?? fallback;
}

/// Nonvisual description registry for elements that must remain accessible
/// without a screen (graphs, maps, timelines). Required elements must have a
/// description.
class NonvisualFallback {
  final Map<String, String> _descriptions = {};

  NonvisualFallback register(String elementKey, String description) {
    if (elementKey.trim().isEmpty) {
      throw ArgumentError('elementKey must be non-empty');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('description must be non-empty');
    }
    _descriptions[elementKey] = description;
    return this;
  }

  String describe(String elementKey) => _descriptions[elementKey] ?? '';

  /// Throws [ArgumentError] when [elementKey] has no nonvisual description.
  /// Used to guarantee a required element stays accessible.
  String requireDescription(String elementKey) {
    final description = _descriptions[elementKey];
    if (description == null || description.trim().isEmpty) {
      throw ArgumentError('missing nonvisual description for $elementKey');
    }
    return description;
  }
}
