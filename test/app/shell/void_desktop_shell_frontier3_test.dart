// Frontier 3: top bar menampilkan konteks proyek live dari sesi aktif.
// Naam proyek berasal dari session.manifest.name, bukan hardcoded.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_desktop_shell.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  testWidgets('top bar menampilkan nama proyek dari sesi aktif', (
    tester,
  ) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('void-frontier3-'),
    );
    final paths = ProjectPaths(rootDirectory: root!);
    final package = await tester.runAsync(
      () => ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Proyek Uji Frontier 3'),
    );
    final session = await tester.runAsync(
      () => ProjectSessionManager().open(package!),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        await session!.close();
        if (root.existsSync()) await root.delete(recursive: true);
      });
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(session!)),
          projectPathsProvider.overrideWithValue(paths),
        ],
        child: const MaterialApp(
          home: VoidDesktopShell(content: Text('ready-body')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nama proyek live terlihat di top bar (project-context button).
    expect(find.text('Proyek Uji Frontier 3'), findsOneWidget);
    expect(find.byTooltip('Project context'), findsOneWidget);
    // Tanpa sesi tidak ada chip save; dengan sesi state muncul dari runtime.
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu context Backup & Export terbuka dari nama proyek live', (
    tester,
  ) async {
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('void-frontier3b-'),
    );
    final paths = ProjectPaths(rootDirectory: root!);
    final package = await tester.runAsync(
      () => ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Proyek Menu Uji'),
    );
    final session = await tester.runAsync(
      () => ProjectSessionManager().open(package!),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(() async {
        await session!.close();
        if (root.existsSync()) await root.delete(recursive: true);
      });
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(() => _FixedSession(session!)),
          projectPathsProvider.overrideWithValue(paths),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              return const VoidDesktopShell(content: Text('ready-body'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proyek Menu Uji'));
    await tester.pumpAndSettle();
    expect(find.text('Backup & Export'), findsOneWidget);
    // Navigasi memakai go_router; cukup memastikan menu tersedia tanpa exception.
    expect(tester.takeException(), isNull);
  });
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}
