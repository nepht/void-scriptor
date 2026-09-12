import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/project_resilience/application/project_resilience_controller.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/project_resilience/presentation/project_resilience_center_screen.dart';

/// Widget wiring for GAP-BACKUP-RESTORE-NO-UI (run228): the Project Backups
/// screen must offer an explicit, confirmed restore of the latest backup and
/// must disable that action while no backup exists.
///
/// The restore execution itself is injected via `onRestoreConfirmed` and
/// verified end-to-end with real I/O in backup_restore_ui_wiring_test.dart
/// (provider-level journey). Real package setup uses tester.runAsync because
/// the fake-async zone never pumps platform file-system completions; the
/// injected seam keeps the fake-async widget zone free of package I/O.
void main() {
  Future<(ProjectPackage, Directory)> makePackage(String name) async {
    final root = await Directory.systemTemp.createTemp('hermes-restoreui-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: name);
    return (package, root);
  }

  /// Pumps in real time until the asynchronous scan renders [probe], with a
  /// hard deadline. pumpAndSettle cannot be used for the first frame: the
  /// scan performs real file-system I/O that only progresses on the real
  /// event loop, so the busy indicator would animate forever under
  /// fake-async pumping.
  Future<void> pumpUntil(
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

  testWidgets(
    'backups screen without backups disables restore with a visible state',
    (tester) async {
      final seeded = await tester.runAsync(() => makePackage('RUI0'));
      final package = seeded!.$1;
      final root = seeded.$2;
      final opened = await tester.runAsync(
        () => ProjectSessionManager().open(package),
      );
      final session = opened!;
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
      await pumpUntil(tester, find.text('Available backups: 0'));
      final restoreButton = find.ancestor(
        of: find.text('Restore Latest Backup'),
        matching: find.byType(FilledButton),
      );
      expect(restoreButton, findsOneWidget);
      expect(
        tester.widget<FilledButton>(restoreButton.first).onPressed,
        isNull,
        reason: 'restore must not be offered when there is nothing to restore',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'restore latest backup requires explicit confirmation before running',
    (tester) async {
      final seeded = await tester.runAsync(() => makePackage('RUI1'));
      final package = seeded!.$1;
      final root = seeded.$2;
      final opened = await tester.runAsync(
        () => ProjectSessionManager().open(package),
      );
      final session = opened!;
      await tester.runAsync(
        () => ProjectResilienceController(
          session,
        ).createBackup(note: 'ui-journey'),
      );
      final rows = (await tester.runAsync(
        () => session.database.projectResilienceRepository.backupsFor(
          package.projectId,
        ),
      ))!;
      addTearDown(() async {
        await tester.runAsync(() => session.close());
        if (root.existsSync()) await root.delete(recursive: true);
      });
      expect(rows, hasLength(1));

      var restoreCalls = 0;
      ProjectBackup? requestedBackup;
      await tester.pumpWidget(
        _wrapDetached(
          MaterialApp(
            home: ProjectResilienceWorkspaceScreen(
              view: ProjectResilienceView.backups,
              session: session,
              onRestoreConfirmed: (backup) async {
                restoreCalls++;
                requestedBackup = backup;
              },
            ),
          ),
        ),
      );
      await pumpUntil(tester, find.text('Available backups: 1'));

      await tester.tap(find.text('Restore Latest Backup'));
      await tester.pumpAndSettle();
      expect(
        find.text('Restore this backup?'),
        findsOneWidget,
        reason: 'restore overwrites live project data and must be confirmed',
      );
      expect(restoreCalls, 0, reason: 'nothing runs before confirmation');

      // Cancel leaves everything untouched.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Restore this backup?'), findsNothing);
      expect(restoreCalls, 0, reason: 'cancelling must not run the restore');

      // Confirming runs the injected restore exactly once with the latest
      // (newest createdAt) backup row.
      await tester.tap(find.text('Restore Latest Backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Restore'));
      await tester.pumpAndSettle();
      expect(restoreCalls, 1);
      expect(requestedBackup!.id, rows.first.id);
      expect(find.text('Restored latest backup.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restore failure surfaces inline without losing the screen', (
    tester,
  ) async {
    final seeded = await tester.runAsync(() => makePackage('RUI2'));
    final package = seeded!.$1;
    final root = seeded.$2;
    final opened = await tester.runAsync(
      () => ProjectSessionManager().open(package),
    );
    final session = opened!;
    await tester.runAsync(
      () =>
          ProjectResilienceController(session).createBackup(note: 'ui-journey'),
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
            onRestoreConfirmed: (backup) async =>
                throw StateError('injected restore failure'),
          ),
        ),
      ),
    );
    await pumpUntil(tester, find.text('Restore Latest Backup'));

    await tester.tap(find.text('Restore Latest Backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Restore'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Operation failed'),
      findsOneWidget,
      reason: 'a failed restore must surface inline, not crash the screen',
    );
    expect(find.text('Restore Latest Backup'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// The screen watches projectSessionProvider as a fallback; the provider's
/// real build path hits platform plugins that do not exist in widget tests
/// (getApplicationSupportDirectory), leaving a never-completing future that
/// makes pumpAndSettle spin. A detached (null) session override keeps the
/// widget zone clean; the injected `session:` drives the screen under test.
Widget _wrapDetached(Widget child) => ProviderScope(
  overrides: [projectSessionProvider.overrideWith(() => _DetachedSession())],
  child: child,
);

class _DetachedSession extends ProjectSessionController {
  @override
  Future<ProjectSession?> build() async => null;
}
