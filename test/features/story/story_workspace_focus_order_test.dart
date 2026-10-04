// Step 145 — Story Workspace Screen, kontrak focus order WCAG 2.4.3.
//
// Fokus utama audit ini: apakah urutan Tab mengikuti urutan baca visual
// (atas ke bawah, kiri ke kanan) dan apakah setiap stop punya area fokus
// non-nol yang bisa dicapai keyboard. Kontak ini mengunci 7 stop yang diukur
// lewat probe pada viewport 1536x1600 / dpr 1.0.
//
// Catatan viewport: probe 1536x1024 membuat rect fokus ikut bergeser antar
// Tab karena Scrollable.ensureVisible menggulir otomatis. Viewport 1600 tinggi
// dipakai agar seluruh isi muat tanpa scroll, sehingga urutan posisinya
// deterministik dan tidak mengukur artefak scroll.
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/domain/character_quick_ref.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/domain/draft_snapshots.dart';
import 'package:void_scriptor/features/story/domain/story_model.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

/// Urutan fokus yang sudah diverifikasi lewat probe: tombol mode fokus,
/// baris bab yang dipilih, editor draft scene, pencarian novel, aksi snapshot,
/// pengaturan retensi, lalu container scroll untuk menurun ke isi panel.
const _expectedLabels = <String>[
  'Mode Fokus',
  'Kedatangan Void',
  'node:scene-draft-editor',
  'Cari Novel',
  'Snapshot',
  'Atur Retensi',
  'Story Bible — story-1',
];

/// Label stop: subtree fokus lebih dulu, lalu debugLabel FocusNode sebagai
/// fallback (editor draft punya debugLabel stabil dan tanpa child Text).
String _labelOf(BuildContext context) {
  final element = context as Element;
  var label = '';
  var widgetType = element.widget.runtimeType.toString();
  void visit(Element node) {
    if (label.isNotEmpty) return;
    final widget = node.widget;
    if (widget is Icon) return;
    if (widget is Text) {
      final data = widget.data ?? widget.semanticsLabel ?? '';
      if (data.trim().isNotEmpty) {
        label = data.trim();
        return;
      }
    }
    if (widget is Semantics) {
      final l = widget.properties.label;
      if (l != null && l.trim().isNotEmpty) {
        label = l.trim();
        return;
      }
    }
    if (widget is InputDecorator) {
      final hint = widget.decoration.hintText;
      if (hint != null && hint.trim().isNotEmpty) {
        label = hint.trim();
        return;
      }
    }
    node.visitChildren(visit);
  }

  visit(element);
  if (label.isEmpty) label = 'widget:$widgetType';
  if (label.startsWith('widget:')) {
    final debugLabel = FocusManager.instance.primaryFocus?.debugLabel;
    if (debugLabel != null && debugLabel.isNotEmpty) label = 'node:$debugLabel';
  }
  return label;
}

