import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_permission_consent.dart';

final DateTime t0 = DateTime.utc(2026, 3, 1, 12);

/// Builds a well-formed read-only declaration.
PermissionDeclaration declaration({
  String permissionRef = 'permref:alpha:read-workspace',
  List<PermissionScope> scopes = const <PermissionScope>[PermissionScope.read],
  String purpose = 'Show your workspace name on the connection card',
  List<DataCategory> dataCategories = const <DataCategory>[
    DataCategory.workspaceMetadata,
  ],
  String destination = 'api.alpha.example',
  DestinationKind destinationKind = DestinationKind.firstParty,
  bool crossOrgConsent = false,
  GrantDuration duration = GrantDuration.thirtyDays,
  RevocationPath revocation = const RevocationPath(
    handle: 'revokeref:alpha:revoke-workspace',
    immediate: true,
    graceMinutes: 0,
  ),
  LeastPrivilegeAttestation? leastPrivilege,
}) {
  return PermissionDeclaration(
    permissionRef: permissionRef,
    scopes: scopes,
    purpose: purpose,
    dataCategories: dataCategories,
    destination: destination,
    destinationKind: destinationKind,
    crossOrgConsent: crossOrgConsent,
    duration: duration,
    revocation: revocation,
    leastPrivilege:
        leastPrivilege ??
        LeastPrivilegeAttestation(
          justification: 'Read access is needed to render the connection card',
          scopeIsMinimal: true,
          reviewedAt: t0,
        ),
  );
}

