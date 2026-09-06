import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/asset_picker.dart';

void main() {
  testWidgets('shows stand-alone armor creation action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetPicker(
            assets: const [],
            assetType: 'armor',
            onSelected: (_) {},
            onCreate: () async => null,
          ),
        ),
      ),
    );

    expect(find.text('Create armor'), findsOneWidget);
    expect(find.text('No matching assets'), findsOneWidget);
  });

  testWidgets('labels prop creation as story item', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AssetPicker(
            assets: const [],
            assetType: 'prop',
            onSelected: (_) {},
            onCreate: () async => null,
          ),
        ),
      ),
    );

    expect(find.text('Create story item'), findsOneWidget);
  });
}
