import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/void_app_shell.dart';
import 'package:void_scriptor/core/security/presentation/project_lock_screen.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// vs-hunt-20260911 BUG-4/5/10 (shell unlock flow hardening):
/// - BUG-5: `_unlocking` gated the prompt render without a setState, so any
///   unrelated rebuild mid-unlock bounced the user to the generic failure
///   screen, and ProjectLockedException was unclassified in
///   `_openFailureMessage` ("Periksa lokasi folder..." for a healthy locked
///   project). Contract: the prompt stays up during an in-flight unlock
///   (ProjectLockScreen owns the busy state), and an unlock-probe failure
///   still falls back to the generic screen with a TYPED human message.
/// - BUG-4: `_unlockProject` did not re-check the request token after its
///   awaits; an unlock finishing after a navigation re-opened the old
///   project behind the new route. Contract: capture the open-request token
///   and re-check it (with the widget project id) after awaiting.
/// - BUG-10: the prompt rendered the raw project UUID. Contract: the
///   display name resolves through projectNameProvider, falling back to
///   the id (registry-backed in production; overridden in these tests, no
///   real IO in the fake-async zone).
class LockThrowingSession extends ProjectSessionController {
  LockThrowingSession(this.lockedProjectId);
  final String lockedProjectId;
  final Completer<bool> gate = Completer<bool>();
  int unlockCalls = 0;

  @override
  Future<ProjectSession?> build() async => null;

  @override
  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    state = AsyncError(
      ProjectLockedException(lockedProjectId),
      StackTrace.current,
    );
    throw ProjectLockedException(lockedProjectId);
  }

  @override
  Future<bool> unlockAndOpen(String projectId, String passphrase) async {
    unlockCalls++;
    return gate.future;
  }
}

/// Session whose unlock PROBE throws a typed database failure, distinct
/// from a rejected passphrase (false) — that is the real "probe failure"
/// shape the shell must route to the generic typed screen.
class ProbeFailureSession extends LockThrowingSession {
  ProbeFailureSession(super.lockedProjectId);
  @override
  Future<bool> unlockAndOpen(String projectId, String passphrase) async {
    unlockCalls++;
    throw ProjectDatabaseUnavailableException(
      'C:/fake/$lockedProjectId/database/app.db',
      StateError('simulated probe failure'),
    );
  }
}

Widget _shell(
  ProjectSessionController controller, {
  String projectId = 'p1',
  List<Override> extra = const [],
}) => ProviderScope(
  overrides: [projectSessionProvider.overrideWith(() => controller), ...extra],
  child: MaterialApp(home: VoidAppShell(projectId: projectId, content: null)),
);

void main() {
  testWidgets(
    'an unrelated rebuild during an in-flight unlock keeps the passphrase '
    'prompt up (vs-hunt-20260911 BUG-5)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = LockThrowingSession('p1');
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectLockScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'whatever');
      await tester.tap(find.text('Buka Proyek'));
      // The unlock future is parked on the completer: force an unrelated
      // rebuild of the shell while the unlock is in flight.
      await tester.pump();
      tester.element(find.byType(VoidAppShell)).markNeedsBuild();
      await tester.pump();

      expect(
        find.byType(ProjectLockScreen),
        findsOneWidget,
        reason:
            'rebuild mid-unlock tak boleh menjatuhkan prompt; '
            'busy state dikelola ProjectLockScreen sendiri',
      );
      expect(find.text('Memeriksa…'), findsOneWidget);

      // Complete the unlock as a rejection: the prompt stays with the
      // inline error once the future settles.
      controller.gate.complete(false);
      await tester.pumpAndSettle();
      expect(find.byType(ProjectLockScreen), findsOneWidget);
      expect(find.textContaining('Passphrase salah'), findsOneWidget);
    },
  );

  testWidgets(
    'an unlock-probe failure falls back to the generic screen with the '
    'typed location message (vs-hunt-20260911 BUG-5 classification tail)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ProbeFailureSession('p1');
      await tester.pumpWidget(_shell(controller));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'x');
      await tester.tap(find.text('Buka Proyek'));
      await tester.pumpAndSettle();

      expect(controller.unlockCalls, 1);
      expect(find.byType(ProjectLockScreen), findsNothing);
      expect(
        find.textContaining('Lokasi penyimpanan proyek tidak dapat diakses'),
        findsOneWidget,
        reason: 'typed classifier terpakai, bukan pesan generik folder',
      );
    },
  );

  testWidgets(
    'an unlock finishing after a navigation does not resurrect the old '
    'project state (vs-hunt-20260911 BUG-4 token guard)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = LockThrowingSession('p1');
      await tester.pumpWidget(_shell(controller, projectId: 'p1'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectLockScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'whatever');
      await tester.tap(find.text('Buka Proyek'));
      await tester.pump();
      expect(controller.unlockCalls, 1);

      // Navigate: the shell now belongs to p2 (a new open request bumps the
      // token; its open also throws a lock for p2).
      await tester.pumpWidget(_shell(controller, projectId: 'p2'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectLockScreen), findsOneWidget);

      // The p1 unlock now settles as a rejection — it must NOT write into
      // the p2 shell state (no inline 'Passphrase salah' on the p2 prompt,
      // no exception from touching a stale element).
      controller.gate.complete(false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Passphrase salah'), findsNothing);
    },
  );

  testWidgets(
    'the lock prompt shows the resolved project name instead of the raw '
    'UUID (vs-hunt-20260911 BUG-10)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = LockThrowingSession('uuid-1234');
      await tester.pumpWidget(
        _shell(
          controller,
          projectId: 'uuid-1234',
          extra: [
            projectNameProvider.overrideWith(
              (ref, projectId) => 'Saga Nusantara',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProjectLockScreen), findsOneWidget);
      expect(find.text('Saga Nusantara terkunci'), findsOneWidget);
      expect(
        find.textContaining('uuid-1234'),
        findsNothing,
        reason: 'UUID mentah tidak boleh tampil sebagai nama proyek',
      );
    },
  );
}
