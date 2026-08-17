/// Sprint 47 — Step 47.61–47.64 Save Slots, HUD Designer.
class SaveSlot {
  const SaveSlot({
    required this.id,
    required this.gameProjectId,
    required this.slotNumber,
    required this.savedAt,
    this.compatible = true,
  });

  final String id;
  final String gameProjectId;
  final int slotNumber;
  final DateTime savedAt;
  final bool compatible;
}

class HudLayout {
  const HudLayout({required this.id, required this.elements});

  final String id;
  final List<HudElement> elements;
}

enum HudElement {
  healthBar,
  manaBar,
  staminaBar,
  minimap,
  questTracker,
  inventoryBar,
  dialogueBox,
  bossBar,
}
