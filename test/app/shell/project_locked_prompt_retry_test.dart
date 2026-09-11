import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/void_app_shell.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/security/crypto/encryption_cipher.dart';
import 'package:void_scriptor/core/security/crypto/key_derivation.dart';
import 'package:void_scriptor/core/security/application/project_lock_service.dart';
import 'package:void_scriptor/core/security/presentation/project_lock_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Wiring sprint Task 2 (bug-hunt run197 BUG-12): `ProjectLockedException`
/// promises "caller (UI) should prompt for the passphrase and retry", but no
/// catch site ever routed there, so locked projects surfaced as a generic
/// open failure. This slice wires the prompt-and-retry contract end to end:
/// the shell intercepts the typed exception, shows the passphrase prompt,
/// and on success re-opens the project into a live session.
class ThrowingSession extends ProjectSessionController {
  ThrowingSession(this.error);
  final Object error;
  @override
  Future<ProjectSession?> build() async => null;
  @override
  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    state = AsyncError(error, StackTrace.current);
    throw error;
  }
}

/// Controller whose first open throws ProjectLockedException and whose
/// unlock outcome is scripted, so the shell contract is observable without
/// constructing a full session.
class ScriptedSession extends ProjectSessionController {
  ScriptedSession(this.unlockSucceeds);
  final bool unlockSucceeds;
  int unlockCalls = 0;
  @override
  Future<ProjectSession?> build() async => null;
  @override
  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    state = AsyncError(ProjectLockedException(projectId), StackTrace.current);
    throw ProjectLockedException(projectId);
  }

  @override
  Future<bool> unlockAndOpen(String projectId, String passphrase) async {
    unlockCalls++;
    return unlockSucceeds;
  }
}

Widget _shell(ProjectSessionController controller) => ProviderScope(
  overrides: [projectSessionProvider.overrideWith(() => controller)],
  child: const MaterialApp(
    home: VoidAppShell(projectId: 'p1', content: Text('ready')),
  ),
);

void main() {
  testWidgets(
    'ProjectLockedException routes to the passphrase prompt with retry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _shell(ThrowingSession(ProjectLockedException('p1'))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(ProjectLockScreen), findsOneWidget);
      expect(find.textContaining('p1'), findsWidgets);
      expect(find.textContaining('Periksa lokasi folder'), findsNothing);
    },
  );

  testWidgets(
    'submitting a correct passphrase closes the prompt into the project',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScriptedSession(true);
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectLockScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'passphrase-123');
      await tester.tap(find.text('Buka Proyek'));
      await tester.pumpAndSettle();
      expect(controller.unlockCalls, 1);
      expect(find.byType(ProjectLockScreen), findsNothing);
      expect(find.text('ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a rejected passphrase surfaces an inline error and keeps the prompt',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScriptedSession(false);
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'wrong-passphrase');
      await tester.tap(find.text('Buka Proyek'));
      await tester.pumpAndSettle();
      expect(controller.unlockCalls, 1);
      expect(find.byType(ProjectLockScreen), findsOneWidget);
      expect(find.textContaining('Passphrase salah'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'unlockProject unlocks a real locked package through the manager',
    () async {
      final root = await Directory.systemTemp.createTemp('unlock-flow-');
      addTearDown(() => root.delete(recursive: true));
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Unlock Flow');
      final manager = ProjectSessionManager();
      final setup = await manager.open(package);
      final lockService = ProjectLockService(
        database: setup.database,
        deriver: const Pbkdf2KeyDeriver(),
        integrity: const HmacIntegrity(),
      );
      // setPassphrase persists the verifier with locked=true engaged.
      await lockService.setPassphrase(package.projectId, 'correct horse');
      await setup.close();

      await expectLater(
        manager.open(package),
        throwsA(isA<ProjectLockedException>()),
      );

      final wrong = await manager.unlockProject(package, 'nope');
      expect(wrong, isFalse);

      final unlocked = await manager.unlockProject(package, 'correct horse');
      expect(unlocked, isTrue);

      final session = await manager.open(package);
      addTearDown(session.close);
      expect(session.mode, ProjectOpenMode.readWrite);
    },
    skip: !Platform.isWindows,
  );
}
