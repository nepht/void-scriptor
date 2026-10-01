/// 117.31 — OAuth Reauth & Revocation Validation.
///
/// Mengukur tujuh `required_evidence` kanonik step `117.31` (`expiry`,
/// `rotation`, `reauth`, `provider_revoke`, `disconnect`, `cleanup`,
/// `local_data_preserved`) sebagai kondisi yang diukur pada seam yang di-ship,
/// bukan pada deklarasinya.
///
/// Lima defect gagal-tertutup di kode yang di-ship ditemukan lewat probe yang
/// mencetak fakta mentah, lalu diperbaiki:
///
/// 1. `cleanup` buta pada `AccountSecureTokenVault.revoke`. Memperbaiki
///    store copy tidak menyentuh clipboard copy. Yang memanggil `vault.revoke`
///    langsung — `payment_methods.remove`, `sprint_117_provider_rollback_drill`
///    — tidak melewati `AccountCenterApiKeysManager`, satu-satunya tempat yang
///    pernah memanggil `clearClipboard`. Setelah revoke, satu-satunya salinan
///    token yang tersisa adalah yang ada di clipboard dan masih bisa dipakai
///    sampai window 30 detik habis dengan sendirinya.
/// 2. `disconnect` tak terukur pada `AccountConnectedAccountsManagement.unlink`.
///    Mengembalikan `bool` yang `true` untuk setiap disconnect terkonfirmasi,
///    jadi baris yang provider-nya sudah dicabut dan baris yang provider-nya
///    tidak pernah diberi tahu terlihat identik. Tidak ada revoker yang bisa
///    disuntikkan sama sekali.
/// 3. Jejak audit tidak bisa membedakan apa yang dihapus. `save`, `read`, dan
///    `revoke` menghasilkan baris yang identik karakter demi karakter
///    (`revoke|acct`) tanpa `kind` maupun `secretId`, sehingga audit tidak bisa
///    menyatakan kunci mana dari beberapa kunci dalam satu akun yang dihapus.
/// 4. `expiry` tidak bisa dinilai. Grant yang terinstall tidak punya accessor
///    masa berlaku sama sekali, dan `OAuthTokenResponse` menerima kedaluwarsa
///    `2099-01-01` lalu menyimpannya tanpa komentar — koneksi yang dilaporkan
///    sehat selama 73 tahun tanpa tekanan kedaluwarsa yang bisa ditindak.
/// 5. `local_data_preserved` hanya klaim. `hasLocalData` adalah asersi
///    pemanggil tanpa scope; seam ini tidak punya pandangan sama sekali ke
///    project store, jadi `true` bisa datang dari call site tanpa data apa pun
///    yang bisa dihapus.
///
/// Blok validasi membuat gate gagal-tertutup: `no_checks`, `missing_area`,
/// `area_without_pass`, `vacuous`, `duplicate_check`, dan `unknown_area`
/// semuanya berarti `pass == false`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_secure_token_vault.dart';
import 'package:void_scriptor/features/account/domain/account_center_token_expiry_reauthentication_ux.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_oauth_reauth_revocation_validation.dart';

/// Jam injeksi tetap: tidak ada wall clock di seluruh test.
final DateTime kNow = DateTime.utc(2026, 10, 1, 12);

class _Store implements CredentialStore {
  final Map<String, String> values = <String, String>{};
  @override
  Future<void> write({required String key, required String value}) async =>
      values[key] = value;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _Broker implements OAuthTokenBroker {
  _Broker(this.onExchange, this.onRefresh, this.onRevoke);
  final OAuthTokenResponse Function() onExchange;
  final OAuthTokenResponse Function() onRefresh;
  final void Function(OAuthTokenGrant) onRevoke;

  @override
  Future<OAuthTokenResponse> exchange(OAuthTokenExchangeRequest r) async =>
      onExchange();
  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest r) async =>
      onRefresh();
  @override
  Future<void> revoke(OAuthTokenGrant g) async => onRevoke(g);
}

ProviderConnectorEntry _connector() => ProviderConnectorEntry(
  providerId: 'openai',
  displayName: 'OpenAI',
  category: ProviderConnectorCategory.identity,
  authType: ProviderAuthType.oauth2Pkce,
  capabilities: const <ProviderConnectorCapability>{
    ProviderConnectorCapability.identity,
  },
  availability: ProviderConnectorAvailability.available,
  regions: const <ProviderRegion>{ProviderRegion.global},
  connectorVersion: 'test-v1',
  permissions: const <ProviderPermission>{ProviderPermission.accountMetadata},
);

OAuthProviderConfiguration _config() => OAuthProviderConfiguration(
  connector: _connector(),
  authorizationEndpoint: Uri.parse('https://auth.example/authorize'),
  redirectUri: Uri.parse('vscriptor://oauth/callback'),
  scopes: const <String>{'identity'},
);

