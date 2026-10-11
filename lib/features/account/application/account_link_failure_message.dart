import 'web_account_auth_identity_provider.dart';

String accountLinkFailureMessage(String provider, Object error) {
  final code = error is AuthException ? error.code : null;
  final safeCode = switch (code) {
    'already_linked' || 'provider_already_linked' => 'already linked',
    'email_already_used' => 'email already belongs to another account',
    'provider_not_configured' => 'provider is not configured',
    'session_expired' || 'session_unavailable' || 'unauthenticated' =>
      'session expired',
    'timeout' => 'request timed out',
    'network_error' => 'network unavailable',
    'provider_cancelled' => 'authorization cancelled',
    'state_mismatch' => 'authorization state mismatch',
    'browser_launch_failed' => 'browser could not be opened',
    _ => null,
  };
  final suffix = safeCode == null ? '' : ': $safeCode';
  return 'Could not connect $provider account$suffix.';
}
