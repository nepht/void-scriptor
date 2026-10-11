import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/application/oauth_client_configuration.dart';

void main() {
  test(
    'uses the managed Google Drive client ID before the secure-store override',
    () async {
      final store = OAuthClientConfigurationStore(
        store: MemoryCredentialStore(),
      );
      await store.writeClientId(
        providerId: 'google_drive',
        clientId: 'vault-override',
      );

      expect(
        OAuthClientConfigurationStore.managedClientIdFor('google_drive'),
        'managed-client-fixture',
      );
      expect(store.hasManagedClientId('google_drive'), isTrue);
      expect(
        await store.readClientId('google_drive'),
        'managed-client-fixture',
      );
    },
    skip: OAuthClientConfigurationStore.managedClientIdFor('google_drive') ==
        null,
  );

  test('does not expose the managed ID for unrelated providers', () {
    expect(OAuthClientConfigurationStore.managedClientIdFor('github'), isNull);
  });

  test(
    'passes the complete OAuth URL to the Windows browser launcher',
    () async {
      final authorizationUri = Uri.parse(
        'https://voidscriptor.com/api/auth/google?client=desktop&'
        'redirect_uri=vscriptor%3A%2F%2Foauth%2Fcallback&state=state-fixture&'
        'code_challenge=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO1234567&'
        'code_challenge_method=S256',
      );
      String? executable;
      List<String>? arguments;
      final launcher = WindowsOAuthBrowserLauncher(
        platformCheck: () => true,
        processRunner: (value, args) async {
          executable = value;
          arguments = args;
          return ProcessResult(1, 0, '', '');
        },
      );

      final launched = await launcher.launch(authorizationUri);

      expect(launched, isTrue);
      expect(executable, 'rundll32.exe');
      expect(arguments, <String>[
        'url.dll,FileProtocolHandler',
        authorizationUri.toString(),
      ]);
    },
  );
}
