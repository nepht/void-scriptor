import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/domain/loadout_slot.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_section.dart';

void main() {
  final asset = Asset(
    id: 'armor-1',
    projectId: 'project-1',
    name: 'Void Guard',
    description: 'Stand-alone armor',
    type: 'armor',
    version: '1.0.0',
    thumbnailPath: null,
    favorite: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    lastOpenedAt: null,
  );

  test('resolves loadout asset id to human-readable asset name', () {
    expect(loadoutAssetLabel('armor-1', [asset]), 'Void Guard');
    expect(loadoutAssetLabel(null, [asset]), 'None');
    expect(loadoutAssetLabel('missing', [asset]), 'Unknown asset');
  });

  test('detects cleared and replaced single-value assignments', () {
    expect(
      loadoutSlotChange(
        slot: LoadoutSlot.armor,
        originalAssetId: 'armor-1',
        selectedAssetId: null,
      ),
      LoadoutSlotChange.remove,
    );
    expect(
      loadoutSlotChange(
        slot: LoadoutSlot.armor,
        originalAssetId: 'armor-1',
        selectedAssetId: 'armor-2',
      ),
      LoadoutSlotChange.replace,
    );
    expect(
      loadoutSlotChange(
        slot: LoadoutSlot.armor,
        originalAssetId: 'armor-1',
        selectedAssetId: 'armor-1',
      ),
      LoadoutSlotChange.unchanged,
    );
  });
}
