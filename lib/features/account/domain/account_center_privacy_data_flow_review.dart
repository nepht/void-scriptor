/// Sprint 115.50 — Privacy & Data-Flow Review contract.
///
/// Documents every account data subject the canonical objective names
/// (`account metadata, tokens, usage, storage, billing, diagnostics,
/// retention, and external transfers`) across the eight canonical
/// `required_outputs`: data flow, classification, consent, retention,
/// deletion, external transfer, redaction, and privacy defaults.
///
/// The review is fail-closed like its siblings (115.44, 115.49): an unknown
/// bucket or subject is rejected, a missing one throws, `isPass` only turns
/// true when every canonical bucket reports `PASS`, and the subject inventory
/// may never claim a live external transfer without explicit consent — a
/// `tokens` record may never be classified below `credentialSecret`.
///
/// Every field of [defaultInventory] is grounded in live code (vault,
/// metrics, redactor, session JSON, audit overview, workspace boundary), not
/// in prose: the accompanying test scans `lib/features/account` sources to
/// prove no surface opens a network client in this build.
library;

/// One bucket of step 115.50 review output.
///
/// [localResult] is a free string so a bucket can honestly report `PASS`,
/// `GAP`, or `DEFERRED` instead of being coerced into a boolean.
final class AccountCenterPrivacyOutput {
  const AccountCenterPrivacyOutput({
    required this.localResult,
    required this.note,
  });

  final String localResult;
  final String note;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'local_result': localResult,
    'note': note,
  };
}

/// The validated review report for step 115.50.
final class AccountCenterPrivacyReviewReport {
  AccountCenterPrivacyReviewReport._(this.evidence);

  final Map<String, AccountCenterPrivacyOutput> evidence;

  bool get isPass => AccountCenterPrivacyDataFlowReview.requiredOutputs.every(
    (key) => evidence[key]!.localResult == 'PASS',
  );

  Map<String, Object?> toPublicJson() => <String, Object?>{
    for (final entry in evidence.entries) entry.key: entry.value.localResult,
  };
}

/// The data subjects the canonical objective asks to document.
enum AccountPrivacySubject {
  accountMetadata('account_metadata'),
  tokens('tokens'),
  usage('usage'),
  storage('storage'),
  billing('billing'),
  diagnostics('diagnostics'),
  retention('retention'),
  externalTransfers('external_transfers');

  const AccountPrivacySubject(this.id);

  /// Manifest key; must match the canonical objective vocabulary.
  final String id;
}

/// Sensitivity class assigned to each subject.
enum AccountDataClass {
  /// Local identity metadata (display name, email, status) — no credential.
  personalLocal,

  /// Secrets: API keys, OAuth tokens, payment method tokens.
  credentialSecret,

  /// Token/cost usage aggregates from the local project database.
  usageMetadata,

  /// Storage byte aggregates and provider quota metadata.
  storageMetadata,

  /// Billing/invoice metadata; never card data.
  billingMetadata,

  /// Aggregate diagnostics counters; never content.
  diagnosticAggregate,

  /// Retention policy description, not user data.
  retentionPolicy,

  /// Transfer policy description, not user data.
  externalTransferPolicy,
}

/// Why the subject may be processed.
enum AccountConsentBasis {
  /// Stays on this device; no transfer or third party involved.
  notRequiredLocalOnly,

  /// User-initiated local action (save, revoke, copy).
  explicitUserAction,

  /// User enabled an opt-in channel that is OFF by default.
  explicitOptIn,

  /// OAuth/connector consent, granted per scope at connect time.
  deferredScopedOAuth,

  /// Cross-workspace transfer consent (115.4 `resolveTransfer`).
  workspaceTransferConsent,
}

/// Whether the subject leaves the device in this build.
enum AccountExternalTransferKind {
  /// Local only: no network client exists for this subject today.
  noneLocalOnly,

  /// Designed to reach a provider API, but only behind scoped OAuth once a
  /// connector is certified — not reachable in this build.
  deferredProviderApi,

  /// Moves between workspace scopes, only with explicit transfer consent.
  workspaceConsentScoped,
}

/// Standing privacy default applied to the subject.
enum AccountPrivacyDefault {
  /// Data stays local unless the user moves it.
  localOnly,

