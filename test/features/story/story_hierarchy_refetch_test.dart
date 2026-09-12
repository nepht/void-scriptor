// bug-hunt-run128 BUG-17 — FutureBuilder inline di build mengalokasikan
// future baru pada SETIAP rebuild: setiap keystroke (dua setState lewat
// _count) menembak ulang getStoryHierarchy penuh (query arcs+chapters+scenes
// + N+1 per scene) dan membuat panel CHAPTERS berkedip "Memuat struktur
// story...". Referee: REAL BUG Medium.
//
// Dua kontrak yang dibuktikan file ini:
// 1. Mengetik (rebuild dari _count) TIDAK boleh menambah panggilan
//    getStoryHierarchy — future hierarchy dipegang State, bukan dialokasi
//    di build.
// 2. Mutasi struktur yang terjadi di luar rebuild keystroke tetap harus
//    sampai ke panel: impor novel workspace yang sukses me-refresh
//    future (cache tidak boleh menjadi panel stale).
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspaces/application/novel_character_link_repository.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_import_service.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_actions.dart';
import 'package:void_scriptor/features/workspaces/presentation/workspace_import_options_dialog.dart';

void main() {
  testWidgets(
    'BUG-17: mengetik tidak menembak ulang getStoryHierarchy per keystroke',
    (tester) async {
      final repository = _CountingStoryRepository();
      repository
        ..hierarchy = _hierarchyWithScenes([
          const _SceneSpec('scene-a', 'Kedatangan Void'),
        ])
        ..draftByScene = {'scene-a': 'teks awal'};

      await tester.pumpWidget(
        _wrap(
          StoryWorkspaceScreen(
            storyId: 'story-1',
            repository: repository,
            sceneId: 'scene-a',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.hierarchyQueries, 1);

      // Satu keystroke = dua setState di _count (word count + reset label
      // simpan). Rebuild hasilnya tidak boleh mengalokasi future baru.
      await tester.enterText(
        find.widgetWithText(TextField, 'teks awal'),
        'teks awal v2',
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        repository.hierarchyQueries,
        1,
        reason:
            'keystroke tidak boleh memicu ulang query hierarchy penuh '
            '(FutureBuilder inline dialokasi future di build)',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-17: impor novel workspace yang sukses me-refresh panel CHAPTERS',
    (tester) async {
      final temp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('bug17-import-'),
      ))!;
      addTearDown(() => temp.delete(recursive: true));
      final archive = File('${temp.path}/fake.voidworkspace');
      await tester.runAsync(() => archive.writeAsString('arsip uji'));

      final repository = _CountingStoryRepository();
      // Sebelum impor: struktur kosong (panel menampilkan empty-state).
      repository.hierarchy = _hierarchyWithScenes(const []);
      repository.chaptersEmpty = true;

      final importActions = _MutatingImportActions(
        package: ProjectPackage(projectId: 'p1', root: temp),
        links: NovelCharacterLinkRepository(
          database: _FakeDatabase(),
          projectId: 'p1',
        ),
        representation: 'embedded_snapshot',
        onRun: () async {
          // Impor "menambah" scene pada sumber data repository.
          repository.chaptersEmpty = false;
          repository.hierarchy = _hierarchyWithScenes([
            const _SceneSpec('scene-baru', 'Scene Baru Setelah Impor'),
          ]);
          return const WorkspaceRestoreResult(
            workspaceId: 'story-1',
            restoredLinkCount: 1,
          );
        },
      );

      await tester.pumpWidget(
        _wrap(
          StoryWorkspaceScreen(
            storyId: 'story-1',
            repository: repository,
            novelImportActions: importActions,
            pickImportArchive: () async => archive,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum ada chapter atau scene.'), findsOneWidget);
      final queriesBefore = repository.hierarchyQueries;

      await tester.tap(find.text('Import Novel'));
      await tester.pumpAndSettle();

      // Dialog opsi impor: pilih Skip lalu konfirmasi.
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Novel workspace diimpor'), findsOneWidget);
      expect(
        find.text('Scene Baru Setelah Impor'),
        findsOneWidget,
        reason:
            'cache future hierarchy tidak boleh membuat panel CHAPTERS '
            'stale setelah mutasi struktur dari impor',
      );
      // Tepat +1: refresh eksplisit pasca-impor. Tanpa cache, setiap rebuild
      // dialog/snackbar/busy juga menembak query penuh (jauh lebih dari 1).
      expect(repository.hierarchyQueries, queriesBefore + 1);
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 1200, child: child)),
    ),
  );
}

class _SceneSpec {
  const _SceneSpec(this.id, this.title);
  final String id;
  final String title;
}

StoryHierarchy _hierarchyWithScenes(List<_SceneSpec> scenes) {
  return StoryHierarchy(
    story: const StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Judul Uji',
    ),
    arcs: const [],
    chapters: [
      StoryChapterNode('chapter-1', 'Chapter One', [
        for (final s in scenes)
          StorySceneNode(s.id, s.title, const [], null, const []),
      ]),
    ],
    scenes: const [],
  );
}

class _CountingStoryRepository extends StoryRepositoryImpl {
  _CountingStoryRepository()
    : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = _hierarchyWithScenes(const []);

  /// Saat true, getStoryHierarchy mengembalikan struktur tanpa chapter —
  /// dipakai untuk menguji empty-state panel CHAPTERS.
  bool chaptersEmpty = false;
  Map<String, String> draftByScene = {};
  int hierarchyQueries = 0;

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async {
    hierarchyQueries++;
    if (chaptersEmpty) {
      return StoryHierarchy(
        story: hierarchy.story,
        arcs: const [],
        chapters: const [],
        scenes: const [],
      );
    }
    return hierarchy;
  }

  @override
  Future<String?> getStoryTitle(String storyId) async => hierarchy.story.title;

  @override
  Future<String?> getSceneDraft(String sceneId) async => draftByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    draftByScene[sceneId] = content;
  }

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(String sceneId) async {
    return const [];
  }

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async {
    return const [];
  }
}

class _MutatingImportActions extends WorkspaceImportActions {
  const _MutatingImportActions({
    required super.package,
    required super.links,
    required this.representation,
    required this.onRun,
  });

  final String? representation;
  final Future<WorkspaceRestoreResult> Function() onRun;

  @override
  Future<String?> peekCharacterRepresentation(File archive) async =>
      representation;

  @override
  Future<WorkspaceRestoreResult> run(
    File archive,
    WorkspaceImportOptions options, {
    String? expectedWorkspaceId,
    WorkspaceArchivePreflight? preflight,
  }) {
    return onRun();
  }

  // The screen's import path preflight-loads the archive before the dialog.
  // The fake archive on disk is not a zip, so return a synthetic snapshot
  // carrying the declared representation.
  @override
  Future<WorkspaceArchivePreflight> preflightArchive(File archive) async =>
      WorkspaceArchivePreflight(
        sourceFile: archive,
        bytes: Uint8List(0),
        decoded: Archive(),
        manifest: {'characterRepresentation': representation},
      );
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
