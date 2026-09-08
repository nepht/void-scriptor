// bug-hunt-run128 BUG-22 (nephthys slice): StoryWorkspaceScreen dibangun
// WorkspaceResolver TANPA key dan State-nya tidak punya didUpdateWidget,
// sehingga story -> story pada element yang sama memakai ulang State dengan
// `_selectedSceneId` story lama dan `_draftJournal` paket lama. Ketikan
// pertama di story baru masuk jalur autosave dengan sceneId story lama =
// kontaminasi draf lintas story (kontrak 145.27 prioritas #1 no silent loss
// dan kebenaran lokasi draf).
//
// Alur uji memakai jalur produksi WorkspaceResolver + selectionProvider dan
// persist lewat flush dispose saat seleksi berpindah keluar dari story
// (jalur no-silent-loss run62), bukan menunggu timer debounce. Kontrak yang
// dikunci: setelah menulis di dua story berbeda dan berpindah workspace,
// draf tiap story tetap di scene miliknya masing-masing.
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
  testWidgets(
    'BUG-22: switching stories must not carry the previous story draft State '
    '(production resolver journey)',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('vs-bug22-reuse-'),
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
        ).create(name: 'Bug22 Story Switch'),
      );
      final session = await tester.runAsync(
        () => ProjectSessionManager().open(package!),
      );
      final liveSession = session!;
      addTearDown(liveSession.close);

      final paths = ProjectPaths(rootDirectory: Directory('${dir.path}/data'));
      final db = liveSession.database;
      final projectId = liveSession.manifest.id;
      final journalDir = Directory(
        '${liveSession.package.root.path}/recovery/draft-journal',
      );

      final characterId = (await tester.runAsync(
        () => CreateCharacterService(
          database: db,
          paths: paths,
        ).create(projectId: projectId, name: 'Sora'),
      ))!;
      final service = CreateStoryService(database: db, paths: paths);
      final storyA = (await tester.runAsync(
        () => service.createStory(projectId: projectId, title: 'Story A'),
      ))!;
      final chapterA = (await tester.runAsync(
        () => service.createChapter(
          storyId: storyA,
          title: 'Chapter A',
          chapterNumber: 1,
        ),
      ))!;
      final sceneA = (await tester.runAsync(
        () => service.createScene(
          storyId: storyA,
          chapterId: chapterA,
          title: 'Scene A1',
          sceneNumber: 1,
        ),
      ))!;

      final storyB = (await tester.runAsync(
        () => service.createStory(projectId: projectId, title: 'Story B'),
      ))!;
      final chapterB = (await tester.runAsync(
        () => service.createChapter(
          storyId: storyB,
          title: 'Chapter B',
          chapterNumber: 1,
        ),
      ))!;
      final sceneB = (await tester.runAsync(
        () => service.createScene(
          storyId: storyB,
          chapterId: chapterB,
          title: 'Scene B1',
          sceneNumber: 1,
        ),
      ))!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(
              () => _FixedSession(liveSession),
            ),
            projectPathsProvider.overrideWithValue(paths),
          ],
          child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceResolver)),
      );
      final repository = StoryRepositoryImpl(
        database: db,
        projectId: projectId,
      );

      Future<void> select(SelectionModel selection) async {
        container.read(selectionProvider.notifier).select(selection);
        await tester.pumpAndSettle();
      }

      // Polling I/O nyata (pola harness T1): drain penuh 100 iterasi TANPA
      // early-exit — kontinuitas real-I/O harness harus bertahan sampai
      // seluruh rantai stage/persist/acknowledge selesai; early-exit
      // menghentikan kontinuitas sehingga flush dispose tak pernah mendarat
      // (pitfall probe slice BUG-22).
      Future<void> drainFull() async {
        for (var i = 0; i < 100; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
        }
      }

      bool journalContains(String needle) {
        if (!journalDir.existsSync()) return false;
        return journalDir.listSync().whereType<File>().any((f) {
          try {
            return f.readAsStringSync().contains(needle);
          } on FileSystemException {
            return false;
          }
        });
      }

      Future<String?> readDraft(String sceneId) async {
        final value = await tester.runAsync(
          () => repository.getSceneDraft(sceneId),
        );
        return value;
      }

      // ---- Story A: ketik; journal durable menahan sejak ketikan pertama.
      await select(
        SelectionModel(
          assetId: storyA,
          assetType: AssetType.story,
          projectId: projectId,
        ),
      );
      expect(find.byType(StoryWorkspaceScreen), findsOneWidget);
      await tester.enterText(_draftField(), 'draf story A');
      await tester.pump(const Duration(milliseconds: 100));
      await drainFull();
      expect(
        journalContains('draf story A'),
        isTrue,
        reason: 'journal harus menahan draf story A segera (no silent loss)',
      );

      // ---- Pindah ke story B pada element yang sama (pra-patch: State
      // tidak dibuang, `_selectedSceneId` dan journal basi story A).
      // Pasca-patch: State A di-dispose di sini; pump fake-time memberi
      // siklus bagi flush persist A (pola T1 journey) sebelum mengetik B.
      await select(
        SelectionModel(
          assetId: storyB,
          assetType: AssetType.story,
          projectId: projectId,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();
      expect(find.byType(StoryWorkspaceScreen), findsOneWidget);
      await tester.enterText(_draftField(), 'draf story B');
      await tester.pump(const Duration(milliseconds: 100));
      await drainFull();
      // Mekanisme BUG-22: entry journal story B harus berdiri sendiri pada
      // scene milik story B — bukan menimpa entry scene lama (sceneId basi).
      bool journalOnlyHasB() {
        if (!journalDir.existsSync()) return false;
        final files = journalDir.listSync().whereType<File>().toList();
        return files.length == 1 &&
            files.single.readAsStringSync().contains('draf story B');
      }

      expect(
        journalOnlyHasB(),
        isTrue,
        reason:
            'mekanisme BUG-22: entry B harus di scene miliknya, '
            'bukan menimpa entry scene story A',
      );

      // ---- Pindah ke Character workspace: layar story di-unmount dan
      // koordinator autosave mem-flush draf pending ke repository (jalur
      // produksi run62 no-silent-loss saat keluar dari story).
      await select(
        SelectionModel(
          assetId: characterId,
          assetType: AssetType.character,
          projectId: projectId,
        ),
      );
      // Flush dispose adalah I/O nyata: pola T1 story_draft_switch_journey
      // (terbukti hijau) menggerakkan fake time melewati debounce setelah
      // dispose sebelum settle, sehingga flush persist selesai di harness.
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pumpAndSettle();
      expect(find.byType(CharacterWorkspaceScreen), findsOneWidget);

      // Flush dispose adalah I/O nyata: drain penuh pola T1, lalu baca kedua
      // draf (pembacaan tetap dilakukan via runAsync karena I/O nyata).
      await drainFull();
      var draftA = await readDraft(sceneA);
      var draftB = await readDraft(sceneB);
      await tester.pumpAndSettle();
      if (draftA != 'draf story A' || draftB != 'draf story B') {
        final journalFiles = journalDir.existsSync()
            ? journalDir
                  .listSync()
                  .whereType<File>()
                  .map((f) {
                    final content = f.readAsStringSync();
                    final head = content.length > 40
                        ? content.substring(0, 40)
                        : content;
                    return '${f.path.split(Platform.pathSeparator).last}'
                        '::$head';
                  })
                  .join(', ')
            : '<no dir>';
        // ignore: avoid_print
        print(
          'BUG22-DIAG sceneA=$sceneA sceneB=$sceneB '
          'draftA=$draftA draftB=$draftB journal=[$journalFiles]',
        );
      }

      // Kontrak: draf tiap story tetap di scene miliknya masing-masing.
      // Pra-patch (BUG-22): 'draf story B' tertulis ke sceneA (menimpa draf
      // story A = kehilangan data diam-diam) dan sceneB kosong.
      expect(
        draftA,
        'draf story A',
        reason:
            'BUG-22: draf story A tidak boleh tertimpa draf story B '
            'lewat sceneId basi',
      );
      expect(
        draftB,
        'draf story B',
        reason: 'BUG-22: draf story B harus tersimpan di scene milik story B',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
