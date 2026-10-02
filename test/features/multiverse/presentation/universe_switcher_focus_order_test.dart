// Kontrak focus order (WCAG 2.2, kriteria 2.4.3) di UniverseSwitcherScreen.
//
// Layar ini dipilih untuk Fase 9 karena:
//   - `const UniverseSwitcherScreen({super.key})` — nol parameter wajib;
//   - `_universes` adalah `static const List<String>` (4 entri), tanpa
//     future/stream/microtask, jadi traversal Tab mewakili tampilan nyata;
//   - tidak ada TabController/Navigator yang menambah stop di luar layar.
//
// Data traversal terukur (sendKeyEvent(LogicalKeyboardKey.tab), viewport
// 1536x1024 dpr 1.0):
//   0 DropdownButton value="Canon Prime"  t=16   l=1288 w=232 h=24
//   1 _UniverseTile "Canon Prime"         t=124  l=37   w=246 h=44
//   2 _UniverseTile "What If: Echoes"     t=168  l=37   w=246 h=64
//   3 _UniverseTile "Parallel Nexus"      t=232  l=37   w=246 h=44
//   4 _UniverseTile "Spin-Off: Embers"    t=276  l=37   w=246 h=64
//   5 LOOP (kembali ke dropdown, t=16 l=1288)
//
// Kontrak 2.4.3 = urutan RELATIF, bukan label bersebelahan. Empat tile
// berbaris vertikal (left konstan 37, top naik monoton), mengikuti urutan
// deklarasi `_universes` (statis). Dropdown topbar adalah stop pertama
// karena berada di AppBar.
//
// Catatan harness yang sudah diperbaiki (bukan defect produksi):
//   - `DropdownButton` tidak pernah menjadi node fokus; yang difokus adalah
//     `InkWell`/`InputDecorator` internal di dalamnya. Classifier harus
//     menelusuri seluruh rantai ancestor (bukan berhenti di `InkWell`
//     pertama) untuk memastikan ada/tidaknya `DropdownButton`.
//   - Label teks `Icon` adalah glyph codepoint internal (mis. `┃`), bukan
//     nama — walker label harus melewati subtree `Icon`.
//   - Label tidak cukup untuk membedakan stop 0 dan stop 1 (keduanya
//     "Canon Prime"): diskriminasi memakai `rect.top`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/universe_switcher_screen.dart';

/// Urutan `_universes` yang dideklarasikan di screen (dibaca dari sumber,
/// bukan ditebak dari tampilan).
const List<String> _universeOrder = <String>[
  'Canon Prime',
  'What If: Echoes',
  'Parallel Nexus',
  'Spin-Off: Embers',
];

