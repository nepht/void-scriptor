// WCAG 2.2 - 2.4.3 Focus Order untuk Tech Tree Workspace.
//
// Probe nyata 2026-10-04, viewport 1536x1024, devicePixelRatio 1.0, fixture
// registry 3 node (Wheel t1 -> Bronze Casting t2 -> Iron Smelting t3) plus
// branch "prime" dan culture "all". Traversal kembali ke stop 0 setelah stop 12:
//  0 branch: all        (ChoiceChip) Rect(124, 21, 76, 38)
//  1 branch: prime      (ChoiceChip) Rect(208, 21, 125, 38)
//  2 culture: all       (ChoiceChip) Rect(138, 77, 96, 38)
//  3 Tick slider        (Slider)     Rect(95, 128, 1298, 48)
//  4 node t-wheel       (InkWell)    Rect(16, 196, 1504, 38)
//  5 node t-bronze      (InkWell)    Rect(16, 242, 1504, 38)
//  6 node t-iron        (InkWell)    Rect(16, 288, 1504, 38)
//  7 Advance tier       (IconButton) Rect(20, 350, 40, 40)
//  8 Retreat tier       (IconButton) Rect(76, 350, 40, 40)
//  9 Jump to first discovery      Rect(132, 350, 40, 40)
// 10 Jump to last discovery       Rect(188, 350, 40, 40)
// 11 Navigate left                Rect(244, 350, 40, 40)
// 12 Navigate right               Rect(300, 350, 40, 40)
//
// Tombol "clear" pada baris Tick sengaja TIDAK menjadi stop fokus: saat
// atTickFilter null, onPressed-nya null sehingga tidak keyboard-reachable
// (bukan control yang hilang).
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

import "package:void_scriptor/features/world_logic/domain/tech_tree_workspace.dart";
import "package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart";
import "package:void_scriptor/features/world_logic/presentation/tech_tree_workspace_view.dart";

/// Label stop fokus dalam urutan Tab yang terukur.
const _expectedLabels = <String>[
  "Text:all",
  "Text:prime",
  "Text:all",
  "Slider:tech-tree-filter-tick-slider",
  "Text:tier 1 | Text:Wheel",
  "Text:tier 2 | Text:Bronze Casting",
  "Text:tier 3 | Text:Iron Smelting",
  "Tooltip:Advance tier",
  "Tooltip:Retreat tier",
  "Tooltip:Jump to first discovery",
  "Tooltip:Jump to last discovery",
  "Tooltip:Navigate left",
  "Tooltip:Navigate right",
];

/// Sisi terpendek fokus minimum. ChoiceChip 38 px, IconButton 40 px, jadi 38.
const _minFocusShortestSide = 38.0;

/// Geometri setiap stop fokus hasil probe; dipakai sebagai kunci traversal
/// (untuk mendeteksi jebakan fokus) dan sebagai kunci urutan baca.
const _expectedGeometry = <String>[
  "124,21,76,38",
  "208,21,125,38",
  "138,77,96,38",
  "95,128,1298,48",
  "16,196,1504,38",
  "16,242,1504,38",
  "16,288,1504,38",
  "20,350,40,40",
  "76,350,40,40",
  "132,350,40,40",
  "188,350,40,40",
  "244,350,40,40",
  "300,350,40,40",
];

TechnologySource _src([String label = "rev"]) =>
    TechnologySource.validated(revision: label, reason: label);

TechnologyNode _node({
  required String id,
  required String name,
  int tier = 1,
  List<String> prerequisites = const [],
}) {
  return TechnologyNode.validated(
    id: id,
    name: name,
    scope: TechnologyScope.civil,
    branch: "prime",
    tier: tier,
    prerequisites: prerequisites,
    source: _src(),
  );
}

TechnologyRegistry _sampleRegistry() {
  return TechnologyRegistry.validated(
    nodes: [
      _node(id: "t-wheel", name: "Wheel", tier: 1),
      _node(
        id: "t-bronze",
        name: "Bronze Casting",
        tier: 2,
        prerequisites: ["t-wheel"],
      ),
      _node(
        id: "t-iron",
        name: "Iron Smelting",
        tier: 3,
        prerequisites: ["t-bronze"],
      ),
    ],
  );
}

