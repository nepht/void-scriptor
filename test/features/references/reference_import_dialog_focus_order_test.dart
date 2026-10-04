import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/references/presentation/reference_import_dialog.dart';

/// Walking the Tab traversal until the cycle repeats.
const int _maxStops = 24;

/// Rantai fokus yang harus dipertahankan dialog import referensi.
///
/// Isi form dibaca satu kolom dari atas ke bawah (tujuh kontrol), lalu baris
/// aksi dibaca kiri ke kanan. Dua label terakhir adalah nilai yang ditampilkan,
/// bukan label dekorasi: `Reference type` merender nilai terpilih (`face`), dan
/// `Set as primary` adalah `SwitchListTile` yang title-nya ikut terbaca.
const List<String> _expectedLabels = <String>[
  'Source file path',
  'Name',
  'Owner asset ID (optional)',
  'face',
  'Priority',
  'Description',
  'Set as primary',
  'Cancel',
  'Import',
];

const int _expectedStops = 9;

/// Jumlah kontrol form sebelum baris aksi.
const int _formFieldStops = 7;

/// Resolve a human label for the focused subtree.
///
/// Preference order:
/// 1. first non-icon [Text] descendant (buttons, dropdown values, list rows);
/// 2. the [InputDecoration] label of the nearest enclosing field, because a
///    text field renders its label inside an [InputDecorator] that sits outside
///    the focus node subtree;
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
            builder: (_) => const ReferenceImportDialog(),
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
}

List<String> _labels(List<({String label, Rect rect})> stops) =>
    stops.map((stop) => stop.label).toList();

/// Memutar daftar label agar dimulai dari [first].
///
/// Tab traversal bersifat siklis: setelah fokus berada di tengah rantai,
/// stmt berikutnya mulai dari node setelahnya. Kontrak yang benar mengunci
/// *rantai* urutan, bukan node mana yang kebetulan sedang memegang fokus,
/// jadi daftar diselaraskan ke label pertama yang diketahui sebelum dibandingkan.
List<String> _rotatedTo(List<({String label, Rect rect})> stops, String first) {
  final labels = _labels(stops);
  final anchor = labels.indexOf(first);
  if (anchor <= 0) return labels;
  return <String>[...labels.sublist(anchor), ...labels.sublist(0, anchor)];
}

void main() {
  group('Reference Import Dialog — kontrak focus order 2.4.3', () {
    testWidgets('form dibaca atas ke bawah lalu aksi kiri ke kanan', (
      tester,
    ) async {
      await _openDialog(tester);

      final stops = await _stops(tester);

      expect(stops, hasLength(_expectedStops));
      expect(_labels(stops), _expectedLabels);

      // Tujuh kontrol form membentuk satu kolom: semua berbagi tepi kiri dan
      // bergerak hanya ke bawah.
      final form = stops.take(_formFieldStops).toList();
      expect(
        form.map((stop) => stop.rect.left).toSet(),
        hasLength(1),
        reason: 'Isi form harus satu kolom, bukan beberapa kolom.',
      );
      for (var i = 1; i < form.length; i++) {
        expect(
          form[i].rect.top,
          greaterThan(form[i - 1].rect.top),
          reason:
              'Stop ${_labels(form)[i]} harus berada di bawah '
              '${_labels(form)[i - 1]}.',
        );
      }

      // Dua aksi berada pada baris yang sama, Cancel dibaca sebelum Import.
      final cancel = stops[_formFieldStops];
      final import = stops[_formFieldStops + 1];
      expect(
        cancel.rect.left,
        lessThan(import.rect.left),
        reason: 'Cancel harus dibaca sebelum Import pada baris aksi.',
      );
      expect(
        cancel.rect.top,
        closeTo(import.rect.top, 0.5),
        reason: 'Cancel dan Import berbagi baris aksi.',
      );

      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus punya area non-zero.',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('dropdown tipe terbuka dan dapat dipilih lewat keyboard', (
      tester,
    ) async {
      await _openDialog(tester);

      // Berhenti pada dropdown Reference type.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }

      expect(
        tester.binding.focusManager.primaryFocus,
        isNotNull,
        reason: 'Stop keempat harus memegang fokus sebelum dropdown dibuka.',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text(ReferenceType.face.name), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol Import menolak payload kosong tanpa menutup dialog', (
      tester,
    ) async {
      await _openDialog(tester);

      final stops = await _stops(tester);
      expect(stops, hasLength(_expectedStops));

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(
        find.byType(ReferenceImportDialog),
        findsOneWidget,
        reason: 'Validasi gagal harus menahan dialog tetap terbuka.',
      );
      expect(find.text('Source file path is required.'), findsOneWidget);
      expect(find.text('Name is required.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Rantai fokus tidak bergeser karena pesan error baru.
      expect(
        _rotatedTo(await _stops(tester), _expectedLabels.first),
        _expectedLabels,
      );
    });
  });
}
