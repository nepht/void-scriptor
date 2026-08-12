import '../../character/domain/character_identity_profile.dart';

class CharacterModeIdentityOverride {
  const CharacterModeIdentityOverride({
    required this.modeId,
    this.faceLock,
    this.hairLock,
    this.bodyLock,
    this.colorLock,
    this.outfitLock,
    this.weaponLock,
  });

  final String modeId;
  final bool? faceLock;
  final bool? hairLock;
  final bool? bodyLock;
  final bool? colorLock;
  final bool? outfitLock;
  final bool? weaponLock;
}

class EffectiveIdentityProfile {
  const EffectiveIdentityProfile({
    required this.faceLock,
    required this.hairLock,
    required this.bodyLock,
    required this.colorLock,
    required this.outfitLock,
    required this.weaponLock,
  });

  final bool faceLock;
  final bool hairLock;
  final bool bodyLock;
  final bool colorLock;
  final bool outfitLock;
  final bool weaponLock;
}

EffectiveIdentityProfile resolveEffectiveIdentity({
  required CharacterIdentityProfile base,
  required CharacterModeIdentityOverride? override,
}) => EffectiveIdentityProfile(
  faceLock: override?.faceLock ?? base.faceLock,
  hairLock: override?.hairLock ?? base.hairLock,
  bodyLock: override?.bodyLock ?? base.bodyLock,
  colorLock: override?.colorLock ?? base.colorLock,
  outfitLock: override?.outfitLock ?? base.outfitLock,
  weaponLock: override?.weaponLock ?? false,
);
