import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/oauth_callback_router.dart';

void main() {
  group('OAuthCallbackRouter', () {
    test('accepts only the registered callback route', () {
      final envelope = OAuthCallbackRouter.parse(
        Uri.parse(
          'vscriptor://oauth/callback?code=auth-code&state=expected-state',
        ),
      );

      expect(envelope, isNotNull);
      expect(envelope!.code, 'auth-code');
      expect(envelope.state, 'expected-state');
      expect(envelope.isAuthorizationSuccess, isTrue);
    });

    test('preserves denial without treating it as success', () {
      final envelope = OAuthCallbackRouter.parse(
        Uri.parse(
          'vscriptor://oauth/callback?error=access_denied'
          '&error_description=User%20cancelled&state=expected-state',
        ),
      );

      expect(envelope, isNotNull);
      expect(envelope!.error, 'access_denied');
      expect(envelope.errorDescription, 'User cancelled');
      expect(envelope.isAuthorizationSuccess, isFalse);
    });

    test('extracts only the native runner callback argument', () {
      final uri = OAuthCallbackRouter.uriFromArguments(<String>[
        '--mode=normal',
        '--oauth-callback=vscriptor://oauth/callback?code=x&state=y',
      ]);
      expect(uri, Uri.parse('vscriptor://oauth/callback?code=x&state=y'));
      expect(
        OAuthCallbackRouter.uriFromArguments(<String>[
          '--oauth-callback=https://evil.test/?code=x',
        ]),
        isNull,
      );
    });

    test(
      'rejects wrong scheme, authority, path, fragment, and empty query',
      () {
        final invalid = <Uri>[
          Uri.parse('https://oauth/callback?code=x&state=y'),
          Uri.parse('vscriptor://other/callback?code=x&state=y'),
          Uri.parse('vscriptor://oauth/other?code=x&state=y'),
          Uri.parse('vscriptor://oauth/callback#code=x'),
          Uri.parse('vscriptor://oauth/callback'),
        ];

        for (final uri in invalid) {
          expect(
            OAuthCallbackRouter.parse(uri),
            isNull,
            reason: uri.toString(),
          );
        }
      },
    );
  });
}
