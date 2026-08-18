import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/cinema_workspace_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan cinema workspace', (tester) async {
    await tester.pumpWidget(wrap(const CinemaWorkspaceScreen()));
    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.text('Render'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CinemaWorkspaceScreen()));
    expect(tester.takeException(), isNull);
  });
}