TechnologyDiscoveryTimeline _sampleTimeline() {
  return TechnologyDiscoveryTimeline.validated(
    events: [
      TechnologyDiscoveryEvent.validated(
        id: "d-wheel",
        technologyId: "t-wheel",
        tick: 5,
        summary: "wheel",
        source: _src(),
      ),
      TechnologyDiscoveryEvent.validated(
        id: "d-bronze",
        technologyId: "t-bronze",
        tick: 20,
        summary: "bronze",
        source: _src(),
      ),
      TechnologyDiscoveryEvent.validated(
        id: "d-iron",
        technologyId: "t-iron",
        tick: 40,
        summary: "iron",
        source: _src(),
      ),
    ],
  );
}

/// Kunci identik sebuah stop fokus: dipakai untuk mendeteksi traversal yang
/// kembali ke stop sebelumnya (jebakan fokus / traversal tidak berulang).
String _geometryOf(Rect rect) =>
    '${rect.left.round()},${rect.top.round()},'
    '${rect.width.round()},${rect.height.round()}';

/// Label deterministik dari widget yang difokuskan: subtree Text/Tooltip dulu,
/// lalu label TextField dan Tooltip di ancestor (IconButton menyimpan tooltip
/// sebagai ancestor, bukan descendant), lalu key Slider yang tidak berlabel.
String _labelOf(BuildContext context) {
  final element = context as Element;
  final buffer = StringBuffer();
  void visit(Element node) {
    final widget = node.widget;
    final data = switch (widget) {
      Text() => (widget.data ?? "").trim(),
      Tooltip() => (widget.message ?? "").trim(),
      _ => "",
    };
    if (data.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(" | ");
      buffer.write('${widget.runtimeType}:$data');
    }
    node.visitChildren(visit);
  }

  visit(element);
  if (buffer.isNotEmpty) return buffer.toString();

  String? ancestorLabel;
  String? ancestorKey;
  element.visitAncestorElements((candidate) {
    final widget = candidate.widget;
    if (widget is TextField) {
      final decoration = widget.decoration;
      final label = decoration?.labelText ?? decoration?.hintText ?? "";
      if (label.trim().isNotEmpty) {
        ancestorLabel = "TextField:${label.trim()}";
        return false;
      }
    }
    if (widget is Tooltip && (widget.message ?? "").trim().isNotEmpty) {
      ancestorLabel = "Tooltip:${(widget.message ?? "").trim()}";
      return false;
    }
    if (widget is Slider && widget.key is ValueKey<String>) {
      ancestorKey = "Slider:${(widget.key! as ValueKey<String>).value}";
      return false;
    }
    return true;
  });
  if (ancestorLabel != null) return ancestorLabel!;
  if (ancestorKey != null) return ancestorKey!;
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

/// Pump workspace Tech Tree dengan controller fixture, dari keadaan fokus segar.
Future<void> _pumpTechTree(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = TechTreeController.forRegistry(
    registry: _sampleRegistry(),
    timeline: _sampleTimeline(),
  );
  addTearDown(controller.dispose);

  _resetFocus();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: TechTreeWorkspaceView(controller: controller)),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<List<({String label, Rect rect})>> _tabStops(
  WidgetTester tester, {
  int maxStops = 60,
}) async {
  await _pumpTechTree(tester);

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
    "2.4.3 focus order mengikuti urutan baca: filter branch, filter culture, "
    "slider tick, node graph, lalu aksi keyboard",
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
    "2.4.3 traversal bergerak dari atas ke bawah tanpa lompatan ke kanan lalu "
    "kembali ke kiri",
    (tester) async {
      final stops = await _tabStops(tester);

      // Setiap baris kontrol dibaca dari kiri ke kanan: tidak ada stop fokus
      // yang berada di kanan anak stop fokus sebelumnya pada baris yang sama.
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
    },
  );

  testWidgets(
    "2.4.3 traversal kembali ke stop pertama sehingga tidak ada jebakan fokus "
    "setelah aksi keyboard terakhir",
    (tester) async {
      // Traversal penuh dari keadaan fokus segar, dua putaran: tab
      // sebanyak 2N. Nudge bawaan Flutter dapat melanjutkan traversal dari
      // stop mana pun (node sebelumnya yang di-dispose), jadi yang diuji
      // adalah sifat cincinnya, bukan offset mulai:
      //   - satu putaran = N stop unik, tiap stop muncul tepat sekali;
      //   - putaran kedua identik dengan putaran pertama, yaitu tidak ada
      //     jebakan fokus dan urutan tidak bergeser setelah aksi keyboard
      //     terakhir;
      //   - urutan melingkar di dalam putaran itu sama dengan kontrak.
      await _pumpTechTree(tester);

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

      // Tiap stop muncul tepat sekali per putaran: tidak ada stop yang
      // dilewati maupun yang diulang di dalam satu putaran.
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
