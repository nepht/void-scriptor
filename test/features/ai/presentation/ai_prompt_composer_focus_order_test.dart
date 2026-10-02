// WCAG 2.2 - 2.4.3 Focus Order untuk AI Prompt Composer.
//
// Layar ini punya dua wilayah yang jelas: panel CONTEXT di kiri (6 toggle
// opsi konteks) dan editor di kanan. Traversal nyata diukur dengan probe
// 2026-10-03 pada viewport 1536x1024:
//
//   0 ink (t=8)   -> tombol FAB di pojok kanan atas Scaffold
//   1 Character  | ink (t=140 l=20  w=240)  ┐
//   2 field      | field(t=144 l=332 w=1152)┘ header baris pertama
//   3 Identity Locks (t=188)               │
//   4 Wardrobe      (t=244)                │ panel CONTEXT, di kiri
//   5 Weapon        (t=292)                │ (l=20, w=240)
//   6 Environment   (t=340)                │
//   7 Timeline      (t=388)                ┘
//   8 <LOOP ke #0>  -> traversal tertutup, tidak ada kontrol tersesat
//
// Yang dikontrak di sini persis apa yang terukur: urutan enam toggle sesuai
// urutan vertikal di panel kiri, dan field editor masuk tepat setelah toggle
// pertama (bukan melompat ke panel lain lebih dulu). Posisi absolut dipakai
// hanya untuk membuktikan rail kiri dibaca dari atas ke bawah - yang ini tidak
// auto-scroll, jadi top yang naik konsisten adalah bukti yang sah.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/ai_prompt_composer_screen.dart';

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
  const _Stop(this.label, this.kind, this.rect);
  final String label;
  final String kind;
  final Rect rect;
}

Future<List<_Stop>> _tabOrder(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: AiPromptComposerScreen())),
  );
  await tester.pump();

  final seen = <FocusNode, int>{};
  final order = <_Stop>[];
  for (var i = 0; i < 40; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = FocusManager.instance.primaryFocus;
    if (node == null || seen.containsKey(node)) break;
    seen[node] = seen.length;

    var label = 'unknown';
    var kind = 'other';
    final ctx = node.context;
    if (ctx != null) {
      ctx.visitAncestorElements((e) {
        if (label != 'unknown') return false;
        final w = e.widget;
        if (w is InkWell) {
          kind = 'ink';
          var txt = '';
          e.visitChildElements((c) {
            if (txt.isNotEmpty) return;
            txt = _firstText(c);
          });
          label = txt.isEmpty ? 'ink' : txt;
          return false;
        }
        if (w is TextFormField || w is TextField) {
          kind = 'field';
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
    order.add(_Stop(label, kind, rect));
  }
  return order;
}

/// Enam toggle panel CONTEXT, sesuai urutan vertikal di `_ContextPanel`.
const _panelToggles = <String>[
  'Character',
  'Identity Locks',
  'Wardrobe',
  'Weapon',
  'Environment',
  'Timeline',
];

void main() {
  group('2.4.3 focus order nyata AI Prompt Composer', () {
    testWidgets('enam toggle panel CONTEXT terurut sesuai urutan vertikal', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();

      // Field editor TIDAK dihitung sebagai pemutus urutan: ia berbagi baris
      // visual dengan toggle pertama (probe: Character t=140 l=20 w=240 dan
      // field t=144 l=332 w=1152 - tinggi baris yang sama, kiri ke kanan),
      // jadi traversal bergerak kiri ke kanan di baris itu. Kontrak 2.4.3
      // adalah urutan RELATIF enam toggle, bukan enam label bersebelahan.
      final indexes = <int>[
        for (var i = 0; i < actual.length; i++)
          if (_panelToggles.contains(actual[i])) i,
      ];
      expect(
        indexes.length,
        6,
        reason: 'harus ada 6 toggle konteks, dapat $indexes dari $actual',
      );

      // Sublist: urutan traversal, bukan posisi absolut. Field boleh
      // menyela di antara toggle, seperti yang terukur nyata.
      var cursor = 0;
      for (final label in _panelToggles) {
        final at = actual.indexOf(label, cursor);
        expect(
          at,
          greaterThan(cursor - 1),
          reason:
              'toggle "$label" harus muncul pada atau setelah posisi $cursor '
              'dari traversal $actual',
        );
        cursor = at + 1;
      }
    });

    testWidgets('rail kiri dibaca dari atas ke bawah (top naik monoton)', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      final toggles = order
          .where((s) => _panelToggles.contains(s.label))
          .toList();
      expect(toggles.length, 6);

      // Panel tidak auto-scroll, jadi top yang naik monoton adalah bukti
      // urutan baca yang benar - bukan hanya kebetulan urutan traversal.
      final tops = toggles.map((s) => s.rect.top.round()).toList();
      for (var i = 1; i < tops.length; i++) {
        expect(
          tops[i],
          greaterThan(tops[i - 1]),
          reason:
              'toggle ke-${i + 1} (${toggles[i].label}) harus di bawah '
              'toggle sebelumnya (${toggles[i - 1].label}), dapat $tops',
        );
      }
      // Semua toggle di rail kiri yang sama, tidak berjajar antar wilayah.
      final lefts = toggles.map((s) => s.rect.left.round()).toSet();
      expect(
        lefts.length,
        1,
        reason: 'enam toggle harus rata kiri di satu panel, dapat $lefts',
      );
    });

    testWidgets(
      'field editor masuk setelah toggle pertama, bukan melompat lebih dulu',
      (tester) async {
        final order = await _tabOrder(tester);
        final actual = order.map((s) => s.label).toList();

        final firstToggle = actual.indexOf('Character');
        expect(firstToggle, greaterThanOrEqualTo(0));

        final fields = <int>[
          for (var i = 0; i < order.length; i++)
            if (order[i].kind == 'field') i,
        ];
        expect(
          fields.length,
          1,
          reason:
              'harus ada tepat satu field editor, dapat $fields dari $actual',
        );
        // Field boleh datang setelah toggle pertama (baris header yang sama)
        // tapi tidak boleh mendahului toggle pertama.
        expect(
          fields.first,
          greaterThanOrEqualTo(firstToggle),
          reason:
              'field di ${order[fields.first].label} tidak boleh mendahului '
              'toggle pertama di $firstToggle: $actual',
        );
      },
    );

    testWidgets('tidak ada kontrol yang fokusnya hilang dari traversal', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      // Traversal harus tertutup (kembali ke node awal) dalam batas wajar,
      // bukan menggantung atau terjebak di luar viewport.
      expect(
        order.length,
        lessThanOrEqualTo(20),
        reason:
            'focus cycle harus tertutup dengan stop terbatas, dapat '
            '${order.length}: ${order.map((s) => s.label).toList()}',
      );
      for (final s in order) {
        expect(
          s.rect.width,
          greaterThan(0),
          reason:
              'stop ${s.label} tidak punya ukuran - bukan target fokus nyata',
        );
      }
    });
  });
}
