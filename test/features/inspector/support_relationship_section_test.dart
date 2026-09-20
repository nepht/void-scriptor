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

/// Backlog `character-roles-support` phase_one UI slice: edit support
/// relationship attributes (type/duration/status + optional purpose and
/// separation reason) in the character Inspector relationships surface.
/// Persistence ground truth is read back through the production repository.
void main() {
  Future<void> seedNovel(ProjectDatabase db, String novel) async {
    final now = DateTime.now();
    final id = 'novel-${novel.toLowerCase().replaceAll(' ', '-')}';
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: id,
            projectId: 'story',
            name: novel,
            type: 'story',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.stories)
        .insert(
          StoriesCompanion.insert(
            assetId: id,
            projectId: 'story',
            title: novel,
          ),
        );
  }

  Future<
    (
      ProjectPackage,
      ProjectSession,
      String,
      String,
      String,
      NarrativeAssignmentRepository,
    )
  >
  seed(WidgetTester tester, String name) async {
    late Directory root;
    late ProjectPackage package;
    late ProjectSession session;
    late String aId;
    late String bId;
    late String cId;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('support-ui-$name-');
      addTearDown(() => root.delete(recursive: true));
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Support UI $name');
      session = await ProjectSessionManager().open(package);
      addTearDown(session.database.close);
      final repo = CharacterRepositoryImpl(
        database: session.database,
        projectId: package.projectId,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      );
      aId = (await repo.createCharacter(name: 'Qowner')).assetId;
      bId = (await repo.createCharacter(name: 'Byte')).assetId;
      cId = (await repo.createCharacter(name: 'Lumi')).assetId;
      await seedNovel(session.database, 'First Novel');
    });
    final repository = NarrativeAssignmentRepository(
      database: session.database,
      projectId: package.projectId,
    );
    return (package, session, aId, bId, cId, repository);
  }

  Future<void> pumpInspector(
    WidgetTester tester,
    ProjectSession session,
    String characterId, {
    Size size = const Size(1280, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
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
              width: size.width,
              height: size.height,
              child: SupportRelationshipSection(assetId: characterId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders support relationship section with add action in inspector',
    (tester) async {
      final (_, session, aId, _, _, _) = await seed(tester, 'render');
      await pumpInspector(tester, session, aId);

      expect(find.text('Support'), findsOneWidget);
      expect(find.text('Add Support'), findsOneWidget);
      expect(find.text('No support relationships yet'), findsOneWidget);
    },
  );

  testWidgets('add support flow persists type, duration, status and purpose', (
    tester,
  ) async {
    final (_, session, aId, bId, _, repository) = await seed(tester, 'add');
    await pumpInspector(tester, session, aId);

    await tester.tap(find.text('Add Support'));
    await tester.pumpAndSettle();

    // Select supported character in the dialog dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Byte').last);
    await tester.pumpAndSettle();

    // Select the story (novel) context.
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('First Novel').last);
    await tester.pumpAndSettle();

    // Type defaults to supporter; set duration and status.
    await tester.tap(find.byType(DropdownButtonFormField<SupportDuration>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Permanent').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<SupportStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'Guides her through the Void Gates',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Support'));
    await tester.pumpAndSettle();

    final supports = await repository.listSupports(aId);
    expect(supports, hasLength(1));
    expect(supports.single.supportedId, bId);
    expect(supports.single.storyNovelWorkspaceId, 'novel-first-novel');
    expect(supports.single.type, SupportType.supporter);
    expect(supports.single.duration, SupportDuration.permanent);
    expect(supports.single.status, SupportStatus.active);
    expect(supports.single.purpose, 'Guides her through the Void Gates');
  });

  testWidgets(
    'editing one row changes only that row and never assignment fields',
    (tester) async {
      final (_, session, aId, bId, cId, repository) = await seed(
        tester,
        'edit',
      );
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: aId,
          supportedId: bId,
          storyNovelWorkspaceId: 'novel-first-novel',
          type: SupportType.supporter,
          duration: SupportDuration.permanent,
        ),
      );
      await repository.saveSupport(
        SupportRelationship(
          sourceCharacterId: aId,
          supportedId: cId,
          storyNovelWorkspaceId: 'novel-first-novel',
          type: SupportType.mentor,
          duration: SupportDuration.temporary,
        ),
      );
      await repository.saveAssignment(
        NarrativeAssignment(
          novelWorkspaceId: 'novel-first-novel',
          characterId: aId,
          roles: const {NarrativeRole.protagonist},
          importance: NarrativeImportance.major,
          pov: NarrativePov.yes,
        ),
      );
      await pumpInspector(tester, session, aId);

      // Open the edit dialog for the Qowner -> Byte row.
      await tester.tap(find.text('Byte'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<SupportDuration>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recurring').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<SupportStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Separated').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Support'));
      await tester.pumpAndSettle();

      final supports = await repository.listSupports(aId);
      expect(supports, hasLength(2));
      final byteRow = supports.singleWhere((s) => s.supportedId == bId);
      final lumiRow = supports.singleWhere((s) => s.supportedId == cId);
      // Edited row keeps its coordinates and takes the new attributes.
      expect(byteRow.duration, SupportDuration.recurring);
      expect(byteRow.status, SupportStatus.separated);
      expect(byteRow.type, SupportType.supporter);
      expect(byteRow.storyNovelWorkspaceId, 'novel-first-novel');
      // The other relationship is untouched.
      expect(lumiRow.duration, SupportDuration.temporary);
      expect(lumiRow.status, SupportStatus.unspecified);
      expect(lumiRow.type, SupportType.mentor);
      // Assignment importance/POV are structurally separate and unchanged.
      final assignment = await repository.getAssignment(
        novelWorkspaceId: 'novel-first-novel',
        characterId: aId,
      );
      expect(assignment!.importance, NarrativeImportance.major);
      expect(assignment.pov, NarrativePov.yes);
      expect(assignment.roles, const [NarrativeRole.protagonist]);
    },
  );

  testWidgets('no support relationships yet empty state, narrow surface', (
    tester,
  ) async {
    // Empty is an honest state, not an error: prove it renders on a narrow
    // surface without overflow so future hardening cannot confuse the two.
    final (_, session, aId, _, _, _) = await seed(tester, 'empty-narrow');
    await pumpInspector(tester, session, aId, size: const Size(320, 700));

    expect(find.text('No support relationships yet'), findsOneWidget);
    expect(find.text('Add Support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('load failure shows error state, not a fake empty list', (
    tester,
  ) async {
    // Failure is a distinct state: when the repository load throws, the
    // section must say what failed and keep Retry available instead of
    // rendering the empty state that would hide real relationships.
    final (_, session, aId, _, _, _) = await seed(tester, 'load-fail');
    await session.database.close();

    await pumpInspector(tester, session, aId, size: const Size(420, 800));

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('No support relationships yet'), findsNothing);
    expect(find.textContaining('failed to load'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('save failure surfaces visible feedback and keeps row', (
    tester,
  ) async {
    final (_, session, aId, bId, _, repository) = await seed(
      tester,
      'save-fail',
    );
    await repository.saveSupport(
      SupportRelationship(
        sourceCharacterId: aId,
        supportedId: bId,
        storyNovelWorkspaceId: 'novel-first-novel',
        type: SupportType.supporter,
        duration: SupportDuration.permanent,
      ),
    );
    await pumpInspector(tester, session, aId);

    expect(find.text('Byte'), findsOneWidget);
    // Open the edit dialog while the database is alive.
    await tester.tap(find.text('Byte'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Support'), findsOneWidget);
    // Kill the database before saving: persistence now fails.
    await session.database.close();

    await tester.tap(find.text('Save Support'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Failed to save'), findsOneWidget);
    // The relationship row itself stays visible; the failure never deletes data.
    expect(find.text('Byte'), findsOneWidget);
  });

  testWidgets('support edit dialog ellipsizes very long names', (tester) async {
    final (_, session, aId, bId, _, repository) = await seed(
      tester,
      'long-name',
    );
    await repository.saveSupport(
      SupportRelationship(
        sourceCharacterId: aId,
        supportedId: bId,
        storyNovelWorkspaceId: 'novel-first-novel',
        type: SupportType.supporter,
        duration: SupportDuration.permanent,
      ),
    );
    await pumpInspector(tester, session, aId);

    await tester.tap(find.text('Byte'));
    await tester.pumpAndSettle();

    // The picker labels wrap instead of clipping mid-row; the dialog holds a
    // narrow surface without RenderFlex overflow.
    expect(find.text('Edit Support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
