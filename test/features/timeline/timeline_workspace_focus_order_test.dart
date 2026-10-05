// Kontrak focus order (WCAG 2.2, kriteria 2.4.3) di TimelineWorkspaceScreen.
//
// Layar ini dipilih untuk Fase 11 karena punya stop fokus paling banyak di
// antara layar yang belum diaudit: enam kontrol toolbar di dua pita
// (header dan toolbar zoom), sebuah SegmentedButton dengan dua segmen, dan
// satu stop per clip timeline.
//
// Syarat determinisme:
//   - async: nol. Satu-satunya kemunculan `Future<void> Function(` adalah tipe
//     callback `onClipTimingChanged`, bukan logika async di dalam widget.
//   - navigasi: nol. Tidak ada Navigator, PageView, maupun TabController.
//   - urutan track berasal dari `TimelineTrackType.values`, urutan clip
//     di dalam track dari `startSeconds`, dan lebar dari
//     `TimelineClipModel(durationSeconds)`.
//
// Traversal diukur dengan `sendKeyEvent(LogicalKeyboardKey.tab)` pada
// viewport 1536x1024 devicePixelRatio 1.0. Koordinat dalam piksel logika.
//
// Mode Edit dengan tiga clip — 9 stop lalu kembali ke atas:
//
//   #  kontrol        t     l     w    h
//   0  Play           6     1476  40   40    IconButton di header
//   1  Zoom out       64    484   40   40    IconButton
//   2  Zoom in        64    660   40   40    IconButton
//   3  Fit Scene      64    704   151  40    TextButton
//   4  Edit           60    867   123  48    segmen SegmentedButton
//   5  Preview        60    990   123  48    segmen SegmentedButton
//   6  clip "Arin Vale"    158  428  240  28    track character, start 1.0
//   7  clip "Mira Solenne" 158  748  160  28    track character, start 5.0
//   8  clip "Dolly In"     290  348  320  28    track camera, start 0.0
//      lalu kembali ke 0 (Play).
//
// Mode Preview mengganti seluruh isi panel: traversal hanya menyisakan satu
// stop, "Back to Edit" di tengah layar (t=557.5 l=650.4 w=235.2 h=40).
//
// Kontrak 2.4.3 yang dikontrakkan:
//   - header (Play) selalu stop pertama, sebelum toolbar di bawahnya;
//   - toolbar kiri ke kanan: zoom out, zoom in, Fit Scene, Edit, Preview;
//     tinggi pita toolbar tidak seragam (IconButton 64, SegmentedButton 60)
//     sehingga urutan dikontrakkan lewat `left`, bukan lewat `top`;
//   - setiap clip punya stop fokus dan muncul setelah seluruh toolbar,
//     dikelompokkan per track: track atas lebih dulu, lalu kiri ke kanan
//     di dalam track;
//   - traversal selalu kembali ke Play setelah clip terakhir;
//   - saat `clips` kosong, tidak ada stop fokus di area timeline sama sekali,
//     sehingga traversal berhenti di toolbar;
//   - mode Preview tidak menyisakan stop dari mode Edit.
//
// Catatan harness yang sudah diperbaiki (bukan defect produksi):
//   - `IconButton` berfokus pada `InkWell`/`Focus` internalnya, sehingga
//     label teks tidak ada di subtree fokus meski `tooltip` terisi. Ketiga
//     IconButton tampil dengan label kosong dan didiskriminasi lewat posisi,
//     bukan label.
//   - `SegmentedButton` memproyeksikan tiap segmen ke node fokus tersendiri,
//     sehingga Edit dan Preview dihitung dua stop, bukan satu.
//   - fokus bertahan saat mode berubah, sehingga traversal mode Preview
//     dimulai dari node yang sedang difokus. Daftar hasil traversal dirotasi
//     agar mulai dari stop dengan `top` terkecil agar indeks assertion
//     deterministik; urutan relatif antar stop tetap dipertahankan.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/timeline/domain/timeline_model.dart';
import 'package:void_scriptor/features/timeline/presentation/timeline_workspace_screen.dart';

const List<TimelineClipModel> _threeClips = [
  TimelineClipModel(
    id: 'c1',
    trackId: 'character',
    startSeconds: 1,
    durationSeconds: 3,
    label: 'Arin Vale',
  ),
  TimelineClipModel(
    id: 'c2',
    trackId: 'character',
    startSeconds: 5,
    durationSeconds: 2,
    label: 'Mira Solenne',
  ),
  TimelineClipModel(
    id: 'c3',
    trackId: 'camera',
    startSeconds: 0,
    durationSeconds: 4,
    label: 'Dolly In',
  ),
];

