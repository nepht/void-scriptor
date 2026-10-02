// Kontrak focus order (WCAG 2.2, kriteria 2.4.3) di CreateUniverseWizardScreen.
//
// Layar ini dipilih untuk Fase 10 karena:
//   - `const CreateUniverseWizardScreen({super.key})` — nol parameter wajib;
//   - `_steps` (3 entri) dan `_universeTypes` (8 entri) adalah `static const
//     List<String>`, tanpa future/stream/microtask, sehingga traversal Tab
//     mewakili tampilan nyata dan dapat direproduksi;
//   - tanpa TabController/Navigator/PageView yang menambah stop di luar layar.
//
// Traversal diukur per langkah memakai `sendKeyEvent(LogicalKeyboardKey.tab)`
// pada viewport 1536x1024 dengan devicePixelRatio 1.0. Semua koordinat dalam
// piksel logika.
//
// Langkah 0 (Name):
//   0 IconButton close (tooltip Cancel)  kind=ink t=8    l=8    w=40  h=40
//   1 TextField "Nama Universe"           kind=RootWidget t=184 l=361 w=1118 h=20
//   2 TextButton "Cancel"                 kind=ink t=960  l=1301 w=103 h=40
//   3 FilledButton "Next"                 kind=ink t=960  l=1416 w=100 h=40
//   (lalu kembali ke 0 — LOOP)
//
// Langkah 1 (Type): 8 ChoiceChip satu baris, kiri ke kanan, berlabel sesuai
// deklarasi `_universeTypes` (baris 21-30), lalu footer Cancel/Next, lalu
// kembali ke IconButton close.
//   0 Canon     t=174 l=345  w=100 h=37
//   1 Alternate t=174 l=457  w=171 h=37
//   2 What If   t=174 l=639  w=126 h=37
//   3 Spin-Off  t=174 l=777  w=139 h=37
//   4 AU        t=174 l=928  w=60  h=37
//   5 Crossover t=174 l=1000 w=152 h=37
//   6 Parallel  t=174 l=1164 w=139 h=37
//   7 Dream     t=174 l=1315 w=100 h=37
//   8 Cancel    t=960 l=1301 w=103 h=40
//   9 Next      t=960 l=1416 w=100 h=40
//   10 IconButton close (LOOP)
//
// Langkah 2 (Confirm): hanya footer — tombol Create (label berubah dari
// Next karena `_stepIndex == _steps.length - 1`), Cancel, lalu close.
//   0 Cancel   t=960 l=1275 w=103 h=40
//   1 Create   t=960 l=1389 w=127 h=40
//   2 IconButton close (LOOP)
//
// Kontrak 2.4.3 = urutan RELATIF. Yang dikontrakkan:
//   - langkah 0: close -> field -> Cancel -> Next (kembali ke atas);
//   - langkah 1: 8 chip berurutan kiri ke kanan sesuai `_universeTypes`,
//     lalu footer Cancel -> Next, lalu kembali ke close;
//   - langkah 2: Cancel -> Create (urutan footer tetap sama, hanya label
//     tombol utama yang berubah), lalu kembali ke close;
//   - langkah 1 dan 2 tidak pernah menaruh field atau chip sebelum footer.
//
// Catatan harness yang sudah diperbaiki (bukan defect produksi):
//   - `DropdownButton` tidak pernah menjadi node fokus; yang difokus adalah
//     `InkWell`/`InputDecorator` internal di dalamnya. Classifier menelusuri
//     seluruh rantai ancestor lebih dulu.
//   - Label `Icon` adalah glyph codepoint internal, bukan nama — walker label
//     melewati subtree `Icon`. Karena itu IconButton close dan ChoiceChip
//     tanpa `Icon` internal tampil dengan label kosong pada langkah 0 dan 2;
//     diskriminasi memakai `rect.top`/`rect.left` dan urutan, bukan label.
//   - `TextField` berfokus pada `EditableText`/`Focus` di dalam `TextField`,
//     sehingga label diambil dari semantics/ancestor `InputDecoration`, bukan
//     dari `Text` di subtree fokus.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/create_universe_wizard_screen.dart';

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

/// Rekam traversal Tab (klasifikasi + label + rect) sampai kembali ke stop
/// yang sudah pernah dilewati.
Future<List<({String kind, String label, Rect rect})>> _stops(
  WidgetTester tester, {
  int maxTabs = 40,
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

  // Fokus bertahan saat pindah langkah, jadi traversal bisa mulai dari stop
  // mana saja dalam siklus. Normalisasi: putar daftar agar dimulai dari stop
  // dengan `top` terkecil (IconButton close di AppBar, satu-satunya stop di
  // baris paling atas) sehingga indeks assertion deterministik. Urutan relatif
  // antar stop tetap dipertahankan, termasuk saat beberapa stop berbagi `top`.
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

Future<void> _pumpWizard(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: CreateUniverseWizardScreen()));
  await tester.pumpAndSettle();
}

