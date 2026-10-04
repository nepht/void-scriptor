import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/presentation/project_reference_library_screen.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Layar ini membungkus `ReferenceLibraryScreen` di dalam `ProviderScope` polos:
/// tanpa sesi proyek aktif, `projectReferencesProvider` mengembalikan daftar
/// kosong sehingga tidak ada kartu yang ikut ter-render. Kontrak ini mengunci
/// urutan keyboard untuk kondisi tersebut - bukan untuk grid kartu, yang sudah
/// diaudit di `reference_library_focus_order_test.dart`.
const List<String> _expectedLabels = [
  'field:Search References...',
  'All types',
];

const int _expectedStops = 2;

/// `TextField` tidak punya `Text` di subtree fokusnya, jadi label diambil dari
/// `Tooltip` lalu `InputDecoration` sebelum `Text`.
String _labelOf(BuildContext focusContext) {
  final tooltip = focusContext.findAncestorWidgetOfExactType<Tooltip>();
  if (tooltip != null && tooltip.message?.trim().isNotEmpty == true) {
    return 'tooltip:${tooltip.message!.trim()}';
  }
  final field = focusContext.findAncestorWidgetOfExactType<TextField>();
  final label = field?.decoration?.labelText ?? field?.decoration?.hintText;
  if (label != null && label.trim().isNotEmpty) return 'field:$label';
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

Widget _screen() => const ProviderScope(
  child: MaterialApp(home: ProjectReferenceLibraryScreen()),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

void main() {
  group('Project Reference Library Screen — kontrak focus order 2.4.3', () {
    testWidgets('baris filter dibaca kiri ke kanan', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops, hasLength(_expectedStops));
      expect(_labels(stops), _expectedLabels);

      final search = stops.first;
      final types = stops.last;

      expect(
        search.rect.left,
        lessThan(types.rect.left),
        reason: 'Search dibaca sebelum dropdown tipe.',
      );
      expect(
        search.rect.top,
        lessThan(types.rect.bottom),
        reason: 'Search dan dropdown tipe berada pada satu baris filter.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
    });

    testWidgets('tanpa sesi proyek, Import tidak menambah stop fokus', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(
        _labels(stops).where((label) => label.startsWith('tooltip:')),
        isEmpty,
        reason:
            'Aksi Import butuh sesi proyek; tanpa sesi hanya kontrol filter '
            'yang harus terjangkau keyboard.',
      );
      expect(_labels(stops), _expectedLabels);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('dropdown tipe terbuka lewat keyboard', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus,
        isNotNull,
        reason: 'Stop kedua harus memegang fokus sebelum dropdown dibuka.',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('All types'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
