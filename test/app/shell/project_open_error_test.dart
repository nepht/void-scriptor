import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/void_app_shell.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

class LockedSession extends ProjectSessionController {
  int attempts = 0;
  @override
  Future<ProjectSession?> build() async => null;
  @override
  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    attempts++;
    final error = StateError('Project has an active or stale session');
    state = AsyncError(error, StackTrace.current);
    throw error;
  }
}

void main() {
  testWidgets(
    'project open failure is visible and retryable without uncaught error',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = LockedSession();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [projectSessionProvider.overrideWith(() => controller)],
          child: const MaterialApp(
            home: VoidAppShell(projectId: 'locked', content: Text('ready')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Proyek tidak dapat dibuka'), findsOneWidget);
      expect(find.text('ready'), findsNothing);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(controller.attempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
