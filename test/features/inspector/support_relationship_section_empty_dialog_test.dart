import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/support_relationship_section.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// hunt-run157 BUG-14: the Add Support dialog opened with empty novel and
/// character dropdowns and a silently disabled Save button, with no
/// explanation of WHY nothing can be selected. The dialog must say what is
/// missing and what to do next instead of rendering dead controls.
void main() {
  Future<(ProjectPackage, ProjectSession, String)> seed(
    WidgetTester tester,
    String name, {
    required bool withOtherCharacter,
    required bool withNovel,
  }) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String aId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('support-empty-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support Empty $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      aId = (await repo.createCharacter(name: 'Qowner')).assetId;
      if (withOtherCharacter) {
        await repo.createCharacter(name: 'Byte');
      }
      if (withNovel) {
        final now = DateTime.now();
        const id = 'novel-first';
        await session.database
            .into(session.database.assets)
            .insert(
              AssetsCompanion.insert(
                id: id,
                projectId: package.projectId,
                name: 'First Novel',
                type: 'story',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await session.database
            .into(session.database.stories)
            .insert(
              StoriesCompanion.insert(
                assetId: id,
                projectId: package.projectId,
                title: 'First Novel',
              ),
            );
      }
    });
    return (package, session, aId);
  }

  Future<void> pumpInspector(
    WidgetTester tester,
    ProjectSession session,
    String characterId,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 900,
              child: SupportRelationshipSection(assetId: characterId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'add-support dialog with no novels explains the missing prerequisite '
    'instead of silently disabled save',
    (tester) async {
      final (package, session, aId) = await seed(
        tester,
        'nonovel',
        withOtherCharacter: true,
        withNovel: false,
      );
      await pumpInspector(tester, session, aId);
      await tester.tap(find.text('Add Support'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No stories/novels exist yet'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'add-support dialog with no other characters explains the missing '
    'prerequisite instead of silently disabled save',
    (tester) async {
      final (package, session, aId) = await seed(
        tester,
        'nochar',
        withOtherCharacter: false,
        withNovel: true,
      );
      await pumpInspector(tester, session, aId);
      await tester.tap(find.text('Add Support'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No other characters exist yet'),
        findsOneWidget,
      );
    },
  );
}
