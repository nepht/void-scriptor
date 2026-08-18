import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/presentation/discovery_home_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan discovery home', (tester) async {
    await tester.pumpWidget(wrap(const DiscoveryHomeScreen()));
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('New Releases'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const DiscoveryHomeScreen()));
    expect(tester.takeException(), isNull);
  });
}