  /// Collection channel exists but is OFF until the user opts in.
  optInDefaultOff,

  /// Anything not explicitly allowlisted is rejected.
  denyByDefault,

  /// Must never be written to the project database or plain file.
  neverPlaintextStorage,
}

/// One documented subject: all eight review dimensions in one record.
final class AccountPrivacySubjectRecord {
  const AccountPrivacySubjectRecord({
    required this.subject,
    required this.dataFlow,
    required this.classification,
    required this.consent,
    required this.retention,
    required this.deletion,
    required this.externalTransfer,
    required this.redaction,
    required this.privacyDefault,
  });

  final AccountPrivacySubject subject;

  /// Where the data lives and how it moves (dimension `data_flow`).
  final String dataFlow;

  /// Sensitivity class (dimension `classification`).
  final AccountDataClass classification;

  /// Consent basis (dimension `consent`).
  final AccountConsentBasis consent;

  /// How long the data is kept (dimension `retention`).
  final String retention;

  /// How the user removes it (dimension `deletion`).
  final String deletion;

  /// Whether it leaves the device (dimension `external_transfer`).
  final AccountExternalTransferKind externalTransfer;

  /// How it is masked before publication (dimension `redaction`).
  final String redaction;

  /// Standing default (dimension `privacy_defaults`).
  final AccountPrivacyDefault privacyDefault;
}

/// Fail-closed Privacy & Data-Flow Review for canonical step 115.50.
abstract final class AccountCenterPrivacyDataFlowReview {
  /// `required_outputs` for canonical step 115.50, in spec order.
  static const List<String> requiredOutputs = <String>[
    'data_flow',
    'classification',
    'consent',
    'retention',
    'deletion',
    'external_transfer',
    'redaction',
    'privacy_defaults',
  ];

  /// Data subjects named by the canonical objective, in order.
  static const List<String> subjectIds = <String>[
    'account_metadata',
    'tokens',
    'usage',
    'storage',
    'billing',
    'diagnostics',
    'retention',
    'external_transfers',
  ];

  /// Consent bases allowed for a subject that leaves the device.
  static const Set<AccountConsentBasis> transferConsentBases =
      <AccountConsentBasis>{
        AccountConsentBasis.explicitUserAction,
        AccountConsentBasis.explicitOptIn,
        AccountConsentBasis.deferredScopedOAuth,
        AccountConsentBasis.workspaceTransferConsent,
      };

