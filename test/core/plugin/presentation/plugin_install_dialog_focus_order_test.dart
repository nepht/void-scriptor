import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/plugin/presentation/plugin_install_dialog.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Rantai fokus yang harus dipertahankan [PluginInstallDialog].
///
/// Isi dialog dibaca satu kolom: field JSON di atas, lalu baris aksi dibaca
/// kiri ke kanan (`Batal` sebelum `Instal`). Label field diambil dari
/// `InputDecoration.hintText` karena `TextField` merender hint di dalam
/// [InputDecorator] yang berada di luar subtree focus node.
const List<String> _expectedLabels = <String>[
  'Tempel JSON manifest plugin…',
  'Batal',
  'Instal',
];

const int _expectedStops = 3;

/// Jumlah kontrol sebelum baris aksi.
const int _fieldStops = 1;

/// Resolve a human label for the focused subtree.
///
/// Preference order:
/// 1. first non-icon [Text] descendant (buttons);
/// 2. the [InputDecoration] label/hint of the nearest enclosing [TextField];
/// 3. the runtime type, so a missing label is visibly unlabelled rather than
///    silently attributed to a neighbouring widget.
String _labelOf(BuildContext context) {
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

  visit(context as Element);
  if (text.isNotEmpty) return text;

  var fieldLabel = '';
  context.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is TextField) {
      final label = widget.decoration?.labelText ?? widget.decoration?.hintText;
      if (label != null && label.trim().isNotEmpty) {
        fieldLabel = label.trim();
        return false;
      }
    }
    return true;
  });
  if (fieldLabel.isNotEmpty) return fieldLabel;
  return 'widget:${context.widget.runtimeType}';
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
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    if (!seen.add(key)) break;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

Widget _app() => MaterialApp(
  home: Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => const PluginInstallDialog(),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

Future<void> _openDialog(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

/// Memutar daftar label agar dimulai dari [first].
///
/// Tab traversal bersifat siklis, jadi kontrak mengunci *rantai* urutan, bukan
/// node mana yang kebetulan sedang memegang fokus saat pengambilan dimulai.
List<String> _rotatedTo(List<({String label, Rect rect})> stops, String first) {
  final labels = _labels(stops);
  final anchor = labels.indexOf(first);
  if (anchor <= 0) return labels;
  return <String>[...labels.sublist(anchor), ...labels.sublist(0, anchor)];
}

void main() {
  group('Plugin Install Dialog — kontrak focus order 2.4.3', () {
    testWidgets('field dibaca di atas, lalu aksi kiri ke kanan', (
      tester,
    ) async {
      await _openDialog(tester);

      final stops = await _stops(tester);

      expect(stops, hasLength(_expectedStops));
      expect(_labels(stops), _expectedLabels);

      // Field JSON berada di atas baris aksi.
      final field = stops.first;
      final cancel = stops[_fieldStops];
      final install = stops[_fieldStops + 1];
      expect(
        field.rect.top,
        lessThan(cancel.rect.top),
        reason: 'Field JSON harus dibaca sebelum baris aksi.',
      );

      // Dua aksi berada pada baris yang sama, Batal dibaca sebelum Instal.
      expect(
        cancel.rect.left,
        lessThan(install.rect.left),
        reason: 'Batal harus dibaca sebelum Instal pada baris aksi.',
      );
      expect(
        cancel.rect.top,
        closeTo(install.rect.top, 0.5),
        reason: 'Batal dan Instal berbagi baris aksi.',
      );

      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Shift+Tab membalik rantai fokus', (tester) async {
      await _openDialog(tester);

      // Maju dua stop sehingga fokus berada pada `Instal`.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        _labelOf(FocusManager.instance.primaryFocus!.context!),
        'Instal',
        reason: 'Tiga Tab harus mendarat pada Instal.',
      );

      // Mundur: Instal → Batal → field JSON.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        _labelOf(FocusManager.instance.primaryFocus!.context!),
        'Batal',
        reason: 'Shift+Tab dari Instal harus mendarat pada Batal.',
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        _labelOf(FocusManager.instance.primaryFocus!.context!),
        'Tempel JSON manifest plugin…',
        reason: 'Shift+Tab dari Batal harus mendarat pada field JSON.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('manifest tidak valid menahan dialog tanpa menggeser rantai', (
      tester,
    ) async {
      await _openDialog(tester);

      final stops = await _stops(tester);
      expect(stops, hasLength(_expectedStops));

      await tester.enterText(find.byType(TextField), '{ not json');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instal'));
      await tester.pumpAndSettle();

      expect(
        find.byType(PluginInstallDialog),
        findsOneWidget,
        reason: 'Validasi gagal harus menahan dialog tetap terbuka.',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.style?.color == Colors.red,
        ),
        findsOneWidget,
        reason: 'Pesan error harus tampil saat manifest tidak valid.',
      );
      expect(tester.takeException(), isNull);

      // Rantai fokus tidak bergeser karena pesan error baru.
      expect(
        _rotatedTo(await _stops(tester), _expectedLabels.first),
        _expectedLabels,
      );
    });
  });
}
