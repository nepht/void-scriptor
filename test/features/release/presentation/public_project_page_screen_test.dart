import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/presentation/public_project_page_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan halaman project publik', (tester) async {
    await tester.pumpWidget(wrap(const PublicProjectPageScreen()));
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const PublicProjectPageScreen()));
    expect(tester.takeException(), isNull);
  });
}