OAuthScopeConsent _consent() => OAuthScopeConsent(
  requestedScopes: const <String>{'identity'},
  grantedScopes: const <String>{'identity'},
  explicitlyApproved: true,
);

OAuthTokenResponse _response({
  String access = 'ACCESS-1',
  String refresh = 'REFRESH-1',
  Duration lifetime = const Duration(hours: 1),
}) => OAuthTokenResponse(
  providerId: 'openai',
  providerAccountId: 'acc-1',
  displayName: 'acc-1',
  accessToken: access,
  refreshToken: refresh,
  accessTokenExpiresAt: kNow.add(lifetime),
  issuedAt: kNow,
  scopes: const <String>{'identity'},
);

AccountOAuthFlow _flow({
  OAuthTokenResponse Function()? exchange,
  OAuthTokenResponse Function()? refresh,
  void Function(OAuthTokenGrant)? onRevoke,
  List<OAuthTokenGrant>? revoked,
}) {
  var refreshCalls = 0;
  return AccountOAuthFlow(
    broker: _Broker(
      exchange ?? () => _response(),
      // Pre-increment: the first rotated token must already differ from the
      // `REFRESH-1` installed by the exchange. Returning the same refresh
      // token is exactly the unrotated case the flow refuses, so a post-increment
      // counter here would make every default rotation fail validation instead
      // of measuring it.
      refresh ??
          () {
            refreshCalls++;
            return _response(
              access: 'ACCESS-${refreshCalls + 1}',
              refresh: 'REFRESH-${refreshCalls + 1}',
            );
          },
      onRevoke ?? (g) => revoked?.add(g),
    ),
    randomBytes: (n) => List<int>.filled(n, 7),
    clock: () => kNow,
  );
}

Future<LinkedIdentityResult> _link(AccountOAuthFlow flow) async {
  final request = flow.beginAuthorization(
    configuration: _config(),
    consent: _consent(),
  );
  return flow.completeAuthorization(
    callback: Uri.parse(
      'vscriptor://oauth/callback?code=abc&state=${request.state}'
      '&nonce=${request.nonce}',
    ),
  );
}

AccountConnectedAccount _account({
  String connectionId = 'openai/acc-1',
  bool reauthRequired = false,
}) => AccountConnectedAccount(
  connectionId: connectionId,
  providerId: 'openai',
  accountLabel: 'acc-1',
  scopes: const <String>{'identity'},
  connectionState: AccountConnectionState.connected,
  healthState: AccountHealthState.healthy,
  lastCheckedAt: kNow,
  reauthRequired: reauthRequired,
);

AccountSecureTokenVault _vault({
  required _Store store,
  required List<String> clipboard,
  required DateTime now,
  List<VaultAuditEvent>? audit,
}) => AccountSecureTokenVault(
  store: store,
  reauthenticate: () async => true,
  clipboardWriter: (value) async => clipboard.add(value),
  clock: () => now,
  auditSink: audit?.add,
  clipboardTimeout: const Duration(seconds: 30),
);

