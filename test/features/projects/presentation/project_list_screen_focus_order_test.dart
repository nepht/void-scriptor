// WCAG 2.2 - 2.4.3 Focus Order untuk Project List Screen.
//
// Probe nyata 2026-10-04, viewport 1536x1024, devicePixelRatio 1.0, fixture
// satu proyek ("Void Universe") di ProjectLocalDataSource in-memory sehingga
// grid merender tiga kolom (>= 1100 px) dan ProjectCard ikut muncul.
// Traversal kembali ke stop 0 setelah stop 2 (N = 3 stop unik):
//  0 New Project         (FilledButton) Rect(1283, 41, 221, 40)
//  1 kartu proyek        (InkWell)     Rect(  32, 117, 480, 310)
//  2 Project actions     (PopupMenu)   Rect( 461, 128,  40,  40)
//
// Tombol "Project actions for Void Universe" adalah satu-satunya kontrol
// per kartu; teks ProjectCard (nama, deskripsi, versi) ikut terbaca sebagai
// bagian dari InkWell yang sama, bukan sebagai stop fokus terpisah.
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/projects/data/project_local_data_source.dart";
import "package:void_scriptor/features/projects/data/project_repository_impl.dart";
import "package:void_scriptor/features/projects/domain/project_model.dart";
import "package:void_scriptor/features/projects/presentation/project_list_screen.dart";
import "package:void_scriptor/features/projects/presentation/project_persistence_providers.dart";

/// Label stop fokus dalam urutan Tab yang terukur.
const _expectedLabels = <String>[
  "Text:New Project",
  "Text:Void Universe | Text:Main universe | Text:Version 0.1.0",
  "Tooltip:Project actions for Void Universe",
];

/// Geometri setiap stop fokus hasil probe: kunci traversal (mendeteksi
/// jebakan fokus) sekaligus kunci urutan baca.
const _expectedGeometry = <String>[
  "1283,41,221,40",
  "32,117,480,310",
  "461,128,40,40",
];

/// Sisi terpendek fokus minimum: New Project 40 px, PopupMenuButton 40 px.
const _minFocusShortestSide = 40.0;

/// Kunci identik sebuah stop fokus.
String _geometryOf(Rect rect) =>
    "${rect.left.round()},${rect.top.round()},"
    "${rect.width.round()},${rect.height.round()}";

/// Label deterministik dari widget yang difokuskan: subtree Text dulu,
/// lalu Tooltip di ancestor. PopupMenuButton menyimpan tooltip sebagai
/// ancestor, bukan descendant, sehingga harus dibaca lewat ancestor.
String _labelOf(BuildContext context) {
  final element = context as Element;
  final buffer = StringBuffer();
  void visit(Element node) {
    final widget = node.widget;
    if (widget is Text) {
      final data = (widget.data ?? "").trim();
      if (data.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write(" | ");
        buffer.write("Text:$data");
      }
    }
    node.visitChildren(visit);
  }

  visit(element);
  if (buffer.isNotEmpty) return buffer.toString();

  element.visitAncestorElements((candidate) {
    final widget = candidate.widget;
    if (widget is Tooltip && (widget.message ?? "").trim().isNotEmpty) {
      buffer.write("Tooltip:${(widget.message ?? "").trim()}");
      return false;
    }
    return true;
  });
  if (buffer.isNotEmpty) return buffer.toString();
  return "widget:${element.widget.runtimeType}";
}

({String label, Rect rect})? _currentStop() {
  final node = FocusManager.instance.primaryFocus;
  if (node == null || node.context == null) return null;
  final object = node.context!.findRenderObject();
  final rect = object is RenderBox && object.hasSize
      ? object.localToGlobal(Offset.zero) & object.size
      : Rect.zero;
  return (label: _labelOf(node.context!), rect: rect);
}

/// Melepaskan fokus utama sebelum traversal baru. `FocusManager.instance`
/// bersifat global di dalam satu file test, jadi traversal kedua akan
/// dilanjutkan dari stop terakhir traversal pertama kecuali fokus dibersihkan.
void _resetFocus() => FocusManager.instance.primaryFocus?.unfocus();

