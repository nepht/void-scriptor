/// Sprint 47 — Step 47.20–47.30 Combat Framework, Weapons, Damage.
class CombatComponent {
  const CombatComponent({
    required this.entityId,
    required this.health,
    required this.maxHealth,
    required this.attack,
    required this.defense,
  });

  final String entityId;
  final int health;
  final int maxHealth;
  final int attack;
  final int defense;

  bool get isAlive => health > 0;

  CombatComponent takeDamage(int amount) {
    final reduced = (amount - defense).clamp(0, 99999);
    final nextHealth = (health - reduced).clamp(0, maxHealth);
    return CombatComponent(
      entityId: entityId,
      health: nextHealth,
      maxHealth: maxHealth,
      attack: attack,
      defense: defense,
    );
  }
}

enum AttackType { light, heavy, ranged, magic, special, signature }

class ComboGraph {
  const ComboGraph({
    required this.comboId,
    required this.sequence,
    this.currentIndex = 0,
  });

  final String comboId;
  final List<String> sequence;
  final int currentIndex;

  bool get isComplete => currentIndex >= sequence.length;
}

class ComboWindow {
  const ComboWindow({
    required this.comboId,
    required this.windowMs,
    required this.nextAttack,
  });

  final String comboId;
  final int windowMs;
  final String nextAttack;
}

class WeaponComponent {
  const WeaponComponent({
    required this.id,
    required this.entityId,
    required this.name,
    required this.damage,
    required this.weaponType,
  });

  final String id;
  final String entityId;
  final String name;
  final int damage;
  final String weaponType;
}

class DamageModel {
  const DamageModel({
    required this.id,
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.amount,
    required this.type,
  });

  final String id;
  final String sourceEntityId;
  final String targetEntityId;
  final int amount;
  final AttackType type;
}
