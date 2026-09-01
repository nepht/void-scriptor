class CharacterIdentityProfile {
  const CharacterIdentityProfile({
    required this.characterId,
    this.faceLock = true,
    this.hairLock = true,
    this.bodyLock = true,
    this.colorLock = true,
    this.outfitLock = false,
    this.weaponLock = false,
    this.accessoryLock = false,
    this.notes = '',
  });

  final String characterId;
  final bool faceLock;
  final bool hairLock;
  final bool bodyLock;
  final bool colorLock;
  final bool outfitLock;
  final bool weaponLock;
  final bool accessoryLock;
  final String notes;

  CharacterIdentityProfile copyWith({
    bool? faceLock,
    bool? hairLock,
    bool? bodyLock,
    bool? colorLock,
    bool? outfitLock,
    bool? weaponLock,
    bool? accessoryLock,
    String? notes,
  }) => CharacterIdentityProfile(
    characterId: characterId,
    faceLock: faceLock ?? this.faceLock,
    hairLock: hairLock ?? this.hairLock,
    bodyLock: bodyLock ?? this.bodyLock,
    colorLock: colorLock ?? this.colorLock,
    outfitLock: outfitLock ?? this.outfitLock,
    weaponLock: weaponLock ?? this.weaponLock,
    accessoryLock: accessoryLock ?? this.accessoryLock,
    notes: notes ?? this.notes,
  );
}
