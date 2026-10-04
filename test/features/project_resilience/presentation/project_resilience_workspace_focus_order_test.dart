import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/project_resilience/presentation/project_resilience_center_screen.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// WCAG 2.4.3 focus-order contract untuk ProjectResilienceWorkspaceScreen
/// (view Backups, satu backup sudah ada). Fixture session memakai pola yang
/// sudah terbukti di backup_restore_screen_wiring_test.dart: package nyata di
/// temp dir + scan asinkron yang ditunggu sampai kartu 'Available backups: 1'
/// muncul, supaya tombol restore enabled dan jumlah stop deterministik.
const _expectedLabels = <String>[
  'Scan Again',
  'Create Backup',
  'Restore Latest Backup',
];

Future<(ProjectPackage, Directory)> _makePackage(String name) async {
  final root = await Directory.systemTemp.createTemp('hermes-wcagfocus-');
  final package = await ProjectPackageService(
    rootDirectory: root,
  ).create(name: name);
  return (package, root);
}

/// Scan layar membaca file I/O nyata yang hanya jalan di event loop nyata;
/// pumpAndSettle murni fake-async tidak akan pernah menyelesaikannya.
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder probe, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (probe.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for $probe');
}

/// Provider session asli menyentuh platform channel yang tidak ada di widget
/// test; override detached supaya injected `session:` yang menggerakkan layar.
Widget _wrapDetached(Widget child) => ProviderScope(
  overrides: [projectSessionProvider.overrideWith(() => _DetachedSession())],
  child: child,
);

class _DetachedSession extends ProjectSessionController {
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

/// Menekan Tab tepat `jumlah stop + 1` kali: stop terakhir harus kembali ke
/// stop pertama (rect identik), sehingga panjang siklus traversal + urutan
/// label terkunci sekaligus.
Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  for (var i = 0; i < _expectedLabels.length + 1; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    expect(context, isNotNull, reason: 'Tab harus selalu memindahkan fokus.');
    final object = context!.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    stops.add((label: _labelOf(context), rect: rect));
  }
  return stops;
}

void main() {
  testWidgets(
    'mengunci urutan focus order 2.4.3 ProjectResilienceWorkspaceScreen',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final seeded = await tester.runAsync(() => _makePackage('wcagfocus'));
      final package = seeded!.$1;
      final root = seeded.$2;
      final opened = await tester.runAsync(
        () => ProjectSessionManager().open(package),
      );
      final session = opened!;
      await tester.runAsync(
        () => ProjectResilienceController(
          session,
        ).createBackup(note: 'focus-order fixture'),
      );
      addTearDown(() async {
        await tester.runAsync(() => session.close());
        if (root.existsSync()) await root.delete(recursive: true);
      });

      await tester.pumpWidget(
        _wrapDetached(
          MaterialApp(
            home: ProjectResilienceWorkspaceScreen(
              view: ProjectResilienceView.backups,
              session: session,
            ),
          ),
        ),
      );
      await _pumpUntil(tester, find.text('Available backups: 1'));
      await tester.pumpAndSettle();

      final stops = await _stops(tester);

      expect(
        stops.map((stop) => stop.label).toList(),
        [..._expectedLabels, _expectedLabels.first],
        reason:
            'Urutan label Tab harus persis 3 stop lalu kembali ke stop pertama.',
      );
      expect(
        stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
        isTrue,
        reason: 'Setiap stop fokus harus memiliki area non-zero.',
      );
      // Stop ke-4 (wrap) harus rect yang sama dengan stop pertama.
      expect(stops[3].rect, stops[0].rect);
      // Ketiga tombol berbagi satu baris Wrap: top identik, kiri makin besar.
      expect(stops[0].rect.top, stops[1].rect.top);
      expect(stops[1].rect.top, stops[2].rect.top);
      expect(stops[0].rect.left, lessThan(stops[1].rect.left));
      expect(stops[1].rect.left, lessThan(stops[2].rect.left));
      expect(tester.takeException(), isNull);
    },
  );
}
