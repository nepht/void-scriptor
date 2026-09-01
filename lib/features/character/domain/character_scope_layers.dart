import '../../../core/commands/app_command.dart';

/// Discriminator for the three Character Scope Layers defined by
/// core_mvp_scope_reset_spec.json (character_model.layers).
///
/// Priority order is canonical (0) -> universe/timeline (1) -> novel (2).
enum CharacterScopeLayer {
  canonical(priority: 0),
  universeTimeline(priority: 1),
  novelSpecific(priority: 2);

  const CharacterScopeLayer({required this.priority});

  /// Higher priority wins when the effective identity is resolved.
  final int priority;
}

/// Explicit ownership map: every scope layer owns a fixed set of fields.
/// A scoped edit may only write fields owned by its declared layer, so a
/// novel-specific edit can never silently mutate canonical identity.
class CharacterScopeFieldOwnership {
  static const Map<CharacterScopeLayer, Set<String>> _fields = {
    CharacterScopeLayer.canonical: {
      'IDENTITY',
      'BASE_VOICE',
      'BASE_VISUAL_PROFILE',
      'BASE_RELATION_REFERENCES',
    },
    CharacterScopeLayer.universeTimeline: {
      'ALTERNATE_HISTORY',
      'ALTERNATE_RELATIONSHIPS',
      'ERA_SPECIFIC_FACTS',
    },
    CharacterScopeLayer.novelSpecific: {
      'ROLE',
      'ARC',
      'CURRENT_LOCATION',
      'CURRENT_AGE',
      'CURRENT_STATUS',
      'SCENE_POV',
      'NOVEL_RELATION_STATE',
    },
  };

  static Set<String> fieldsFor(CharacterScopeLayer layer) =>
      _fields[layer] ?? const {};

  static bool owns(CharacterScopeLayer layer, String field) =>
      _fields[layer]?.contains(field) ?? false;
}

/// Immutable state for one scope layer. Every field is nullable so that
/// `null` means "inherit from the layer below" (never a mutation of it).
/// Removing an override is expressed by writing the lower layer value or an
/// empty/absent record; the resolver always falls back on null.
class CharacterScopeState {
  const CharacterScopeState({
    this.identity,
    this.baseVoice,
    this.baseVisualProfile,
    this.baseRelationReferences,
    this.alternateHistory,
    this.alternateRelationships,
    this.eraSpecificFacts,
    this.role,
    this.arc,
    this.currentLocation,
    this.currentAge,
    this.currentStatus,
    this.scenePov,
    this.novelRelationState,
  });

  const CharacterScopeState.empty() : this();

  factory CharacterScopeState.canonical({
    String? identity,
    String? baseVoice,
    String? baseVisualProfile,
    String? baseRelationReferences,
    String? role,
    String? currentStatus,
    String? currentLocation,
  }) => CharacterScopeState(
    identity: identity,
    baseVoice: baseVoice,
    baseVisualProfile: baseVisualProfile,
    baseRelationReferences: baseRelationReferences,
    role: role,
    currentStatus: currentStatus,
    currentLocation: currentLocation,
  );

  factory CharacterScopeState.universeTimeline({
    String? alternateHistory,
    String? alternateRelationships,
    String? eraSpecificFacts,
    String? currentStatus,
    String? currentLocation,
  }) => CharacterScopeState(
    alternateHistory: alternateHistory,
    alternateRelationships: alternateRelationships,
    eraSpecificFacts: eraSpecificFacts,
    currentStatus: currentStatus,
    currentLocation: currentLocation,
  );

  factory CharacterScopeState.novelSpecific({
    String? identity,
    String? role,
    String? arc,
    String? currentLocation,
    String? currentAge,
    String? currentStatus,
    String? scenePov,
    String? novelRelationState,
  }) => CharacterScopeState(
    identity: identity,
    role: role,
    arc: arc,
    currentLocation: currentLocation,
    currentAge: currentAge,
    currentStatus: currentStatus,
    scenePov: scenePov,
    novelRelationState: novelRelationState,
  );

  final String? identity;
  final String? baseVoice;
  final String? baseVisualProfile;
  final String? baseRelationReferences;
  final String? alternateHistory;
  final String? alternateRelationships;
  final String? eraSpecificFacts;
  final String? role;
  final String? arc;
  final String? currentLocation;
  final String? currentAge;
  final String? currentStatus;
  final String? scenePov;
  final String? novelRelationState;
}

/// Resolves the effective identity from all three layers without mutating
/// any of them. Precedence is canonical -> universe/timeline -> novel.
class CharacterScopeEffectiveResolver {
  CharacterScopeEffectiveResolver({
    required this.canonical,
    required this.universeTimeline,
    required this.novelSpecific,
  });

  final CharacterScopeState canonical;
  final CharacterScopeState universeTimeline;
  final CharacterScopeState novelSpecific;

  String? get identity => _first(
    novelSpecific.identity,
    universeTimeline.identity,
    canonical.identity,
  );

  String? get role =>
      _first(novelSpecific.role, universeTimeline.role, canonical.role);

  String? get currentStatus => _first(
    novelSpecific.currentStatus,
    universeTimeline.currentStatus,
    canonical.currentStatus,
  );

  String? get currentLocation => _first(
    novelSpecific.currentLocation,
    universeTimeline.currentLocation,
    canonical.currentLocation,
  );

  String? _first(String? novel, String? universe, String? base) =>
      novel ?? universe ?? base;
}

/// Explicit scoped command. Writes only the declared scope: `execute`
/// rejects any field not owned by `targetLayer` with an [ArgumentError], so a
/// scoped edit can never silently mutate another layer (in particular
/// canonical identity). Persistence wiring lands in a later slice; the
/// payload already carries the explicit scope discriminator.
class UpdateCharacterScopeCommand extends BaseCommand {
  UpdateCharacterScopeCommand({
    required super.id,
    required super.projectId,
    required this.targetLayer,
    required this.field,
    required this.value,
  }) : super(label: 'Update Character ${field.toLowerCase()}');

  final CharacterScopeLayer targetLayer;
  final String field;
  final String value;

  @override
  String get commandType => 'character.scope.update';

  @override
  Map<String, Object?> get payload => {
    'scope': targetLayer.name,
    'field': field,
    'value': value,
  };

  @override
  Future<void> execute() async {
    if (!CharacterScopeFieldOwnership.owns(targetLayer, field)) {
      throw ArgumentError(
        'Field $field is not owned by scope ${targetLayer.name}',
      );
    }
  }

  // Persistence wiring (scoped tables + migration preserving canonical data)
  // is the next slice of 145.26; until it lands this command validates the
  // scope contract only, so undo/redo must not claim durable state yet.
  @override
  Future<void> undo() async {}

  @override
  Future<void> redo() => execute();
}
