import 'dart:io';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/project_resilience/application/durable_draft_journal.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

/// vs-native-20260914-run309 BUG-303-01 (Medium) — regression.
///
/// Gejala native terverifikasi (journey_report run309): ketik scene -> tutup
/// saat draf pending ada -> relaunch -> klik "Pulihkan Draft" -> editor
/// membisu input: ketikan pasca-restore tidak masuk kontrol dan label beku
/// 'Belum tersimpan'. Data DB aman.
///
/// Mekanisme yang dikunci test ini (layer widget deterministik):
/// 1. `_restorePendingDraft` memasang `_draft.value = TextEditingValue(text:)`
///    tanpa caret. Selection default = invalid (baseOffset -1). Restore juga
///    tidak mengembalikan fokus ke editor (fokus tertinggal di TextButton),
///    sehingga pada Windows ketikan berikutnya tidak pernah mencapai
///    EditableText. Kontrak: pasca-restore editor siap tulis = caret valid
///    di akhir teks DAN fokus editor diminta.
/// 2. Kontrak vs-hunt-20260912-autosave BUG-5 (ditegakkan untuk snapshot
///    restore, belum untuk draft-journal restore): tulis eksternal yang
///    MENGGANTIKAN konten draf wajib dikoordinasikan lewat
///    `aroundExternalDraftWrite`. Tanpa koordinasi, konten yang masih
///    menunggu debounce persist SETELAH restore dan menimpa hasil restore
///    secara diam-diam di repository.
void main() {
  Future<void> pumpWithPendingRecovery(
    WidgetTester tester, {
    required DurableDraftJournal journal,
    required StoryRepositoryImpl repository,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1200,
              child: StoryWorkspaceScreen(
                storyId: 'story-1',
                repository: repository,
                sceneId: 'scene-a',
                draftJournal: journal,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('DRAFT RECOVERY'), findsOneWidget);
  }

  testWidgets(
    'BUG-303-01(1): Pulihkan Draft installs a valid caret at the end of the '
    'restored text and returns focus to the editor',
    (tester) async {
      final journal = _FakeDurableDraftJournal()
        ..stageForTest(sceneId: 'scene-a', content: 'Draf pemulihan caret.');
      final repository = _FakeStoryRepository()..hierarchy = _hierarchyWith();
      await pumpWithPendingRecovery(
        tester,
        journal: journal,
        repository: repository,
      );

      await tester.tap(find.text('Pulihkan Draft'));
      await tester.pumpAndSettle();

      final editor = find.widgetWithText(TextField, 'Draf pemulihan caret.');
      expect(editor, findsOneWidget);
      final textField = tester.widget<TextField>(editor);
      final controller = textField.controller!;
      expect(
        controller.selection.isValid,
        isTrue,
        reason: 'restore wajib menormalkan caret; selection -1 = editor bisu',
      );
      expect(
        controller.selection.baseOffset,
        'Draf pemulihan caret.'.length,
        reason: 'caret harus di akhir teks hasil restore',
      );
      expect(
        textField.focusNode?.hasFocus ?? false,
        isTrue,
        reason:
            'pasca-restore fokus editor diminta agar ketikan langsung masuk',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-303-01(2): pending autosave is coordinated before journal restore '
    '— stale debounce must not silently clobber the restored text',
    (tester) async {
      final journal = _FakeDurableDraftJournal()
        ..stageForTest(sceneId: 'scene-a', content: 'Isi jurnal lama.');
      final repository = _FakeStoryRepository()..hierarchy = _hierarchyWith();
      await pumpWithPendingRecovery(
        tester,
        journal: journal,
        repository: repository,
      );

      // Ketikan live: masuk debounce pending + menimpa entri jurnal scene-a
      // (semantics file-per-scene journal nyata).
      await tester.enterText(find.byType(TextField), 'Ketik baru pengguna');
      await tester.pump();

      await tester.ensureVisible(find.text('Pulihkan Draft'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pulihkan Draft'));
      // Lewati jendela debounce 1500ms koordinator SETELAH restore.
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Panel hilang: restore selesai.
      expect(find.text('DRAFT RECOVERY'), findsNothing);
      // Kontrak: hasil restore bertahan di repository — bukan tergantikan
      // oleh debounce konten pra-restore.
      expect(
        repository.savedByScene['scene-a'],
        'Isi jurnal lama.',
        reason: 'stale pending menimpa hasil restore secara diam-diam',
      );
      final editor = tester.widget<TextField>(find.byType(TextField).last);
      expect(editor.controller!.value.text, 'Isi jurnal lama.');
      expect(tester.takeException(), isNull);
    },
  );
}

class _FakeDurableDraftJournal extends DurableDraftJournal {
  /// Directory nyata yang TIDAK PERNAH disentuh: semua method IO dioverride,
  /// super(dir:) hanya memenuhi kontrak constructor base class.
  _FakeDurableDraftJournal() : super(dir: Directory.systemTemp);

  final Map<String, PendingDraftEntry> entries = {};

  void stageForTest({required String sceneId, required String content}) {
    entries[sceneId] = PendingDraftEntry(
      sceneId: sceneId,
      content: content,
      stagedAt: DateTime(2026, 9, 14, 8),
    );
  }

  @override
  Future<List<PendingDraftEntry>> pendingEntries() async =>
      entries.values.toList()..sort((a, b) => a.sceneId.compareTo(b.sceneId));

  /// Meniru semantics file-per-scene journal nyata: stage overwrite entri.
  @override
  Future<void> stage({required String sceneId, required String content}) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('journal content must not be blank');
    }
    entries[sceneId] = PendingDraftEntry(
      sceneId: sceneId,
      content: content,
      stagedAt: DateTime(2026, 9, 14, 9),
    );
  }

  @override
  Future<void> acknowledge(String sceneId, {String? content}) async {
    final entry = entries[sceneId];
    if (entry == null) return;
    if (content != null && entry.content != content) return;
    entries.remove(sceneId);
  }

  @override
  Future<void> close() async {
    // No IO: journal base punya directory nyata yang tidak boleh disentuh.
  }
}

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Recovery Story',
    ),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  final Map<String, String> savedByScene = {};

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => savedByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    savedByScene[sceneId] = content;
  }
}

StoryHierarchy _hierarchyWith() {
  return const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Recovery Story',
    ),
    arcs: [],
    chapters: [
      StoryChapterNode('chapter-1', 'Chapter One', [
        StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
        StorySceneNode('scene-b', 'Gema Kedalaman', [], null, []),
      ]),
    ],
    scenes: [],
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
