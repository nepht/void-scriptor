import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/features/game/presentation/level_editor_screen.dart';

/// Kontrak fokus WCAG 2.4.3 — Level Editor.
///
/// Harness: layar dipush ke Navigator (cara rute aplikasi membuka layar) sehingga
/// affordance back pada AppBar ikut teraudit. Viewport desktop 1536x1024, dpr 1.0.
const double _viewportWidth = 1536;
const double _viewportHeight = 1024;

/// Label fokus: pesan Tooltip > hint/label TextField > teks pertama non-icon.
String focusOrderLabel(BuildContext ctx) {
  final root = ctx as Element;
  final tooltip = root.findAncestorWidgetOfExactType<Tooltip>();
  final msg = tooltip?.message?.trim();
  if (msg != null && msg.isNotEmpty) return msg;
  final field = root.findAncestorWidgetOfExactType<TextField>();
  final hint =
      field?.decoration?.hintText ?? field?.decoration?.labelText ?? '';
  if (hint.trim().isNotEmpty) return hint.trim();
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

/// Tangkap pesan layout selama [body] berjalan tanpa membuat test gagal.
///
/// Panel Assets (180px, padding 16) menyisakan 118px untuk teks; font uji
/// Flutter memakai glyph selebar fontSize sehingga 'Character' dan
/// 'Environment' overflow pada lebar itu (2 pesan RenderFlex). Font produksi
/// (Space Grotesk/Roboto) lebih sempit, jadi ini artefak harness — dikunci di
/// sini supaya kegagalan fokus berikutnya tetap terlihat.
Future<List<String>> _captureLayoutMessages(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final captured = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    captured.add(details.exceptionAsString());
  };
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return captured;
}

void _useDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(_viewportWidth, _viewportHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void _noOp() {}

Future<void> _pushScreen(WidgetTester tester) async {
  final navKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: navKey,
        home: const SizedBox.expand(child: Text('seed')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  navKey.currentState!.push(
    MaterialPageRoute<void>(builder: (_) => LevelEditorScreen(onPlay: _noOp)),
  );
  await tester.pumpAndSettle(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('focus order 2.4.3: Back -> Play, 2 stop pada rute yang dipush', (
    tester,
  ) async {
    _useDesktopViewport(tester);
    final layoutMessages = await _captureLayoutMessages(tester, () async {
      await _pushScreen(tester);
    });

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(2));
    expect(stops.map((s) => s.label).toList(), <String>['Back', 'Play']);

    for (final stop in stops) {
      expect(stop.rect.width, greaterThan(0), reason: stop.label);
      expect(stop.rect.height, greaterThan(0), reason: stop.label);
      expect(stop.rect.width, lessThanOrEqualTo(_viewportWidth));
      expect(stop.rect.height, lessThanOrEqualTo(_viewportHeight));
    }

    // Kiri-ke-kanan: kedua stop berada di bar atas (AppBar) — back di kiri,
    // aksi Play di kanan. Tidak ada lompat kolom atau urutan terbalik.
    expect(stops[0].rect.top, lessThanOrEqualTo(16));
    expect(stops[1].rect.top, lessThanOrEqualTo(16));
    expect(stops[0].rect.left, lessThanOrEqualTo(16));
    expect(stops[1].rect.right, greaterThanOrEqualTo(_viewportWidth - 160));
    expect(stops[0].rect.left, lessThan(stops[1].rect.left));

    // Artefak harness yang diketahui: hanya overflow RenderFlex panel Assets.
    expect(layoutMessages, hasLength(2));
    expect(
      layoutMessages.where((m) => !m.contains('RenderFlex overflowed')),
      isEmpty,
      reason: 'pesan layout non-overflow tidak terduga: $layoutMessages',
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('focus order 2.4.3: Play satu-satunya stop tanpa rute induk', (
    tester,
  ) async {
    _useDesktopViewport(tester);
    final layoutMessages = await _captureLayoutMessages(tester, () async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: LevelEditorScreen(onPlay: _noOp)),
        ),
      );
      await tester.pumpAndSettle();
    });

    final stops = await collectFocusStops(tester);

    expect(stops, hasLength(1));
    expect(stops.single.label, 'Play');
    expect(stops.single.rect.width, greaterThan(0));
    expect(stops.single.rect.height, greaterThan(0));
    expect(stops.single.rect.top, lessThanOrEqualTo(16));
    expect(stops.single.rect.right, greaterThanOrEqualTo(_viewportWidth - 160));

    expect(
      layoutMessages.where((m) => !m.contains('RenderFlex overflowed')),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
