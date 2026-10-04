import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';

/// Kontrak WCAG 2.4.3 (Focus Order) untuk CharacterWorkspaceScreen.
///
/// Fixture: `characterWorkspaceProvider('qowner-1')` di-override dengan satu
/// [CharacterModel] in-memory — tanpa database Drift, tanpa file system,
/// tanpa network. Layar dipompa pada konfigurasi `activeSection: 'Relations'`
/// (desktop, viewport 1536x1024, dpr 1.0) sehingga dua panel berkontrol
/// terlihat: header RelationSection (aksi `Add Relation`) di atas, panel
/// CharacterModeSection kosong (aksi `Create Mode`) di bawahnya.
const _expectedLabels = <String>['Add Relation', 'Create Mode'];

const _character = CharacterModel(
  assetId: 'qowner-1',
  projectId: 'project-1',
  displayName: 'Qowner',
  alias: 'Quiz Maker of Void',
  gender: 'Male',
  age: 24,
  heightCm: 185,
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

Widget _screen() => ProviderScope(
  overrides: [
    characterWorkspaceProvider(
      'qowner-1',
    ).overrideWith((ref) async => _character),
  ],
  child: const MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1536,
        height: 1024,
        child: CharacterWorkspaceScreen(
          characterId: 'qowner-1',
          activeSection: 'Relations',
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('mengunci urutan focus order 2.4.3', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_screen());
    // Provider async (relations/mode) diselesaikan dulu supaya keadaan kosong
    // final — daftarisi bisa menambah stop kalau masih loading.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final stops = await _walk(tester);

    // 1. Jumlah stop = 2 unik, lalu wrap ke stop pertama (bukan cap iterasi).
    expect(stops.map((stop) => stop.label).toList(), [
      ..._expectedLabels,
      _expectedLabels.first,
    ], reason: 'Rantai Tab harus mengunjungi dua stop lalu kembali ke awal.');

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

    final first = stops.first;
    final second = stops[1];

    // 3. Properti posisi: panel RelationSection berada DI ATAS panel
    //    CharacterModeSection, sehingga traversal membaca atas-ke-bawah;
    //    kedua aksi menempel di sisi kanan layar desktop.
    expect(
      first.rect.top,
      lessThan(second.rect.top),
      reason: 'Header RelationSection harus di atas panel CharacterMode.',
    );
    expect(first.rect.left, greaterThan(1000), reason: 'Aksi kanan.');
    expect(second.rect.left, greaterThan(1000), reason: 'Aksi kanan.');

    // 4. Stop jatuh tepat di dalam affordance milikinya.
    final relationRect = tester.getRect(
      find.widgetWithText(TextButton, 'Add Relation'),
    );
    expect(
      relationRect.left - 0.01 <= first.rect.left &&
          relationRect.right + 0.01 >= first.rect.right &&
          relationRect.top - 0.01 <= first.rect.top &&
          relationRect.bottom + 0.01 >= first.rect.bottom,
      isTrue,
      reason: 'Stop pertama harus berada di dalam tombol "Add Relation".',
    );
    final modeRect = tester.getRect(
      find.widgetWithText(FilledButton, 'Create Mode'),
    );
    expect(
      modeRect.left - 0.01 <= second.rect.left &&
          modeRect.right + 0.01 >= second.rect.right &&
          modeRect.top - 0.01 <= second.rect.top &&
          modeRect.bottom + 0.01 >= second.rect.bottom,
      isTrue,
      reason: 'Stop kedua harus berada di dalam tombol "Create Mode".',
    );

    // 5. Wrap: tab terakhir kembali ke rect stop pertama.
    expect(stops.last.rect, stops.first.rect);
    expect(stops.last.label, _expectedLabels.first);

    expect(tester.takeException(), isNull);
  });
}
