import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/sprint_119_authentication_broker.dart';

Map<String, dynamic> _acceptance([String boundary = 'DEFERRED-EXTERNAL.']) {
  return <String, dynamic>{
    for (final name in Sprint119AuthenticationBrokerContract.requiredAcceptance)
      name: <String, dynamic>{
        'description': 'declared $name acceptance',
        'claim_boundary': boundary,
      },
  };
}

Map<String, dynamic> _record({
  Map<String, dynamic>? acceptance,
  Object? extraKey,
}) {
  final record = <String, dynamic>{
    'canonical_step': '119.7',
    'title': 'Authentication Broker',
    'schema_version': 1,
    'unknown_field_policy': 'REJECT',
    'external_gates': 'DEFERRED-EXTERNAL',
    'state': 'pass',
    'verdict': 'AUTHENTICATION_BROKER_CONTRACT_COMPLETE_LOCAL',
    'acceptance': acceptance ?? _acceptance(),
    'registration_fields':
        Sprint119AuthenticationBrokerContract.requiredRegistrationFields,
    'operations': <String>['authorize', 'refresh', 'reauthenticate', 'revoke'],
    'claim_boundary': <String>[
      'Local contract only.',
      'No tokens or secrets are stored.',
      'External evidence deferred. DEFERRED-EXTERNAL.',
    ],
  };
  if (extraKey != null) record['unexpected'] = extraKey;
  return record;
}

