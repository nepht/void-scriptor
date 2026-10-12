import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_panel.dart';

class SessionOverride extends ProjectSessionController {
  SessionOverride(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets(
    'empty Character and World navigation does not fall back to Novel',
    (tester) async {
      late Directory root;
      late ProjectSession session;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('empty-workspace-');
        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Empty Project');
        session = await ProjectSessionManager().open(package);
      });
      addTearDown(() async {
        await session.close();
        await root.delete(recursive: true);
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => SessionOverride(session)),
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: root),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    TextButton(
                      onPressed: () =>
                          focusExplorerAsset(ref, AssetType.character),
                      child: const Text('Characters'),
                    ),
                    TextButton(
                      onPressed: () =>
                          focusExplorerAsset(ref, AssetType.environment),
                      child: const Text('World'),
                    ),
                    const Expanded(child: WorkspacePanel()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Characters'));
      await tester.pumpAndSettle();
      expect(find.text('Character Workspace'), findsWidgets);
      expect(find.text('Create Novel'), findsNothing);
      expect(find.text('Buat Karakter'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspacePanel)),
      );
      expect(container.read(selectionProvider), isNull);
      await tester.tap(find.text('World'));
      await tester.pumpAndSettle();
      expect(find.text('Worldbuilding Workspace'), findsWidgets);
      expect(find.text('Buat Lokasi'), findsOneWidget);
      expect(find.text('Create Novel'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Characters'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => tester.tap(find.text('Buat Karakter')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Nebula Character');
      await tester.runAsync(() async {
        await tester.tap(find.text('Create'));
        for (
          var i = 0;
          i < 50 && container.read(selectionProvider) == null;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      // CharacterWorkspaceScreen starts an async provider and may show an
      // indeterminate progress indicator; settling is not required to verify
      // selection/routing and can hang under parallel load.
      await tester.pump();
      expect(container.read(selectionProvider)?.assetType, AssetType.character);
      expect(find.byType(CharacterWorkspaceScreen), findsOneWidget);
      await tester.runAsync(() async {
        final assets = await session.database.assetDao.getAllAssets();
        expect(
          assets.where((asset) => asset.name == 'Nebula Character'),
          hasLength(1),
        );
      });
      expect(tester.takeException(), isNull);
    },
  );
}
