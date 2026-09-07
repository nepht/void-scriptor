import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/project_exit_guard.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';

class DelayedCloseController extends ProjectSessionController {
  final completion = Completer<void>();
  int calls = 0;

  @override
  Future<ProjectSession?> build() async => null;

  @override
  Future<void> closeProject() {
    calls++;
    return completion.future;
  }
}

void main() {
  testWidgets('repeated exit waits for one close operation', (tester) async {
    final controller = DelayedCloseController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectSessionProvider.overrideWith(() => controller)],
        child: const ProjectExitGuard(child: SizedBox()),
      ),
    );
    final first = tester.binding.handleRequestAppExit();
    final second = tester.binding.handleRequestAppExit();
    await tester.pump();
    expect(controller.calls, 1);
    var completed = false;
    first.then((_) => completed = true);
    await tester.pump();
    expect(completed, isFalse);
    controller.completion.complete();
    expect(await first, AppExitResponse.exit);
    expect(await second, AppExitResponse.exit);
  });

  testWidgets('failed close cancels exit instead of discarding the failure', (
    tester,
  ) async {
    final controller = DelayedCloseController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [projectSessionProvider.overrideWith(() => controller)],
        child: const ProjectExitGuard(child: SizedBox()),
      ),
    );
    final exit = tester.binding.handleRequestAppExit();
    await tester.pump();
    controller.completion.completeError(StateError('close failed'));
    expect(await exit, AppExitResponse.cancel);
    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('exit awaits session release and the same project reopens', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('void-exit-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Reopen');
      final container = ProviderContainer(
        overrides: [
          projectPathsProvider.overrideWithValue(
            ProjectPaths(rootDirectory: root),
          ),
        ],
      );
      try {
        final controller = container.read(projectSessionProvider.notifier);
        await controller.open(package.projectId);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ProjectExitGuard(child: SizedBox()),
          ),
        );
        expect(await package.sessionFile.exists(), isTrue);
        expect(
          await tester.binding.handleRequestAppExit(),
          AppExitResponse.exit,
        );
        expect(await package.sessionFile.exists(), isFalse);
        expect(await package.lockFile.exists(), isFalse);
        await controller.open(package.projectId);
        await controller.closeProject();
        await tester.pumpWidget(const SizedBox());
      } finally {
        await container.read(projectSessionProvider.notifier).closeProject();
        container.dispose();
        if (await root.exists()) await root.delete(recursive: true);
      }
    });
  });
}
