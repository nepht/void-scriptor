import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/my_library_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan library', (tester) async {
    await tester.pumpWidget(wrap(const MyLibraryScreen()));
    expect(find.text('My Library'), findsOneWidget);
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('Updates'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const MyLibraryScreen()));
    expect(tester.takeException(), isNull);
  });
}
