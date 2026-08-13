import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';

void main() {
  testWidgets('Bible route opens Project Bible workspace', (tester) async {
    final router = createAppRouter(initialLocation: AppRoutes.bible);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.byType(ProjectBibleWorkspaceScreen), findsOneWidget);
    expect(find.text('PROJECT BIBLE'), findsOneWidget);
  });
}