void main() {
  group('119.22 permission declaration and consent contract', () {
    test('declares the seven canonical fields in canonical order', () {
      expect(PermissionDeclarationContract.canonicalStep, '119.22');
      expect(PermissionDeclarationContract.requiredFields, <String>[
        'permission',
        'purpose',
        'data_categories',
        'destination',
        'duration',
        'revocation',
        'least_privilege',
      ]);
      expect(declaration().toJson().keys.toList(), <String>[
        'permission',
        'purpose',
        'data_categories',
        'destination',
        'duration',
        'revocation',
        'least_privilege',
      ]);
      expect(declaration().toJson()['data_categories'], <String>[
        'workspace_metadata',
      ]);
      expect(declaration().toJson()['duration'], '30d');
    });

    test('canonical manifest satisfies the contract', () {
      expect(
        PermissionDeclarationContract.validateCanonicalManifest(),
        isEmpty,
      );
    });

    test('manifest missing a field or reordering fields is refused', () {
      final missing = <String, dynamic>{
        'canonical_step': '119.22',
        'unknown_field_policy': 'REJECT',
        'required_fields': <String, dynamic>{
          'permission': <String, dynamic>{},
          'purpose': <String, dynamic>{},
          'data_categories': <String, dynamic>{},
          'destination': <String, dynamic>{},
          'duration': <String, dynamic>{},
          'revocation': <String, dynamic>{},
        },
      };
      expect(PermissionDeclarationContract.validateManifest(missing), <String>[
        'field_missing:least_privilege',
      ]);

      final reordered = <String, dynamic>{
        'canonical_step': '119.22',
        'unknown_field_policy': 'REJECT',
        'required_fields': <String, dynamic>{
          'permission': <String, dynamic>{},
          'data_categories': <String, dynamic>{},
          'purpose': <String, dynamic>{},
          'destination': <String, dynamic>{},
          'duration': <String, dynamic>{},
          'revocation': <String, dynamic>{},
          'least_privilege': <String, dynamic>{},
        },
      };
      expect(
        PermissionDeclarationContract.validateManifest(reordered),
        <String>['field_order_invalid'],
      );
    });

    test('a well-formed read-only declaration validates clean', () {
      expect(declaration().validate(), isEmpty);
      expect(declaration().mutates, isFalse);
    });

    test('a missing or vague purpose is refused', () {
      expect(
        declaration(purpose: '   ').validate(),
        contains('purpose_missing'),
      );
      expect(
        declaration(purpose: 'unspecified').validate(),
        contains('purpose_vague'),
      );
      expect(
        declaration(purpose: 'Anything').validate(),
        contains('purpose_vague'),
      );
      expect(
        declaration(purpose: '<b>show card</b>').validate(),
        contains('purpose_not_plain'),
      );
      expect(
        declaration(purpose: List<String>.filled(300, 'a').join()).validate(),
        contains('purpose_too_long'),
      );
    });

    test('admin is refused outright and an unknown scope is refused', () {
      expect(
        declaration(
          scopes: const <PermissionScope>[PermissionScope.admin],
        ).validate(),
        contains('admin_scope_refused'),
      );
      expect(
        declaration(
          scopes: const <PermissionScope>[PermissionScope.unknown],
        ).validate(),
        contains('permission_unknown'),
      );
      expect(
        declaration(scopes: const <PermissionScope>[]).validate(),
        contains('permission_scope_empty'),
      );
      expect(
        declaration(
          scopes: const <PermissionScope>[
            PermissionScope.read,
            PermissionScope.read,
          ],
        ).validate(),
        contains('permission_scope_duplicate'),
      );
      expect(
        declaration(permissionRef: 'alpha').validate(),
        contains('permission_ref_invalid'),
      );
    });

    test('data categories must be a non-empty, known, duplicate-free set', () {
      expect(
        declaration(dataCategories: const <DataCategory>[]).validate(),
        contains('data_categories_empty'),
      );
      expect(
        declaration(
          dataCategories: const <DataCategory>[DataCategory.unknown],
        ).validate(),
        contains('data_category_unknown'),
      );
      expect(
        declaration(
          dataCategories: const <DataCategory>[
            DataCategory.novelContent,
            DataCategory.novelContent,
          ],
        ).validate(),
        contains('data_category_duplicate'),
      );
    });

    test('a plaintext destination and a malformed host are refused', () {
      expect(
        declaration(destination: 'http://api.alpha.example').validate(),
        contains('destination_not_tls'),
      );
      expect(
        declaration(destination: 'not a host').validate(),
        contains('destination_invalid'),
      );
      expect(
        declaration(destinationKind: DestinationKind.unknown).validate(),
        contains('destination_unknown'),
      );
    });

    test('a third-party destination needs explicit cross-org consent', () {
      expect(
        declaration(
          destination: 'api.partner.example',
          destinationKind: DestinationKind.thirdParty,
        ).validate(),
        contains('cross_org_not_declared'),
      );
      expect(
        declaration(
          destination: 'api.partner.example',
          destinationKind: DestinationKind.thirdParty,
          crossOrgConsent: true,
        ).validate(),
        isEmpty,
      );
    });

    test(
      'a mutating grant must be bounded and a local destination needs no host',
      () {
        expect(
          declaration(
            scopes: const <PermissionScope>[PermissionScope.write],
            duration: GrantDuration.untilRevoked,
          ).validate(),
          contains('write_requires_bounded_grant'),
        );
        expect(
          declaration(
            scopes: const <PermissionScope>[PermissionScope.read],
            duration: GrantDuration.untilRevoked,
          ).validate(),
          isEmpty,
        );
        expect(
          declaration(
            scopes: const <PermissionScope>[PermissionScope.write],
            duration: GrantDuration.unknown,
          ).validate(),
          contains('duration_invalid'),
        );
        expect(
          declaration(
            destination: '',
            destinationKind: DestinationKind.local,
          ).validate(),
          isEmpty,
        );
      },
    );

    test('revocation must be immediate, bounded, and well formed', () {
      expect(
        declaration(
          revocation: const RevocationPath(
            handle: 'revokeref:alpha:revoke-workspace',
            immediate: false,
            graceMinutes: 0,
          ),
        ).validate(),
        contains('revocation_not_immediate'),
      );
      expect(
        declaration(
          revocation: const RevocationPath(
            handle: 'revokeref:alpha:revoke-workspace',
            immediate: true,
            graceMinutes: 60,
          ),
        ).validate(),
        contains('revocation_grace_too_long'),
      );
      expect(
        declaration(
          revocation: const RevocationPath(
            handle: 'revoke-workspace',
            immediate: true,
            graceMinutes: 0,
          ),
        ).validate(),
        contains('revocation_ref_invalid'),
      );
    });

    test('least privilege must be attested and justified', () {
      expect(
        declaration(
          leastPrivilege: LeastPrivilegeAttestation(
            justification: 'needed',
            scopeIsMinimal: false,
            reviewedAt: t0,
          ),
        ).validate(),
        contains('least_privilege_not_attested'),
      );
      expect(
        declaration(
          leastPrivilege: LeastPrivilegeAttestation(
            justification: '  ',
            scopeIsMinimal: true,
            reviewedAt: t0,
          ),
        ).validate(),
        contains('justification_missing'),
      );
      expect(
        declaration(
          leastPrivilege: LeastPrivilegeAttestation(
            justification: '<script>x</script>',
            scopeIsMinimal: true,
            reviewedAt: t0,
          ),
        ).validate(),
        contains('justification_not_plain'),
      );
    });

    test('consent is deny-by-default and a grant needs a prior request', () {
      final ledger = ConsentLedger();
      final perm = 'permref:alpha:read-workspace';

      expect(ledger.stateOf(perm), ConsentState.none);
      expect(ledger.isUsable(perm, now: t0), isFalse);
      expect(ledger.grant(perm, now: t0), <String>['consent_not_requested']);

      expect(ledger.request(perm, declaration()), isEmpty);
      expect(ledger.stateOf(perm), ConsentState.requested);
      expect(ledger.isUsable(perm, now: t0), isFalse);

      expect(ledger.grant(perm, now: t0), isEmpty);
      expect(ledger.stateOf(perm, now: t0), ConsentState.granted);
      expect(ledger.isUsable(perm, now: t0), isTrue);
    });

    test('an invalid declaration can never be requested', () {
      final ledger = ConsentLedger();
      final perm = 'permref:alpha:read-workspace';

      final diagnostics = ledger.request(
        perm,
        declaration(scopes: const <PermissionScope>[PermissionScope.admin]),
      );
      expect(diagnostics, contains('admin_scope_refused'));
      expect(ledger.stateOf(perm), ConsentState.none);
    });

    test('revocation is immediate, idempotent, and always possible', () {
      final ledger = ConsentLedger();
      final perm = 'permref:alpha:read-workspace';

      ledger.request(perm, declaration());
      ledger.grant(perm, now: t0);
      ledger.revoke(perm);

      expect(ledger.stateOf(perm, now: t0), ConsentState.revoked);
      expect(ledger.isUsable(perm, now: t0), isFalse);

      ledger.revoke(perm);
      expect(ledger.stateOf(perm, now: t0), ConsentState.revoked);

      expect(ledger.grant(perm, now: t0), <String>[
        'regrant_requires_new_request',
      ]);

      final unknown = 'permref:alpha:never-seen';
      ledger.revoke(unknown);
      expect(ledger.stateOf(unknown, now: t0), ConsentState.revoked);
      expect(ledger.isUsable(unknown, now: t0), isFalse);
    });

    test('a denied permission cannot be re-granted without a new request', () {
      final ledger = ConsentLedger();
      final perm = 'permref:alpha:read-workspace';

      ledger.request(perm, declaration());
      expect(ledger.deny(perm), isEmpty);
      expect(ledger.stateOf(perm, now: t0), ConsentState.denied);
      expect(ledger.isUsable(perm, now: t0), isFalse);
      expect(ledger.grant(perm, now: t0), <String>[
        'regrant_requires_new_request',
      ]);
    });

    test('a bounded grant expires and an unbounded read grant does not', () {
      final ledger = ConsentLedger();
      final bounded = 'permref:alpha:read-workspace';
      final unbounded = 'permref:alpha:read-workspace-long';

      ledger.request(bounded, declaration(duration: GrantDuration.oneHour));
      ledger.grant(bounded, now: t0);
      expect(
        ledger.isUsable(bounded, now: t0.add(const Duration(minutes: 59))),
        isTrue,
      );
      expect(
        ledger.isUsable(bounded, now: t0.add(const Duration(hours: 2))),
        isFalse,
      );
      expect(
        ledger.stateOf(bounded, now: t0.add(const Duration(hours: 2))),
        ConsentState.expired,
      );

      ledger.request(
        unbounded,
        declaration(duration: GrantDuration.untilRevoked),
      );
      ledger.grant(unbounded, now: t0);
      expect(
        ledger.isUsable(unbounded, now: t0.add(const Duration(days: 365))),
        isTrue,
      );
    });

    test('references are never rendered and diagnostics are redacted', () {
      final json = declaration().toJson();
      expect(json['permission'], isA<Map<String, Object?>>());
      expect(
        (json['permission']! as Map<String, Object?>)['ref'],
        '[REDACTED]',
      );
      expect(
        (json['revocation']! as Map<String, Object?>)['handle'],
        '[REDACTED]',
      );
      expect(
        declaration().toString(),
        isNot(contains('permref:alpha:read-workspace')),
      );
      expect(
        PermissionDeclarationContract.redact(
          'failed permref:alpha:read-workspace',
        ),
        'failed [REDACTED]',
      );
    });
  });
}
