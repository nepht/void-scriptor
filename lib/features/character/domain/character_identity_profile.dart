class CharacterIdentityProfile {
  const CharacterIdentityProfile({
    required this.characterId,
    this.faceLock = true,
    this.hairLock = true,
    this.bodyLock = true,
    this.colorLock = true,
    this.outfitLock = false,
    this.weaponLock = false,
  });

  final String characterId;
  final bool faceLock;
  final bool hairLock;
  final bool bodyLock;
  final bool colorLock;
  final bool outfitLock;
  final bool weaponLock;
}
