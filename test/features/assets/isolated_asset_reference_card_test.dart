import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/presentation/widgets/isolated_asset_reference_card.dart';

void main() {
  testWidgets('keeps description outside the isolated image area', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IsolatedAssetReferenceCard(
            name: 'Void Guard',
            assetType: 'Armor',
            description: 'Armor pertahanan Qowner.',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('isolated-reference-image-area')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('isolated-reference-description')),
      findsOneWidget,
    );
    expect(find.text('Void Guard'), findsOneWidget);
    expect(find.text('Armor pertahanan Qowner.'), findsOneWidget);
    expect(find.text('Add isolated reference'), findsOneWidget);
  });
}
