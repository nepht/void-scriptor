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
import 'package:void_scriptor/features/workspaces/application/narrative_assignment_repository.dart';
import 'package:void_scriptor/features/workspaces/domain/narrative_assignment.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// hunt-run157 BUG-18: support relationship type/duration/status render as
/// raw wire tokens ("travel_companion · permanent · active") in the inspector
/// row and the edit dialog, inconsistent with the narrative card's human
/// labels. Users must read human labels, never wire tokens.
void main() {
  Future<(ProjectPackage, ProjectSession, String)> seed(
    WidgetTester tester,
    String name,
  ) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String aId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('support-labels-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support Labels $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      aId = (await repo.createCharacter(name: 'Qowner')).assetId;
      final bId = (await repo.createCharacter(name: 'Byte')).assetId;
      final now = DateTime.now();
      const novelId = 'novel-first';
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: novelId,
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
              assetId: novelId,
              projectId: package.projectId,
              title: 'First Novel',
            ),
          );
      await NarrativeAssignmentRepository(
        database: session.database,
        projectId: package.projectId,
      ).saveSupport(
        SupportRelationship(
          sourceCharacterId: aId,
          supportedId: bId,
          storyNovelWorkspaceId: novelId,
          type: SupportType.travelCompanion,
          duration: SupportDuration.permanent,
          status: SupportStatus.active,
        ),
      );
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

  testWidgets('inspector row shows human labels instead of raw wire tokens', (
    tester,
  ) async {
    final (package, session, aId) = await seed(tester, 'row');
    await pumpInspector(tester, session, aId);
    expect(find.textContaining('travel_companion'), findsNothing);
    expect(find.textContaining('Travel companion'), findsOneWidget);
  });

  testWidgets(
    'edit dialog dropdowns show human labels instead of raw wire tokens',
    (tester) async {
      final (package, session, aId) = await seed(tester, 'dialog');
      await pumpInspector(tester, session, aId);
      await tester.tap(find.text('Byte'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Support'), findsOneWidget);
      expect(find.text('travel_companion'), findsNothing);
      expect(find.text('Travel companion'), findsOneWidget);
      expect(find.text('permanent'), findsNothing);
      expect(find.text('Permanent'), findsOneWidget);
      expect(find.text('active'), findsNothing);
      expect(find.text('Active'), findsOneWidget);
    },
  );
}
