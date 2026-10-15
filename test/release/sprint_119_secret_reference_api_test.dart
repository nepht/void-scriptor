import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/sprint_119_secret_reference_api.dart';

void main() {
  group('119.8 Secret Reference API', () {
    test('keeps references opaque and redacts diagnostics', () {
      const api = SecretReferenceApi();
      const reference = OpaqueSecretReference('credref:github:primary');

      expect(reference.value, 'credref:github:primary');
      expect(reference.toString(), '[REDACTED]');
      expect(api.redact('token=super-secret'), 'token=[REDACTED]');
      expect(api.redact('credref:github:primary'), '[REDACTED]');
    });

    test('redacts client_secret diagnostics in any casing', () {
      const api = SecretReferenceApi();

      expect(api.redact('client_secret=abc123'), 'client_secret=[REDACTED]');
      expect(api.redact('CLIENT_SECRET=abc123'), 'CLIENT_SECRET=[REDACTED]');
      expect(
        api.redact('provider client_secret=xyz; next=1'),
        'provider client_secret=[REDACTED]; next=1',
      );
    });

    test('redacts api keys named in the contract claim boundary', () {
      const api = SecretReferenceApi();

      expect(api.redact('api_key=abc123'), 'api_key=[REDACTED]');
      expect(api.redact('apikey=abc123'), 'apikey=[REDACTED]');
      expect(api.redact('apiKey=abc123'), 'apiKey=[REDACTED]');
      expect(api.redact('key=abc123'), 'key=[REDACTED]');
      expect(api.redact('private_key=abc123'), 'private_key=[REDACTED]');
    });

    test('redacts colon and quoted credential diagnostics', () {
      const api = SecretReferenceApi();

      expect(api.redact('client_secret: abc123'), 'client_secret: [REDACTED]');
      expect(
        api.redact('"client_secret": "abc123"'),
        '"client_secret": "[REDACTED]"',
      );
    });

    test('redacts authorization bearer diagnostics', () {
      const api = SecretReferenceApi();

      expect(
        api.redact('Authorization: Bearer abc123'),
        'Authorization: Bearer [REDACTED]',
      );
      expect(api.redact('X-Api-Key: abc123'), 'X-Api-Key: [REDACTED]');
    });

    test('requires reauthentication for rotation and deletion', () async {
      const api = SecretReferenceApi();
      const reference = OpaqueSecretReference('credref:github:primary');

      expect(
        await api.rotate(reference, reauthenticated: false),
        SecretReferenceResult.deniedReauthentication,
      );
      expect(
        await api.delete(reference, reauthenticated: false),
        SecretReferenceResult.deniedReauthentication,
      );
    });

    test('uses a broker callback without exposing the stored value', () async {
      const api = SecretReferenceApi();
      const reference = OpaqueSecretReference('credref:github:primary');
      String? observed;

      final result = await api.use(reference, (value) async {
        observed = value;
        return 'ok';
      });

      expect(result, 'ok');
      expect(observed, '[BROKERED_SECRET]');
    });

    test('rejects malformed references and unknown operations', () {
      expect(OpaqueSecretReference.tryParse('raw-secret'), isNull);
      expect(
        SecretReferenceApi().evaluateOperation('unknown'),
        SecretReferenceResult.unknownOperation,
      );
    });

    test('validates the canonical manifest contract', () {
      expect(const SecretReferenceApi().validateCanonicalManifest(), isEmpty);
      final missing = <String, dynamic>{
        'canonical_step': '119.8',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{},
      };
      expect(
        const SecretReferenceApi().validateManifest(missing),
        containsAll(<String>[
          'acceptance_missing:opaque_ref',
          'acceptance_missing:reauth',
        ]),
      );
    });
  });
}