  /// Validates an evidence map against [requiredOutputs].
  ///
  /// Throws [ArgumentError] for an unknown bucket and [StateError] when a
  /// canonical bucket is missing, so a report can never claim completeness by
  /// quietly dropping a bucket.
  static AccountCenterPrivacyReviewReport buildReport(
    Map<String, AccountCenterPrivacyOutput> evidence,
  ) {
    for (final key in evidence.keys) {
      if (!requiredOutputs.contains(key)) {
        throw ArgumentError.value(
          key,
          'evidence',
          'Bucket outside the canonical required_outputs of step 115.50.',
        );
      }
    }
    final missing = requiredOutputs
        .where((key) => !evidence.containsKey(key))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required output bucket(s): ${missing.join(', ')}.',
      );
    }
    return AccountCenterPrivacyReviewReport._(Map.unmodifiable(evidence));
  }

  /// Validates the subject inventory against [subjectIds].
  ///
  /// Throws [ArgumentError] for an unknown subject key, an empty documentation
  /// dimension, a `tokens` record classified below `credentialSecret`, or a
  /// subject that leaves the device without an explicit consent basis.
  /// Throws [StateError] when a canonical subject is missing.
  static Map<String, AccountPrivacySubjectRecord> buildReview(
    Map<String, AccountPrivacySubjectRecord> inventory,
  ) {
    for (final key in inventory.keys) {
      if (!subjectIds.contains(key)) {
        throw ArgumentError.value(
          key,
          'inventory',
          'Subject outside the canonical objective of step 115.50.',
        );
      }
    }
    final missing = subjectIds
        .where((key) => !inventory.containsKey(key))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Missing data subject(s): ${missing.join(', ')}.');
    }
    final ordered = <String, AccountPrivacySubjectRecord>{
      for (final key in subjectIds) key: inventory[key]!,
    };
    for (final entry in ordered.entries) {
      final record = entry.value;
      if (record.subject.id != entry.key) {
        throw ArgumentError.value(
          entry.key,
          'inventory',
          'Key does not match the record subject.',
        );
      }
      _requireDocumented(record.dataFlow, entry.key, 'data_flow');
      _requireDocumented(record.retention, entry.key, 'retention');
      _requireDocumented(record.deletion, entry.key, 'deletion');
      _requireDocumented(record.redaction, entry.key, 'redaction');
      if (entry.key == 'tokens' &&
          record.classification != AccountDataClass.credentialSecret) {
        throw ArgumentError.value(
          record.classification.name,
          'inventory',
          'tokens must be classified credentialSecret.',
        );
      }
      if (record.externalTransfer !=
              AccountExternalTransferKind.noneLocalOnly &&
          !transferConsentBases.contains(record.consent)) {
        throw ArgumentError.value(
          record.consent.name,
          'inventory',
          'A subject that leaves the device requires explicit consent.',
        );
      }
    }
    return Map<String, AccountPrivacySubjectRecord>.unmodifiable(ordered);
  }

  static void _requireDocumented(String value, String subject, String dim) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'inventory',
        'Dimension $dim of subject $subject is undocumented.',
      );
    }
  }

  /// The documented inventory for this build, keyed in canonical order.
  ///
  /// Every description is grounded in live code: `AuthSessionJson`,
  /// `AccountSecureTokenVault` + `CredentialStore`, `AiUsageRow.publicFields`,
  /// `ProjectStorageAnalyzer` aggregates, `billing_contract`
  /// (`PLANNED_NOT_VERIFIED`), `PrivacySafeMetrics`, the audit overview
  /// retention window, and the workspace boundary `resolveTransfer` gate.
  static const Map<String, AccountPrivacySubjectRecord>
  defaultInventory = <String, AccountPrivacySubjectRecord>{
    'account_metadata': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.accountMetadata,
      dataFlow:
          'AuthSession fields (status, displayName, userId, email) held '
          'in memory and persisted by AuthSessionStore as local JSON; '
          'never sent anywhere (no network client in the feature).',
      classification: AccountDataClass.personalLocal,
      consent: AccountConsentBasis.notRequiredLocalOnly,
      retention:
          'Kept while signed in; persisted only to restore Guest/Offline '
          'sessions across restarts (Sprint 145.20).',
      deletion:
          'logout() clears the store (best-effort) and drops the '
          'in-memory session immediately.',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'AuthSessionJson serializes exactly four keys; no password, '
          'token, or credential key exists in the schema to leak.',
      privacyDefault: AccountPrivacyDefault.localOnly,
    ),
    'tokens': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.tokens,
      dataFlow:
          'AccountSecureTokenVault -> CredentialStore (FlutterSecureStorage '
          'OS keystore in production; MemoryCredentialStore for tests); '
          'keys namespaced account/<accountId>/<kind>.',
      classification: AccountDataClass.credentialSecret,
      consent: AccountConsentBasis.explicitUserAction,
      retention:
          'Held until the user revokes the connection; no expiry timer of '
          'its own — token expiry surfaces via 115.43 reauth UX.',
      deletion:
          'vault.revoke() deletes the key from the store; clipboard '
          'copies self-clear after clipboardTimeout (30s default).',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'maskedDisplay() bullets every value, audit events expose no '
          'secret field, and SecretRedactor.mask/redact cover publication.',
      privacyDefault: AccountPrivacyDefault.neverPlaintextStorage,
    ),
    'usage': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.usage,
      dataFlow:
          'AiUsageLogRepository writes token/cost rows (provider, model, '
          'prompt/completion token counts, cost) into the local drift '
          'project database; charts read AiUsageRow only.',
      classification: AccountDataClass.usageMetadata,
      consent: AccountConsentBasis.notRequiredLocalOnly,
      retention:
          'Lives with the project database; retained as long as the '
          'project exists.',
      deletion:
          'Removed when the project database is deleted; no separate '
          'usage-log purge exists yet.',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'AiUsageRow.publicFields is a closed set with no prompt, '
          'content, or free-text field; only numeric aggregates publish.',
      privacyDefault: AccountPrivacyDefault.denyByDefault,
    ),
    'storage': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.storage,
      dataFlow:
          'Local byte aggregates from ProjectStorageAnalyzer plus '
          'provider quota metadata (provider_id, used/quota bytes, '
          'measured_at) held as report rows.',
      classification: AccountDataClass.storageMetadata,
      consent: AccountConsentBasis.notRequiredLocalOnly,
      retention:
          'Report rows are derived per view; raw readings carry their own '
          'measured_at and freshness instead of an archive.',
      deletion:
          'Dropping the local scan source or the project removes the '
          'underlying files the aggregates describe.',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'Aggregates publish byte counts and category labels only — no '
          'file names, paths, or content; local and remote stay separate.',
      privacyDefault: AccountPrivacyDefault.localOnly,
    ),
    'billing': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.billing,
      dataFlow:
          'No billing data is collected in this build: billing_contract '
          'is PLANNED_NOT_VERIFIED and invoice/payment surfaces are not '
          'wired to any processor.',
      classification: AccountDataClass.billingMetadata,
      consent: AccountConsentBasis.notRequiredLocalOnly,
      retention:
          'Nothing retained — there is no live invoice, card, or payment '
          'record to keep.',
      deletion:
          'Not applicable while uncollected; future deletion must cover '
          'any invoice record at the source (step 115.54 verifies).',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'raw_card_storage_allowed is false, so no card number may ever '
          'enter the store; payment tokens, if any, ride the vault only.',
      privacyDefault: AccountPrivacyDefault.neverPlaintextStorage,
    ),
    'diagnostics': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.diagnostics,
      dataFlow:
          'PrivacySafeMetrics accumulates aggregate counters '
          '(flag|surface|outcome) in memory and, only when asked, a local '
          'metrics.json; no analytics endpoint exists.',
      classification: AccountDataClass.diagnosticAggregate,
      consent: AccountConsentBasis.explicitOptIn,
      retention:
          'Local metrics.json until the user deletes it; counters are not '
          'exported automatically.',
      deletion:
          'Deleting metrics.json empties the store; KillSwitch disables '
          'individual flags without touching data.',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'Allowlist keys only (flag/outcome/surface/count); unknown '
          'flags are dropped deny-by-default so content cannot ride in.',
      privacyDefault: AccountPrivacyDefault.optInDefaultOff,
    ),
    'retention': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.retention,
      dataFlow:
          'Retention rules run locally: audit overview filters events '
          'older than its retention window, backup policy caps copies via '
          'BackupRetention.maxCopies.',
      classification: AccountDataClass.retentionPolicy,
      consent: AccountConsentBasis.notRequiredLocalOnly,
      retention:
          'Audit events fall out of queries once older than the window '
          '(retention > 0 enforced); backups keep at most maxCopies.',
      deletion:
          'Events past the window are never served; old backup copies are '
          'superseded by the copy cap, not archived off-device.',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'Audit publication runs through publicDetails, which replaces '
          'sensitive detail keys with [REDACTED].',
      privacyDefault: AccountPrivacyDefault.denyByDefault,
    ),
    'external_transfers': AccountPrivacySubjectRecord(
      subject: AccountPrivacySubject.externalTransfers,
      dataFlow:
          'No transfer exists in this build: a source scan of '
          'lib/features/account finds no http/dio/WebSocket client; any '
          'future provider call is contract-only (deferred).',
      classification: AccountDataClass.externalTransferPolicy,
      consent: AccountConsentBasis.workspaceTransferConsent,
      retention:
          'No transfer records exist to retain; future connectors must '
          'log transfers under the audit retention window.',
      deletion:
          'Not applicable while no transfer is possible; revoking a '
          'connection removes the credential that would authorize one.',
      externalTransfer: AccountExternalTransferKind.noneLocalOnly,
      redaction:
          'Cross-workspace movement is gated by resolveTransfer: without '
          'explicit consent the decision is DENIED_TRANSFER_CONSENT_REQUIRED.',
      privacyDefault: AccountPrivacyDefault.denyByDefault,
    ),
  };
}
