/// Sprint 47 — Step 47.51–47.60 Inventory, Equipment, XP, Save Games.
class Inventory {
  const Inventory({
    required this.id,
    required this.entityId,
    this.items = const [],
    this.equipment = const [],
  });

  final String id;
  final String entityId;
  final List<InventoryItem> items;
  final List<String> equipment;

  int get totalCount => items.fold(0, (sum, i) => sum + i.quantity);
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
  });

  final String id;
  final String name;
  final int quantity;
}

class XpLevel {
  const XpLevel({required this.level, required this.xpRequired});

  final int level;
  final int xpRequired;
}

class SkillTree {
  const SkillTree({
    required this.id,
    required this.skillNodes,
    this.unlockedNodeIds = const [],
  });

  final String id;
  final Map<String, SkillNode> skillNodes;
  final List<String> unlockedNodeIds;

  SkillTree unlock(String nodeId) {
    if (!skillNodes.containsKey(nodeId)) return this;
    final unlocked = [...unlockedNodeIds, nodeId];
    return SkillTree(id: id, skillNodes: skillNodes, unlockedNodeIds: unlocked);
  }
}

class SkillNode {
  const SkillNode({required this.id, required this.name});

  final String id;
  final String name;
}

class SaveGame {
  const SaveGame({
    required this.id,
    required this.projectId,
    required this.savedAt,
    this.checkpointId,
    this.data = const {},
  });

  final String id;
  final String projectId;
  final DateTime savedAt;
  final String? checkpointId;
  final Map<String, Object> data;
}
