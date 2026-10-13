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
