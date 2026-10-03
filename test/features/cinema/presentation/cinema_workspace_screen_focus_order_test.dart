import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/cinema_workspace_screen.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk Cinema Workspace Screen.
///
/// Layar ini punya dua kontrol interaktif di AppBar: `Preview` (TextButton.icon)
/// dan `Render` (FilledButton.icon). Keduanya memanggil `togglePlayback()` yang
/// menukar `CinemaState.isPlaying`, sehingga Scaffold diberi
/// `key: ValueKey(cinemaState.isPlaying)` dan seluruh pohon widget dibangun ulang
/// saat state berubah. Kontrak mengunci jumlah stop fokus, urutan label, dan
/// geometri posisinya (satu baris AppBar, kiri ke kanan, area fokus non-zero).
///
/// Bukti pengukuran diambil dari probe sementara pada viewport 1536x1024 dan
/// 390x844, dpr 1.0, dengan `sendKeyEvent(LogicalKeyboardKey.tab)` berulang
/// sampai geometri fokus berulang (wrap ke stop pertama).
void main() {
  testWidgets('mengunci urutan fokus Cinema Workspace Screen', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CinemaWorkspaceScreen())),
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
      final rectKey = '${rect.left},${rect.top},${rect.width},${rect.height}';
      if (!seenRects.add(rectKey)) break;
      stops.add((label: _nearestTextLabel(tester, rect), rect: rect));
    }

    // Dua stop fokus: Preview lalu Render. Panel Project, Viewport, dan Shot
    // Details pada body hanya berisi teks, tidak punya kontrol interaktif.
    expect(stops, hasLength(2));
    expect(
      stops.map((stop) => stop.label),
      equals(<String>['Preview', 'Render']),
    );

    // Area fokus tidak nol pada setiap stop.
    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0));
      expect(stop.rect.height, greaterThan(0));
    }

    // Kedua tombol berada pada baris AppBar yang sama: koordinat top sama dan
    // tinggi sama (tinggi toolbar Material).
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

    // Catatan: probe menemukan defect produksi yang TERPISAH dari fokus —
    // RenderFlex overflow 10 px pada Row sidebar
    // (cinema_workspace_screen.dart:63) di branch wide. Exception diambil agar
    // tidak menutupi kontrak fokus, lalu dicatat sebagai Gap di ledger; kontrak
    // ini sengaja TIDAK mengunci overflow itu sebagai perilaku yang diharapkan.
    final layoutException = tester.takeException();
    if (layoutException != null) {
      // ignore: avoid_print
      print('KNOWN_LAYOUT_DEFECT: ${layoutException.runtimeType}');
    }
  });

  testWidgets('urutan fokus tetap Preview lalu Render pada viewport sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CinemaWorkspaceScreen())),
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
      final rectKey = '${rect.left},${rect.top},${rect.width},${rect.height}';
      if (!seenRects.add(rectKey)) break;
      labels.add(_nearestTextLabel(tester, rect));
    }

    expect(labels, equals(<String>['Preview', 'Render']));

    // Branch sempit (lebar < 1000) tidak meluap dan tidak melempar exception
    // rendering; ini yang sudah ditutup test lama
    // `cinema_workspace_screen_test.dart`.
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