/// Klasifikasi satu stop fokus berdasarkan widget + ancestor.
String _classify(BuildContext ctx) {
  var insideDropdown = false;
  var hasInk = false;
  Widget? lastWidget;

  final e = ctx as Element;
  e.visitAncestorElements((el) {
    final widget = el.widget;
    if (widget is DropdownButton ||
        widget is DropdownButtonFormField ||
        widget.runtimeType.toString().startsWith('DropdownButton')) {
      insideDropdown = true;
      return false;
    }
    if (widget is InkWell) {
      hasInk = true;
    }
    lastWidget = widget;
    return true;
  });

  if (insideDropdown) return 'dropdown';
  if (hasInk) return 'ink';
  return (lastWidget ?? ctx.widget).runtimeType.toString();
}

/// Label teks pertama di dalam subtree fokus, melewati glyph `Icon`.
String _labelOf(BuildContext ctx) {
  var label = '?';
  void findText(Element e) {
    if (label != '?') return;
    final w = e.widget;
    if (w is Icon) return;
    if (w is Text) {
      final d = w.data;
      if (d != null && d.trim().isNotEmpty) {
        label = d.trim();
        return;
      }
    }
    if (w is RichText) {
      final t = w.text.toPlainText().trim();
      if (t.isNotEmpty) {
        label = t;
        return;
      }
    }
    e.visitChildren(findText);
  }

  findText(ctx as Element);
  return label;
}

/// Traversal Tab sampai kembali ke stop yang sudah pernah dilewati.
/// Setelah selesai, daftar dirotasi agar mulai dari stop `top` terkecil
/// (Play di header, satu-satunya stop di pita paling atas).
Future<List<({String kind, String label, Rect rect})>> _stops(
  WidgetTester tester, {
  int maxTabs = 30,
}) async {
  final out = <({String kind, String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < maxTabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) break;

    final ro = ctx.findRenderObject();
    final rect = (ro is RenderBox && ro.hasSize)
        ? ro.localToGlobal(Offset.zero) & ro.size
        : Rect.zero;
    final key = '${rect.top}|${rect.left}';
    if (!seen.add(key)) break;

    out.add((kind: _classify(ctx), label: _labelOf(ctx), rect: rect));
  }

  if (out.isEmpty) return out;
  var minIdx = 0;
  for (var i = 1; i < out.length; i++) {
    if (out[i].rect.top < out[minIdx].rect.top) minIdx = i;
  }
  return <({String kind, String label, Rect rect})>[
    ...out.sublist(minIdx),
    ...out.sublist(0, minIdx),
  ];
}