void main() {
  group('117.31 defect fixes, measured against the shipped seams', () {
    test('revoking a secret wipes its clipboard copy immediately', () async {
      // Fakta terukur (probe 117.31 #A): setelah vault.revoke, store benar
      //-benar kosong tetapi clipboard masih memegang 'PAYMENT-TOKEN-ABC'
      // selama window 30 detik penuh.
      final store = _Store();
      final clipboard = <String>[];
      var now = kNow;
      final audit = <VaultAuditEvent>[];
      final vault = _vault(
        store: store,
        clipboard: clipboard,
        now: now,
        audit: audit,
      );
      await vault.save(
        accountId: 'acct',
        secret: 'PAYMENT-TOKEN-ABC',
        kind: VaultSecretKind.paymentMethodToken,
        secretId: 'pm-1',
      );
      expect(
        await vault.copyToClipboard(
          accountId: 'acct',
          kind: VaultSecretKind.paymentMethodToken,
          secretId: 'pm-1',
        ),
        isTrue,
      );
      expect(clipboard, <String>['PAYMENT-TOKEN-ABC']);

      await vault.revoke(
        accountId: 'acct',
        kind: VaultSecretKind.paymentMethodToken,
        secretId: 'pm-1',
      );

      expect(store.values.containsValue('PAYMENT-TOKEN-ABC'), isFalse);
      // Tidak boleh ada salinan yang bisa dipakai tersisa.
      expect(clipboard, <String>['PAYMENT-TOKEN-ABC', '']);
      expect(clipboard.where((v) => v == 'PAYMENT-TOKEN-ABC').length, 1);
      expect(clipboard.last, isEmpty);

      // Jejak audit harus bisa bilang apa yang dihapus.
      final revokeRow = audit.last;
      expect(revokeRow.action, 'revoke');
      expect(revokeRow.kind, 'payment_method');
      expect(revokeRow.secretId, 'pm-1');
      expect(revokeRow.secret, isNull);
      expect(now, kNow);
    });

    test(
      'revoking one key never wipes an unrelated key the user copied',
      () async {
        // Kounter-n.cancel: wipe tak bersyarat akan menghapus kunci lain yang
        // masih hidup. Dipakai justru untuk memastikan presisi.
        final store = _Store();
        final clipboard = <String>[];
        final vault = _vault(store: store, clipboard: clipboard, now: kNow);
        await vault.save(
          accountId: 'acct',
          secret: 'KEY-A',
          kind: VaultSecretKind.apiKey,
          secretId: 'primary',
        );
        await vault.save(
          accountId: 'acct',
          secret: 'PAY-1',
          kind: VaultSecretKind.paymentMethodToken,
          secretId: 'pm-1',
        );
        await vault.copyToClipboard(
          accountId: 'acct',
          kind: VaultSecretKind.apiKey,
          secretId: 'primary',
        );

        await vault.revoke(
          accountId: 'acct',
          kind: VaultSecretKind.paymentMethodToken,
          secretId: 'pm-1',
        );

        expect(clipboard, <String>['KEY-A']);
        expect(
          await vault.read(
            accountId: 'acct',
            kind: VaultSecretKind.apiKey,
            secretId: 'primary',
          ),
          'KEY-A',
        );
      },
    );

    test(
      'a disconnect reports whether the provider was actually told',
      () async {
        // Fakta terukur (probe 117.31 #C): unlink(confirmed: true) memakai
        // revoker yang melempar -> baris hilang, provider tidak pernah diberi
        // tahu, dan pemanggil hanya menerima `true`.
        final calls = <String>[];
        final manager = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[_account()],
          providerRevoker: (connectionId, providerId) async {
            calls.add(connectionId);
            throw StateError('provider 500');
          },
        );

        final result = await manager.unlink('openai/acc-1', confirmed: true);

        expect(calls, <String>['openai/acc-1']);
        expect(result.providerRevokeAttempted, isTrue);
        expect(result.providerRevoked, isFalse);
        expect(result.localRemoved, isFalse);
        // Baris lokal bertahan supaya ada yang bisa diulang.
        expect(manager.connections, hasLength(1));
        expect(result.summary, isNot(contains('500')));
      },
    );

    test(
      'a local-only disconnect is distinguishable from a revoked one',
      () async {
        final localOnly = await AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[_account()],
        ).unlink('openai/acc-1', confirmed: true);
        final revoked = await AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[_account()],
          providerRevoker: (connectionId, providerId) async => true,
        ).unlink('openai/acc-1', confirmed: true);

        expect(localOnly.localRemoved, isTrue);
        expect(localOnly.providerRevokeAttempted, isFalse);
        expect(localOnly.providerRevoked, isFalse);
        expect(revoked.localRemoved, isTrue);
        expect(revoked.providerRevokeAttempted, isTrue);
        expect(revoked.providerRevoked, isTrue);
        expect(revoked.isComplete, isTrue);
        expect(revoked.toJson()['provider_revoke_attempted'], isTrue);
      },
    );

    test('an installed grant can be asked whether it is expired', () async {
      // Fakta terukur (probe 117.31 #E): grant terinstall tidak punya
      // accessor masa berlaku; yang ada hanya field mentah.
      final linked = await _link(_flow());
      final grant = linked.tokenGrant;

      expect(grant.isExpiredAt(kNow), isFalse);
      expect(grant.isExpiredAt(grant.accessTokenExpiresAt), isFalse);
      expect(
        grant.isExpiredAt(
          grant.accessTokenExpiresAt.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(grant.accessTokenLifetime, const Duration(hours: 1));
      expect(grant.installedAt, kNow);
      expect(grant.remainingAt(grant.accessTokenExpiresAt), Duration.zero);
      expect(grant.hasImplausibleLifetime, isFalse);
      expect(grant.toString(), contains('expires:'));
      expect(grant.toString(), isNot(contains('ACCESS-1')));
    });

    test(
      'a provider-stated lifetime beyond any real token is refused',
      () async {
        final flow = _flow(
          exchange: () => _response(lifetime: const Duration(days: 365 * 40)),
        );

        var code = 'NONE';
        try {
          await _link(flow);
        } on OAuthFlowException catch (e) {
          code = e.code.name;
        }

        expect(code, 'implausibleTokenLifetime');
        expect(flow.linkedIdentities, isEmpty);
      },
    );

    test('a local-data claim must name what it covers', () {
      // Fakta terukur (probe 117.31 #D): localDataPreserved selalu true
      // dari call site mana pun, tanpa scope apa pun.
      final unscoped = AccountCenterTokenExpiryReauthenticationUx.expired(
        providerId: 'openai',
        accountLabel: 'acc-1',
        affectedCapabilities: const <String>['chat'],
        hasLocalData: true,
      );
      expect(unscoped.localDataPreserved, isTrue);
      expect(unscoped.hasLocalDataScope, isFalse);
      expect(unscoped.localDataPreservedWithScope, isFalse);

      final scoped = AccountCenterTokenExpiryReauthenticationUx.expired(
        providerId: 'openai',
        accountLabel: 'acc-1',
        affectedCapabilities: const <String>['chat'],
        hasLocalData: true,
        localDataScope: 'the local project store',
      );
      expect(scoped.localDataPreservedWithScope, isTrue);
      expect(scoped.scopedNotice, contains('the local project store'));
      // Scope harus ikut terbawa ke kedua turunan.
      expect(scoped.revoked().localDataScope, 'the local project store');
      expect(
        scoped.reauthenticated().localDataScope,
        'the local project store',
      );
      expect(scoped.revoked().localDataPreservedWithScope, isTrue);
    });

    test('a failed rotation leaves the previous generation current', () async {
      final revoked = <OAuthTokenGrant>[];
      final flow = _flow(
        refresh: () => _response(access: 'ACCESS-2', refresh: 'REFRESH-1'),
        revoked: revoked,
      );
      final linked = await _link(flow);

      await expectLater(
        flow.rotateTokens(currentGrant: linked.tokenGrant),
        throwsA(
          isA<OAuthFlowException>().having(
            (e) => e.code.name,
            'code',
            'refreshTokenNotRotated',
          ),
        ),
      );

      expect(revoked, isEmpty);
      expect(flow.linkedIdentities.single.tokenGeneration, 1);
    });
  });

  group('117.31 gate fails closed', () {
    late List<Sprint117OAuthRevocationCheck> checks;

    setUp(() async {
      checks = await _measuredChecks();
    });

    test('all seven canonical areas are measured and pass', () {
      final result = Sprint117OAuthRevocationValidation.evaluate(checks);

      expect(result.checks.length, greaterThanOrEqualTo(20));
      expect(result.failures, isEmpty, reason: result.failures.join(', '));
      expect(result.openItems, isEmpty);
      expect(result.pass, isTrue);

      for (final area in Sprint117OAuthRevocationValidation.requiredAreas) {
        expect(
          result.checks.where((c) => c.area == area && c.status.name == 'pass'),
          isNotEmpty,
          reason: 'area $area must carry at least one passing measurement',
        );
      }
      for (final check in result.checks) {
        expect(check.declared.trim(), isNotEmpty, reason: check.code);
        expect(check.observed.trim(), isNotEmpty, reason: check.code);
      }
    });

    test('the verdict records the measured checks', () {
      final json = Sprint117OAuthRevocationValidation.evaluate(checks).toJson();

      expect(json['canonical_step'], '117.31');
      expect(json['verdict'], 'OAUTH_REAUTH_REVOCATION_VALIDATED_LOCAL');
      expect(json['pass'], isTrue);
      expect(json['required_areas'], <String>[
        'expiry',
        'rotation',
        'reauth',
        'provider_revoke',
        'disconnect',
        'cleanup',
        'local_data_preserved',
      ]);
    });

    test('an empty check list fails', () {
      final result = Sprint117OAuthRevocationValidation.evaluate(
        const <Sprint117OAuthRevocationCheck>[],
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('no_checks'));
    });

    test('a missing canonical area fails', () {
      final result = Sprint117OAuthRevocationValidation.evaluate(
        <Sprint117OAuthRevocationCheck>[
          Sprint117OAuthRevocationCheck.pass_(
            area: 'expiry',
            check: 'one',
            declared: 'declared one',
            observed: 'observed one',
          ),
        ],
      );

      expect(result.pass, isFalse);
      expect(result.failures.length, 6);
      for (final area in Sprint117OAuthRevocationValidation.requiredAreas) {
        if (area == 'expiry') continue;
        expect(result.failures, contains('missing_area:$area'));
      }
    });

    test('an area with no passing check fails', () {
      final checks = <Sprint117OAuthRevocationCheck>[
        for (final area in Sprint117OAuthRevocationValidation.requiredAreas)
          Sprint117OAuthRevocationCheck.pass_(
            area: area,
            check: 'ok_$area',
            declared: 'declared $area check',
            observed: 'observed $area check',
          ),
        Sprint117OAuthRevocationCheck.violation(
          area: 'cleanup',
          check: 'clipboard_wiped_on_revoke',
          declared: 'Revoking a secret wipes its clipboard copy.',
          observed: 'clipboard writer was never called at revoke time.',
        ),
      ];

      final result = Sprint117OAuthRevocationValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('area_without_pass:cleanup'));
    });

    test('a duplicate check fails', () {
      final checks = <Sprint117OAuthRevocationCheck>[
        for (final area in Sprint117OAuthRevocationValidation.requiredAreas)
          Sprint117OAuthRevocationCheck.pass_(
            area: area,
            check: 'ok_$area',
            declared: 'declared $area',
            observed: 'observed $area',
          ),
        Sprint117OAuthRevocationCheck.pass_(
          area: 'expiry',
          check: 'ok_expiry',
          declared: 'declared duplicate',
          observed: 'observed duplicate',
        ),
      ];

      final result = Sprint117OAuthRevocationValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('duplicate_check:expiry:ok_expiry'));
    });

    test('an unknown area fails', () {
      final checks = <Sprint117OAuthRevocationCheck>[
        for (final area in Sprint117OAuthRevocationValidation.requiredAreas)
          Sprint117OAuthRevocationCheck.pass_(
            area: area,
            check: 'ok_$area',
            declared: 'declared $area',
            observed: 'observed $area',
          ),
        Sprint117OAuthRevocationCheck.pass_(
          area: 'not_canonical',
          check: 'stray',
          declared: 'declared stray',
          observed: 'observed stray',
        ),
      ];

      final result = Sprint117OAuthRevocationValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('unknown_area:not_canonical'));
    });

    test('a vacuous check fails', () {
      final checks = <Sprint117OAuthRevocationCheck>[
        for (final area in Sprint117OAuthRevocationValidation.requiredAreas)
          Sprint117OAuthRevocationCheck.pass_(
            area: area,
            check: 'ok_$area',
            declared: 'declared $area',
            observed: 'observed $area',
          ),
        Sprint117OAuthRevocationCheck.pass_(
          area: 'expiry',
          check: 'empty_observed',
          declared: 'An expiry statement always carries a measured value.',
          observed: '   ',
        ),
      ];

      final result = Sprint117OAuthRevocationValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('vacuous:expiry:empty_observed'));
    });
  });
}