/// Pump Project List dengan satu proyek in-memory, dari keadaan fokus segar.
Future<void> _pumpProjectList(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final source = ProjectLocalDataSource();
  final now = DateTime(2026, 9, 2);
  await source.createProject(
    ProjectModel(
      id: "void-universe",
      name: "Void Universe",
      description: "Main universe",
      createdAt: now,
      updatedAt: now,
      lastOpenedAt: now,
      localPath: r"D:\VoidScriptor\Projects\void-universe.voidproject",
      version: "0.1.0",
    ),
  );

  _resetFocus();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectLocalDataSourceProvider.overrideWithValue(source),
        projectRepositoryProvider.overrideWithValue(
          ProjectRepositoryImpl(source),
        ),
      ],
      child: const MaterialApp(home: ProjectListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<List<({String label, Rect rect})>> _tabStops(
  WidgetTester tester, {
  int maxStops = 24,
}) async {
  await _pumpProjectList(tester);

  final seen = <String>{};
  final stops = <({String label, Rect rect})>[];
  for (var i = 0; i < maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final stop = _currentStop();
    if (stop == null) continue;
    if (seen.contains(_geometryOf(stop.rect))) break;
    seen.add(_geometryOf(stop.rect));
    stops.add(stop);
  }
  return stops;
}

void main() {
  testWidgets(
    "2.4.3 focus order mengikuti urutan baca: aksi utama di header, kartu "
    "proyek, lalu menu aksi kartu",
    (tester) async {
      final stops = await _tabStops(tester);

      expect(stops.length, _expectedLabels.length);
      expect(stops.map((s) => s.label).toList(), _expectedLabels);
      expect(stops.map((s) => _geometryOf(s.rect)).toList(), _expectedGeometry);
    },
  );

  testWidgets("2.4.3 setiap stop fokus punya area bukan nol", (tester) async {
    final stops = await _tabStops(tester);

    expect(stops, isNotEmpty);
    for (final stop in stops) {
      expect(
        stop.rect.width > 0 && stop.rect.height > 0,
        isTrue,
        reason: 'stop ${stop.label} punya Rect nol',
      );
      expect(
        stop.rect.shortestSide >= _minFocusShortestSide,
        isTrue,
        reason: 'stop ${stop.label} terlalu kecil: ${stop.rect}',
      );
    }
  });

  testWidgets(
    "2.4.3 traversal bergerak dari atas ke bawah, dan kartu dibaca sebelum "
    "menu aksinya",
    (tester) async {
      final stops = await _tabStops(tester);

      // Setiap baris kontrol dibaca dari kiri ke kanan: tidak ada stop fokus
      // di kanan anak stop fokus sebelumnya pada baris yang sama.
      for (var i = 1; i < stops.length; i++) {
        final previous = stops[i - 1].rect;
        final current = stops[i].rect;
        final sameRow = (previous.top - current.top).abs() < 1;
        if (!sameRow) continue;
        expect(
          current.left >= previous.left,
          isTrue,
          reason:
              'stop ${stops[i].label}(${current.left}) kembali ke kiri dari '
              '${stops[i - 1].label}(${previous.left}) pada baris yang sama',
        );
      }

      // Baris-baris fokus membentuk urutan vertikal monoton.
      final rowTops = <double>[for (final s in stops) s.rect.top];
      for (var i = 1; i < rowTops.length; i++) {
        expect(
          rowTops[i] >= rowTops[i - 1],
          isTrue,
          reason:
              'baris fokus $i naik ke atas: ${rowTops[i - 1]} -> ${rowTops[i]}',
        );
      }

      // Kartu proyek adalah stop kedua dan menu aksinya (PopupMenuButton)
      // terletak di dalam area kartu itu, bukan di halaman terpisah: fokus
      // tidak boleh mendahului kartu yang memuatnya.
      final card = stops[1].rect;
      final cardMenu = stops[2].rect;
      expect(cardMenu.left, greaterThanOrEqualTo(card.left));
      expect(cardMenu.right, lessThanOrEqualTo(card.right));
      expect(cardMenu.top, greaterThanOrEqualTo(card.top));
      expect(cardMenu.bottom, lessThanOrEqualTo(card.bottom));
    },
  );

  testWidgets(
    "2.4.3 traversal kembali ke stop pertama sehingga tidak ada jebakan fokus "
    "setelah menu aksi kartu",
    (tester) async {
      await _pumpProjectList(tester);

      final n = _expectedLabels.length;
      final geometries = <String>[];
      for (var i = 0; i < n * 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final stop = _currentStop();
        expect(stop, isNotNull, reason: 'stop fokus $i hilang');
        geometries.add(_geometryOf(stop!.rect));
      }

      final firstLap = geometries.sublist(0, n);
      final secondLap = geometries.sublist(n);

      // Tidak ada jebakan fokus: putaran kedua mengulang putaran pertama.
      expect(secondLap, firstLap);

      // Tiap stop muncul tepat sekali per putaran.
      expect(firstLap.toSet().length, n);

      // Offset awal boleh berputar; urutan melingkar harus tetap sama.
      final offset = secondLap.indexOf(_expectedGeometry.first);
      expect(offset, greaterThanOrEqualTo(0));
      expect(
        secondLap.sublist(offset) + secondLap.sublist(0, offset),
        _expectedGeometry,
      );
    },
  );
}
