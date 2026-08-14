class VoiceProfileModel {
  const VoiceProfileModel({
    required this.characterId,
    required this.displayName,
    required this.language,
    required this.vocalTexture,
    required this.deliveryNotes,
  });
  final String characterId, displayName, language, vocalTexture, deliveryNotes;
}

class VoiceReferenceModel {
  const VoiceReferenceModel({
    required this.id,
    required this.characterId,
    required this.audioFileId,
    required this.name,
    this.primary = false,
  });
  final String id, characterId, audioFileId, name;
  final bool primary;
}

class DialogueLineModel {
  const DialogueLineModel({
    required this.id,
    required this.projectId,
    required this.sceneId,
    required this.characterId,
    required this.text,
    required this.startSeconds,
    required this.durationSeconds,
    required this.subtitleText,
  });
  final String id, projectId, sceneId, characterId, text, subtitleText;
  final double startSeconds, durationSeconds;
}

class DialogueTakeModel {
  const DialogueTakeModel({
    required this.id,
    required this.lineId,
    required this.audioFileId,
    required this.label,
    this.selected = false,
    this.notes = '',
  }) : assert(selected == true || selected == false);
  final String id, lineId, audioFileId, label, notes;
  final bool selected;
}
