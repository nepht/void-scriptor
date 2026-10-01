// WCAG 2.2 - 2.4.3 Focus Order.
//
// Data ini bukan asumsi: urutan di bawah diukur dengan memakai
// LogicalKeyboardKey.tab (cara yang sama seperti pengguna nyata) lalu
// membandingkan `FocusManager.instance.primaryFocus` sebelum/sesudah tiap tab,
// sambil membaca Rect global tiap target. Viewport 1440x1000 = ukuran golden
// login, supaya tidak ada artefak clipping seperti saat viewport test default
// 800x600 (di sana node "Work Offline" dan "Continue as Guest" proudly
// melaporkan rect identik karena ter-clip di y=552, bukan karena produksi salah).
//
// Kriteria 2.4.3: urutan fokus harus mempertahankan makna & kerelligian -
// untuk form, artinya urutan tab mengikuti urutan baca atas ke bawah.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/authentication/presentation/forgot_password_screen.dart';
import 'package:void_scriptor/features/authentication/presentation/login_screen.dart';
import 'package:void_scriptor/features/authentication/presentation/register_screen.dart';

/// Deskripsi target fokus + Rect globalnya.
class _Stop {
  _Stop(this.kind, this.text, this.rect);
  final String kind;
  final String text;
  final Rect rect;

  @override
  String toString() => '$kind${text.isEmpty ? "" : ":$text"}';
}

/// (kind, accessibleName) - accessibleName dipakai untuk membedakan
/// suffix icon dari field-nya: keduanya satu baris, jadi posisi y tidak
/// boleh dipakai sebagai penentu urutan di antara keduanya.
({String kind, String name}) _kindOf(BuildContext? ctx) {
  if (ctx == null) return (kind: 'none', name: '');
  // Prioritas TIPE, bukan kedekatan. IconButton membuat InkWell sebagai
  // descendant-nya, jadi "ancestor terdekat" selalu InkWell - kalau itu
  // jadi dasar, suffix icon salah dilaporkan sebagai button biasa.
  const rank = {'icon': 0, 'field': 1, 'button': 2};
  var best = (kind: 'unknown', name: '');
  var bestRank = 99;
  var bestDepth = 1 << 30;
  var depth = 0;
  ctx.visitAncestorElements((e) {
    depth++;
    final w = e.widget;
    String kind;
    String name = '';
    if (w is IconButton) {
      kind = 'icon';
      name = w.tooltip ?? '';
    } else if (w is TextFormField || w is TextField) {
      kind = 'field';
    } else if (w is FilledButton || w is ElevatedButton || w is OutlinedButton ||
        w is TextButton || w is InkWell) {
      kind = 'button';
    } else {
      return true;
    }
    final r = rank[kind]!;
    if (r < bestRank || (r == bestRank && depth < bestDepth)) {
      bestRank = r;
      bestDepth = depth;
      best = (kind: kind, name: name);
    }
    return true;
  });
  return best;
}

/// Jalankan traversal Tab sampai wrap, kembalikan daftar stop.
Future<List<_Stop>> _tabOrder(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1440, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      initialAuthSessionProvider.overrideWithValue(const AuthSession.loggedOut()),
    ],
    child: MaterialApp(home: child),
  ));
  await tester.pump();

  final seen = <FocusNode, int>{};
  final order = <_Stop>[];
  for (var i = 0; i < 24; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final node = FocusManager.instance.primaryFocus;
    if (node == null) break;
    if (seen.containsKey(node)) break; // wrap = traversal selesai
    seen[node] = seen.length;

    final info = _kindOf(node.context);
    final ro = node.context?.findRenderObject();
    final rect = (ro is RenderBox && ro.hasSize)
        ? ro.localToGlobal(Offset.zero) & ro.size
        : Rect.zero;
    order.add(_Stop(info.kind, info.name, rect));
  }
  return order;
}

