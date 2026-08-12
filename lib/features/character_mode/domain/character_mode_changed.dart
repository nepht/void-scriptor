class CharacterModeChanged {
  const CharacterModeChanged({
    required this.characterId,
    required this.previousModeId,
    required this.currentModeId,
  });

  final String characterId;
  final String? previousModeId;
  final String currentModeId;
}
