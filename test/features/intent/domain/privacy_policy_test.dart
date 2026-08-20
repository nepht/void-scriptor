import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/privacy_policy.dart';

void main() {
  test('denies voice input without consent', () {
    const policy = PrivacyPolicy(consent: InputConsent());
    final result = policy.evaluate(
      const PrivacyRequest(input: InputPermission.voice),
    );

    expect(result.allowed, isFalse);
    expect(result.reason, PrivacyDenialReason.consentRequired);
  });

  test('allows explicitly consented voice input', () {
    const policy = PrivacyPolicy(consent: InputConsent(voice: true));
    final result = policy.evaluate(
      const PrivacyRequest(input: InputPermission.voice),
    );

    expect(result.allowed, isTrue);
    expect(result.requiresConfirmation, isFalse);
  });

  test('revoked consent immediately denies future requests', () {
    const policy = PrivacyPolicy(
      consent: InputConsent(voice: true, revoked: true),
    );
    final result = policy.evaluate(
      const PrivacyRequest(input: InputPermission.voice),
    );

    expect(result.allowed, isFalse);
    expect(result.reason, PrivacyDenialReason.consentRevoked);
  });
}
