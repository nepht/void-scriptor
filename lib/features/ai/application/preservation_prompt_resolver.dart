class PreservationLocks {
  const PreservationLocks({
    this.faceLock = false,
    this.hairLock = false,
    this.bodyLock = false,
    this.colorLock = false,
    this.outfitLock = false,
    this.weaponLock = false,
  });
  final bool faceLock;
  final bool hairLock;
  final bool bodyLock;
  final bool colorLock;
  final bool outfitLock;
  final bool weaponLock;
}

class PreservationPromptResolver {
  List<String> resolve(PreservationLocks profile) => [
    if (profile.faceLock)
      'Preserve exact facial identity and facial proportions.',
    if (profile.hairLock)
      'Preserve hairstyle geometry, length and strand direction.',
    if (profile.bodyLock) 'Preserve body proportions and topology.',
    if (profile.colorLock) 'Preserve established character color palette.',
    if (profile.outfitLock) 'Preserve wardrobe geometry and construction.',
    if (profile.weaponLock) 'Preserve weapon geometry and proportions.',
  ];
}
