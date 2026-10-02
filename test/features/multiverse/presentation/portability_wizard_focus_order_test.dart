// WCAG 2.2 - 2.4.3 Focus Order untuk Portability Wizard.
//
// Layar tiga region yang jelas, semua tanpa state async:
//   1. dua dropdown universe (sumber lalu tujuan) - satu baris
//   2. empat chip mode port, sesuai urutan enum PortMode.values
//   3. empat chip aset, sesuai urutan list _PortAsset statis
//
// Traversal nyata diukur dengan probe 2026-10-03 pada viewport 1536x1024:
//
//   0 Canon Prime              t=216 l=54  w=379 h=24  ┐ baris universe
//   1 What If: Echoes          t=216 l=491 w=379 h=24  ┘ (sumber lalu tujuan)
//   2 Reference                t=267 l=41  w=171 h=37  ┐
//   3 Clone                    t=267 l=224 w=100 h=37  │ baris mode
//   4 Variant                  t=267 l=335 w=126 h=37  │
//   5 Locked Identity          t=267 l=473 w=231 h=37  ┘
//   6 Character: Arin Vale     t=329 l=41  w=841 h=63  ┐
//   7 Environment: Obsidian... t=392 l=41  w=841 h=63  │ daftar aset,
//   8 Prop: Aether Blade       t=455 l=41  w=841 h=63  │ satu chip per baris
//   9 Timeline: Fall of Embers t=518 l=41  w=841 h=63  ┘
//
// Tombol footer sengaja TIDAK masuk traversal: onPressed-nya
// `_selectedAssets.isEmpty ? null : () {}`, jadi saat belum ada aset dipilih
// tombol itu disabled dan dilewati traversal. Itu perilaku yang benar untuk
// kontrol disabled, bukan kontrol yang tersesat - jadi tidak dikontrak di sini
// sebagai stop fokus.
//
// Posisi absolut dipakai hanya untuk dua hal yang bisa dibuktikan tanpa
// asumsi: (a) baris universe dan baris mode dibaca kiri ke kanan (left naik
// monoton di top yang sama), (b) daftar aset dibaca atas ke bawah (top naik
// monoton di left yang sama). Wrap pada chip mode tidak auto-scroll, jadi
// left yang naik konsisten adalah bukti urutan, bukan kebetulan.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/portability_wizard_screen.dart';

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
    const MaterialApp(home: Scaffold(body: PortabilityWizardScreen())),
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
      //apakah salah satu stop universe ini hidup di dalam DropdownButton.
      //DropdownButton sendiri tidak pernah menjadi node fokus: ia membungkus
      //field-nya di StatefulWidget internal, dan node fokus yang diisi adalah
      //InkWell atau InputDecorator di dalam. Jadi kita telusuri seluruh rantai
      //ancestor dulu, lalu baru memutuskan kelas dari apa yang ditemukan.
      var insideDropdown = false;
      ctx.visitAncestorElements((e) {
        if (e.widget is DropdownButton<String>) insideDropdown = true;
        return true; // lanjut ke atas, jangan berhenti
      });

      ctx.visitAncestorElements((e) {
        if (label != 'unknown') return false;
        final w = e.widget;
        if (w is InkWell || w is GestureDetector) {
          var txt = '';
          e.visitChildElements((c) {
            if (txt.isNotEmpty) return;
            txt = _firstText(c);
          });
          kind = insideDropdown ? 'dropdown' : 'ink';
          label = txt.isEmpty ? kind : txt;
          return false;
        }
        if (w is TextFormField || w is TextField) {
          kind = insideDropdown ? 'dropdown' : 'field';
          label = kind;
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

/// Dua nilai universe, sesuai _sourceUniverses lalu _targetUniverses.
const _universeLabels = <String>['Canon Prime', 'What If: Echoes'];

/// Empat mode, sesuai urutan deklarasi enum PortMode.
const _modeLabels = <String>[
  'Reference',
  'Clone',
  'Variant',
  'Locked Identity',
];

/// Empat aset, sesuai urutan list statis _PortAsset.
const _assetLabels = <String>[
  'Character: Arin Vale',
  'Environment: Obsidian Keep',
  'Prop: Aether Blade',
  'Timeline: Fall of Embers',
];

void main() {
  group('2.4.3 focus order nyata Portability Wizard', () {
    testWidgets('dropdown universe focus lebih dulu, sumber sebelum tujuan', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();

      expect(
        actual.take(2),
        _universeLabels,
        reason:
            'dua dropdown universe harus menjadi stop fokus pertama, '
            'dapat $actual',
      );
      expect(
        order[0].kind,
        'dropdown',
        reason:
            'stop universe harus terklasifikasi dropdown, '
            'dapat ${order[0].kind}',
      );
    });

    testWidgets('empat chip mode terurut sesuai urutan enum', (tester) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();

      var cursor = 2; // setelah dua dropdown universe
      for (final label in _modeLabels) {
        final at = actual.indexOf(label, cursor);
        expect(
          at,
          greaterThanOrEqualTo(cursor),
          reason:
              'mode "$label" harus muncul pada atau setelah posisi $cursor '
              'dari traversal $actual',
        );
        cursor = at + 1;
      }

      // Baris mode dibaca kiri ke kanan: left naik monoton pada top yang sama.
      final modes = order.where((s) => _modeLabels.contains(s.label)).toList();
      expect(
        modes.length,
        4,
        reason:
            'harus ada 4 chip mode, dapat '
            '${modes.map((s) => s.label).toList()}',
      );
      final lefts = modes.map((s) => s.rect.left.round()).toList();
      final tops = modes.map((s) => s.rect.top.round()).toSet();
      expect(
        tops.length,
        1,
        reason:
            'keempat mode harus satu baris, '
            'dapat top $tops',
      );
      for (var i = 1; i < lefts.length; i++) {
        expect(
          lefts[i],
          greaterThan(lefts[i - 1]),
          reason:
              'mode ke-${i + 1} (${modes[i].label}) harus di kanan '
              'mode sebelumnya (${modes[i - 1].label}), dapat $lefts',
        );
      }
    });

    testWidgets('empat chip aset terurut atas ke bawah sesuai list statis', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();

      var cursor = 0;
      for (final label in _assetLabels) {
        final at = actual.indexOf(label, cursor);
        expect(
          at,
          greaterThanOrEqualTo(cursor),
          reason:
              'aset "$label" harus muncul pada atau setelah posisi $cursor '
              'dari traversal $actual',
        );
        cursor = at + 1;
      }

      // Satu chip per baris: top naik monoton, left dan lebar sama.
      final assets = order
          .where((s) => _assetLabels.contains(s.label))
          .toList();
      expect(
        assets.length,
        4,
        reason:
            'harus ada 4 chip aset, dapat '
            '${assets.map((s) => s.label).toList()}',
      );
      final tops = assets.map((s) => s.rect.top.round()).toList();
      for (var i = 1; i < tops.length; i++) {
        expect(
          tops[i],
          greaterThan(tops[i - 1]),
          reason:
              'aset ke-${i + 1} (${assets[i].label}) harus di bawah '
              'aset sebelumnya (${assets[i - 1].label}), dapat $tops',
        );
      }
      expect(
        assets.map((s) => s.rect.left.round()).toSet().length,
        1,
        reason: 'keempat aset harus rata kiri, satu kolom',
      );
      expect(
        assets.map((s) => s.rect.width.round()).toSet().length,
        1,
        reason: 'keempat aset harus selebar sama sebagai chip satu baris',
      );
    });

    testWidgets('urutan wilayah: universe, lalu mode, lalu aset', (
      tester,
    ) async {
      final order = await _tabOrder(tester);
      final actual = order.map((s) => s.label).toList();

      final lastUniverse = actual.lastIndexOf(_universeLabels.last);
      final firstMode = actual.indexOf(_modeLabels.first);
      final lastMode = actual.lastIndexOf(_modeLabels.last);
      final firstAsset = actual.indexOf(_assetLabels.first);

      expect(
        lastUniverse,
        greaterThanOrEqualTo(0),
        reason:
            'harus ada dua '
            'dropdown universe, dapat $actual',
      );
      expect(
        firstMode,
        greaterThan(lastUniverse),
        reason: 'mode harus dibaca setelah kedua dropdown universe',
      );
      expect(
        firstAsset,
        greaterThan(lastMode),
        reason: 'daftar aset harus dibaca setelah semua chip mode',
      );

      // Seluruh traversal tertutup dalam 10 stop dan tiap stop punya ukuran
      // render nyata (bukan target fokus hantu).
      expect(
        order.length,
        10,
        reason:
            'focus cycle harus tertutup tepat pada 10 stop, '
            'dapat ${order.length}: $actual',
      );
      for (final s in order) {
        expect(
          s.rect.width,
          greaterThan(0),
          reason: 'stop ${s.label} tidak punya ukuran render',
        );
        expect(
          s.rect.height,
          greaterThan(0),
          reason: 'stop ${s.label} tidak punya tinggi render',
        );
      }
    });
  });
}
