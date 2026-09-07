// bug-hunt-run128 BUG-18 — story_workspace_screen.dart: (a) keputusan
// seleksi scene awal dimutasi langsung di dalam builder FutureBuilder
// (mutasi State saat build = anti-pattern Flutter), dan (b) _loadDraftFor/
// _loadSnapshotsFor/_loadQuickRefsFor tidak membawa nomor urut: pindah
// scene cepat A→B membuat muatan A yang selesai belakangan menimpa editor
// B, dan ketikan berikutnya meng-autosave teks campuran ke scene B
// (jalur korupsi konten lintas scene). Referee: REAL BUG Medium.
//
// Tiga kontrak yang dibuktikan file ini:
// 1. Muatan draf scene lama yang selesai SETELAH seleksi berpindah harus
//    ditolak — editor tetap menampilkan draf scene aktif.
// 2. Hal yang sama untuk muatan snapshot dan quick-ref scene lama.
// 3. (proteksi, kontrak run62) ketikan sebelum hierarchy termuat tetap
//    dipertahankan dan autosave meneruskannya ke scene pertama.
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
  // Harness UI memakai _FakeDatabase (noSuchMethod, tidak pernah membuka
  // file database) per test — warning drift "multiple databases" di sini
  // noise (preseden one-shot run132 pada harness UI serupa).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  testWidgets(
    'BUG-18: muatan draf scene lama yang datang terlambat tidak menimpa '
    'editor scene baru',
    (tester) async {
      final repository = _GatedStoryRepository();
      repository.hierarchy = _hierarchyWithScenes(const [
        _SceneSpec('scene-a', 'Kedatangan Void'),
        _SceneSpec('scene-b', 'Pertarungan Puncak'),
      ]);

      await tester.pumpWidget(
        _wrap(StoryWorkspaceScreen(storyId: 'story-1', repository: repository)),
      );
      await tester.pump();
      await tester.pump();
      expect(
        repository.draftGates.length,
        1,
        reason: 'muatan draf scene-a diminta tepat satu kali',
      );
      expect(find.text('Editing — Kedatangan Void'), findsOneWidget);

      // Pindah scene sebelum muatan mana pun selesai (disk lambat).
      await tester.tap(find.text('Pertarungan Puncak'));
      await tester.pump();
      expect(
        repository.draftGates.length,
        2,
        reason: 'muatan draf scene-b diminta setelah seleksi berpindah',
      );
      expect(find.text('Editing — Pertarungan Puncak'), findsOneWidget);

      // Muatan scene-b selesai lebih dulu: editor menampilkan scene b (sehat).
      repository.draftGates[1].complete('isi scene b');
      await tester.pump();
      expect(_editorText(tester), 'isi scene b');

      // Muatan scene-a (stale) selesai belakangan: TIDAK boleh menimpa
      // editor; ketikan berikutnya jadi ter-autosave ke scene yang salah.
      repository.draftGates[0].complete('isi scene a');
      await tester.pump();
      expect(
        _editorText(tester),
        'isi scene b',
        reason:
            'muatan stale scene-a tidak boleh menimpa draf scene-b yang '
            'aktif (clobber lintas scene BUG-18)',
      );
      expect(find.text('Editing — Pertarungan Puncak'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-18: muatan snapshot & quick-ref scene lama tidak menimpa panel '
    'scene baru',
    (tester) async {
      final repository = _GatedStoryRepository();
      repository.hierarchy = _hierarchyWithScenes(const [
        _SceneSpec('scene-a', 'Kedatangan Void'),
        _SceneSpec('scene-b', 'Pertarungan Puncak'),
      ]);

      await tester.pumpWidget(
        _wrap(StoryWorkspaceScreen(storyId: 'story-1', repository: repository)),
      );
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Pertarungan Puncak'));
      await tester.pump();

      // Sehat: muatan scene-b melengkapi editor + panel.
      repository.draftGates[1].complete('isi scene b');
      repository.snapshotGates[1].complete([
        _snapshot('snap-b', 'scene-b', 'Snap B'),
      ]);
      repository.quickRefGates[1].complete([_quickRef('Karakter B')]);
      await tester.pump();
      expect(_editorText(tester), 'isi scene b');
      expect(find.text('Snap B'), findsOneWidget);
      expect(find.text('Karakter B'), findsOneWidget);

      // Muatan stale scene-a selesai belakangan: tidak boleh menimpa
      // editor maupun panel snapshot/quick-ref scene aktif.
      repository.draftGates[0].complete('isi scene a');
      repository.snapshotGates[0].complete([
        _snapshot('snap-a', 'scene-a', 'Snap A'),
      ]);
      repository.quickRefGates[0].complete([_quickRef('Karakter A')]);
      await tester.pump();
      expect(
        _editorText(tester),
        'isi scene b',
        reason: 'muatan stale scene-a tidak boleh menimpa editor scene-b',
      );
      expect(
        find.text('Snap B'),
        findsOneWidget,
        reason: 'daftar snapshot tidak boleh tertimpa muatan stale scene-a',
      );
      expect(find.text('Snap A'), findsNothing);
      expect(
        find.text('Karakter B'),
        findsOneWidget,
        reason: 'quick-ref tidak boleh tertimpa muatan stale scene-a',
      );
      expect(find.text('Karakter A'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-18 proteksi run62: ketikan sebelum hierarchy termuat dipertahankan '
    'dan autosave meneruskannya ke scene pertama',
    (tester) async {
      final repository = _GatedStoryRepository();
      repository.hierarchy = _hierarchyWithScenes(const [
        _SceneSpec('scene-a', 'Kedatangan Void'),
      ]);
      final hierarchyGate = Completer<StoryHierarchy>();
      repository.hierarchyDelay = hierarchyGate.future;

      await tester.pumpWidget(
        _wrap(StoryWorkspaceScreen(storyId: 'story-1', repository: repository)),
      );
      await tester.pump();

      // Pengguna mengetik sebelum struktur story selesai dimuat.
      await tester.enterText(find.byType(TextField), 'ketikan awal pengguna');
      await tester.pump();

      hierarchyGate.complete(repository.hierarchy);
      await tester.pump();
      await tester.pump();

      // Seleksi awal mendarat, tetapi ketikan TIDAK ditimpa muatan draf.
      expect(find.text('Editing — Kedatangan Void'), findsOneWidget);
      expect(_editorText(tester), 'ketikan awal pengguna');
      expect(
        repository.draftGates,
        isEmpty,
        reason:
            'ketikan terlanjur ada: muatan ulang draf tidak boleh '
            'menimpanya (kontrak run62)',
      );

      // Autosave meneruskan ketikan ke scene pertama (jalur no-silent-loss).
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
      expect(repository.draftByScene['scene-a'], 'ketikan awal pengguna');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}

String _editorText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!.text;
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

SceneDraftSnapshot _snapshot(String id, String sceneId, String label) {
  return SceneDraftSnapshot(
    id: id,
    sceneId: sceneId,
    projectId: 'p1',
    kind: 'manual',
    content: '',
    label: label,
    createdAt: DateTime(2026),
  );
}

CharacterQuickRef _quickRef(String name) {
  return CharacterQuickRef(
    characterId: 'c-$name',
    name: name,
    compactDescription: 'deskripsi uji',
    role: 'participant',
  );
}

/// Repository dengan gerbang eksplisit: setiap panggilan pemuatan
/// mengembalikan future yang hanya selesai ketika test meng-complete
/// gerbangnya, sehingga urutan penyelesaian bisa diatur stale.
class _GatedStoryRepository extends StoryRepositoryImpl {
  _GatedStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = _hierarchyWithScenes(const []);

  /// Bila diisi, getStoryHierarchy menunggu future ini (untuk mengatur
  /// hierarchy yang selesai SETELAH pengguna mengetik).
  Future<StoryHierarchy>? hierarchyDelay;

  final requestedDrafts = <String>[];
  final draftGates = <Completer<String?>>[];
  final snapshotGates = <Completer<List<SceneDraftSnapshot>>>[];
  final quickRefGates = <Completer<List<CharacterQuickRef>>>[];
  final draftByScene = <String, String>{};

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async {
    return hierarchyDelay ?? hierarchy;
  }

  @override
  Future<String?> getStoryTitle(String storyId) async => hierarchy.story.title;

  @override
  Future<String?> getSceneDraft(String sceneId) {
    requestedDrafts.add(sceneId);
    final gate = Completer<String?>();
    draftGates.add(gate);
    return gate.future;
  }

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    draftByScene[sceneId] = content;
  }

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
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used in UI journey tests');
}
