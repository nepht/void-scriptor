/// Sprint 47 — Step 47.31–47.36 Damage Types, Abilities.
enum DamageType { physical, fire, ice, lightning, voidDamage, holy, poison }

class Ability {
  const Ability({
    required this.id,
    required this.name,
    required this.category,
    required this.cooldownMs,
    this.manaCost = 0,
  });

  final String id;
  final String name;
  final AbilityCategory category;
  final int cooldownMs;
  final int manaCost;
}

enum AbilityCategory { offensive, defensive, utility, passive, ultimate }
