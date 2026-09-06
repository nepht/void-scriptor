// Loadout picker create hook for creature/vehicle (product decision,
// Choirudin 2026-09-06): the picker's Create action must be available when
// the editor requests those asset types.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/asset_picker.dart';

void main() {
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
}