void main() {
  group('CreateUniverseWizardScreen — kontrak focus order 2.4.3', () {
    testWidgets('1. langkah Name: field sebelum footer, Next terakhir', (
      tester,
    ) async {
      await _pumpWizard(tester);

      final stops = await _stops(tester, maxTabs: 10);

      // 4 stop lalu LOOP: close, field, Cancel, Next.
      expect(stops.length, 4, reason: 'harus 4 stop lalu kembali ke close');

      // Stop 0 = IconButton close di AppBar (top paling atas).
      expect(stops[0].rect.top, lessThan(stops[1].rect.top),
          reason: 'close di AppBar harus stop pertama (top paling kecil)');

      // Stop 1 = TextField (tengah layar).
      expect(stops[1].rect.top, greaterThan(stops[0].rect.top));
      expect(stops[1].rect.top, lessThan(stops[2].rect.top),
          reason: 'field harus di atas footer');

      // Stop 2 = Cancel, stop 3 = Next: footer satu baris, kiri ke kanan.
      expect(stops[2].rect.top, stops[3].rect.top,
          reason: 'Cancel dan Next harus satu baris (top sama)');
      expect(stops[2].rect.left, lessThan(stops[3].rect.left),
          reason: 'Cancel harus di kiri Next');

      // Next adalah tombol utama (FilledButton) dan berada paling kanan.
      expect(stops[3].label, 'Next', reason: 'tombol utama harus "Next"');
    });

    testWidgets('2. langkah Type: delapan chip kiri ke kanan sesuai _universeTypes',
        (tester) async {
      await _pumpWizard(tester);

      // Pindah ke langkah Type.
      final next = find.text('Next');
      expect(next, findsOneWidget);
      await tester.tap(next);
      await tester.pumpAndSettle();

      final stops = await _stops(tester, maxTabs: 20);

      // 8 chip + Cancel + Next + close = 11 stop lalu LOOP. Setelah
      // normalisasi, close (top terkecil) jadi stop 0.
      expect(stops.length, 11,
          reason: 'harus 8 chip + 2 footer + close = 11 stop, dapat ${stops.length}');

      // Stop 0 = IconButton close di AppBar.
      expect(stops[0].rect.top, lessThan(stops[1].rect.top),
          reason: 'close di AppBar harus stop pertama');

      // Chip 1..8 semua satu baris (top sama) dan kiri ke kanan.
      final chips = stops.sublist(1, 9);
      final expectedTypes = <String>[
        'Canon',
        'Alternate',
        'What If',
        'Spin-Off',
        'AU',
        'Crossover',
        'Parallel',
        'Dream',
      ];
      expect(chips.map((s) => s.label).toList(), expectedTypes,
          reason: 'urutan chip harus sama dengan deklarasi _universeTypes');
      for (var i = 1; i < chips.length; i++) {
        expect(chips[i].rect.top, chips[0].rect.top,
            reason: 'semua chip harus satu baris');
        expect(chips[i].rect.left, greaterThan(chips[i - 1].rect.left),
            reason: 'chip harus urut kiri ke kanan');
      }

      // Footer Cancel lalu Next, keduanya di bawah chip.
      final cancel = stops[9];
      final nextBtn = stops[10];
      expect(cancel.rect.top, greaterThan(chips[7].rect.top),
          reason: 'footer harus di bawah semua chip');
      expect(nextBtn.rect.top, cancel.rect.top,
          reason: 'Cancel dan Next satu baris');
      expect(nextBtn.rect.left, greaterThan(cancel.rect.left),
          reason: 'Next harus di kanan Cancel');
      expect(nextBtn.label, 'Next', reason: 'tombol utama di langkah Type');
    });

    testWidgets('3. langkah Confirm: hanya footer, tombol utama "Create"', (
      tester,
    ) async {
      await _pumpWizard(tester);

      // Name -> Type.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      // Type -> Confirm.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final stops = await _stops(tester, maxTabs: 8);

      // Confirm: close, Cancel, Create = 3 stop lalu LOOP. Setelah
      // normalisasi, close (top terkecil) jadi stop 0.
      expect(stops.length, 3, reason: 'harus 3 stop, dapat ${stops.length}');

      // Stop 0 = IconButton close di AppBar, di atas footer.
      expect(stops[0].rect.top, lessThan(stops[1].rect.top),
          reason: 'close di AppBar harus stop pertama');

      // Footer Cancel lalu Create, satu baris, kiri ke kanan.
      expect(stops[1].label, 'Cancel');
      expect(stops[2].label, 'Create',
          reason: 'tombol utama berubah jadi "Create" di langkah terakhir');
      expect(stops[1].rect.top, stops[2].rect.top,
          reason: 'Cancel dan Create satu baris');
      expect(stops[1].rect.left, lessThan(stops[2].rect.left),
          reason: 'Cancel harus di kiri Create');
    });

    testWidgets('4. traversal selalu kembali ke close (LOOP di tiap langkah)', (
      tester,
    ) async {
      await _pumpWizard(tester);

      // Langkah 0: 4 stop lalu kembali ke close.
      final stops0 = await _stops(tester, maxTabs: 10);
      expect(stops0.length, 4);

      // Pindah ke Confirm untuk memastikan loop juga di langkah terakhir.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      final stops2 = await _stops(tester, maxTabs: 8);
      expect(stops2.length, 3);
      // Setelah normalisasi, close (top terkecil) selalu jadi stop 0 di
      // setiap langkah: satu-satunya stop di baris paling atas.
      expect(stops2[0].rect.top, lessThan(stops2[1].rect.top),
          reason: 'loop harus kembali ke close di AppBar');
    });

    testWidgets('5. tidak ada field/chip mendahului footer di langkah mana pun', (
      tester,
    ) async {
      await _pumpWizard(tester);

      // Langkah 0: field (stop 1) tidak boleh di bawah footer mana pun.
      final stops0 = await _stops(tester, maxTabs: 10);
      expect(stops0.length, 4);
      final fieldTop = stops0[1].rect.top;
      final footerTop = stops0[2].rect.top;
      expect(fieldTop, lessThan(footerTop),
          reason: 'field harus sebelum footer di langkah Name');

      // Langkah 1: semua chip (1..8) harus sebelum footer.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      final stops1 = await _stops(tester, maxTabs: 20);
      expect(stops1.length, 11);
      final lastChipTop = stops1[8].rect.top;
      final footerTop1 = stops1[9].rect.top;
      expect(lastChipTop, lessThan(footerTop1),
          reason: 'chip terakhir harus sebelum footer di langkah Type');
    });
  });
}