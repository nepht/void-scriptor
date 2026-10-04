import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/my_library_screen.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Layar ini mandiri: seluruh konten di-hardcode di widget, tanpa database,
/// tanpa network, tanpa Riverpod provider.
const List<String> _expectedLabels = ['Installed', 'Updates'];

const int _expectedStops = 2;

/// Tab di dalam `TabBar` tidak membungkus `Icon`, jadi label diambil dari
/// `Text` pertama di subtree fokus. Kalau `Text` tidak ada, laporkan
/// runtimeType supaya kegagalan tetap bisa dibaca.
String _labelOf(BuildContext focusContext) {
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

Widget _screen() => const MaterialApp(home: MyLibraryScreen());

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

void main() {
  group('My Library Screen — kontrak focus order 2.4.3', () {
    testWidgets('dua tab dibaca kiri ke kanan pada satu baris', (tester) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops, hasLength(_expectedStops));
      expect(_labels(stops), _expectedLabels);

      expect(
        stops[0].rect.left,
        lessThan(stops[1].rect.left),
        reason: 'Installed harus dibaca sebelum Updates.',
      );
      expect(
        stops[0].rect.top,
        stops[1].rect.top,
        reason: 'Kedua tab berbagi satu baris fokus.',
      );
      expect(
        stops[0].rect.top,
        equals(stops[1].rect.top),
        reason: 'Baris TabBar tidak bergeser antar tab.',
      );
      expect(
        stops[0].rect.bottom,
        equals(stops[1].rect.bottom),
        reason: 'Tinggi baris TabBar sama untuk kedua tab.',
      );
      expect(
        stops[0].rect.right,
        equals(stops[1].rect.left),
        reason: 'Kedua tab berdempetan tanpa celah horizontal.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
    });

    testWidgets('tab Updates aktif lewat keyboard menampilkan isinya', (
      tester,
    ) async {
      _viewport(tester, const Size(1536, 1024));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      expect(find.text('v1.2.0'), findsOneWidget);
      expect(find.text('v1.3.0 available'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        _labelOf(FocusManager.instance.primaryFocus!.context!),
        'Updates',
        reason: 'Tab kedua harus fokus sebelum diaktifkan.',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(
        find.text('v1.3.0 available'),
        findsOneWidget,
        reason: 'Tab Updates harus menampilkan konten Updates.',
      );
      expect(
        find.text('v1.2.0'),
        findsNothing,
        reason: 'Konten tab Installed tidak boleh tetap terlihat.',
      );
    });

    testWidgets('lebar sempit tetap menyisakan dua stop tanpa overflow', (
      tester,
    ) async {
      _viewport(tester, const Size(390, 844));
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(_labels(stops), _expectedLabels);
      expect(
        stops[0].rect.left,
        lessThan(stops[1].rect.left),
        reason: 'Urutan kiri ke kanan tetap sama di viewport sempit.',
      );
      expect(stops[0].rect.top, equals(stops[1].rect.top));
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'TabBar 390px tidak boleh memicu RenderFlex overflow.',
      );
    });
  });
}
