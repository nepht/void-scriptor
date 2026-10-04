import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/app/shell/desktop/collaboration_comments_screen.dart';
import 'package:void_scriptor/features/collaboration/domain/collaborator.dart';

/// Kontrak fokus WCAG 2.4.3 — Collaboration Comments Screen.
///
/// Harness: layar dipush ke Navigator (cara rute aplikasi membuka layar) sehingga
/// affordance back pada AppBar ikut teraudit. Viewport desktop 1536x1024, dpr 1.0.
///
/// Deviasi cakupan (dicatat di laporan fase 82): kolam kandidat di
/// `lib/features/*/presentation/*_screen.dart` terbukti habis pada fase 80/81,
/// sehingga pemilihan jatuh ke layar `lib/**/*_screen.dart` yang memenuhi ambang
/// "minimal 2 elemen interaktif" tanpa fixture database/jaringan. Layar ini
/// murni lokal: satu `TextField` + satu `IconButton` kirim, tanpa penyimpanan.
const double _viewportWidth = 1536;
const double _viewportHeight = 1024;

/// Label fokus: pesan Tooltip > hint/label TextField > tooltip/icon-button >
/// teks pertama non-icon.
String focusOrderLabel(BuildContext ctx) {
  final root = ctx as Element;
  final tooltip = root.findAncestorWidgetOfExactType<Tooltip>();
  final msg = tooltip?.message?.trim();
  if (msg != null && msg.isNotEmpty) return msg;
  final field = root.findAncestorWidgetOfExactType<TextField>();
  final hint =
      field?.decoration?.hintText ?? field?.decoration?.labelText ?? '';
  if (hint.trim().isNotEmpty) return hint.trim();
  final button = root.findAncestorWidgetOfExactType<IconButton>();
  if (button != null) {
    final tip = button.tooltip?.trim();
    if (tip != null && tip.isNotEmpty) return tip;
    return '<icon-button>';
  }
  final queue = <BuildContext>[root];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final widget = current.widget;
    if (widget is Icon) continue;
    if (widget is Text) {
      final data = widget.data;
      if (data != null && data.trim().isNotEmpty) return data.trim();
    }
    current.visitChildElements(queue.add);
  }
  return '<non-text:${ctx.widget.runtimeType}>';
}

/// Tekan Tab berulang, catat label + Rect tiap stop, berhenti saat Rect berulang.
Future<List<({String label, Rect rect})>> collectFocusStops(
  WidgetTester tester,
) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 20; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final node = FocusManager.instance.primaryFocus;
    if (node == null) break;
    if (node.context?.widget is FocusScope) break;
    final ctx = node.context!;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) break;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final label = focusOrderLabel(ctx);
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}|$label';
    if (!seen.add(key)) break;
    stops.add((label: label, rect: rect));
  }
  return stops;
}

void _useDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(_viewportWidth, _viewportHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pushScreen(WidgetTester tester, Widget screen) async {
  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navKey,
      home: const SizedBox.expand(child: Text('seed')),
    ),
  );
  await tester.pumpAndSettle();
  navKey.currentState!.push(MaterialPageRoute<void>(builder: (_) => screen));
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 200));
}

/// Satu komentar agar baris thread ikut terpompa (ListTile tanpa onTap).
ProjectComment _comment() => ProjectComment(
  id: 'c1',
  projectId: 'p1',
  authorId: 'choi',
  targetType: 'project',
  targetId: 'p1',
  body: 'Draf bab 1 sudah rilis.',
  createdAt: DateTime.utc(2026, 10, 5, 9, 30),
);

void main() {
  testWidgets('focus order 2.4.3: Back -> Add a comment… -> kirim (3 stop) '
      'pada rute yang dipush', (tester) async {
    _useDesktopViewport(tester);
    await _pushScreen(tester, const CollaborationCommentsScreen());

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(3));
    expect(stops.map((s) => s.label).toList(), <String>[
      'Back',
      'Add a comment…',
      '<icon-button>',
    ]);

    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0), reason: stop.label);
      expect(stop.rect.height, greaterThan(0), reason: stop.label);
      expect(stop.rect.width, lessThanOrEqualTo(_viewportWidth));
      expect(stop.rect.height, lessThanOrEqualTo(_viewportHeight));
    }

    // Back ada di AppBar, kiri-atas.
    expect(stops[0].rect.left, lessThanOrEqualTo(16));
    expect(stops[0].rect.top, lessThanOrEqualTo(16));

    // Baris kompon ada di bawah area daftar.
    expect(stops[1].rect.top, greaterThan(stops[0].rect.top));

    // Kolom input di kiri, tombol kirim di kanannya (kiri-ke-kanan).
    expect(stops[1].rect.left, lessThan(stops[2].rect.left));
    expect(stops[1].rect.right, lessThanOrEqualTo(stops[2].rect.left));
    expect(stops[1].rect.left, greaterThan(0));

    // Input melebar sampai menyentuh kolom tombol kirim.
    expect(stops[1].rect.right, greaterThanOrEqualTo(_viewportWidth - 64));

    // Tombol kirim menempel di margin kanan bawah.
    expect(stops[2].rect.right, greaterThanOrEqualTo(_viewportWidth - 16));
    expect(
      stops[2].rect.top,
      closeTo(stops[1].rect.top - 8, 16),
      reason: 'input dan tombol kirim berada pada baris yang sama',
    );

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order 2.4.3: tanpa rute induk urutan isi tetap '
      'kiri-ke-kanan (2 stop)', (tester) async {
    _useDesktopViewport(tester);
    await tester.pumpWidget(
      const MaterialApp(home: CollaborationCommentsScreen()),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(2));
    expect(stops.map((s) => s.label).toList(), <String>[
      'Add a comment…',
      '<icon-button>',
    ]);
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));
    expect(stops[0].rect.top, greaterThan(0));
    expect(stops[0].rect.height, greaterThan(0));
    expect(stops[1].rect.width, greaterThan(0));

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order 2.4.3: baris komentar existing tidak menambah '
      'stop (ListTile tanpa onTap) — tetap 3 stop', (tester) async {
    _useDesktopViewport(tester);
    await _pushScreen(
      tester,
      CollaborationCommentsScreen(
        initialComments: <ProjectComment>[_comment()],
      ),
    );

    expect(find.text('Draf bab 1 sudah rilis.'), findsOneWidget);

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(3));
    expect(stops.map((s) => s.label).toList(), <String>[
      'Back',
      'Add a comment…',
      '<icon-button>',
    ]);

    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
