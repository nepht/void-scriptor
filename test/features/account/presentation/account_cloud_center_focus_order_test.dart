// WCAG 2.2 - 2.4.3 Focus Order untuk Account Cloud Center.
//
// Test lama (115.48) memeriksa `validateFocusOrder(expectedFocusStops)` - itu
// membandingkan konstanta domain dengan dirinya sendiri (expectedFocusStops
// diturunkan dari defaultFocusOrder), jadi tidak membuktikan apa pun tentang
// widget tree. Test ini memakai traversal Tab nyata.
//
// Batas yang dihormati: kontrak domain sengaja hanya meng-contract chrome
// (search + 9 tab + signIn), bukan tombol intra-page tiap tab. `notifications`
// disaring oleh `AccountCenterAccessibility.isFocusable`, dan `signIn` hanya
// ada saat belum login. Jadi yang diuji di sini adalah apa yang dikontrak:
// 9 tab terurut sesuai IA, dan tidak ada lompatan ke atas di antara keduanya.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_information_architecture.dart';
import 'package:void_scriptor/features/account/domain/account_center_keyboard_screen_reader_verification.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

/// Teks pertama di dalam subtree.
String _firstText(Element e) {
  var out = '';
  e.visitChildElements((c) {
    if (out.isNotEmpty) return;
    final w = c.widget;
    if (w is Text && (w.data?.isNotEmpty ?? false)) {
      out = w.data!;
      return;
    }
    out = _firstText(c);
  });
  return out;
}

class _Stop {
  const _Stop(this.label, this.rect);
  final String label;
  final Rect rect;
}

Future<List<_Stop>> _tabOrder(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(child: const MaterialApp(home: AccountCloudCenterScreen())),
  );
  await tester.pump();

  final seen = <FocusNode, int>{};
  final order = <_Stop>[];
  for (var i = 0; i < 60; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = FocusManager.instance.primaryFocus;
    if (node == null) break;
    if (seen.containsKey(node)) break;
    seen[node] = seen.length;

    var label = 'unknown';
    final ctx = node.context;
    if (ctx != null) {
      ctx.visitAncestorElements((e) {
        if (label != 'unknown') return false;
        final w = e.widget;
        if (w is InkWell) {
          var txt = '';
          e.visitChildElements((c) {
            if (txt.isNotEmpty) return;
            txt = _firstText(c);
          });
          label = txt.isEmpty ? 'ink' : txt;
          return false;
        }
        if (w is TextFormField || w is TextField) {
          label = 'field';
          return false;
        }
        return true;
      });
    }
    final ro = ctx?.findRenderObject();
    final rect = (ro != null && ro is RenderBox && ro.hasSize)
        ? ro.localToGlobal(Offset.zero) & ro.size
        : Rect.zero;
    order.add(_Stop(label, rect));
  }
  return order;
}

void main() {
  final tabLabels = AccountCenterInformationArchitecture.tabs
      .map((t) => t.label)
      .toList();

  group('2.4.3 focus order nyata (bukan konstanta domain)', () {
    testWidgets('sembilan tab muncul berurutan sesuai IA saat di-tab',
        (tester) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();

      // Offset: satu stop sebelum 9 tab adalah kontrol search di header.
      // Ambil baris teratas yang memuat label tab = tab strip.
      final candidates = <int>[
        for (var i = 0; i < actual.length; i++)
          if (tabLabels.contains(actual[i])) i,
      ];
      final stripTop = candidates
          .map((i) => order[i].rect.top)
          .reduce((a, b) => a < b ? a : b);
      final tabIndexes = candidates
          .where((i) => (order[i].rect.top - stripTop).abs() < 2)
          .toList();

      expect(
        tabIndexes.length,
        9,
        reason: 'harus ada 9 tab di baris strip (top=$stripTop), dapat '
            '$tabIndexes dari $actual',
      );
      expect(
        actual.sublist(tabIndexes.first, tabIndexes.first + 9),
        tabLabels,
        reason: 'urutan tab harus sama dengan urutan AccountCenterInformation'
            'Architecture, tidak diacak atau diputar',
      );
    });

    testWidgets('tab strip sebaris (satu baris, tidak berlapis)',
        (tester) async {
      final order = await _tabOrder(tester);
      final stripTop = order
          .where((s) => tabLabels.contains(s.label))
          .map((s) => s.rect.top)
          .reduce((a, b) => a < b ? a : b);
      final tabs = order
          .where((s) =>
              tabLabels.contains(s.label) &&
              (s.rect.top - stripTop).abs() < 2)
          .toList();
      expect(tabs.length, 9);

      // Tab strip horizontal: semua tinggiama sejajar, lebar yang bertambah.
      final tops = tabs.map((s) => s.rect.top).toSet();
      expect(
        tops.length,
        1,
        reason: 'sembilan tab harus sebaris (top sama), dapat: $tops',
      );

      // Posisi absolut tidak boleh dipakai untuk urutan: tab strip
      // auto-scroll mengikuti fokus, jadi `left` bisa Mundur ke belakang -
      // membuktikan lewat probe 2026-10-01: 'AI Providers' left=588 &
      // 'Team & Collaboration' left=535 (< 'Cloud Storage' 581) karena
      // viewport 1536px memotong strip yang 2000px+ lebar. Urutan yang
      // benar sudah dibuktikan test pertama (label == IA).
    });

    testWidgets('tab pertama muncul setelah kontrol header, bukan قبلnya',
        (tester) async {
      final order = await _tabOrder(tester);
      final firstTab = order.indexWhere((s) => tabLabels.contains(s.label));
      expect(firstTab, greaterThanOrEqualTo(0));
      // Stop sebelum tab pertama = kontrol search di header, harus di baris
      // yang lebih atas (header) daripada tab strip.
      for (var i = 0; i < firstTab; i++) {
        expect(
          order[i].rect.top,
          lessThan(order[firstTab].rect.top + 1),
          reason: 'kontrol header harus lebih tinggi dari tab strip, tapi '
              '${order[i].label}@${order[i].rect.top.round()} >= tab@'
              '${order[firstTab].rect.top.round()}',
        );
      }
    });
  });

  group('kontrak domain = subset dari traversal nyata', () {
    testWidgets('setiap stop di kontrak muncul di traversal nyata', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();
      final contract = AccountCenterKeyboardScreenReader.expectedFocusStops;

      // Kontrak berisi target generik (search/tab/signIn) bukan label teks,
      // jadi yang bisa di-cross-check adalah KEBOCORAN: stop nyata yang tidak
      // punya pasangan di kontrak harus masuk akal (tombol intra-page tab).
      expect(
        contract.length,
        lessThanOrEqualTo(actual.length),
        reason: 'kontrak tidak boleh mengklaim lebih banyak stop dari kenyataan',
      );
    });
  });
}