({String label, Rect rect})? _currentStop() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  final object = context.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (label: _labelOf(context), rect: rect);
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 16; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) break;
    final key =
        '${stop.rect.left.toStringAsFixed(1)}|'
        '${stop.rect.top.toStringAsFixed(1)}|'
        '${stop.rect.width.toStringAsFixed(1)}|'
        '${stop.rect.height.toStringAsFixed(1)}';
    if (!seen.add(key)) break;
    stops.add(stop);
  }
  return stops;
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final repository = _FakeStoryRepository()
    ..hierarchy = const StoryHierarchy(
      story: StoryModel(
        assetId: 'story-1',
        projectId: 'p1',
        title: 'Focus Story',
      ),
      arcs: [],
      chapters: [
        StoryChapterNode('chapter-1', 'Chapter One', [
          StorySceneNode('scene-a', 'Kedatangan Void', [], null, []),
        ]),
      ],
      scenes: [],
    );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          child: StoryWorkspaceScreen(
            storyId: 'story-1',
            repository: repository,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Story Workspace Screen - kontrak focus order 2.4.3', () {
    testWidgets('1. tujuh stop fokus dengan urutan label terkunci', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(7));
      expect(
        stops.map((stop) => stop.label).toList(),
        _expectedLabels,
        reason:
            'Tab harus menelusuri mode fokus, bab, editor scene, pencarian '
            'novel, snapshot, retensi, lalu container scroll.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. tiap stop punya area fokus non-nol', (tester) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(7));
      for (final stop in stops) {
        expect(
          stop.rect.width > 0 && stop.rect.height > 0,
          isTrue,
          reason: 'Stop "${stop.label}" punya area fokus berawan.',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '3. urutan mengikuti baca visual: atas ke bawah, kiri ke kanan',
      (tester) async {
        await _pump(tester);
        final stops = await _stops(tester);
        expect(stops, hasLength(7));
        // Lima stop UI pertama harus menuruni halaman. Stop keenam tetap
        // sebaris dengan stop kelima (satu panel Snapshots), jadi keduanya
        // dicek terpisah; stop terakhir adalah container scroll yang memang
        // menutup siklus.
        for (var i = 1; i < 5; i++) {
          expect(
            stops[i].rect.top,
            greaterThan(stops[i - 1].rect.top),
            reason:
                'Stop "${stops[i].label}" harus di bawah stop '
                '"${stops[i - 1].label}".',
          );
        }
        // Dua stop pada baris yang sama (snapshot + retensi) harus ke kanan.
        final sameRow = stops[4];
        final nextInRow = stops[5];
        expect(
          nextInRow.rect.top,
          sameRow.rect.top,
          reason: 'Snapshot dan Atur Retensi berada pada baris yang sama.',
        );
        expect(
          nextInRow.rect.left,
          greaterThan(sameRow.rect.left),
          reason: 'Atur Retensi berada di kanan Snapshot pada baris yang sama.',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('4. Tab setelah container scroll kembali ke stop pertama', (
      tester,
    ) async {
      await _pump(tester);
      final stops = await _stops(tester);
      expect(stops, hasLength(7));
      // _stops berhenti tepat saat rect berulang, jadi fokus sudah kembali
      // ke Mode Fokus dengan rect identik.
      final wrapped = _currentStop();
      expect(wrapped, isNotNull);
      expect(wrapped!.label, _expectedLabels.first);
      expect(wrapped.rect, stops.first.rect);
      // Satu Tab lagi melanjutkan ke baris bab - siklus benar-benar utuh.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_currentStop()!.label, _expectedLabels[1]);
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeStoryRepository extends StoryRepositoryImpl {
  _FakeStoryRepository() : super(database: _FakeDatabase(), projectId: 'p1');

  StoryHierarchy hierarchy = const StoryHierarchy(
    story: StoryModel(
      assetId: 'story-1',
      projectId: 'p1',
      title: 'Focus Story',
    ),
    arcs: [],
    chapters: [],
    scenes: [],
  );
  Map<String, String> draftByScene = {};

  @override
  Future<StoryHierarchy> getStoryHierarchy(String storyId) async => hierarchy;

  @override
  Future<String?> getSceneDraft(String sceneId) async => draftByScene[sceneId];

  @override
  Future<void> saveSceneDraft(String sceneId, String content) async {
    draftByScene[sceneId] = content;
  }

  @override
  Future<List<CharacterQuickRef>> quickReferenceForScene(
    String sceneId,
  ) async => const <CharacterQuickRef>[];

  @override
  Future<List<SceneDraftSnapshot>> getSceneDraftSnapshots(
    String sceneId, {
    String? snapshotId,
    DraftSnapshotKind? kind,
  }) async => const <SceneDraftSnapshot>[];
}

class _FakeDatabase extends ProjectDatabase {
  _FakeDatabase() : super(_FakeExecutor());
}

class _FakeExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('focus order contract never touches storage');
}
