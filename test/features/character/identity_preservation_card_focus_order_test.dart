import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/presentation/widgets/identity_preservation_card.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk [IdentityPreservationCard].
///
/// Fixture: widget di-pump mandiri (tanpa database Drift, tanpa file system,
/// tanpa network) pada viewport 1536x1024, dpr 1.0. Kartu berisi lima baris
/// kunci identitas yang masing-masing memiliki satu `Switch` — lima-satunya
/// affordance fokusable, tersusun atas-ke-bawah di sisi kanan kartu.
const _expectedLabels = <String>[
  'Face Lock',
  'Hair Geometry Lock',
  'Body Topology Lock',
  'Color Lock',
  'Outfit Geometry Lock',
];

/// Membaca label baris untuk node fokus. `Switch` difokuskan sebagai anak
/// `Row`, sedangkan teks label adalah sibling-nya, sehingga label dibaca dari
/// ancestor `Row` terdekat.
String _labelOf(BuildContext context) {
  final element = context as Element;
  var label = '';
  element.visitAncestorElements((candidate) {
    if (candidate.widget is! Row) return true;
    final texts = <String>[];
    void collect(Element node) {
      final widget = node.widget;
      if (widget is Text && widget.data?.trim().isNotEmpty == true) {
        texts.add(widget.data!.trim());
      }
      node.visitChildren(collect);
    }

    candidate.visitChildren(collect);
    if (texts.isNotEmpty) {
      label = texts.first;
      return false;
    }
    return true;
  });
  return label.isEmpty ? 'widget:${element.widget.runtimeType}' : label;
}

/// Menekan Tab berulang, mencatat label + Rect tiap stop, dan berhenti begitu
/// rect mengulang (traversal wrap) atau fokus hilang.
Future<List<({String label, Rect rect})>> _walk(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <Rect>{};
  for (var i = 0; i < _expectedLabels.length + 1; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(milliseconds: 50));
    final context = FocusManager.instance.primaryFocus?.context;
    expect(context, isNotNull, reason: 'Setiap Tab harus memindahkan fokus.');
    final object = context!.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    final label = _labelOf(context);
    final repeated = seen.contains(rect);
    stops.add((label: label, rect: rect));
    if (repeated) break;
    seen.add(rect);
  }
  return stops;
}

Widget _card() => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 1536,
      height: 1024,
      child: IdentityPreservationCard(
        faceLock: true,
        hairLock: false,
        bodyLock: true,
        colorLock: false,
        outfitLock: true,
        onFaceChanged: (_) {},
        onHairChanged: (_) {},
        onBodyChanged: (_) {},
        onColorChanged: (_) {},
        onOutfitChanged: (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('mengunci urutan focus order 2.4.3', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_card());
    await tester.pumpAndSettle();

    final stops = await _walk(tester);

    // 1. Jumlah stop = 5 unik, lalu wrap ke stop pertama (bukan cap iterasi).
    expect(stops.map((stop) => stop.label).toList(), [
      ..._expectedLabels,
      _expectedLabels.first,
    ], reason: 'Rantai Tab harus mengunjungi lima baris lalu kembali ke awal.');

    // 2. Area fokus non-zero dan di dalam viewport yang diaudit.
    for (final stop in stops) {
      expect(stop.rect, isNot(Rect.zero), reason: stop.label);
      expect(stop.rect.width, greaterThan(0), reason: stop.label);
      expect(stop.rect.height, greaterThan(0), reason: stop.label);
      expect(stop.rect.left, greaterThanOrEqualTo(0), reason: stop.label);
      expect(stop.rect.top, greaterThanOrEqualTo(0), reason: stop.label);
      expect(stop.rect.right, lessThanOrEqualTo(1536), reason: stop.label);
      expect(stop.rect.bottom, lessThanOrEqualTo(1024), reason: stop.label);
    }

    // 3. Properti posisi: lima baris tersusun atas-ke-bawah, sehingga urutan
    //    fokus harus monoton naik pada sumbu Y dan tetap pada kolom kanan.
    for (var i = 1; i < _expectedLabels.length; i++) {
      expect(
        stops[i].rect.top,
        greaterThan(stops[i - 1].rect.top),
        reason: 'Baris ${_expectedLabels[i]} harus di bawah baris sebelumnya.',
      );
      expect(
        stops[i].rect.left,
        greaterThan(1000),
        reason: 'Switch menempel di sisi kanan kartu.',
      );
    }

    // 4. Setiap stop jatuh tepat di dalam `Switch` miliknya (indeks sama).
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(_expectedLabels.length));
    for (var i = 0; i < _expectedLabels.length; i++) {
      final switchRect = tester.getRect(switches.at(i));
      final stop = stops[i];
      expect(
        switchRect.left - 0.01 <= stop.rect.left &&
            switchRect.right + 0.01 >= stop.rect.right &&
            switchRect.top - 0.01 <= stop.rect.top &&
            switchRect.bottom + 0.01 >= stop.rect.bottom,
        isTrue,
        reason: 'Stop ${stop.label} harus berada di dalam Switch barisnya.',
      );
    }

    // 5. Wrap: tab terakhir kembali ke rect stop pertama.
    expect(stops.last.rect, stops.first.rect);
    expect(stops.last.label, _expectedLabels.first);

    expect(tester.takeException(), isNull);
  });
}
