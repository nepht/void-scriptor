import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/presentation/supporting_asset_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk SupportingAssetWorkspaceScreen.
///
/// Fixture: `projectSessionProvider` mengembalikan `null` (tanpa database,
/// tanpa file system, tanpa network) dan `supportingAssetProvider`
/// di-override dengan satu baris [Asset] in-memory bertipe `armor`, sehingga
/// detail view lengkap ter-render: aksi favorit, aksi edit, tiga field
/// spesifikasi armor, dan tombol simpan.
///
/// Urutan Tab membuktikan rantai fokus dibaca: baris kepala (kanan) lebih
/// dulu, lalu kolom detail dari atas ke bawah, lalu kembali ke kepala.
const _expectedLabels = <String>[
  'Add to favorites',
  'Edit details',
  'Protection',
  'Material',
  'Condition',
  'Save Armor',
];

class _EmptySessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

Asset _asset() => Asset(
  id: 'probe-armor',
  projectId: 'probe-project',
  name: 'Probe Armor',
  description: 'Probe fixture row built in memory.',
  type: 'armor',
  version: 'v1',
  favorite: false,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
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
  if (label.isNotEmpty) return label;
  Element? current = context;
  for (var depth = 0; depth < 40 && current != null; depth++) {
    final widget = current.widget;
    if (widget is Tooltip) {
      final message = widget.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }
    if (widget is IconButton) {
      final tip = widget.tooltip?.trim();
      if (tip != null && tip.isNotEmpty) return tip;
    }
    if (widget is TextField) {
      final labelText = widget.decoration?.labelText?.trim();
      if (labelText != null && labelText.isNotEmpty) return labelText;
    }
    Element? ancestor;
    current.visitAncestorElements((element) {
      ancestor = element;
      return false;
    });
    current = ancestor;
  }
  return 'widget:${context.widget.runtimeType}';
}

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <Rect>{};
  // Satu Tab ekstra untuk membuktikan rantai fokus berputar kembali ke
  // stop pertama.
  for (var i = 0; i < _expectedLabels.length + 1; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    expect(context, isNotNull, reason: 'Setiap Tab harus punya fokus.');
    final object = context!.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    if (seen.contains(rect)) {
      stops.add((label: _labelOf(context), rect: rect));
      break;
    }
    seen.add(rect);
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

bool _containsInclusive(Rect outer, Rect inner) =>
    inner.left >= outer.left - 0.01 &&
    inner.top >= outer.top - 0.01 &&
    inner.right <= outer.right + 0.01 &&
    inner.bottom <= outer.bottom + 0.01;

Widget _screen() => ProviderScope(
  overrides: [
    projectSessionProvider.overrideWith(_EmptySessionController.new),
    supportingAssetProvider(
      'probe-armor',
    ).overrideWith((ref) async => _asset()),
  ],
  child: const MaterialApp(
    home: Scaffold(
      body: SupportingAssetWorkspaceScreen(assetId: 'probe-armor'),
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

    // 1. Jumlah stop: enam unik, lalu wrap ke stop pertama.
    expect(stops.map((stop) => stop.label).toList(), [
      ..._expectedLabels,
      _expectedLabels.first,
    ], reason: 'Rantai Tab harus mengunjungi enam stop lalu kembali ke awal.');

    // 2. Area fokus non-zero pada semua stop.
    expect(
      stops.every(
        (stop) =>
            stop.rect != Rect.zero &&
            stop.rect.width > 0 &&
            stop.rect.height > 0,
      ),
      isTrue,
      reason: 'Setiap stop fokus harus memiliki area non-zero.',
    );

    // 3. Seluruh stop berada di dalam viewport yang diaudit.
    expect(
      stops.every(
        (stop) =>
            stop.rect.left >= 0 &&
            stop.rect.top >= 0 &&
            stop.rect.right <= 1536 &&
            stop.rect.bottom <= 1024,
      ),
      isTrue,
      reason: 'Tidak ada stop fokus yang boleh berada di luar viewport.',
    );

    final header = stops.first;
    final body = stops.sublist(1, _expectedLabels.length);

    // 4. Stop kepala (aksi favorit) berada di baris atas dan di sisi kanan,
    //    sehingga traversal membaca kepala lebih dulu, baru kolom detail.
    expect(
      header.rect.top,
      lessThan(body.first.rect.top),
      reason: 'Baris kepala harus berada di atas kolom detail.',
    );
    expect(
      header.rect.left,
      greaterThan(body.first.rect.left),
      reason: 'Aksi favorit menempel di sisi kanan baris kepala.',
    );
    expect(
      header.rect.width,
      lessThan(100),
      reason: 'Aksi favorit berbentuk tombol ikon kecil.',
    );

    // 5. Lima stop kolom detail dibaca atas-ke-bawah pada kolom yang sama.
    expect(
      body.map((stop) => stop.rect.left).toSet().length,
      1,
      reason: 'Kolom detail harus berbagi satu sumbu kiri.',
    );
    for (var i = 1; i < body.length; i++) {
      expect(
        body[i].rect.top,
        greaterThan(body[i - 1].rect.top),
        reason:
            'Stop ${i + 1} kolom detail harus berada di bawah stop $i '
            'sebelumnya.',
      );
    }

    // 6. Tombol aksi lebih lebar daripada field input, dan seluruh aksi
    //    kolom detail berada di sisi kiri layar (bukan di baris kepala).
    final editDetails = body[0];
    final saveArmor = body.last;
    expect(editDetails.rect.width, greaterThan(150));
    expect(saveArmor.rect.width, greaterThan(150));
    expect(
      body.every((stop) => stop.rect.left < 800),
      isTrue,
      reason: 'Kolom detail harus berada di sisi kiri layar.',
    );

    // 7. Tiap stop berada di dalam render box affordance miliknya.
    final favoriteRect = tester.getRect(find.byType(IconButton));
    expect(
      _containsInclusive(favoriteRect, header.rect),
      isTrue,
      reason: 'Stop kepala harus berada di dalam IconButton favorit.',
    );
    final editRect = tester.getRect(
      find.widgetWithText(FilledButton, 'Edit details'),
    );
    expect(
      _containsInclusive(editRect, editDetails.rect),
      isTrue,
      reason: 'Stop "Edit details" harus berada di dalam tombolnya.',
    );
    final saveRect = tester.getRect(
      find.widgetWithText(FilledButton, 'Save Armor'),
    );
    expect(
      _containsInclusive(saveRect, saveArmor.rect),
      isTrue,
      reason: 'Stop "Save Armor" harus berada di dalam tombolnya.',
    );
    final fieldRects = [
      for (var i = 0; i < 3; i++) tester.getRect(find.byType(TextField).at(i)),
    ];
    expect(fieldRects.length, 3, reason: 'Editor armor punya tiga field.');
    for (final stop in body.sublist(1, body.length - 1)) {
      expect(
        fieldRects.any((field) => _containsInclusive(field, stop.rect)),
        isTrue,
        reason:
            'Stop field "${stop.label}" harus berada di dalam satu '
            'TextField.',
      );
    }

    // 8. Wrap: Tab terakhir kembali tepat ke posisi stop pertama.
    expect(stops.last.rect, stops.first.rect);
    expect(stops.last.label, _expectedLabels.first);

    expect(tester.takeException(), isNull);
  });
}
