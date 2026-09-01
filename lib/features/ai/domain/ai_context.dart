import '../../character/domain/character_quick_ref.dart';

class AiContext {
  const AiContext({
    required this.projectId,
    required this.characterContexts,
    required this.environmentContext,
    required this.sceneContext,
    required this.timelineContext,
    this.sceneAssetContexts = const [],
    this.canonContext = '[RELEVANT CANON CONTEXT]\n(none)',
  });
  final String projectId;
  final List<AiCharacterContext> characterContexts;
  final AiEnvironmentContext? environmentContext;
  final AiSceneContext? sceneContext;
  final AiTimelineContext? timelineContext;
  final List<AiSceneAssetContext> sceneAssetContexts;
  final String canonContext;
}

class AiSceneAssetContext {
  const AiSceneAssetContext({
    required this.assetId,
    required this.name,
    required this.type,
    required this.priority,
    this.state,
    this.references = const [],
  });
  final String assetId;
  final String name;
  final String type;
  final String priority;
  final String? state;
  final List<String> references;
}

class AiCharacterContext {
  const AiCharacterContext({
    required this.characterId,
    required this.name,
    this.alias,
    this.modeName,
    this.identityDescription = '',
    this.wardrobeDescription = '',
    this.weaponDescription = '',
    this.preservationRules = const [],
    this.referenceBundle,
    this.quickRef,
  });
  final String characterId;
  final String name;
  final String? alias;
  final String? modeName;
  final String identityDescription;
  final String wardrobeDescription;
  final String weaponDescription;
  final List<String> preservationRules;
  final AiReferenceBundle? referenceBundle;

  /// Kartu ringkas kanonik karakter (Step 145.25) untuk propagasi
  /// quick reference ke prompt AI.
  final CharacterQuickRef? quickRef;
}

class AiReferenceBundle {
  const AiReferenceBundle({
    required this.referenceIds,
    required this.lockInstructions,
  });
  final List<String> referenceIds;
  final List<String> lockInstructions;
}

class AiEnvironmentContext {
  const AiEnvironmentContext({
    required this.environmentId,
    required this.name,
    this.zone,
    this.timeOfDay,
    this.weather,
    this.lighting,
    this.atmosphere,
    this.continuity,
  });
  final String environmentId;
  final String name;
  final String? zone;
  final String? timeOfDay;
  final String? weather;
  final String? lighting;
  final String? atmosphere;
  final String? continuity;
}

class AiSceneContext {
  const AiSceneContext({
    required this.sceneId,
    required this.title,
    required this.durationSeconds,
    required this.beats,
  });
  final String sceneId;
  final String title;
  final double durationSeconds;
  final List<AiSceneBeat> beats;
}

class AiSceneBeat {
  const AiSceneBeat({
    required this.type,
    required this.content,
    this.startSeconds,
    this.durationSeconds,
  });
  final String type;
  final String content;
  final double? startSeconds;
  final double? durationSeconds;
}

class AiTimelineContext {
  const AiTimelineContext({
    required this.durationSeconds,
    required this.sections,
  });
  final double durationSeconds;
  final List<AiTimelineSection> sections;
}

class AiTimelineSection {
  const AiTimelineSection({
    required this.start,
    required this.end,
    required this.entries,
  });
  final double start;
  final double end;
  final List<String> entries;
}
