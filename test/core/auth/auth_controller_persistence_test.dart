import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_session_store.dart';
import 'package:void_scriptor/core/auth/auth_session_store_io.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';

void main() {
  test(
    'legacy logged-out state migrates to local-first offline mode',
    () async {
      final store = InMemoryAuthSessionStore();
      await store.save(const AuthSession.loggedOut());
      final container = ProviderContainer(
        overrides: [authSessionStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      final restored = await container.read(authControllerProvider.future);

      expect(restored.status, AuthStatus.offline);
    },
  );

  test(
    'guest session persists across controller restarts (in-memory store)',
    () async {
      final store = InMemoryAuthSessionStore();
      final first = ProviderContainer(
        overrides: [authSessionStoreProvider.overrideWithValue(store)],
      );
      await first.read(authControllerProvider.future);
      expect(
        first.read(authControllerProvider).value?.status,
        AuthStatus.offline,
      );

      await first.read(authControllerProvider.notifier).continueAsGuest();
      expect(
        first.read(authControllerProvider).value?.status,
        AuthStatus.guest,
      );
      first.dispose();

      // Simulate an app restart: a fresh container over the SAME store.
      final second = ProviderContainer(
        overrides: [authSessionStoreProvider.overrideWithValue(store)],
      );
      final restored = await second.read(authControllerProvider.future);
      expect(restored.status, AuthStatus.guest);
      second.dispose();
    },
  );

  test(
    'offline session survives restart through the real file-backed store',
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'vs_auth_ctrl_io_test',
      );
      final sessionFile = File(
        '${tempDir.path}${Platform.pathSeparator}session.json',
      );
      try {
        final store = AuthSessionStoreIo(file: sessionFile);
        final first = ProviderContainer(
          overrides: [authSessionStoreProvider.overrideWithValue(store)],
        );
        await first.read(authControllerProvider.future);
        await first.read(authControllerProvider.notifier).continueOffline();
        expect(sessionFile.existsSync(), isTrue);
        first.dispose();

        // Fresh store instance re-reading the SAME file = restart.
        final reopened = AuthSessionStoreIo(file: sessionFile);
        final second = ProviderContainer(
          overrides: [authSessionStoreProvider.overrideWithValue(reopened)],
        );
        final restored = await second.read(authControllerProvider.future);
        expect(restored.status, AuthStatus.offline);
        expect(restored.displayName, 'Offline User');
        second.dispose();
      } finally {
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException catch (_) {}
      }
    },
  );

  test('logout clears the persisted session', () async {
    final store = InMemoryAuthSessionStore();
    final container = ProviderContainer(
      overrides: [authSessionStoreProvider.overrideWithValue(store)],
    );
    await container.read(authControllerProvider.future);
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.continueAsGuest();
    expect(store.load(), completion(isNotNull));

    await notifier.logout();
    expect(await store.load(), isNull);
    expect(
      container.read(authControllerProvider).value?.status,
      AuthStatus.unauthenticated,
    );
    container.dispose();
  });
}