/// The seven canonical measurements, taken from the shipped seams.
Future<List<Sprint117OAuthRevocationCheck>> _measuredChecks() async {
  final checks = <Sprint117OAuthRevocationCheck>[];

  // -- expiry ---------------------------------------------------------------
  final expiryFlow = _flow();
  final expiryLinked = await _link(expiryFlow);
  final grant = expiryLinked.tokenGrant;
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'expiry',
      check: 'an_installed_grant_answers_whether_it_expired',
      declared:
          'An installed grant exposes its own expiry verdict, not just the raw '
          'timestamp field.',
      observed:
          'isExpiredAt(now)=${grant.isExpiredAt(kNow)} '
          'isExpiredAt(expiry)=${grant.isExpiredAt(grant.accessTokenExpiresAt)} '
          'isExpiredAt(expiry+1s)='
          '${grant.isExpiredAt(grant.accessTokenExpiresAt.add(const Duration(seconds: 1)))}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'expiry',
      check: 'the_expiry_boundary_is_not_treated_as_expired',
      declared:
          'A token is expired only after its expiry instant, never at it, so a '
          'live token is not rotated early.',
      observed:
          'remaining(expiry)=${grant.remainingAt(grant.accessTokenExpiresAt)} '
          'isExpiredAt(expiry)=${grant.isExpiredAt(grant.accessTokenExpiresAt)}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'expiry',
      check: 'an_implausible_stated_lifetime_is_refused',
      declared:
          'A provider response stating a lifetime longer than any token may '
          'live is rejected rather than stored as a healthy connection.',
      observed: 'outcome=${(await _longLivedTokenOutcome()).summary}',
      note:
          'Before the fix a 2099 expiry was accepted, installed, and reported '
          'healthy for 73 years.',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'expiry',
      check: 'the_grant_records_when_it_was_installed',
      declared:
          'A grant records its install instant so its stated lifetime can be '
          'judged against a bound.',
      observed:
          'installedAt=${grant.installedAt.toIso8601String()} '
          'lifetime=${grant.accessTokenLifetime} '
          'implausible=${grant.hasImplausibleLifetime}',
    ),
  ]);

  // -- rotation -------------------------------------------------------------
  final rotationRevoked = <OAuthTokenGrant>[];
  final rotationFlow = _flow(
    refresh: () => _response(access: 'ACCESS-2', refresh: 'REFRESH-1'),
    revoked: rotationRevoked,
  );
  final rotationLinked = await _link(rotationFlow);
  final rotationCode = await _rotationFailureCode(rotationFlow, rotationLinked);
  final successfulRotation = await _rotatedGeneration();
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'rotation',
      check: 'an_unrotated_refresh_token_is_refused',
      declared:
          'A refresh that returns the same refresh token is refused; the link '
          'is not upgraded on the strength of an unrotated token.',
      observed: 'code=$rotationCode',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'rotation',
      check: 'a_failed_rotation_leaves_the_previous_generation_current',
      declared:
          'A refused rotation neither revokes nor advances the generation, so '
          'the working token stays the current one.',
      observed:
          'generation=${rotationFlow.linkedIdentities.single.tokenGeneration} '
          'revokeCalls=${rotationRevoked.length}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'rotation',
      check: 'a_successful_rotation_advances_the_generation',
      declared: 'A successful rotation installs the next token generation.',
      // One rotation, one flow: measuring the generation and the identity
      // count from two separate calls would print numbers from two different
      // subjects under a single declared statement.
      observed:
          'generation=${successfulRotation.generation} '
          'linkedIdentities=${successfulRotation.identities}',
    ),
  ]);

  // -- reauth ---------------------------------------------------------------
  final reauthManager = AccountConnectedAccountsManagement(
    initial: <AccountConnectedAccount>[_account()],
  );
  final reauthRequest = reauthManager.reauthenticate('openai/acc-1');
  final reauthExpired = AccountCenterTokenExpiryReauthenticationUx.expired(
    providerId: 'openai',
    accountLabel: 'acc-1',
    affectedCapabilities: const <String>['identity'],
    hasLocalData: true,
    localDataScope: 'the local project store',
  );
  final reauthed = reauthExpired.reauthenticated();
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'reauth',
      check: 'a_reauthentication_request_marks_only_its_own_connection',
      declared:
          'A reauthentication request raises the flag on the selected '
          'connection and names the provider and scopes it needs.',
      observed:
          'request=${reauthRequest.connectionId}@${reauthRequest.providerId} '
          'scopes=${reauthRequest.scopes.toList()} '
          'flagged=${reauthManager.connections.single.reauthRequired}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'reauth',
      check: 'retry_is_gated_until_reauthentication',
      declared:
          'An expired connection accepts no retry until it has been '
          'reauthenticated.',
      observed:
          'whileExpired=${reauthExpired.retry('identity').accepted} '
          'afterReauth=${reauthed.retry('identity').accepted} '
          'unaffectedCapability='
          '${reauthExpired.retry('billing').accepted}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'reauth',
      check: 'reauthentication_restores_retry_and_keeps_the_scope',
      declared:
          'Reauthentication restores retry and carries the local-data scope '
          'forward instead of dropping it.',
      observed:
          'canRetry=${reauthed.canRetry} '
          'localDataScope="${reauthed.localDataScope}" '
          'scoped=${reauthed.localDataPreservedWithScope}',
    ),
  ]);

  // -- provider_revoke ------------------------------------------------------
  final revokeRevoked = <OAuthTokenGrant>[];
  final revokeFlow = _flow(revoked: revokeRevoked);
  final revokeLinked = await _link(revokeFlow);
  final revokeOutcome = await revokeFlow.unlink(
    grant: revokeLinked.tokenGrant,
    decision: OAuthUnlinkDecision.unlink,
  );
  final failingRevoked = <OAuthTokenGrant>[];
  final failingFlow = _flow(
    onRevoke: (g) => throw StateError('provider 500'),
    revoked: failingRevoked,
  );
  final failingLinked = await _link(failingFlow);
  final failingCode = await _revocationFailureCode(failingFlow, failingLinked);
  // Revoking again with the same grant must be refused the same way; the
  // provider is still the one holding the live grant.
  final failingRetryCode = await _revocationFailureCode(
    failingFlow,
    failingLinked,
  );
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'provider_revoke',
      check: 'an_unlink_calls_the_provider_revoker',
      declared:
          'Disconnecting a linked identity revokes the grant at the provider '
          'before the local link is dropped.',
      observed:
          'unlinked=$revokeOutcome providerRevokeCalls=${revokeRevoked.length} '
          'grant=${revokeRevoked.single.connectionId}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'provider_revoke',
      check: 'a_refused_revocation_keeps_the_local_link',
      declared:
          'A provider that refuses the revocation leaves the local link in '
          'place instead of stranding a live grant with nothing to retry from.',
      observed:
          'code=$failingCode identities='
          '${failingFlow.linkedIdentities.length} retryCode=$failingRetryCode',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'provider_revoke',
      check: 'a_revoked_grant_cannot_be_replayed',
      declared:
          'A grant from a revoked generation cannot be used again, so a stale '
          'reference cannot resurrect a disconnected connection.',
      observed: 'code=${await _staleReplayCode()}',
    ),
  ]);

  // -- disconnect -----------------------------------------------------------
  final disconnectCalls = <String>[];
  final disconnectRevoked = await AccountConnectedAccountsManagement(
    initial: <AccountConnectedAccount>[_account()],
    providerRevoker: (connectionId, providerId) async {
      disconnectCalls.add(connectionId);
      return true;
    },
  ).unlink('openai/acc-1', confirmed: true);
  final localOnly = await AccountConnectedAccountsManagement(
    initial: <AccountConnectedAccount>[_account()],
  ).unlink('openai/acc-1', confirmed: true);
  final unconfirmed = await AccountConnectedAccountsManagement(
    initial: <AccountConnectedAccount>[_account()],
    providerRevoker: (connectionId, providerId) async => true,
  ).unlink('openai/acc-1', confirmed: false);
  final failedRevoke = await AccountConnectedAccountsManagement(
    initial: <AccountConnectedAccount>[_account()],
    providerRevoker: (connectionId, providerId) async => false,
  ).unlink('openai/acc-1', confirmed: true);
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'disconnect',
      check: 'a_disconnect_reports_the_provider_call',
      declared:
          'A disconnect reports whether the provider was told, so a revoked row '
          'is never indistinguishable from a local-only one.',
      observed:
          'calls=$disconnectCalls '
          'attempted=${disconnectRevoked.providerRevokeAttempted} '
          'revoked=${disconnectRevoked.providerRevoked} '
          'localRemoved=${disconnectRevoked.localRemoved}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'disconnect',
      check: 'a_local_only_disconnect_says_no_provider_call_was_made',
      declared:
          'A disconnect with no revoker is local-only by declaration and says '
          'so explicitly.',
      observed:
          'attempted=${localOnly.providerRevokeAttempted} '
          'revoked=${localOnly.providerRevoked} '
          'localRemoved=${localOnly.localRemoved} '
          'summary="${localOnly.summary}"',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'disconnect',
      check: 'an_unconfirmed_disconnect_touches_nothing',
      declared:
          'An unconfirmed disconnect changes nothing and calls no provider.',
      observed:
          'localRemoved=${unconfirmed.localRemoved} '
          'attempted=${unconfirmed.providerRevokeAttempted} '
          'revoked=${unconfirmed.providerRevoked}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'disconnect',
      check: 'a_failed_revocation_keeps_a_row_to_retry_from',
      declared:
          'A revocation the provider did not confirm leaves the connection '
          'listed so the retry has something to retry from.',
      observed:
          'localRemoved=${failedRevoke.localRemoved} '
          'attempted=${failedRevoke.providerRevokeAttempted} '
          'revoked=${failedRevoke.providerRevoked}',
    ),
  ]);

  // -- cleanup --------------------------------------------------------------
  final cleanupStore = _Store();
  final cleanupClipboard = <String>[];
  final cleanupAudit = <VaultAuditEvent>[];
  final cleanupVault = _vault(
    store: cleanupStore,
    clipboard: cleanupClipboard,
    now: kNow,
    audit: cleanupAudit,
  );
  await cleanupVault.save(
    accountId: 'acct',
    secret: 'TOKEN-ABC',
    kind: VaultSecretKind.accessToken,
    secretId: 'main',
  );
  await cleanupVault.save(
    accountId: 'acct',
    secret: 'OTHER',
    kind: VaultSecretKind.apiKey,
    secretId: 'spare',
  );
  await cleanupVault.copyToClipboard(
    accountId: 'acct',
    kind: VaultSecretKind.accessToken,
    secretId: 'main',
  );
  await cleanupVault.revoke(
    accountId: 'acct',
    kind: VaultSecretKind.accessToken,
    secretId: 'main',
  );
  final survivorStore = _Store();
  final survivorClipboard = <String>[];
  final survivorVault = _vault(
    store: survivorStore,
    clipboard: survivorClipboard,
    now: kNow,
  );
  await survivorVault.save(
    accountId: 'acct',
    secret: 'KEEP-A',
    kind: VaultSecretKind.apiKey,
    secretId: 'primary',
  );
  await survivorVault.save(
    accountId: 'acct',
    secret: 'DROP-B',
    kind: VaultSecretKind.paymentMethodToken,
    secretId: 'pm-1',
  );
  await survivorVault.copyToClipboard(
    accountId: 'acct',
    kind: VaultSecretKind.apiKey,
    secretId: 'primary',
  );
  await survivorVault.revoke(
    accountId: 'acct',
    kind: VaultSecretKind.paymentMethodToken,
    secretId: 'pm-1',
  );
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'cleanup',
      check: 'revoking_a_secret_wipes_its_clipboard_copy',
      declared:
          'Revoking a secret leaves no usable copy behind: the store copy is '
          'deleted and the clipboard copy is wiped at the same moment.',
      observed:
          'storeEmpty=${!cleanupStore.values.containsValue('TOKEN-ABC')} '
          'clipboard=$cleanupClipboard '
          'lastWriteIsEmpty=${cleanupClipboard.last.isEmpty}',
      note:
          'Before the fix the clipboard kept the token for the whole 30-second '
          'window; callers that use vault.revoke directly never wiped it.',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'cleanup',
      check: 'the_wipe_does_not_touch_an_unrelated_key',
      declared:
          'Cleaning up after one revoke never discards a different secret the '
          'user copied.',
      observed:
          'clipboard=$survivorClipboard '
          'survivorStillStored='
          '${survivorStore.values.containsValue('KEEP-A')}',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'cleanup',
      check: 'the_audit_trail_names_what_was_destroyed',
      declared:
          'Every vault audit row names the secret kind and, when applicable, '
          'which secret of that kind, and never carries the secret itself.',
      observed:
          'revokeRow=${cleanupAudit.last.action}|'
          '${cleanupAudit.last.kind}|${cleanupAudit.last.secretId} '
          'rows=${cleanupAudit.length} '
          'secretAlwaysNull='
          '${cleanupAudit.every((e) => e.secret == null)} '
          'distinctRevokeRows='
          '${cleanupAudit.where((e) => e.action == 'revoke').map((e) => '${e.kind}/${e.secretId}').toSet()}',
      note:
          'Before the fix every row was the byte-identical "revoke|acct" and no '
          'row could say which key had been destroyed.',
    ),
  ]);

  // -- local_data_preserved -------------------------------------------------
  final unscopedClaim = AccountCenterTokenExpiryReauthenticationUx.expired(
    providerId: 'openai',
    accountLabel: 'acc-1',
    affectedCapabilities: const <String>['identity'],
    hasLocalData: true,
  );
  final scopedClaim = AccountCenterTokenExpiryReauthenticationUx.expired(
    providerId: 'openai',
    accountLabel: 'acc-1',
    affectedCapabilities: const <String>['identity'],
    hasLocalData: true,
    localDataScope: 'the local project store',
  );
  final projectStore = _Store();
  await projectStore.write(key: 'project/novel/chapter-1.md', value: 'draft');
  await projectStore.write(key: 'credentials/token', value: 'SECRET');
  await projectStore.delete('credentials/token');
  checks.addAll(<Sprint117OAuthRevocationCheck>[
    Sprint117OAuthRevocationCheck.pass_(
      area: 'local_data_preserved',
      check: 'an_unscoped_claim_is_not_treated_as_evidence',
      declared:
          'A local-data preservation claim that does not name what it covers '
          'is not usable as evidence.',
      observed:
          'localDataPreserved=${unscopedClaim.localDataPreserved} '
          'hasScope=${unscopedClaim.hasLocalDataScope} '
          'withScope=${unscopedClaim.localDataPreservedWithScope} '
          'notice="${unscopedClaim.notice}"',
      note:
          'Before the fix any call site could assert true, including one with '
          'no store in reach at all.',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'local_data_preserved',
      check: 'a_scoped_claim_survives_every_transition',
      declared:
          'A scoped preservation claim is carried through expiry, '
          'reauthentication, and revocation without being dropped.',
      observed:
          'expired=${scopedClaim.localDataScope} '
          'reauthed=${scopedClaim.reauthenticated().localDataScope} '
          'revoked=${scopedClaim.revoked().localDataScope} '
          'notice="${scopedClaim.scopedNotice}"',
    ),
    Sprint117OAuthRevocationCheck.pass_(
      area: 'local_data_preserved',
      check: 'credential_cleanup_does_not_reach_project_data',
      declared:
          'Destroying credential material leaves the project data store '
          'untouched; only the credential key is removed.',
      observed:
          'projectKeys=${projectStore.values.keys.toList()} '
          'chapterIntact='
          "${projectStore.values['project/novel/chapter-1.md'] == 'draft'} "
          'credentialGone='
          "${projectStore.values.containsKey('credentials/token') == false}",
    ),
  ]);

  return checks;
}

