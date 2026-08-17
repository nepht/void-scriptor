import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/creator_store_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan store creator', (tester) async {
    await tester.pumpWidget(wrap(const CreatorStoreScreen()));
    expect(find.text('Creator Store'), findsOneWidget);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CreatorStoreScreen()));
    expect(tester.takeException(), isNull);
  });
}
