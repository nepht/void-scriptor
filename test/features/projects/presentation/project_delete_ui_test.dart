import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/projects/data/project_repository_impl.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/project_list_screen.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  testWidgets('project deletion requires its exact name and removes the card', (
    tester,
  ) async {
    final source = ProjectLocalDataSource();
    final now = DateTime(2026, 9, 2);
    await source.createProject(
      ProjectModel(
        id: 'void-universe',
        name: 'Void Universe',
        description: 'Main universe',
        createdAt: now,
        updatedAt: now,
        lastOpenedAt: now,
        localPath: r'D:\VoidScriptor\Projects\void-universe.voidproject',
        version: '0.1.0',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectLocalDataSourceProvider.overrideWithValue(source),
          projectRepositoryProvider.overrideWithValue(
            ProjectRepositoryImpl(source),
          ),
        ],
        child: const MaterialApp(home: ProjectListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Project actions for Void Universe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Project'));
    await tester.pumpAndSettle();

    final confirmFinder = find.byKey(
      const Key('confirm-delete-project-button'),
    );
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Void Universe');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNotNull);

    await tester.tap(confirmFinder);
    await tester.pumpAndSettle();

    expect(find.text('Void Universe'), findsNothing);
    expect(await source.getProjects(), isEmpty);
    expect(
      find.text('Project removed. Local files were kept.'),
      findsOneWidget,
    );
  });
}
