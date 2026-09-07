// bug-hunt-run128 BUG-25 — story_workspace_screen.dart:1281:
// `_showSnapshotDialog` await `captureSceneDraftSnapshot` tanpa try/catch.
// Repository melempar StateError('no draft content for scene ...') ketika
// scene belum pernah punya baris draf (tap Snapshot sebelum autosave pertama
// men-debounce) — exception asinkron lepas tanpa umpan balik, dialog diam-diam
// tidak menghasilkan apa pun. Referee: REAL BUG Low.
//
// Kontrak yang dibuktikan: kegagalan capture dari tombol Snapshot TIDAK boleh
// melepas exception tak tertangkap; pengguna melihat SnackBar penjelasan, dan
// daftar snapshot tidak di-reload dari jalur gagal.
import 'dart:async';

import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart'
    show DraftSnapshotKind;
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  // Harness UI memakai _FakeDatabase (noSuchMethod) — warning drift
  // "multiple databases" noise di sini (preseden run132/run133/run135).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'BUG-25: Snapshot atas scene tanpa draf tersimpan menampilkan SnackBar, '
    'tanpa exception lepas',
    (tester) async {
      final repository = _GatedCaptureStoryRepository();
      repository.hierarchy = _hierarchyWithScene();

      await tester.pumpWidget(
        _wrap(StoryWorkspaceScreen(storyId: 'story-1', repository: repository)),
      );
      await tester.pump();
      await tester.pump();

      // Scene aktif termuat: draf + daftar snapshot (kosong) + quick ref.
      repository.draftGates.single.complete(null);
      repository.snapshotGates.single.complete(const []);
      repository.quickRefGates.single.complete(const []);
      await tester.pump();
      expect(find.text('Snapshot'), findsOneWidget);

      // Pengguna menekan Snapshot lalu mengisi label — jalur produksi:
      // scene belum pernah autosave, repository melempar StateError.
      await tester.ensureVisible(find.text('Snapshot'));
      await tester.pump();
      await tester.tap(find.text('Snapshot'));
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Sebelum autosave',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Rekam'));
      await tester.pump();

      // Feedback pengguna: SnackBar penjelasan, bukan exception senyap.
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason: 'kegagalan capture snapshot wajib terlihat pengguna (BUG-25)',
      );
      expect(
        find.textContaining('Snapshot tidak dapat direkam'),
        findsOneWidget,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'StateError dari capture tidak boleh lepas tak tertangkap',
      );

      // Jalur gagal tidak memicu reload daftar snapshot.
      expect(
        repository.snapshotGates.length,
        1,
        reason: 'reload daftar hanya untuk capture yang sukses',
      );

      // Ratakan timer SnackBar agar tidak ada timer pending di akhir test.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
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

StoryHierarchy _hierarchyWithScene() {
  return const StoryHierarchy(
    story: StoryModel(assetId: 'story-1', projectId: 'p1', title: 'Judul Uji'),
    arcs: [],
    chapters: [
      StoryChapterNode('chapter-1', 'Chapter One', [
        StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
      ]),
    ],
    scenes: [],
  );
}

/// Repository UI: muatan ter-gate (harness run135), dan capture selalu
/// melempar StateError — meniru perilaku repository produksi ketika scene
/// belum punya baris draf (pra-patch, story_repository_impl.dart:283-286).
class _GatedCaptureStoryRepository extends StoryRepositoryImpl {
  _GatedCaptureStoryRepository()
    : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = _hierarchyWithScene();

  final draftGates = <Completer<String?>>[];
  final snapshotGates = <Completer<List<SceneDraftSnapshot>>>[];
  final quickRefGates = <Completer<List<CharacterQuickRef>>>[];

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getStoryTitle(String storyId) async => hierarchy.story.title;

  @override
  Future<String?> getSceneDraft(String sceneId) {
    final gate = Completer<String?>();
    draftGates.add(gate);
    return gate.future;
  }

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {}

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(String sceneId) {
    final gate = Completer<List<CharacterQuickRef>>();
    quickRefGates.add(gate);
    return gate.future;
  }

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) {
    final gate = Completer<List<SceneDraftSnapshot>>();
    snapshotGates.add(gate);
    return gate.future;
  }

  @override
  Future<String> captureSceneDraftSnapshot(
    String sceneId, {
    required String label,
    DraftSnapshotKind kind = DraftSnapshotKind.manual,
  }) async {
    // Perilaku pra-patch repository produksi: belum ada draf tersimpan.
    throw StateError('no draft content for scene $sceneId');
  }
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
