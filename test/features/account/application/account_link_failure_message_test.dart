import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_identity_provider.dart';
import 'package:void_scriptor/features/account/application/account_link_failure_message.dart';
import 'package:void_scriptor/features/account/application/web_account_auth_identity_provider.dart';

void main() {
  test('maps known remote link failures without exposing raw response text', () {
    expect(
      accountLinkFailureMessage(
        'GitHub',
        const AuthRemoteRequestFailed('provider_not_configured'),
      ),
      'Could not connect GitHub account: provider is not configured.',
    );
  });

  test('maps a missing local session to an actionable message', () {
    expect(
      accountLinkFailureMessage('GitHub', const AuthIdentityUnavailable()),
      'Could not connect GitHub account.',
    );
  });

  test('does not copy an unknown server error into the UI', () {
    expect(
      accountLinkFailureMessage(
        'GitHub',
        const AuthRemoteRequestFailed('secret-token-leak'),
      ),
      'Could not connect GitHub account.',
    );
  });
}
