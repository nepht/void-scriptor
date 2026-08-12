class CharacterReference {
  const CharacterReference({
    required this.id,
    required this.characterId,
    required this.type,
    required this.filePath,
    this.priority = 0,
    this.primaryReference = false,
  });

  final String id;
  final String characterId;
  final String type;
  final String filePath;
  final int priority;
  final bool primaryReference;
}
