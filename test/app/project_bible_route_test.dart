import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';

void main() {
  testWidgets('Bible route opens Project Bible workspace', (tester) async {
    final router = createAppRouter(initialLocation: AppRoutes.bible);
    // The Bible workspace reads the project session through Riverpod, so the
    // routed app must run inside a ProviderScope (as it does in main.dart).
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    expect(find.byType(ProjectBibleWorkspaceScreen), findsOneWidget);
    expect(find.text('PROJECT BIBLE'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });
}
