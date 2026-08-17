import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/creator_workspace_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan 9 seksi workspace', (tester) async {
    await tester.pumpWidget(wrap(const CreatorWorkspaceScreen()));
    expect(find.text('My Projects'), findsOneWidget);
    expect(find.text('My Characters'), findsOneWidget);
    expect(find.text('My Worlds'), findsOneWidget);
    expect(find.text('My Assets'), findsOneWidget);
    expect(find.text('My Stories'), findsOneWidget);
    expect(find.text('My AI Agents'), findsOneWidget);
    expect(find.text('My Workflows'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('seksi punya ikon', (tester) async {
    await tester.pumpWidget(wrap(const CreatorWorkspaceScreen()));
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CreatorWorkspaceScreen()));
    expect(tester.takeException(), isNull);
  });
}
