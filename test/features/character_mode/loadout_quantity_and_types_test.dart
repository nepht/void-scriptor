// Loadout picker create hook for creature/vehicle (product decision,
// Choirudin 2026-09-06): the picker's Create action must be available when
// the editor requests those asset types, and the created asset's name must
// survive the picker round-trip (C fix: no 'Unknown asset' fallback right
// after creation).
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/asset_picker.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_section.dart';

void main() {
  late ProjectDatabase database;

  setUp(() async {
    database = ProjectDatabase(NativeDatabase.memory());
    await database.initialize();
  });

  tearDown(() => database.close());

  Future<void> pumpPicker(
    WidgetTester tester, {
    required String assetType,
    required ValueChanged<String> onCreateType,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AssetPicker(
          assets: const [],
          assetType: assetType,
          onSelected: (_) {},
          onCreate: () async {
            onCreateType(assetType);
            return null;
          },
        ),
      ),
    ),
  );

  testWidgets('create hook fires for creature type', (tester) async {
    var createdType = '';
    await pumpPicker(
      tester,
      assetType: 'creature',
      onCreateType: (type) => createdType = type,
    );
    await tester.tap(find.text('Create creature'));
    await tester.pump();
    expect(createdType, 'creature');
  });

  testWidgets('create hook fires for vehicle type', (tester) async {
    var createdType = '';
    await pumpPicker(
      tester,
      assetType: 'vehicle',
      onCreateType: (type) => createdType = type,
    );
    await tester.tap(find.text('Create vehicle'));
    await tester.pump();
    expect(createdType, 'vehicle');
  });

  test('created asset name survives loadout picker round-trip', () async {
    await database.assetDao.createStandaloneAsset(
      id: 'created-vehicle-1',
      projectId: 'project-1',
      name: 'Void Skiff — Fixture (bukan canon)',
      description: 'Vehicle fixture.',
      type: 'vehicle',
      now: DateTime(2026),
    );
    final assets = await database.assetDao.getAllAssets();
    final label = loadoutAssetLabel('created-vehicle-1', assets);
    expect(label, 'Void Skiff — Fixture (bukan canon)');
    expect(label, isNot('Unknown asset'));
  });
}
