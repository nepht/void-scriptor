import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/web_account_auth_identity_provider.dart';
import 'package:void_scriptor/features/authentication/presentation/login_screen.dart';

void main() {
  test('maps known authentication failures to safe user-facing messages', () {
    expect(
      loginFailureMessage(const AuthProviderCancelled()),
      'Sign-in was cancelled. Choose Google or GitHub to try again.',
    );
    expect(
      loginFailureMessage(const AuthRemoteRequestFailed('invalid_grant')),
      'The authorization expired or was already used. Try signing in again.',
    );
    expect(
      loginFailureMessage(const AuthRemoteRequestFailed('network_error')),
      'The account service could not be reached. Check your connection and try again.',
    );
  });
}