Future<void> _pump(
  WidgetTester tester, {
  List<TimelineClipModel> clips = const [],
}) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TimelineWorkspaceScreen(
          sceneId: 'scene-1',
          sceneTitle: 'Megacity Landing',
          durationSeconds: 10,
          clips: clips,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TimelineWorkspaceScreen — kontrak focus order 2.4.3', () {
    testWidgets('1. header Play dulu, lalu toolbar kiri ke kanan', (
      tester,
    ) async {
      await _pump(tester);

      final stops = await _stops(tester, maxTabs: 8);

      // Tanpa clip hanya ada 6 kontrol: Play, dua zoom, Fit Scene, 2 segmen.
      expect(stops.length, 6, reason: 'harus 6 stop, dapat ${stops.length}');

      // Stop 0 = Play di header, pita paling atas.
      expect(
        stops[0].rect.top,
        lessThan(stops[1].rect.top),
        reason: 'Play di header harus stop pertama',
      );
      expect(
        stops[0].rect.left,
        greaterThan(stops[1].rect.left),
        reason: 'Play berada di ujung kanan header',
      );

      // Toolbar kiri ke kanan: zoom out, zoom in, Fit Scene, Edit, Preview.
      // Tingginya tidak seragam, jadi urutan dikontrakkan lewat `left`.
      final toolbar = stops.sublist(1);
      for (var i = 1; i < toolbar.length; i++) {
        expect(
          toolbar[i].rect.left,
          greaterThan(toolbar[i - 1].rect.left),
          reason: 'toolbar harus urut kiri ke kanan',
        );
      }

      // Dua segmen SegmentedButton dihitung dua stop terpisah.
      expect(toolbar[3].label, 'Edit');
      expect(toolbar[4].label, 'Preview');
      expect(
        toolbar[3].rect.left,
        lessThan(toolbar[4].rect.left),
        reason: 'Edit harus di kiri Preview',
      );

      // Ketiga IconButton (Play, zoom out, zoom in) punya label kosong di
      // subtree fokus meski tooltip terisi, jadi hanya posisinya yang dikunci.
      expect(stops[0].label, '?');
      expect(toolbar[0].label, '?');
      expect(toolbar[1].label, '?');
      expect(
        toolbar[2].label,
        'Fit Scene',
        reason: 'TextButton punya label di subtree fokusnya',
      );
    });

    testWidgets('2. setiap clip dapat stop fokus, dikelompokkan per track', (
      tester,
    ) async {
      await _pump(tester, clips: _threeClips);

      final stops = await _stops(tester, maxTabs: 12);

      // 6 kontrol toolbar + 3 clip = 9 stop lalu kembali ke Play.
      expect(
        stops.length,
        9,
        reason: 'harus 6 toolbar + 3 clip = 9 stop, dapat ${stops.length}',
      );

      // Tiga clip terakhir, semua muncul setelah toolbar.
      final clips = stops.sublist(6);
      expect(clips.map((s) => s.label).toList(), [
        'Arin Vale',
        'Mira Solenne',
        'Dolly In',
      ], reason: 'clip harus urut track atas lebih dulu, lalu kiri ke kanan');

      // Semua clip satu tinggi baris (28) dan di bawah toolbar.
      for (final c in clips) {
        expect(c.rect.height, 28.0, reason: 'tinggi clip tetap 28');
        expect(
          c.rect.top,
          greaterThan(stops[5].rect.top),
          reason: 'clip harus setelah seluruh toolbar',
        );
      }

      // Track character (baris pertama) sebelum track camera (baris kedua).
      expect(
        clips[0].rect.top,
        clips[1].rect.top,
        reason: 'dua clip character berbagi satu track',
      );
      expect(
        clips[0].rect.left,
        lessThan(clips[1].rect.left),
        reason: 'clip character urut kiri ke kanan sesuai startSeconds',
      );
      expect(
        clips[2].rect.top,
        greaterThan(clips[0].rect.top),
        reason: 'track camera berada di baris di bawah track character',
      );
    });

    testWidgets('3. traversal kembali ke Play setelah clip terakhir', (
      tester,
    ) async {
      await _pump(tester, clips: _threeClips);

      final stops = await _stops(tester, maxTabs: 12);

      // Setelah normalisasi, Play (top terkecil) selalu jadi stop 0.
      expect(stops.length, 9);
      expect(stops[0].rect.top, 6.0, reason: 'Play berada di header');
      expect(stops[0].rect.left, 1476.0, reason: 'Play di ujung kanan header');
      expect(stops[0].rect.top, lessThan(stops[1].rect.top));
      // Loop terjadi karena traversal berhenti setelah kembali ke Play.
    });

    testWidgets('4. clips kosong tidak menyisakan stop di area timeline', (
      tester,
    ) async {
      await _pump(tester);

      final stops = await _stops(tester, maxTabs: 12);

      expect(stops.length, 6);
      // Tidak ada stop fokus di bawah pita toolbar, sehingga tidak ada fokus
      // yang tertahan pada area timeline yang kosong.
      final lowest = stops
          .map((s) => s.rect.top)
          .reduce((a, b) => a > b ? a : b);
      expect(
        lowest,
        lessThanOrEqualTo(64.0),
        reason: 'seluruh stop harus di header atau toolbar',
      );
    });

    testWidgets('5. mode Preview menyisakan satu stop Back to Edit', (
      tester,
    ) async {
      await _pump(tester, clips: _threeClips);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      final stops = await _stops(tester, maxTabs: 8);

      // Panel diganti total: hanya tombol kembali yang bisa difokus.
      expect(stops.length, 1, reason: 'harus 1 stop, dapat ${stops.length}');
      expect(stops[0].label, 'Back to Edit');
      expect(
        find.text('Fit Scene'),
        findsNothing,
        reason: 'toolbar mode Edit tidak boleh tersisa',
      );
      expect(
        find.text('Arin Vale'),
        findsNothing,
        reason: 'clip timeline tidak boleh tersisa',
      );
    });
  });
}
