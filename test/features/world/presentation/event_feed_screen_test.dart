import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/presentation/event_feed_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan event feed', (tester) async {
    await tester.pumpWidget(wrap(const EventFeedScreen()));
    expect(find.text('World Events'), findsOneWidget);
    expect(find.text('Trade route reopened.'), findsOneWidget);
    expect(find.text('Void storm detected.'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const EventFeedScreen()));
    expect(tester.takeException(), isNull);
  });
}