void main() {
  group('119.7 Authentication Broker', () {
    test('accepts a safe OAuth/OIDC broker registration', () {
      const registration = AuthenticationBrokerRegistration(
        providerId: 'google_drive',
        protocol: AuthenticationProtocol.oauth2,
        authorizationEndpoint: 'https://accounts.example/authorize',
        tokenEndpoint: 'https://accounts.example/token',
        redirectUris: <String>['https://app.example/oauth/callback'],
        credentialReference: 'credref:google-drive:primary',
        scopes: <String>['openid', 'drive.readonly'],
        supportsRefresh: true,
        supportsReauthentication: true,
        supportsRevocation: true,
        pkceRequired: true,
      );

      expect(registration.validate(), isEmpty);
      expect(registration.toRedactedJson(), <String, Object?>{
        'provider_id': 'google_drive',
        'protocol': 'oauth2',
        'authorization_endpoint': 'https://accounts.example/authorize',
        'token_endpoint': 'https://accounts.example/token',
        'redirect_uris': <String>['https://app.example/oauth/callback'],
        'credential_reference': 'credref:google-drive:primary',
        'scopes': <String>['openid', 'drive.readonly'],
        'supports_refresh': true,
        'supports_reauthentication': true,
        'supports_revocation': true,
        'pkce_required': true,
        'pkce_method': 'S256',
      });
      expect(
        registration.toRedactedJson().keys,
        isNot(contains('access_token')),
      );
      expect(
        registration.toRedactedJson().keys,
        isNot(contains('client_secret')),
      );
    });

    test('rejects insecure endpoints and non-opaque credential references', () {
      const registration = AuthenticationBrokerRegistration(
        providerId: 'google_drive',
        protocol: AuthenticationProtocol.oidc,
        authorizationEndpoint: 'http://accounts.example/authorize',
        tokenEndpoint: 'https://accounts.example/token',
        redirectUris: <String>['http://app.example/callback'],
        credentialReference: 'raw-secret-value',
        scopes: <String>[],
        supportsRefresh: false,
        supportsReauthentication: false,
        supportsRevocation: false,
      );

      expect(
        registration.validate(),
        containsAll(<String>[
          'authorization_endpoint_must_use_https',
          'redirect_uri_must_use_https',
          'credential_reference_invalid',
          'scopes_missing',
        ]),
      );
    });

    test('rejects PKCE registrations that do not use the S256 method', () {
      const registration = AuthenticationBrokerRegistration(
        providerId: 'google_drive',
        protocol: AuthenticationProtocol.oauth2,
        authorizationEndpoint: 'https://accounts.example/authorize',
        tokenEndpoint: 'https://accounts.example/token',
        redirectUris: <String>['https://app.example/oauth/callback'],
        credentialReference: 'credref:google-drive:primary',
        scopes: <String>['openid'],
        supportsRefresh: true,
        supportsReauthentication: true,
        supportsRevocation: true,
        pkceRequired: true,
        pkceMethod: 'plain',
      );

      expect(registration.validate(), contains('pkce_method_must_be_s256'));
    });

    test(
      'models lifecycle operations without carrying credential material',
      () {
        const request = AuthenticationBrokerOperation(
          providerId: 'google_drive',
          credentialReference: 'credref:google-drive:primary',
          operation: AuthenticationBrokerOperationKind.reauthenticate,
          redirectUri: 'https://app.example/oauth/callback',
        );

        expect(request.validate(), isEmpty);
        expect(request.toRedactedJson(), <String, Object?>{
          'provider_id': 'google_drive',
          'credential_reference': 'credref:google-drive:primary',
          'operation': 'reauthenticate',
          'redirect_uri': 'https://app.example/oauth/callback',
        });
      },
    );

    test('canonical manifest passes the fail-closed gate', () {
      final report = const Sprint119AuthenticationBrokerGate().evaluate();
      expect(report.state, Sprint119AuthenticationBrokerState.pass);
      expect(report.verdict, 'AUTHENTICATION_BROKER_CONTRACT_COMPLETE_LOCAL');
      expect(report.diagnostics, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
      expect(
        report.acceptance,
        Sprint119AuthenticationBrokerContract.requiredAcceptance,
      );
    });

    test('emitted manifest declares every required acceptance dimension', () {
      final file = File(Sprint119AuthenticationBrokerContract.manifestPath);
      expect(file.existsSync(), isTrue);
      final record =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(record['canonical_step'], '119.7');
      expect(record['acceptance'], isA<Map<String, dynamic>>());
      for (final name
          in Sprint119AuthenticationBrokerContract.requiredAcceptance) {
        expect(
          (record['acceptance'] as Map<String, dynamic>)[name],
          isA<Map<String, dynamic>>(),
        );
      }
      expect(record['operations'], isA<List<dynamic>>());
    });

    test('unknown top-level fields fail closed', () {
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        _record(extraKey: true),
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(report.diagnostics, contains('unknown_field:unexpected'));
    });

    test('unknown acceptance keys fail closed', () {
      final acceptance = _acceptance()
        ..['saml'] = <String, dynamic>{
          'description': 'not part of this contract',
        };
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        _record(acceptance: acceptance),
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(report.diagnostics, contains('unknown_acceptance:saml'));
    });

    test('unsupported schema version blocks validation', () {
      final record = _record()..['schema_version'] = 2;
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119AuthenticationBrokerState.blocked);
      expect(
        report.verdict,
        'AUTHENTICATION_BROKER_SCHEMA_VERSION_UNSUPPORTED',
      );
    });

    test('missing acceptance dimension blocks instead of passing', () {
      final acceptance = _acceptance()..remove('revoke');
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        _record(acceptance: acceptance),
      );
      expect(report.state, Sprint119AuthenticationBrokerState.blocked);
      expect(report.diagnostics, contains('acceptance_missing:revoke'));
    });

    test('acceptance entries without a description fail closed', () {
      final acceptance = _acceptance();
      acceptance['refresh'] = <String, dynamic>{'claim_boundary': 'x'};
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        _record(acceptance: acceptance),
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(
        report.diagnostics,
        contains('acceptance_description_missing:refresh'),
      );
    });

    test('acceptance claim boundaries must stay deferred', () {
      final acceptance = _acceptance('Live and certified.');
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        _record(acceptance: acceptance),
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(
        report.diagnostics,
        contains('acceptance_claim_not_deferred:oidc'),
      );
    });

    test('registration fields are required and cannot be dropped', () {
      final record = _record()
        ..['registration_fields'] = <String>[
          'provider_id',
          'protocol',
          'authorization_endpoint',
          'token_endpoint',
          'redirect_uris',
          'credential_reference',
          'scopes',
          'supports_refresh',
          'supports_reauthentication',
          'supports_revocation',
        ];
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(
        report.diagnostics,
        contains('registration_field_missing:pkce_required'),
      );
      expect(
        report.diagnostics,
        contains('registration_field_missing:pkce_method'),
      );
    });

    test('all lifecycle operations are required', () {
      final record = _record()..['operations'] = <String>['authorize'];
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(report.diagnostics, contains('operation_missing:revoke'));
      expect(report.diagnostics, contains('operation_missing:refresh'));
      expect(report.diagnostics, contains('operation_missing:reauthenticate'));
    });

    test('claim boundary must remain deferred and non-empty', () {
      final record = _record()..['claim_boundary'] = <String>[];
      final report = const Sprint119AuthenticationBrokerGate().evaluateRecord(
        record,
      );
      expect(report.state, Sprint119AuthenticationBrokerState.fail);
      expect(report.diagnostics, contains('claim_boundary_missing'));
    });
  });
}
