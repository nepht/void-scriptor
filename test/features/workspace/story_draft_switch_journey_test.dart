// Run62 - 145.27 prioritas #1 (keamanan draf saat berpindah workspace):
// jalur produksi WorkspaceResolver + selectionProvider, bukan screen mandiri.
//
// T1: mengetik di Novel workspace TANPA memilih scene secara eksplisit,
//     lalu pindah ke Character workspace dan kembali ke Novel. Draf tidak
//     boleh hilang diam-diam (no silent loss) dan journal durable harus
//     menahan draf sejak ketikan pertama.
// T2: kegagalan persist nyata (database tertutup) harus terlihat lewat
//     banner, dan setelah project dibuka ulang draf dipulihkan lewat
//     panel DRAFT RECOVERY dengan tombol 'Pulihkan Draft'.
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
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

Finder _draftField() => find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.decoration?.hintText == 'Tulis draft scene di sini...',
);

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);
  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}

void main() {
  testWidgets('T1: typing in Novel survives switching to Character and back '
      '(production resolver journey)', (tester) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('vs-draft-journey-'),
    );
    final dir = root!;
    addTearDown(() {
      try {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on FileSystemException {
        // File masih terkunci handle sesi; biarkan OS membersihkan %TEMP%.
      }
    });

    final package = await tester.runAsync(
      () => ProjectPackageService(
        rootDirectory: Directory('${dir.path}/pkg'),
      ).create(name: 'Draft Switch Journey'),
    );
    final session = await tester.runAsync(
      () => ProjectSessionManager().open(package!),
    );
    final liveSession = session!;
    addTearDown(liveSession.close);

    final paths = ProjectPaths(rootDirectory: Directory('${dir.path}/data'));
    final db = liveSession.database;
    final projectId = liveSession.manifest.id;

    final characterId = (await tester.runAsync(
      () => CreateCharacterService(
        database: db,
        paths: paths,
      ).create(projectId: projectId, name: 'Sora'),
    ))!;
    final service = CreateStoryService(database: db, paths: paths);
    final storyId = (await tester.runAsync(
      () => service.createStory(projectId: projectId, title: 'Void Cube'),
    ))!;
    final chapterId = (await tester.runAsync(
      () => service.createChapter(
        storyId: storyId,
        title: 'Chapter 1',
        chapterNumber: 1,
      ),
    ))!;
    final sceneId = (await tester.runAsync(
      () => service.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene 1',
        sceneNumber: 1,
      ),
    ))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(liveSession)),
          projectPathsProvider.overrideWithValue(paths),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspaceResolver)),
    );

    // Novel workspace dibuka lewat selectionProvider (jalur Explorer).
    container
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: storyId,
            assetType: AssetType.story,
            projectId: projectId,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byType(StoryWorkspaceScreen), findsOneWidget);

    // Mengetik TANPA memilih scene (layar baru tanpa scene eksplisit).
    await tester.enterText(_draftField(), 'draf lintas switch');
    await tester.pump(const Duration(milliseconds: 100));

    // Journal durable menahan draf sejak ketikan pertama (no silent loss).
    final journalDir = Directory(
      '${liveSession.package.root.path}/recovery/draft-journal',
    );
    var staged = false;
    for (var i = 0; i < 100 && !staged; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    staged =
        journalDir.existsSync() &&
        journalDir.listSync().whereType<File>().isNotEmpty;
    expect(staged, isTrue, reason: 'journal harus menahan draf segera');

    // Pindah ke Character workspace (jalur produksi yang sama).
    container
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: characterId,
            assetType: AssetType.character,
            projectId: projectId,
          ),
        );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.byType(CharacterWorkspaceScreen), findsOneWidget);

    // Kembali ke Novel workspace.
    container
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: storyId,
            assetType: AssetType.story,
            projectId: projectId,
          ),
        );
    await tester.pumpAndSettle();
    expect(find.byType(StoryWorkspaceScreen), findsOneWidget);

    // Draf selamat: autosave/flush persist ke repository proyek nyata.
    final repository = StoryRepositoryImpl(database: db, projectId: projectId);
    final saved = await tester.runAsync(
      () => repository.getSceneDraft(sceneId),
    );
    expect(saved, 'draf lintas switch');
    expect(tester.takeException(), isNull);
  });

  testWidgets('T2: real persist failure shows banner; reopening project offers '
      'user-controlled recovery', (tester) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('vs-draft-fail-'),
    );
    final dir = root!;
    addTearDown(() {
      try {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on FileSystemException {
        // File masih terkunci handle sesi; biarkan OS membersihkan %TEMP%.
      }
    });

    final packageRef = await tester.runAsync(
      () => ProjectPackageService(
        rootDirectory: Directory('${dir.path}/pkg'),
      ).create(name: 'Draft Fail Journey'),
    );
    final pkg = packageRef!;
    final sessionA = await tester.runAsync(
      () => ProjectSessionManager().open(pkg),
    );
    final liveSession = sessionA!;
    final paths = ProjectPaths(rootDirectory: Directory('${dir.path}/data'));
    final db = liveSession.database;
    final projectId = liveSession.manifest.id;

    final service = CreateStoryService(database: db, paths: paths);
    final storyId = (await tester.runAsync(
      () => service.createStory(projectId: projectId, title: 'Novel Gagal'),
    ))!;
    final chapterId = (await tester.runAsync(
      () => service.createChapter(
        storyId: storyId,
        title: 'Chapter 1',
        chapterNumber: 1,
      ),
    ))!;
    final sceneId = (await tester.runAsync(
      () => service.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene 1',
        sceneNumber: 1,
      ),
    ))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(liveSession)),
          projectPathsProvider.overrideWithValue(paths),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(WorkspaceResolver)))
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: storyId,
            assetType: AssetType.story,
            projectId: projectId,
          ),
        );
    await tester.pumpAndSettle();

    await tester.enterText(_draftField(), 'draf gagal persist');
    await tester.pump(const Duration(milliseconds: 100));
    final journalDir = Directory(
      '${liveSession.package.root.path}/recovery/draft-journal',
    );
    var staged = false;
    for (var i = 0; i < 100 && !staged; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    staged =
        journalDir.existsSync() &&
        journalDir.listSync().whereType<File>().isNotEmpty;
    expect(staged, isTrue);

    // Persist gagal secara nyata: sesi proyek ditutup (database tertutup).
    await tester.runAsync(() => liveSession.close());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 1700));

    // Banner error terlihat, tanpa uncaught exception (no silent loss).
    expect(find.byKey(const ValueKey('autosave_error_banner')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Simulasi restart: buka ulang project (sesi baru) dan render ulang.
    final sessionB = await tester.runAsync(
      () => ProjectSessionManager().open(pkg),
    );
    final reopened = sessionB!;
    addTearDown(reopened.close);

    // Unmount penuh pohon lama agar layar Novel dimount ulang (initState
    // jalan ulang dan memuat pending recovery), seperti proses baru.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(reopened)),
          projectPathsProvider.overrideWithValue(paths),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(WorkspaceResolver)))
        .read(selectionProvider.notifier)
        .select(
          SelectionModel(
            assetId: storyId,
            assetType: AssetType.story,
            projectId: projectId,
          ),
        );
    await tester.pumpAndSettle();

    // Panel DRAFT RECOVERY memuat entri journal belum ter-acknowledge.
    // pendingEntries() adalah IO nyata: beri waktu nyata sebelum setState.
    var recoveryShown = false;
    for (var i = 0; i < 100 && !recoveryShown; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      recoveryShown = find.text('DRAFT RECOVERY').evaluate().isNotEmpty;
    }
    expect(recoveryShown, isTrue);

    // Pulihkan: tulis ke database sesi baru, lalu acknowledge journal.
    await tester.ensureVisible(find.text('Pulihkan Draft'));
    await tester.tap(find.text('Pulihkan Draft'));
    var acknowledged = false;
    for (var i = 0; i < 100 && !acknowledged; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      acknowledged =
          !journalDir.existsSync() ||
          journalDir.listSync().whereType<File>().isEmpty;
    }
    await tester.pumpAndSettle();

    final repository = StoryRepositoryImpl(
      database: reopened.database,
      projectId: projectId,
    );
    final restored = await tester.runAsync(
      () => repository.getSceneDraft(sceneId),
    );
    expect(acknowledged, isTrue, reason: 'journal harus di-acknowledge');
    expect(restored, 'draf gagal persist');
    expect(find.byKey(const ValueKey('autosave_error_banner')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // T3 (bug-hunt-run128 BUG-22, run176 formalisasi): story -> story lewat
  // resolver produksi. Tanpa ValueKey('story-<id>') State layar story
  // dipakai ulang: sceneId story lama tetap terpilih dan ketikan story B
  // ter-autosave ke scene milik story A (draftA/draftB basi - RED eksak
  // a4d86ae). Acceptance: tiap scene menyimpan draftnya sendiri.
  testWidgets('T3: story A -> story B keeps both drafts on their own scenes', (
    tester,
  ) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('vs-draft-bug22-'),
    );
    final dir = root!;
    addTearDown(() {
      try {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } on FileSystemException {
        // File masih terkunci handle sesi; biarkan OS membersihkan %TEMP%.
      }
    });

    final package = await tester.runAsync(
      () => ProjectPackageService(
        rootDirectory: Directory('${dir.path}/pkg'),
      ).create(name: 'Draft Bug22'),
    );
    final session = await tester.runAsync(
      () => ProjectSessionManager().open(package!),
    );
    final liveSession = session!;
    addTearDown(liveSession.close);

    final paths = ProjectPaths(rootDirectory: Directory('${dir.path}/data'));
    final db = liveSession.database;
    final projectId = liveSession.manifest.id;
    final service = CreateStoryService(database: db, paths: paths);

    final storyA = (await tester.runAsync(
      () => service.createStory(projectId: projectId, title: 'Novel A'),
    ))!;
    final chapterA = (await tester.runAsync(
      () => service.createChapter(
        storyId: storyA,
        title: 'Chapter 1',
        chapterNumber: 1,
      ),
    ))!;
    final sceneA = (await tester.runAsync(
      () => service.createScene(
        storyId: storyA,
        chapterId: chapterA,
        title: 'Scene A',
        sceneNumber: 1,
      ),
    ))!;

    final storyB = (await tester.runAsync(
      () => service.createStory(projectId: projectId, title: 'Novel B'),
    ))!;
    final chapterB = (await tester.runAsync(
      () => service.createChapter(
        storyId: storyB,
        title: 'Chapter 1',
        chapterNumber: 1,
      ),
    ))!;
    final sceneB = (await tester.runAsync(
      () => service.createScene(
        storyId: storyB,
        chapterId: chapterB,
        title: 'Scene B',
        sceneNumber: 1,
      ),
    ))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(liveSession)),
          projectPathsProvider.overrideWithValue(paths),
        ],
        child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspaceResolver)),
    );
    final notifier = container.read(selectionProvider.notifier);

    // Ketik draf A di story A. Persist butuh waktu nyata (pola T1/T2:
    // FakeAsync pump saja tidak mendarat) - poll repository sampai draft
    // benar-benar tersimpan, bukan fixed pump.
    notifier.select(
      SelectionModel(
        assetId: storyA,
        assetType: AssetType.story,
        projectId: projectId,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(_draftField(), 'draf novel A');
    await tester.pump(const Duration(milliseconds: 100));

    final repository = StoryRepositoryImpl(database: db, projectId: projectId);
    var draftALanded = false;
    for (var i = 0; i < 100 && !draftALanded; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      draftALanded =
          await tester.runAsync(() => repository.getSceneDraft(sceneA)) ==
          'draf novel A';
    }
    expect(draftALanded, isTrue, reason: 'draft A harus ter-persist');

    // Pindah langsung story A -> story B (jalur produksi yang sama).
    notifier.select(
      SelectionModel(
        assetId: storyB,
        assetType: AssetType.story,
        projectId: projectId,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.byType(StoryWorkspaceScreen), findsOneWidget);

    // Layar B segar: teks A tidak bocor ke field (State tidak dipakai ulang).
    expect(find.text('draf novel A'), findsNothing);

    await tester.enterText(_draftField(), 'draf novel B');
    await tester.pump(const Duration(milliseconds: 100));

    var draftBLanded = false;
    for (var i = 0; i < 100 && !draftBLanded; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      draftBLanded =
          await tester.runAsync(() => repository.getSceneDraft(sceneB)) ==
          'draf novel B';
    }
    expect(draftBLanded, isTrue, reason: 'draft B harus ter-persist');

    // Kontrak akhir BUG-22: tiap scene punya draft-nya sendiri. Pada versi
    // tanpa key, ketikan B mendarat ke sceneId basi milik A (draftA
    // tertimpa / draftB basi) - kedua asersi ini menangkapnya.
    final draftA = await tester.runAsync(
      () => repository.getSceneDraft(sceneA),
    );
    final draftB = await tester.runAsync(
      () => repository.getSceneDraft(sceneB),
    );
    expect(draftA, 'draf novel A');
    expect(draftB, 'draf novel B');
    expect(tester.takeException(), isNull);
  });
}
