import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/presentation/reference_comparison_screen.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Layar ini mandiri: kedua path gambar disuntikkan lewat constructor dan
/// sengaja menunjuk file yang tidak ada, sehingga tiap pane memakai
/// `errorBuilder` dan tidak menyentuh database maupun network.
const String _sideBySideLabels = 'Side by Side';

/// `SegmentedButton` expose `Text` di subtree fokusnya, tapi `Slider` tidak,
/// jadi label diambil dari `Slider.label` sebelum `Text`.
String _labelOf(BuildContext focusContext) {
  final tooltip = focusContext.findAncestorWidgetOfExactType<Tooltip>();
  if (tooltip != null && tooltip.message?.trim().isNotEmpty == true) {
    return 'tooltip:${tooltip.message!.trim()}';
  }
  final slider = focusContext.findAncestorWidgetOfExactType<Slider>();
  if (slider != null) return 'slider:${slider.label ?? 'no-label'}';
  var text = '';
  void visit(Element element) {
    if (text.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      text = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(focusContext as Element);
  return text.isEmpty ? 'widget:${focusContext.widget.runtimeType}' : text;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < _maxStops; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    if (!seen.add('${rect.top}|${rect.left}|${rect.width}')) break;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

Widget _screen() => const MaterialApp(
  home: ReferenceComparisonScreen(
    referencePath: 'D:/missing-one.png',
    generatedPath: 'D:/missing-two.png',
  ),
);

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Beralih ke mode Overlay lewat keyboard, bukan lewat tap koordinat.
Future<void> _switchToOverlay(WidgetTester tester) async {
  await tester.tap(find.text(_sideBySideLabels));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Overlay'));
  await tester.pumpAndSettle();
}

void main() {
  group('Reference Comparison Screen — kontrak focus order 2.4.3', () {
    testWidgets('mode Side by Side hanya menyisakan tiga segment', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(
        _labels(stops),
        ['Side by Side', 'Overlay', 'Swipe'],
        reason:
            'Mode Side by Side tidak punya slider opacity, jadi traversal '
            'hanya memindai tiga segment mode.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
      expect(
        find.byType(Slider),
        findsNothing,
        reason: 'Slider hanya boleh muncul di mode Overlay.',
      );
    });

    testWidgets('tiga segment dibaca kiri ke kanan pada satu baris', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops, hasLength(3));
      expect(
        stops[0].rect.left,
        lessThan(stops[1].rect.left),
        reason: 'Side by Side dibaca sebelum Overlay.',
      );
      expect(
        stops[1].rect.left,
        lessThan(stops[2].rect.left),
        reason: 'Overlay dibaca sebelum Swipe.',
      );
      expect(
        stops[0].rect.top,
        stops[1].rect.top,
        reason: 'Ketiga segment berbagi satu baris fokus.',
      );
      expect(
        stops[0].rect.height,
        stops[1].rect.height,
        reason: 'Ketiga segment berbagi satu baris fokus dengan tinggi sama.',
      );
      expect(
        stops[0].rect.top,
        lessThan(stops[0].rect.bottom),
        reason: 'Tinggi fokus segment harus non-zero dan positif.',
      );
      expect(
        stops[2].rect.right,
        lessThanOrEqualTo(1536),
        reason: 'Segment terakhir tidak boleh meluber melewati viewport.',
      );
    });

    testWidgets('mode Overlay menambahkan slider sebagai stop keempat', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await _switchToOverlay(tester);

      final stops = await _stops(tester);

      expect(stops, hasLength(4));
      expect(
        _labels(stops),
        ['Side by Side', 'Overlay', 'Swipe', 'slider:50% generated'],
        reason:
            'Slider opacity muncul setelah tiga segment mode, mengikuti '
            'urutan baca Panel kontrol dari kiri ke kanan.',
      );
      expect(
        stops[3].rect.left,
        greaterThan(stops[2].rect.left),
        reason:
            'Di layout lebar slider tetap sebaris dengan segment, di sebelah '
            'kanan Swipe, karena memakai Wrap pada panel kontrol.',
      );
      expect(
        stops[3].rect.top,
        stops[2].rect.top,
        reason: 'Di layout lebar slider dan segment mode berbagi satu baris.',
      );
      expect(
        stops[3].rect.width,
        greaterThan(stops[2].rect.width),
        reason:
            'Slider memakai lebar panel yang lebih besar dari satu segment.',
      );
      expect(
        stops[3].rect.right,
        lessThanOrEqualTo(1536),
        reason: 'Slider tidak boleh meluber melewati viewport.',
      );
      expect(
        find.text('50% generated'),
        findsNothing,
        reason: 'Label slider hanya muncul saat di-drag, bukan saat idle.',
      );
    });

    testWidgets('viewport sempit tetap membaca seluruh kontrol', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 844));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await _switchToOverlay(tester);

      final stops = await _stops(tester);

      expect(tester.takeException(), isNull);
      expect(
        _labels(stops),
        ['Side by Side', 'Overlay', 'Swipe', 'slider:50% generated'],
        reason:
            'Di 390 px ketiga segment tetap satu baris dan slider turun ke '
            'baris penuh di bawahnya, tanpa kontrol yang hilang.',
      );
      expect(
        stops[3].rect.width,
        lessThanOrEqualTo(390),
        reason: 'Kontrol tidak boleh meluber melewati viewport sempit.',
      );
      expect(stops[0].rect.top, lessThan(stops[3].rect.top));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
    });

    testWidgets('navigasi keyboard berpindah mode tanpa kehilangan fokus', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(_sideBySideLabels));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // `Slider` tidak muncul: panah kanan pada `SegmentedButton` memindahkan
      // sorot visual, bukan memilih segment. Ini dokumentasi perilaku nyata,
      // bukan defect focus order.
      expect(
        find.byType(Slider),
        findsNothing,
        reason: 'ArrowRight memindahkan sorot visual, bukan mengubah mode.',
      );
      expect(find.text('Overlay'), findsOneWidget);

      final stops = await _stops(tester);

      expect(
        _labels(stops),
        ['Overlay', 'Swipe', 'Side by Side'],
        reason:
            'Traversal dilanjutkan dari node fokus yang sedang aktif, jadi '
            'urutan relatif bergeser satu posisi dari traversal awal.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
    });
  });
}