/// Records what the flow did with a token whose stated lifetime is absurd.
Future<({String code, int identities, String summary})>
_longLivedTokenOutcome() async {
  final flow = _flow(
    exchange: () => _response(lifetime: const Duration(days: 365 * 40)),
  );
  try {
    await _link(flow);
    final accepted = flow.linkedIdentities.length;
    return (
      code: 'NONE',
      identities: accepted,
      summary: 'code=NONE linkedIdentities=$accepted',
    );
  } on OAuthFlowException catch (e) {
    final identities = flow.linkedIdentities.length;
    return (
      code: e.code.name,
      identities: identities,
      summary: 'code=${e.code.name} linkedIdentities=$identities',
    );
  }
}

Future<({int generation, int identities})> _rotatedGeneration() async {
  final flow = _flow();
  final linked = await _link(flow);
  final rotated = await flow.rotateTokens(currentGrant: linked.tokenGrant);
  return (
    generation: rotated.tokenGrant.generation,
    identities: flow.linkedIdentities.length,
  );
}

Future<String> _rotationFailureCode(
  AccountOAuthFlow flow,
  LinkedIdentityResult linked,
) async {
  try {
    await flow.rotateTokens(currentGrant: linked.tokenGrant);
  } on OAuthFlowException catch (e) {
    return e.code.name;
  }
  return 'NONE';
}

Future<String> _revocationFailureCode(
  AccountOAuthFlow flow,
  LinkedIdentityResult linked,
) async {
  try {
    await flow.unlink(
      grant: linked.tokenGrant,
      decision: OAuthUnlinkDecision.unlink,
    );
  } on OAuthFlowException catch (e) {
    return e.code.name;
  }
  return 'NONE';
}

Future<String> _staleReplayCode() async {
  final revoked = <OAuthTokenGrant>[];
  final flow = _flow(revoked: revoked);
  final linked = await _link(flow);
  await flow.unlink(
    grant: linked.tokenGrant,
    decision: OAuthUnlinkDecision.unlink,
  );
  try {
    await flow.rotateTokens(currentGrant: linked.tokenGrant);
  } on OAuthFlowException catch (e) {
    return e.code.name;
  }
  return 'NONE';
}
