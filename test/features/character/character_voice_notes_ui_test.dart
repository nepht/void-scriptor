import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/character/presentation/widgets/identity_preservation_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets(
    'character workspace displays voice row and opens private notes editor',
    (tester) async {
      late final Directory root;
      late final ProjectPackage package;
      late final ProjectSession session;
      late final String characterId;

      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('voice-notes-ui-');
        package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Voice Notes UI');
        session = await ProjectSessionManager().open(package);

        final repo = CharacterRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
          paths: ProjectPaths(rootDirectory: package.root.parent),
        );
        final character = await repo.createCharacter(name: 'Qowner');
        characterId = character.assetId;
        await repo.updateCharacter(
          character.copyWith(voice: 'Tenang, berwibawa, sedikit serak'),
        );
      });

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
                child: CharacterWorkspaceScreen(characterId: characterId),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Canonical BASE_VOICE must be visible in the identity card.
      expect(find.text('Tenang, berwibawa, sedikit serak'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);

      // Private notes are owned by the canonical Notes section.
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
                child: CharacterWorkspaceScreen(
                  characterId: characterId,
                  activeSection: 'Notes',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Character Private Notes'));
      await tester.pumpAndSettle();
      expect(find.text('Character Private Notes'), findsOneWidget);
      expect(find.text('Place your private notes here'), findsOneWidget);

      final fieldFinder = find.byType(TextField);
      expect(fieldFinder, findsOneWidget);
      await tester.enterText(fieldFinder, 'Jangan ubah warna mata');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Persistence through the production identity action path.
      // Drift writes are real async IO: poll with a bounded deadline.
      CharacterIdentityProfile? stored;
      await tester.runAsync(() async {
        final repo = CharacterRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
          paths: ProjectPaths(rootDirectory: package.root.parent),
        );
        for (var i = 0; i < 50; i++) {
          final identity = await repo.getIdentity(characterId);
          if (identity != null && identity.notes == 'Jangan ubah warna mata') {
            stored = identity;
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      expect(stored, isNotNull);
      expect(stored!.notes, 'Jangan ubah warna mata');
      final initialFaceLock = stored!.faceLock;

      // Continuity locks are owned by Wardrobe; switching owners must preserve
      // the notes written through the Notes section.
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
                height: 1200,
                child: CharacterWorkspaceScreen(
                  characterId: characterId,
                  activeSection: 'Wardrobe',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final switchFinder = find
          .descendant(
            of: find.byType(IdentityPreservationCard),
            matching: find.byType(Switch),
          )
          .first;
      final lockSwitch = tester.widget<Switch>(switchFinder);
      lockSwitch.onChanged!(!lockSwitch.value);
      await tester.pumpAndSettle();
      var toggleLanded = false;
      await tester.runAsync(() async {
        final repo = CharacterRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
          paths: ProjectPaths(rootDirectory: package.root.parent),
        );
        for (var i = 0; i < 50; i++) {
          final identity = await repo.getIdentity(characterId);
          if (identity != null && identity.faceLock != initialFaceLock) {
            toggleLanded = true;
            expect(
              identity.notes,
              'Jangan ubah warna mata',
              reason:
                  'Toggling a lock must not silently drop the private notes '
                  '(scoped edit safety, 145.26 guidance)',
            );
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      expect(toggleLanded, isTrue, reason: 'lock toggle write never landed');
    },
  );
}
