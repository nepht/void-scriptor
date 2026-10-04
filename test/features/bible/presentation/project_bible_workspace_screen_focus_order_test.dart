import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/bible/presentation/project_bible_workspace_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk ProjectBibleWorkspaceScreen.
///
/// Layar ini adalah workspace kanon dengan tab navigasi enam section di
/// kepala (Universe Overview, Canon Rules, Worldbuilding, Factions,
/// Timeline / Eras, Canon Conflicts) ditambah dua aksi tulis di kolom kanan
/// (Faksi Baru, Add Relation).
///
/// Rantai fokus sengaja diaudit TANPA fixture database: dengan
/// `projectSessionProvider` mengembalikan `null`, semua section tetap
/// merender shell dan header yang stabil. Probe membuktikan urutan, label, dan
/// geometri stop identik baik pada session null maupun pada session Drift
/// sungguhan, jadi kontrak ini tidak bergantung pada state IO apa pun.
const _expectedLabels = <String>[
  'Universe Overview',
  'Canon Rules',
  'Worldbuilding',
  'Factions',
  'Timeline / Eras',
  'Canon Conflicts',
  'Faksi Baru',
  'Add Relation',
];

class _EmptySessionController extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}

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
  // Satu Tab ekstra untuk membuktikan rantai fokus berputar kembali ke awal.
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

Widget _screen() => ProviderScope(
  overrides: [projectSessionProvider.overrideWith(_EmptySessionController.new)],
  child: const MaterialApp(home: ProjectBibleWorkspaceScreen()),
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

    // 1. Rantai fokus mengikuti urutan tab navigasi, lalu dua aksi kolom
    //    kanan, lalu wrap ke tab pertama.
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

    // 3. Lima tab navigasi pertama membentuk satu baris di kepala dan dibaca
    //    kiri-ke-kanan pada koordinat top yang sama.
    final tabs = stops.take(_expectedLabels.length - 3).toList();
    expect(tabs.length, 5);
    expect(
      tabs.map((stop) => stop.rect.top).toSet().length,
      1,
      reason: 'Lima tab navigasi harus berbagi satu baris (top sama).',
    );
    for (var i = 1; i < tabs.length; i++) {
      expect(
        tabs[i].rect.left,
        greaterThan(tabs[i - 1].rect.left),
        reason: 'Tab ${i + 1} harus berada di kanan tab sebelumnya.',
      );
      expect(
        tabs[i].rect.left,
        greaterThanOrEqualTo(tabs[i - 1].rect.right),
        reason: 'Tab ${i + 1} tidak boleh tumpang tindih tab sebelumnya.',
      );
    }

    // 4. Tab keenam (Canon Conflicts) melompat ke baris kedua di kiri.
    final conflicts = stops[5].rect;
    expect(conflicts.top, greaterThan(tabs.last.rect.top));
    expect(conflicts.left, closeTo(tabs.first.rect.left, 1.0));

    // 5. Dua aksi tulis berada di kolom kanan, urut ke bawah.
    const rightColumnLeft = 1100.0;
    final actions = stops.sublist(
      _expectedLabels.length - 2,
      _expectedLabels.length,
    );
    expect(
      actions.every((stop) => stop.rect.left >= rightColumnLeft),
      isTrue,
      reason: 'Aksi tulis harus berada di kolom kanan.',
    );
    expect(
      actions[1].rect.top,
      greaterThan(actions[0].rect.top),
      reason: 'Add Relation harus berada di bawah Faksi Baru.',
    );

    // 6. Rantai fokus tetap berada di dalam viewport yang diaudit.
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

    expect(tester.takeException(), isNull);
  });
}
