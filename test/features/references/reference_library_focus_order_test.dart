import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/references/presentation/reference_library_screen.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Layar ini mandiri: data disuntikkan lewat constructor, tanpa database,
/// tanpa network, tanpa Riverpod provider.
List<ReferenceModel> _references() => const [
  ReferenceModel(
    id: 'r1',
    projectId: 'p1',
    type: ReferenceType.face,
    source: ReferenceSource.imported,
    name: 'Reika Front',
    filePath: 'D:/missing-one.png',
    priority: 10,
    primary: true,
    enabled: true,
  ),
  ReferenceModel(
    id: 'r2',
    projectId: 'p1',
    type: ReferenceType.wardrobe,
    source: ReferenceSource.imported,
    name: 'Reika Uniform',
    filePath: 'D:/missing-two.png',
    priority: 5,
    primary: false,
    enabled: true,
  ),
  ReferenceModel(
    id: 'r3',
    projectId: 'p1',
    type: ReferenceType.weapon,
    source: ReferenceSource.imported,
    name: 'Kokuen Katana',
    filePath: 'D:/missing-three.png',
    priority: 7,
    primary: false,
    enabled: true,
  ),
];

/// Kiri-atas AppBar, lalu baris filter, lalu grid kartu dibaca baris per baris.
const List<String> _expectedLabels = [
  'tooltip:Import reference',
  'field:Search References...',
  'All types',
  'Set Primary',
  'Set Primary',
  'Repair',
  'Repair',
  'Repair',
];

const int _filterStopCount = 3;
const int _expectedStops = 8;

/// `IconButton` di AppBar dan `TextField` tidak punya `Text` di subtree fokusnya,
/// jadi label diambil dari `Tooltip` lalu `InputDecoration` sebelum `Text`.
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

Widget _screen() => MaterialApp(
  home: ReferenceLibraryScreen(
    references: _references(),
    onImport: (_) async {},
    onSetPrimary: (_) async {},
    onRepair: (_) async {},
  ),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

void main() {
  group('Reference Library Screen — kontrak focus order 2.4.3', () {
    testWidgets(
      'AppBar lalu baris filter lalu grid kartu dibaca baris per baris',
      (tester) async {
        _viewport(tester);
        await tester.pumpWidget(_screen());
        await tester.pumpAndSettle();

        final stops = await _stops(tester);

        expect(stops, hasLength(_expectedStops));
        expect(_labels(stops), _expectedLabels);

        final appBar = stops.first;
        final filterRow = stops.sublist(1, _filterStopCount);
        final cardRow = stops.sublist(_filterStopCount);

        expect(
          appBar.rect.top,
          lessThan(filterRow.first.rect.top),
          reason: 'Aksi AppBar harus dibaca sebelum baris filter.',
        );
        expect(
          filterRow.first.rect.top,
          lessThan(cardRow.first.rect.top),
          reason: 'Baris filter harus dibaca sebelum grid kartu.',
        );
        expect(
          filterRow[0].rect.left,
          lessThan(filterRow[1].rect.left),
          reason: 'Search lalu dropdown tipe dibaca kiri ke kanan.',
        );
        expect(
          filterRow[0].rect.top,
          lessThan(filterRow[1].rect.bottom),
          reason: 'Search dan dropdown tipe berada pada satu baris filter.',
        );

        expect(
          cardRow[0].rect.top,
          cardRow[1].rect.top,
          reason: 'Dua aksi Set Primary berbagi satu baris fokus.',
        );
        expect(
          cardRow[0].rect.left,
          lessThan(cardRow[1].rect.left),
          reason: 'Baris Set Primary dibaca kiri ke kanan.',
        );
        expect(
          cardRow[2].rect.left,
          lessThan(cardRow[3].rect.left),
          reason: 'Baris Repair dibaca kiri ke kanan.',
        );
        expect(
          cardRow[2].rect.top,
          greaterThan(cardRow[0].rect.top),
          reason: 'Baris Repair berada di bawah baris Set Primary.',
        );
        expect(
          stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
          isTrue,
          reason: 'Setiap stop fokus harus punya area non-zero.',
        );
      },
    );

    testWidgets(
      'filter nonempty menyembunyikan kartu tanpa menambah stop fokus',
      (tester) async {
        _viewport(tester);
        await tester.pumpWidget(_screen());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Kokuen');
        await tester.pumpAndSettle();

        final stops = await _stops(tester);

        expect(
          _labels(stops),
          [
            'All types',
            'Set Primary',
            'Repair',
            'tooltip:Import reference',
            'field:Search References...',
          ],
          reason:
              'Hanya kartu Kokuen Katana yang tersisa, jadi baris kedua dan '
              'ketiga hilang dari traversal.',
        );
        expect(
          stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
          isTrue,
        );
      },
    );

    testWidgets('hasil kosong tetap menyisakan kontrol chrome', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(
        _labels(stops),
        ['All types', 'tooltip:Import reference', 'field:Search References...'],
        reason:
            'Kartu hilang saat hasil kosong, tapi aksi AppBar, search, dan '
            'dropdown tipe harus tetap terjangkau keyboard.',
      );
      expect(find.text('No references found'), findsOneWidget);
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
    });
  });
}
