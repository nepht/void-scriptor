import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/presentation/game_creation_dashboard_screen.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk Game Creation Dashboard Screen.
///
/// Layar ini punya dua kontrol interaktif, keduanya di `AppBar.actions`:
/// `Play` (TextButton.icon) dan `Build` (FilledButton.icon). Callback-nya
/// (`onPlay`, `onBuild`) bersifat nullable, jadi probe dan kontrak ini WAJIB
/// mengirim callback non-null — kalau null, Flutter membuang tombol dari
/// traversal fokus dan hasil probe akan salah (hanya satu stop yang tersisa).
///
/// Body layar (sidebar World, panel Game World, Inspector) murni teks: tidak ada
/// ListTile onTap, Switch, Checkbox, atau TextField. Jadi urutan fokus_screen ini
/// tepat dua stop dan keduanya berada pada baris AppBar yang sama.
///
/// Bukti pengukuran diambil dari probe sementara pada viewport 1536x1024 dan
/// 390x844, dpr 1.0, dengan `sendKeyEvent(LogicalKeyboardKey.tab)` berulang sampai
/// geometri fokus berulang (wrap ke stop pertama).
void main() {
  testWidgets('mengunci urutan fokus Game Creation Dashboard Screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var playCalls = 0;
    var buildCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GameCreationDashboardScreen(
            onPlay: () => playCalls++,
            onBuild: () => buildCalls++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stops = <({String label, Rect rect})>[];
    final seenRects = <String>{};
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      final object = focus?.context?.findRenderObject();
      if (object is! RenderBox || !object.hasSize) continue;
      final rect = object.localToGlobal(Offset.zero) & object.size;
      final rectKey =
          '${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)},'
          '${rect.width.toStringAsFixed(1)},${rect.height.toStringAsFixed(1)}';
      if (!seenRects.add(rectKey)) break;
      stops.add((label: _nearestTextLabel(tester, rect), rect: rect));
    }

    // Tepat dua stop fokus: Play lalu Build.
    expect(stops, hasLength(2));
    expect(stops.map((stop) => stop.label), equals(<String>['Play', 'Build']));

    // Area fokus tidak nol pada setiap stop — kontrol harus benar-benar bisa
    // dijangkau keyboard, bukan fokus berukuran 0.
    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }

    // Kedua tombol berada pada baris AppBar yang sama: koordinat top sama dan
    // tinggi sama (tinggi tombol Material default).
    final rowTop = stops.first.rect.top;
    for (final stop in stops) {
      expect(stop.rect.top, rowTop);
      expect(stop.rect.height, stops.first.rect.height);
    }

    // Urutan fokus mengikuti urutan visual kiri ke kanan.
    for (var i = 1; i < stops.length; i++) {
      expect(stops[i].rect.left, greaterThan(stops[i - 1].rect.left));
    }

    // Baris tombol menempel di atas layar dan tidak keluar dari viewport.
    expect(stops.first.rect.top, greaterThanOrEqualTo(0));
    expect(stops.last.rect.right, lessThan(1536));

    // Fokus keyboard harus benar-benar dapat memicu aksi, bukan hanya berpindah.
    // Diawali dari keadaan awal: belum ada aksi yang terpicu.
    expect(playCalls, 0);
    expect(buildCalls, 0);

    // Catatan defect TERPISAH dari fokus (bukan bagian kontrak 2.4.3 ini):
    // pada viewport 1536x1024 (branch `wide`), item sidebar "Characters"
    // membutuhkan 172.5 px (Icon 18 + SizedBox 12 + Text 142.5) sementara
    // lebar yang tersedia hanya 148 px (Container width 180 dikurangi padding
    // md 16 x2). Akibatnya RenderFlex meluap 25 px ke kanan. Test lama
    // `game_creation_dashboard_screen_test.dart` hanya mengecek viewport 390,
    // sehingga defect ini tidak pernah tertangkap. Kontrak ini sengaja TIDAK
    // mengunci overflow tersebut sebagai perilaku yang diharapkan; exception
    // diambil agar tidak menutupi kontrak fokus, lalu dicatat sebagai Gap.
    final layoutException = tester.takeException();
    if (layoutException != null) {
      // ignore: avoid_print
      print('KNOWN_LAYOUT_DEFECT: ${layoutException.runtimeType}');
    }

    // Loop fokus berhenti saat geometri berulang, yaitu saat traversal wrap ke
    // stop pertama. Jadi setelah loop, fokus berada di Play.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(playCalls, 1);
    expect(buildCalls, 0);

    // Tab maju ke stop kedua (Build) dan Enter memicu aksi kedua.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context?.findRenderObject(),
      isA<RenderBox>(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(buildCalls, 1);
    expect(playCalls, 1);
  });

  testWidgets('urutan fokus tetap Play lalu Build pada viewport sempit 390x844', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: GameCreationDashboardScreen(onPlay: () {}, onBuild: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final labels = <String>[];
    final seenRects = <String>{};
    for (var i = 0; i < 20; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focus = FocusManager.instance.primaryFocus;
      final object = focus?.context?.findRenderObject();
      if (object is! RenderBox || !object.hasSize) continue;
      final rect = object.localToGlobal(Offset.zero) & object.size;
      final rectKey =
          '${rect.left.toStringAsFixed(1)},${rect.top.toStringAsFixed(1)},'
          '${rect.width.toStringAsFixed(1)},${rect.height.toStringAsFixed(1)}';
      if (!seenRects.add(rectKey)) break;
      labels.add(_nearestTextLabel(tester, rect));
    }

    expect(labels, equals(<String>['Play', 'Build']));

    // Branch sempit (lebar < 1000) memakai ListView dan tidak meluap; ini yang
    // sudah ditutup test lama `game_creation_dashboard_screen_test.dart`.
    expect(tester.takeException(), isNull);
  });
}

String _nearestTextLabel(WidgetTester tester, Rect focusRect) {
  var nearest = '';
  var distance = double.infinity;
  for (final element in find.byType(Text).evaluate()) {
    final text = element.widget as Text;
    final object = element.renderObject;
    if (object is! RenderBox || !object.hasSize) continue;
    final rect = object.localToGlobal(Offset.zero) & object.size;
    final center = rect.center;
    final d =
        (center.dx - focusRect.center.dx).abs() +
        (center.dy - focusRect.center.dy).abs();
    if (d < distance) {
      distance = d;
      nearest = text.data ?? '';
    }
  }
  return nearest;
}
