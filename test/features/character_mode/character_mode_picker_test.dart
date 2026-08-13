import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/asset_picker.dart';

void main() {
  final weapon = Asset(
    id: 'weapon-1',
    projectId: 'project-1',
    name: 'Void Dual Dagger',
    type: 'weapon',
    description: '',
    version: '1',
    favorite: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  final wardrobe = Asset(
    id: 'wardrobe-1',
    projectId: 'project-1',
    name: 'Void Combat Coat',
    type: 'wardrobe',
    description: '',
    version: '1',
    favorite: false,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  testWidgets('asset picker filters by type and query', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetPicker(
            assets: [weapon, wardrobe],
            assetType: 'weapon',
            onSelected: (asset) => selected = asset.id,
          ),
        ),
      ),
    );

    expect(find.text('Void Dual Dagger'), findsOneWidget);
    expect(find.text('Void Combat Coat'), findsNothing);
    await tester.enterText(find.byType(TextField), 'dagger');
    await tester.pump();
    expect(find.text('Void Dual Dagger'), findsOneWidget);
    await tester.tap(find.text('Void Dual Dagger'));
    expect(selected, 'weapon-1');
  });
}
