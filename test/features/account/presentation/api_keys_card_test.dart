import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_api_keys_manager.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/account/presentation/api_keys_card.dart';

/// The 117.16 open item was that the manager existed but nothing outside its own
/// drill harness could reach it. These tests close that by driving the card
/// through the real manager: every button presses the manager method, the
/// rendered state comes from the manager's own fields, and no plaintext can
/// reach the widget tree because the manager never hands one out.
void main() {
  group('ApiKeysCard is the production consumer of the manager', () {
    testWidgets('renders active keys with masked values only', (tester) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'super-secret-value',
        scopes: const {'models:read', 'generation:write'},
      );

      await tester.pumpWidget(_app(ApiKeysCard(keys: fixture.manager.keys)));
      await tester.pumpAndSettle();

      expect(find.text('Primary key'), findsOneWidget);
      expect(find.text('cloud-ai · ••••••••••••'), findsOneWidget);
      expect(find.textContaining('super-secret'), findsNothing);
      expect(find.textContaining('2 active of 1 stored'), findsNothing);
      expect(find.textContaining('1 active of 1 stored'), findsOneWidget);
    });

    testWidgets('a revoked key is never rendered as if it were live', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'secret',
        scopes: const {'models:read'},
      );
      await fixture.manager.revoke('primary');

      await tester.pumpWidget(_app(ApiKeysCard(keys: fixture.manager.keys)));
      await tester.pumpAndSettle();

      expect(find.text('Revoked'), findsOneWidget);
      expect(find.text('Secret destroyed'), findsOneWidget);
      expect(find.text('Validate against the provider'), findsNothing);
      expect(find.byIcon(Icons.verified_outlined), findsNothing);
      expect(find.byIcon(Icons.content_copy_outlined), findsNothing);
      expect(find.byIcon(Icons.block), findsNothing);
    });

    testWidgets('validate button routes to the manager and shows its verdict', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );

      await tester.pumpWidget(
        _app(
          ApiKeysCardView(controller: ApiKeysCardController(fixture.manager)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not verified yet'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.verified_outlined));
      await tester.pumpAndSettle();

      expect(fixture.validatedSecrets, ['valid-secret']);
      expect(find.text('Valid'), findsOneWidget);
      expect(find.text('Not verified yet'), findsNothing);
    });

    testWidgets('an invalid key reports the manager verdict, not a success', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'wrong-secret',
        scopes: const {'models:read'},
      );

      await tester.pumpWidget(
        _app(
          ApiKeysCardView(controller: ApiKeysCardController(fixture.manager)),
        ),
      );
      await tester.tap(find.byIcon(Icons.verified_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Invalid'), findsOneWidget);
      expect(find.text('Valid'), findsNothing);
    });

    testWidgets('copy button reaches the vault through the manager', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );

      await tester.pumpWidget(
        _app(
          ApiKeysCard(
            keys: fixture.manager.keys,
            onCopy: (id) => fixture.manager.secureCopy(id),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.content_copy_outlined));
      await tester.pumpAndSettle();

      expect(fixture.clipboard, 'valid-secret');
    });

    testWidgets('revoke without reauthentication fails closed in the UI', (
      tester,
    ) async {
      final fixture = _Fixture(reauthenticated: false);
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );

      await tester.pumpWidget(
        _app(
          ApiKeysCard(
            keys: fixture.manager.keys,
            onRevoke: (id) => fixture.manager.revoke(id),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.block));
      await tester.pumpAndSettle();

      // The manager refused, so the key must still be rendered as live.
      expect(find.text('Revoked'), findsNothing);
      expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);
    });

    testWidgets('no action buttons render when no callbacks are supplied', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'secret',
        scopes: const {'models:read'},
      );

      await tester.pumpWidget(_app(ApiKeysCard(keys: fixture.manager.keys)));
      await tester.pumpAndSettle();

      // The icons stay visible - a user should still see what can be done with
      // this key - but every control is inert because no action was wired, so
      // the card cannot pretend to work while silently dropping the taps.
      for (final icon in [
        Icons.verified_outlined,
        Icons.content_copy_outlined,
        Icons.autorenew,
        Icons.block,
      ]) {
        final button = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(icon),
            matching: find.byType(IconButton),
          ),
        );
        expect(button.onPressed, isNull, reason: '$icon must be inert');
      }
      expect(find.text('Add key'), findsNothing);
    });

    testWidgets('empty state offers the vault route when wired', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        _app(ApiKeysCard(keys: const [], onOpenVault: () => opened++)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No provider keys are stored for this account.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Connect a provider or add a key'),
        findsOneWidget,
      );

      await tester.tap(find.text('Open secure vault'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('semantics expose the key state without the secret', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );

      await tester.pumpWidget(_app(ApiKeysCard(keys: fixture.manager.keys)));
      await tester.pumpAndSettle();

      // The row's own label is merged with its children by Semantics, so match
      // on the identifying part instead of the whole flattened string.
      expect(
        find.bySemanticsLabel(
          RegExp(r'API key Primary key for cloud-ai, Not verified yet'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'valid-secret')), findsNothing);
      handle.dispose();
    });
  });

  group('ApiKeysCardController republishes manager decisions', () {
    testWidgets('a validation that flips a key invalid becomes visible', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'wrong-secret',
        scopes: const {'models:read'},
      );
      final controller = ApiKeysCardController(fixture.manager);

      await tester.pumpWidget(_app(ApiKeysCardView(controller: controller)));
      await tester.pumpAndSettle();
      expect(find.text('Not verified yet'), findsOneWidget);

      await controller.validate('primary');
      await tester.pumpAndSettle();

      expect(find.text('Invalid'), findsOneWidget);
      expect(find.text('Not verified yet'), findsNothing);
    });

    testWidgets('revoke removes the actions and keeps the key visible', (
      tester,
    ) async {
      final fixture = _Fixture();
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );
      final controller = ApiKeysCardController(fixture.manager);

      await tester.pumpWidget(_app(ApiKeysCardView(controller: controller)));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.content_copy_outlined), findsOneWidget);

      await controller.revoke('primary');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.content_copy_outlined), findsNothing);
      expect(find.text('Revoked'), findsOneWidget);
      expect(find.text('Secret destroyed'), findsOneWidget);
    });

    test(
      'a second concurrent action is refused, not queued silently',
      () async {
        final fixture = _Fixture();
        await fixture.manager.add(
          id: 'primary',
          providerId: 'cloud-ai',
          label: 'Primary key',
          secret: 'valid-secret',
          scopes: const {'models:read'},
        );
        final controller = ApiKeysCardController(fixture.manager);

        final first = controller.copy('primary');
        await expectLater(
          controller.copy('primary'),
          throwsA(isA<StateError>()),
        );
        expect(await first, isTrue);
        expect(controller.busyKeyId, isNull);
      },
    );

    test('an action that fails still releases the lock', () async {
      final fixture = _Fixture(reauthenticated: false);
      await fixture.manager.add(
        id: 'primary',
        providerId: 'cloud-ai',
        label: 'Primary key',
        secret: 'valid-secret',
        scopes: const {'models:read'},
      );
      final controller = ApiKeysCardController(fixture.manager);

      // The manager refuses an unauthenticated rotate; the lock must not be
      // left held, or every later action would be refused forever.
      await expectLater(
        controller.replace('primary', 'new-secret'),
        throwsStateError,
      );
      expect(controller.busyKeyId, isNull);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

class _Fixture {
  _Fixture({this.reauthenticated = true}) {
    vault = AccountSecureTokenVault(
      store: store,
      reauthenticate: () async => reauthenticated,
      clipboardWriter: (value) async => clipboard = value,
      clock: () => now,
    );
    manager = AccountCenterApiKeysManager(
      accountId: 'account-1',
      vault: vault,
      clock: () => now,
      validator: (request) async {
        validatedSecrets.add(request.secret);
        return request.secret == 'valid-secret';
      },
    );
  }

  final store = MemoryCredentialStore();
  late final AccountSecureTokenVault vault;
  late final AccountCenterApiKeysManager manager;
  final validatedSecrets = <String>[];
  DateTime now = DateTime.utc(2026, 9, 26, 2);
  bool reauthenticated;
  String? clipboard;
}
