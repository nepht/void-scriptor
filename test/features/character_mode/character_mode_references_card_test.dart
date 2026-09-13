import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character_mode/data/character_mode_reference_repository.dart';
import 'package:void_scriptor/features/character_mode/data/character_mode_repository_impl.dart';
import 'package:void_scriptor/features/character_mode/presentation/character_mode_controller.dart';
import 'package:void_scriptor/features/character_mode/presentation/widgets/character_mode_references_card.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  testWidgets('references refresh after project assets invalidation', (
    tester,
  ) async {
    late Directory temp;
    late ProjectSession session;
    late String modeId;
    await tester.runAsync(() async {
      temp = await Directory.systemTemp.createTemp('mode-references-');
      final package = await ProjectPackageService(
        rootDirectory: temp,
      ).create(name: 'References');
      session = await ProjectSessionManager().open(package);
      await session.database
          .into(session.database.assets)
          .insert(
            AssetsCompanion.insert(
              id: 'character',
              projectId: session.manifest.id,
              name: 'Character',
              type: 'character',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          );
      modeId = await CharacterModeRepositoryImpl(session.database).createMode(
        projectId: session.manifest.id,
        characterId: 'character',
        name: 'Base',
      );
    });
    addTearDown(() async {
      await session.close();
      await temp.delete(recursive: true);
    });
    final container = ProviderContainer(
      overrides: [
        projectSessionProvider.overrideWith(() => _FixedSession(session)),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(projectSessionProvider.future));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: CharacterModeReferencesCard(modeId: modeId)),
        ),
      ),
    );

    Future<void> settleReferences() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
    }

    await settleReferences();
    expect(find.text('0 references'), findsOneWidget);
    await tester.runAsync(() async {
      await CharacterModeReferenceRepository(session.database).add(
        modeId: modeId,
        referenceType: 'custom',
        filePath: 'updated-reference.png',
      );
      container.invalidate(projectAssetsProvider);
    });
    await tester.pump();
    await settleReferences();
    expect(find.text('updated-reference.png'), findsOneWidget);
    expect(find.text('1 references'), findsOneWidget);

    await tester.runAsync(() => tester.tap(find.byIcon(Icons.delete_outline)));
    await tester.pump();
    await settleReferences();
    expect(find.text('updated-reference.png'), findsNothing);
    expect(find.text('0 references'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}
