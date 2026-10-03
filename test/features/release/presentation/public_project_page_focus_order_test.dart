import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/presentation/public_project_page_screen.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Baris aksi (Follow/Watch/Play) dan strip tab harus berada pada dua baris
/// fokus yang berbeda, masing-masing dibaca kiri ke kanan.
const String _firstAction = 'Follow';
const String _firstTab = 'About';
const int _actionCount = 3;
const int _tabCount = 6;
const int _expectedStops = _actionCount + _tabCount;

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
    var label = '?';
    void visit(Element element) {
      if (label != '?') return;
      final widget = element.widget;
      if (widget is Icon) return;
      if (widget is Text && widget.data?.trim().isNotEmpty == true) {
        label = widget.data!.trim();
        return;
      }
      element.visitChildren(visit);
    }

    visit(context as Element);
    stops.add((label: label, rect: rect));
  }
  return stops;
}

Widget _screen() =>
    const ProviderScope(child: MaterialApp(home: PublicProjectPageScreen()));

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

void main() {
  group('Public Project Page Screen — kontrak focus order 2.4.3', () {
    testWidgets('baris aksi dibaca kiri ke kanan sebelum strip tab', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(_labels(stops), [
        'Follow',
        'Watch',
        'Play',
        'About',
        'Characters',
        'Gallery',
        'Episodes',
        'Game Updates',
        'Credits',
      ]);

      final actionRow = stops.take(_actionCount).toList(growable: false);
      final tabStrip = stops.skip(_actionCount).toList(growable: false);

      expect(
        actionRow.every((stop) => stop.rect.top == actionRow.first.rect.top),
        isTrue,
        reason: 'Tiga aksi utama harus berbagi satu baris fokus.',
      );
      expect(
        tabStrip.every((stop) => stop.rect.top == tabStrip.first.rect.top),
        isTrue,
        reason: 'Enam tab harus berbagi satu baris fokus.',
      );
      for (var i = 1; i < _actionCount; i++) {
        expect(
          actionRow[i - 1].rect.left,
          lessThan(actionRow[i].rect.left),
          reason: 'Urutan aksi harus kiri ke kanan pada baris yang sama.',
        );
      }
      for (var i = 1; i < _tabCount; i++) {
        expect(
          tabStrip[i - 1].rect.left,
          lessThan(tabStrip[i].rect.left),
          reason: 'Urutan tab harus kiri ke kanan pada baris yang sama.',
        );
      }
      expect(
        tabStrip.first.rect.top,
        greaterThan(actionRow.first.rect.top),
        reason: 'Strip tab harus berada di bawah baris aksi.',
      );
      expect(
        tabStrip.first.rect.left,
        greaterThanOrEqualTo(actionRow.first.rect.left),
        reason: 'Strip tab tidak boleh dimulai sebelum baris aksi.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
    });

    testWidgets('ganti tab tidak menambah stop fokus', (tester) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(stops, hasLength(_expectedStops));
      expect(
        _labels(stops).sublist(0, _actionCount),
        ['Follow', 'Watch', 'Play'],
        reason: 'Baris aksi tetap menjadi urutan fokus pertama.',
      );
      expect(
        _labels(stops).skip(_actionCount),
        [
          'About',
          'Characters',
          'Gallery',
          'Episodes',
          'Game Updates',
          'Credits',
        ],
        reason: 'Strip tab tetap lengkap dan tidak berubah urutan.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
      );
    });

    testWidgets('tab terakhir membungkus kembali ke aksi pertama', (
      tester,
    ) async {
      _viewport(tester);
      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(_labels(stops).first, _firstAction);
      expect(_labels(stops)[_actionCount], _firstTab);
      expect(
        stops.last.rect.left,
        greaterThan(stops[_actionCount].rect.left),
        reason: 'Tab terakhir berada di ujung kanan strip tab.',
      );
    });
  });
}
