import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_integrity_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/project_resilience/presentation/project_resilience_center_screen.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// vs-hunt-20260915-resilience BUG-6 (Referee: REAL BUG, Medium, verified at
/// HEAD 762ed7f): `ProjectIntegrityReport.portable` omitted `orphanFiles`, so
/// a project whose only defect is orphan asset files displayed
/// `Portable: yes` in the diagnostics view while the repair view still asked
/// for orphan cleanup. The portable predicate must require `orphanFiles == 0`,
/// and the diagnostics presentation must surface `needs attention` for an
/// orphan-only project.
void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('hermes-bug6-portable-'),
  );
  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('integrity report with orphan files is not portable', () async {
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Bug6Service');
    await File(
      '${package.assetsDirectory.path}/images/orphan.txt',
    ).writeAsString('orphan');
    final report = await ProjectIntegrityService(
      package,
    ).scan(referencedPaths: const {});
    expect(report.manifestValid, isTrue);
    expect(report.databaseValid, isTrue);
    expect(report.missingFiles, 0);
    expect(report.externalFiles, 0);
    expect(report.orphanFiles, 1);
    expect(
      report.portable,
      isFalse,
      reason:
          'BUG-6: orphan asset files require repair and must block the '
          'portable verdict',
    );
  });

  testWidgets(
    'diagnostics view reports needs attention for an orphan-only project',
    (tester) async {
      final package = await tester.runAsync(
        () => ProjectPackageService(rootDirectory: root).create(name: 'Bug6Ui'),
      );
      await tester.runAsync(() async {
        await File(
          '${package!.assetsDirectory.path}/images/orphan.png',
        ).writeAsBytes([1, 2, 3]);
      });
      final session = await tester.runAsync(
        () => ProjectSessionManager().open(package!),
      );
      addTearDown(() async => tester.runAsync(() => session!.close()));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            projectSessionProvider.overrideWith(() => _DetachedSession()),
          ],
          child: MaterialApp(
            home: ProjectResilienceWorkspaceScreen(
              view: ProjectResilienceView.diagnostics,
              session: session,
            ),
          ),
        ),
      );

      // The first scan runs on the real event loop; pump until it renders.
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (DateTime.now().isBefore(deadline)) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (tester.any(find.textContaining('Manifest: '))) break;
      }
      expect(find.text('Manifest: valid'), findsOneWidget);

      // Proof the fixture reached the scan path (repair-equivalent data).
      final snapshot = await tester.runAsync(
        () => ProjectResilienceController(session!).scan(),
      );
      expect(snapshot!.integrity.orphanFiles, 1);

      expect(
        find.text('Portable: needs attention'),
        findsOneWidget,
        reason:
            'BUG-6: an orphan-only project must never display Portable: yes',
      );
      expect(find.text('Portable: yes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _DetachedSession extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}
