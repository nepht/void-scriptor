import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/production_assets/application/production_asset_detail.dart';
import 'package:void_scriptor/features/production_assets/presentation/production_asset_workspace_screen.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk ProductionAssetWorkspaceScreen.
///
/// Layar ini menyajikan tiga region: navigator kiri, preview tengah,
/// inspector kanan. Setiap section inspector yang punya data ter-resolve
/// dirender sebagai ExpansionTile, sehingga menjadi stop focus. Section yang
/// belum ter-resolve dirender sebagai ListTile non-interaktif dan TIDAK boleh
/// muncul di rantai fokus.
const _expectedLabels = <String>['Identity', 'Physical', 'Abilities', 'Modes'];

const _detail = ProductionAssetDetail(
  title: 'BYTE',
  subtitle: 'companion',
  sections: {
    'Identity': DetailSection('Identity', [
      DetailRow('Description', 'A small cube shaped companion.'),
      DetailRow('Behavior', 'Watches silently.'),
    ]),
    'Physical': DetailSection('Physical', [
      DetailRow('Height', '40 cm'),
      DetailRow('Weight', '2 kg'),
    ]),
    'Abilities': DetailSection('Abilities', [
      DetailRow('Watch Mode', 'Passive sensing.'),
    ]),
    'Modes': DetailSection('Modes', [DetailRow('Capsule', 'default')]),
  },
);

String _labelOf(BuildContext context) {
  var label = '';
  void visit(Element element) {
    if (label.isNotEmpty) return;
    final widget = element.widget;
    if (widget is Icon) return;
    if (widget is Text && widget.data?.trim().isNotEmpty == true) {
      label = widget.data!.trim();
      return;
    }
    element.visitChildren(visit);
  }

  visit(context as Element);
  return label.isEmpty ? 'widget:${context.widget.runtimeType}' : label;
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  for (var i = 0; i < _expectedLabels.length + 1; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    expect(context, isNotNull, reason: 'Setiap Tab harus punya fokus.');
    final object = context!.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

Widget _screen() => const MaterialApp(
  home: Scaffold(
    body: ProductionAssetWorkspaceScreen(
      kind: ProductionAssetKind.creature,
      detail: _detail,
    ),
  ),
);

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('mengunci urutan focus order 2.4.3', (tester) async {
    _viewport(tester);
    await tester.pumpWidget(_screen());
    await tester.pumpAndSettle();

    final stops = await _stops(tester);

    // 1. Rantai fokus mengikuti urutan section inspector, lalu wrap ke awal.
    expect(stops.map((stop) => stop.label).toList(), [
      ..._expectedLabels,
      _expectedLabels.first,
    ]);

    // 2. Semua stop punya area fokus non-zero.
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
      reason: 'Setiap stop fokus harus memiliki area non-zero.',
    );

    // 3. Inspector berada di kolom kanan dan urutan focus menurun ke bawah.
    const inspectorLeft = 1250.0;
    expect(
      stops.every((stop) => stop.rect.left >= inspectorLeft),
      isTrue,
      reason: 'Semua stop fokus harus berada di kolom inspector kanan.',
    );
    expect(
      stops[0].rect.top,
      lessThan(stops[1].rect.top),
      reason: 'Identity harus berada di atas Physical.',
    );
    expect(
      stops[1].rect.top,
      lessThan(stops[2].rect.top),
      reason: 'Physical harus berada di atas Abilities.',
    );
    expect(
      stops[2].rect.top,
      lessThan(stops[3].rect.top),
      reason: 'Abilities harus berada di atas Modes.',
    );

    // 4. Section tanpa data (Species, Canon) tidak boleh masuk rantai fokus.
    expect(find.text('Species'), findsOneWidget);
    expect(
      stops.map((stop) => stop.label),
      isNot(contains('Species')),
      reason: 'ListTile non-interaktif tidak boleh bisa difokuskan.',
    );
    expect(tester.takeException(), isNull);
  });
}
