import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/oauth_callback_bootstrap.dart';

void main() {
  test(
    'hands a validated native callback to the completion boundary',
    () async {
      Uri? received;
      final bootstrap = OAuthCallbackBootstrap(
        complete: (callback) async => received = callback,
      );

      final processed = await bootstrap.process(const <String>[
        '--oauth-callback=vscriptor://oauth/callback?code=fixture&state=state',
      ]);

      expect(processed, isTrue);
      expect(received, isNotNull);
      expect(received!.scheme, 'vscriptor');
    },
  );

  test('does not invoke completion for an invalid callback', () async {
    var calls = 0;
    final bootstrap = OAuthCallbackBootstrap(complete: (_) async => calls++);

    final processed = await bootstrap.process(const <String>[
      '--oauth-callback=https://example.invalid/?code=fixture',
    ]);

    expect(processed, isFalse);
    expect(calls, 0);
  });

  test(
    'reports completion failure without exposing callback material',
    () async {
      final bootstrap = OAuthCallbackBootstrap(
        complete: (_) async => throw StateError('fixture completion failure'),
      );

      final processed = await bootstrap.process(const <String>[
        '--oauth-callback=vscriptor://oauth/callback?code=fixture&state=state',
      ]);

      expect(processed, isFalse);
    },
  );
}
