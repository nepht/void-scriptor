// Slice 145.43 friksi #1: wiring resolver -> layar novel -> service link.
// Production proof: saat sesi proyek hidup dan katalog karakter berisi data,
// kartu Linked Characters pada Outline harus menyediakan aksi link yang
// benar-benar persist dan menampilkan hasilnya.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}

class _FixedSelection extends SelectionController {
  _FixedSelection(this._selection);

  final SelectionModel _selection;

  @override
  SelectionModel? build() => _selection;
}

void main() {
  Future<Directory> makeTemp(WidgetTester tester, String prefix) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp(prefix),
    );
    return dir!;
  }

  Future<({ProjectSession session, String storyId, String? characterId})> seed(
    WidgetTester tester,
    Directory temp, {
    bool withCharacter = true,
  }) async {
    final session = await tester.runAsync(() async {
      final package = await ProjectPackageService(
        rootDirectory: Directory('${temp.path}/pkg'),
      ).create(name: 'Link Wiring Novel');
      return ProjectSessionManager().open(package);
    });
    final liveSession = session!;
    addTearDown(liveSession.close);
    final storyId = await tester.runAsync(
      () async => CreateStoryService(
        database: liveSession.database,
        paths: ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
      ).createStory(projectId: liveSession.manifest.id, title: 'Wired Novel'),
    );
    String? characterId;
    if (withCharacter) {
      characterId = await tester.runAsync(
        () => CreateCharacterService(
          database: liveSession.database,
          paths: ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
        ).create(projectId: liveSession.manifest.id, name: 'Raka'),
      );
    }
    return (session: liveSession, storyId: storyId!, characterId: characterId);
  }

  Future<void> pumpResolver(
    WidgetTester tester,
    ProjectSession session,
    String storyId,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(session)),
          selectionProvider.overrideWith(
            () => _FixedSelection(
              SelectionModel(
                assetId: storyId,
                assetType: AssetType.story,
                projectId: session.manifest.id,
              ),
            ),
          ),
        ],
        // Default view (tanpa section): kartu Linked Characters tampil di
        // tree ter-commit maupun saat blok Outline sibling ter-merge.
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('aksi link dari kartu persist dan menampilkan link baru', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'link-wiring-');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });
    final fixture = await seed(tester, temp);
    await pumpResolver(tester, fixture.session, fixture.storyId);

    expect(find.byTooltip('Link character'), findsOneWidget);

    // Dialog pilih karakter + persist SQLite nyata berjalan di zone asli.
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Link character'));
      await tester.pump();
      // Katalog dimuat lewat I/O SQLite nyata: beri waktu nyata, lalu
      // pump tetap (bukan pumpAndSettle - dialog terbuka tanpa animasi
      // yang bisa berhenti).
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Link character to novel'), findsOneWidget);
      await tester.tap(find.text('Raka'));
      await tester.pump();
      // Persist + projection reload: I/O nyata.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();

    final persisted = await tester.runAsync(
      () => fixture.session.novelCharacterLinks.listForNovel(fixture.storyId),
    );
    expect(persisted, hasLength(1));
    expect(persisted!.single.characterId, fixture.characterId);
    expect(find.text('${fixture.characterId} · Character'), findsOneWidget);
  });

  testWidgets('katalog karakter kosong: aksi tidak membuat dialog', (
    tester,
  ) async {
    final temp = await makeTemp(tester, 'link-wiring-empty-');
    addTearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });
    final fixture = await seed(tester, temp, withCharacter: false);
    await pumpResolver(tester, fixture.session, fixture.storyId);

    expect(find.byTooltip('Link character'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Link character'));
      await tester.pumpAndSettle();
    });
    await tester.pumpAndSettle();

    expect(find.text('Link character to novel'), findsNothing);
    final persisted = await tester.runAsync(
      () => fixture.session.novelCharacterLinks.listForNovel(fixture.storyId),
    );
    expect(persisted, isEmpty);
  });
}
