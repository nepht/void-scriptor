import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/dashboard/presentation/widgets/storage_card.dart';

void main() {
  testWidgets('storage card does not claim unmeasured quota', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StorageCard(onManage: () => opened = true)),
      ),
    );

    expect(find.text('Local storage'), findsOneWidget);
    expect(find.text('Usage is calculated per project.'), findsOneWidget);
    expect(find.textContaining('GB of'), findsNothing);

    await tester.tap(find.text('Manage local storage'));
    expect(opened, isTrue);
  });
}