void main() {
  // Batas toleransi: node di dalam baris yang sama boleh berbeda beberapa
  // piksel (suffix icon vs field), jadi yang diperiksa adalah monotonicitas
  // antar-baris, bukan kesamaan absolut.
  const sameRowTolerance = 8.0;

  void expectTopToBottom(List<_Stop> order, String label) {
    expect(order, isNotEmpty, reason: '$label tidak punya target fokus');

    // Suffix icon (tombol lihat/sembunyikan password) berada di baris yang
    // sama dengan field-nya dan sering punya top sedikit lebih tinggi karena
    // lebarnya lebih pendek. Pasangan seperti ini bukan "lompat ke atas" -
    // keduanya satu baris baca, jadi posisinya digabung menjadi satu grup.
    final groups = <List<_Stop>>[];
    for (final s in order) {
      final isInlineCompanion = groups.isNotEmpty &&
          (s.kind == 'icon' || s.kind == 'field') &&
          (groups.last.last.kind == 'icon' || groups.last.last.kind == 'field') &&
          (groups.last.last.rect.top - s.rect.top).abs() <=
              sameRowTolerance * 2;
      if (isInlineCompanion) {
        groups.last.add(s);
      } else {
        groups.add([s]);
      }
    }

    for (var g = 1; g < groups.length; g++) {
      final prevTop = groups[g - 1].first.rect.top;
      final curTop = groups[g].first.rect.top;
      final drop = prevTop - curTop;
      expect(
        drop,
        lessThanOrEqualTo(sameRowTolerance),
        reason: '$label: fokus melompat ke ATAS dari '
            '${groups[g - 1].join(",")}@y=${prevTop.round()} ke '
            '${groups[g].join(",")}@y=${curTop.round()}. '
            'Urutan tab harus mengikuti urutan baca.',
      );
    }
  }

  test('NEGATIVE CONTROL: urutan terbalik harus terdeteksi', () {
      // Bukti assertion-nya tidak lumpuh. `_Stop` dibuat di atas dengan y=500
      // lalu y=300 - fokus lompat ke ATAS. expectTopToBottom harus melempar.
      final bad = <_Stop>[
        _Stop('field', '', const Rect.fromLTWH(0, 500, 100, 20)),
        _Stop('button', '', const Rect.fromLTWH(0, 300, 100, 20)),
      ];
      var threw = false;
      try {
        expectTopToBottom(bad, 'negctl');
      } on TestFailure {
        threw = true;
      }
      expect(threw, isTrue,
          reason: 'urutan terbalik harus GAGAL. Kalau lolos, assertion 2.4.3 '
              'tidak benar-benar menguji apa pun.');
    });

  group('2.4.3 Focus Order - urutan mengikuti urutan baca', () {
    testWidgets('register: 4 field lalu 2 tombol, monoton turun',
        (tester) async {
      final order = await _tabOrder(
          tester, RegisterScreen(onBackToLogin: () {}));
      expect(order.map((s) => s.kind).toList(),
          ['field', 'field', 'field', 'field', 'button', 'button']);
      expectTopToBottom(order, 'register');
    });

    testWidgets('forgot password: field lalu 2 tombol, monoton turun',
        (tester) async {
      final order =
          await _tabOrder(tester, ForgotPasswordScreen(onBack: () {}));
      expect(order.map((s) => s.kind).toList(), ['field', 'button', 'button']);
      expectTopToBottom(order, 'forgot');
    });

    testWidgets('login: monoton turun tanpa keluar viewport', (tester) async {
      final order = await _tabOrder(
        tester,
        LoginScreen(onForgotPassword: () {}, onRegister: () {}),
      );
      expectTopToBottom(order, 'login');
      // Kontrol tema di top-right adalah target fokus pertama di layar ini.
      // Dikonfirmasi di produksi: login_screen.dart:340 `ThemeModeMenu`.
      expect(order.first.rect.top, lessThan(100),
          reason: 'fokus pertama seharusnya kontrol tema di header');
    });
  });

  group('2.4.3 - tidak ada target fokus yang ter-clip atau tak terjangkau', () {
    testWidgets('login: setiap stop punya area bukan nol', (tester) async {
      final order = await _tabOrder(
        tester,
        LoginScreen(onForgotPassword: () {}, onRegister: () {}),
      );
      for (final s in order) {
        expect(s.rect.width, greaterThan(0),
            reason: 'target ${s.kind} lebar 0 - tidak bisa difokuskan');
        expect(s.rect.height, greaterThan(0),
            reason: 'target ${s.kind} tinggi 0 - tidak bisa difokuskan');
      }
    });
  });
}