/// Klasifikasi satu stop fokus berdasarkan widget + ancestor.
///
/// `DropdownButton` tidak pernah menjadi node fokus (fokus berada di
/// `InkWell`/`InputDecorator` internal milik StatefulWidget-nya). Karena itu
/// telusuri seluruh rantai ancestor untuk mendeteksi `DropdownButton` lebih
/// dulu, baru putuskan kelas stop dari `InkWell` atau field yang ditemukan.
String _classify(BuildContext ctx) {
  var insideDropdown = false;
  var hasInk = false;
  Widget? lastWidget;

  final e = ctx as Element;
  // Telusuri seluruh rantai ancestor tanpa berhenti di kemunculan pertama.
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

void main() {
  group('UniverseSwitcherScreen — kontrak focus order 2.4.3', () {
    testWidgets('1. lima stop dalam urutan baca atas ke bawah', (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: UniverseSwitcherScreen()));
      await tester.pumpAndSettle();

      final seen = <String>{};
      final kinds = <String>[];
      final tops = <double>[];

      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) break;

        final ro = ctx.findRenderObject();
        final rect = (ro is RenderBox && ro.hasSize)
            ? ro.localToGlobal(Offset.zero) & ro.size
            : null;

        final typeName = ctx.widget.runtimeType.toString();
        final key = '$typeName|${rect?.top}|${rect?.left}';
        if (!seen.add(key)) break;

        kinds.add(_classify(ctx));
        tops.add(rect?.top ?? 0);
      }

      // Empat tile adalah stop 1..4 (stop 0 = dropdown topbar).
      expect(kinds.length, 5, reason: 'harus 5 stop lalu LOOP, dapat ${kinds.length}');
      expect(kinds.first, 'dropdown',
          reason: 'stop pertama harus dropdown universe di topbar');
      expect(kinds.sublist(1), <String>['ink', 'ink', 'ink', 'ink'],
          reason: 'empat tile berikutnya harus InkWell');

      // Urutan baca atas ke bawah: top monoton naik.
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]),
            reason: 'stop $i harus di bawah stop ${i - 1}');
      }
    });

    testWidgets('2. empat tile terurut sesuai deklarasi _universes', (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: UniverseSwitcherScreen()));
      await tester.pumpAndSettle();

      final labels = <String>[];
      final seen = <String>{};

      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) break;
        if (_classify(ctx) != 'ink') continue;

        final ro = ctx.findRenderObject();
        final rect = (ro is RenderBox && ro.hasSize)
            ? ro.localToGlobal(Offset.zero) & ro.size
            : null;
        final key = '${rect?.top}|${rect?.left}';
        if (!seen.add(key)) continue;

        var label = '?';
        void findText(Element e) {
          if (label != '?') return;
          final w = e.widget;
          if (w is Icon) return; // glyph codepoint, bukan label
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
        labels.add(label);
      }

      expect(labels, _universeOrder,
          reason: 'urutan tile harus persis sama dengan deklarasi _universes');
    });

    testWidgets('3. empat tile berbaris vertikal, satu per baris', (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: UniverseSwitcherScreen()));
      await tester.pumpAndSettle();

      final tops = <double>[];
      final lefts = <double>[];
      final seen = <String>{};

      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) break;
        if (_classify(ctx) != 'ink') continue;

        final ro = ctx.findRenderObject();
        final rect = (ro is RenderBox && ro.hasSize)
            ? ro.localToGlobal(Offset.zero) & ro.size
            : null;
        if (rect == null) continue;
        final key = '${rect.top}|${rect.left}';
        if (!seen.add(key)) continue;

        tops.add(rect.top);
        lefts.add(rect.left);
      }

      expect(tops.length, 4);
      expect(lefts.first, 37.0, reason: 'tile pertama harus align kiri kolom');
      for (final l in lefts.skip(1)) {
        expect(l, lefts.first, reason: 'semua tile harus satu kolom');
      }
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i], greaterThan(tops[i - 1]),
            reason: 'tile harus satu baris (top naik monoton)');
      }
    });

    testWidgets('4. dropdown universe muncul sebelum semua tile', (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: UniverseSwitcherScreen()));
      await tester.pumpAndSettle();

      var dropdownTop = 0.0;
      var firstTileTop = 0.0;
      var sawDropdown = false;
      final seen = <String>{};

      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) break;
        final ro = ctx.findRenderObject();
        final rect = (ro is RenderBox && ro.hasSize)
            ? ro.localToGlobal(Offset.zero) & ro.size
            : null;
        if (rect == null) continue;
        final key = '${rect.top}|${rect.left}';
        if (!seen.add(key)) continue;

        final kind = _classify(ctx);
        if (kind == 'dropdown' && !sawDropdown) {
          sawDropdown = true;
          dropdownTop = rect.top;
        } else if (kind == 'ink' && firstTileTop == 0) {
          firstTileTop = rect.top;
        }
      }

      expect(sawDropdown, isTrue, reason: 'dropdown harus muncul di traversal');
      expect(dropdownTop, lessThan(firstTileTop),
          reason: 'dropdown harus di atas tile pertama (stop pertama)');
    });
  });
}
