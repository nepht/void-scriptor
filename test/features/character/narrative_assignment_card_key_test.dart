import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/character/presentation/widgets/narrative_assignment_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _FakeSessionController extends ProjectSessionController {
  _FakeSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

/// hunt-run157 BUG-01 follow-up (Referee fix direction): the narrative
/// assignment card is instantiated WITHOUT a key, so its State survives a
/// character switch and a straddled in-flight load could combine one
/// character's editor with another character's id. Contract: the workspace
/// screen keys the card per character (same pattern as the resolver's
/// `wb-<projectId>` keying).
void main() {
  testWidgets(
    'narrative assignment card is keyed per character in the workspace',
    (tester) async {
      late Directory root;
      late ProjectPackage package;
      late ProjectSession session;
      late String characterId;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('narr-key-');
        addTearDown(() => root.delete(recursive: true));
        package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Narrative Key');
        session = await ProjectSessionManager().open(package);
        addTearDown(session.database.close);
        final charRepo = CharacterRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
          paths: ProjectPaths(rootDirectory: package.root.parent),
        );
        final character = await charRepo.createCharacter(name: 'Qowner');
        characterId = character.assetId;
      });
      await tester.binding.setSurfaceSize(const Size(1280, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FakeSessionController(session),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 1400,
                child: CharacterWorkspaceScreen(
                  characterId: characterId,
                  activeSection: 'Story',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<NarrativeAssignmentCard>(
        find.byType(NarrativeAssignmentCard),
      );
      final key = card.key;
      expect(
        key,
        isA<ValueKey<String>>(),
        reason:
            'card must be keyed per '
            'character so its State cannot straddle a character switch',
      );
      expect((key as ValueKey<String>).value, contains(characterId));
    },
    skip: !Platform.isWindows,
  );
}
