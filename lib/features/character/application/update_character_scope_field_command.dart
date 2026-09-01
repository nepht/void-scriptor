import '../../../core/commands/app_command.dart';
import '../data/character_repository_impl.dart';
import '../domain/character_scope_layers.dart';

/// Scoped field edit for Sprint 145.26 Character Scope Layers.
///
/// Executes a single-field write against ONLY the declared [targetLayer]:
/// the current layer state is read, the owned field is replaced, and the
/// merged state is written back, so sibling fields in the same layer are
/// never silently cleared. A field not owned by the layer is rejected with
/// [ArgumentError] before any database access, and canonical rows are never
/// touched by universe/novel scoped edits (override_never_silently_mutates_
/// canonical). `null` [newValue] clears the override field so the effective
/// resolver falls back to the layer below.
class UpdateCharacterScopeFieldCommand extends BaseCommand {
  UpdateCharacterScopeFieldCommand({
    required super.id,
    required super.projectId,
    required this.repository,
    required this.characterId,
    required this.targetLayer,
    required this.field,
    required this.oldValue,
    required this.newValue,
  }) : super(label: 'Update Character ${field.toLowerCase()} scope');

  final CharacterRepositoryImpl repository;
  final String characterId;
  final CharacterScopeLayer targetLayer;
  final String field;
  final String? oldValue;
  final String? newValue;

  @override
  String get commandType => 'character.scope.field.update';

  @override
  Map<String, Object?> get payload => {
    'characterId': characterId,
    'scope': targetLayer.name,
    'field': field,
    'oldValue': oldValue,
    'newValue': newValue,
  };

  @override
  Map<String, Object?> get undoPayload => {
    'characterId': characterId,
    'scope': targetLayer.name,
    'field': field,
    'value': oldValue,
  };

  CharacterScopeState _mergedState(CharacterScopeState current, String? value) {
    switch (field) {
      case 'IDENTITY':
        return CharacterScopeState(
          identity: value,
          baseVoice: current.baseVoice,
          baseVisualProfile: current.baseVisualProfile,
          baseRelationReferences: current.baseRelationReferences,
        );
      case 'BASE_VOICE':
        return CharacterScopeState(
          identity: current.identity,
          baseVoice: value,
          baseVisualProfile: current.baseVisualProfile,
          baseRelationReferences: current.baseRelationReferences,
        );
      case 'BASE_VISUAL_PROFILE':
        return CharacterScopeState(
          identity: current.identity,
          baseVoice: current.baseVoice,
          baseVisualProfile: value,
          baseRelationReferences: current.baseRelationReferences,
        );
      case 'BASE_RELATION_REFERENCES':
        return CharacterScopeState(
          identity: current.identity,
          baseVoice: current.baseVoice,
          baseVisualProfile: current.baseVisualProfile,
          baseRelationReferences: value,
        );
      case 'ALTERNATE_HISTORY':
        return CharacterScopeState(
          alternateHistory: value,
          alternateRelationships: current.alternateRelationships,
          eraSpecificFacts: current.eraSpecificFacts,
        );
      case 'ALTERNATE_RELATIONSHIPS':
        return CharacterScopeState(
          alternateHistory: current.alternateHistory,
          alternateRelationships: value,
          eraSpecificFacts: current.eraSpecificFacts,
        );
      case 'ERA_SPECIFIC_FACTS':
        return CharacterScopeState(
          alternateHistory: current.alternateHistory,
          alternateRelationships: current.alternateRelationships,
          eraSpecificFacts: value,
        );
      case 'ROLE':
        return CharacterScopeState(
          role: value,
          arc: current.arc,
          currentLocation: current.currentLocation,
          currentAge: current.currentAge,
          currentStatus: current.currentStatus,
          scenePov: current.scenePov,
          novelRelationState: current.novelRelationState,
        );
      case 'ARC':
        return CharacterScopeState(
          role: current.role,
          arc: value,
          currentLocation: current.currentLocation,
          currentAge: current.currentAge,
          currentStatus: current.currentStatus,
          scenePov: current.scenePov,
          novelRelationState: current.novelRelationState,
        );
      case 'CURRENT_LOCATION':
        return CharacterScopeState(
          role: current.role,
          arc: current.arc,
          currentLocation: value,
          currentAge: current.currentAge,
          currentStatus: current.currentStatus,
          scenePov: current.scenePov,
          novelRelationState: current.novelRelationState,
        );
      case 'CURRENT_AGE':
        return CharacterScopeState(
          role: current.role,
          arc: current.arc,
          currentLocation: current.currentLocation,
          currentAge: value,
          currentStatus: current.currentStatus,
          scenePov: current.scenePov,
          novelRelationState: current.novelRelationState,
        );
      case 'CURRENT_STATUS':
        return CharacterScopeState(
          role: current.role,
          arc: current.arc,
          currentLocation: current.currentLocation,
          currentAge: current.currentAge,
          currentStatus: value,
          scenePov: current.scenePov,
          novelRelationState: current.novelRelationState,
        );
      case 'SCENE_POV':
        return CharacterScopeState(
          role: current.role,
          arc: current.arc,
          currentLocation: current.currentLocation,
          currentAge: current.currentAge,
          currentStatus: current.currentStatus,
          scenePov: value,
          novelRelationState: current.novelRelationState,
        );
      case 'NOVEL_RELATION_STATE':
        return CharacterScopeState(
          role: current.role,
          arc: current.arc,
          currentLocation: current.currentLocation,
          currentAge: current.currentAge,
          currentStatus: current.currentStatus,
          scenePov: current.scenePov,
          novelRelationState: value,
        );
      default:
        throw ArgumentError(
          'Field $field is not owned by scope ${targetLayer.name}',
        );
    }
  }

  @override
  Future<void> execute() async {
    if (!CharacterScopeFieldOwnership.owns(targetLayer, field)) {
      throw ArgumentError(
        'Field $field is not owned by scope ${targetLayer.name}',
      );
    }
    final current = (await repository.getScopeStates(
      characterId,
    ))[targetLayer]!;
    await repository.updateScopeState(
      characterId,
      targetLayer,
      _mergedState(current, newValue),
    );
  }

  @override
  Future<void> undo() async {
    final current = (await repository.getScopeStates(
      characterId,
    ))[targetLayer]!;
    await repository.updateScopeState(
      characterId,
      targetLayer,
      _mergedState(current, oldValue),
    );
  }

  @override
  Future<void> redo() => execute();
}
