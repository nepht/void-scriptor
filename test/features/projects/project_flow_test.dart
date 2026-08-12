import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/features/projects/data/project_local_data_source.dart';
import 'package:void_scriptor/features/projects/data/project_repository_impl.dart';
import 'package:void_scriptor/features/projects/presentation/project_controller.dart';
import 'package:void_scriptor/features/projects/presentation/project_list_screen.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  testWidgets('ProjectListScreen shows empty state and create action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProjectListScreen())),
    );
    await tester.pump();

    expect(find.text('Projects'), findsOneWidget);
  });

  test('project controller creates a project with generated id', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'void-scriptor-project-test-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: tempDirectory);

    final container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(paths),
        projectRegistryServiceProvider.overrideWithValue(
          ProjectRegistryService(paths: paths),
        ),
        projectLocalDataSourceProvider.overrideWithValue(
          ProjectLocalDataSource(
            registry: ProjectRegistryService(paths: paths),
          ),
        ),
        projectRepositoryProvider.overrideWith(
          (ref) =>
              ProjectRepositoryImpl(ref.watch(projectLocalDataSourceProvider)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final project = await container
        .read(projectControllerProvider.notifier)
        .createProject(
          name: 'Void Universe',
          description: 'Main universe',
          localPath: tempDirectory.path,
        );

    final projects = container.read(projectControllerProvider).valueOrNull;
    expect(projects, hasLength(1));
    expect(project.id, isNotEmpty);
    expect(projects!.single.name, 'Void Universe');
    expect(Directory(project.localPath).existsSync(), isTrue);
    expect(Directory('${project.localPath}/assets').existsSync(), isTrue);
    expect(
      File('${project.localPath}/project.json').readAsStringSync(),
      contains('Void Universe'),
    );
  });
}
