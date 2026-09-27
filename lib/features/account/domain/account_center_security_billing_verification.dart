/// Sprint 115.54 — Security & Billing Verification contract.
///
/// The canonical objective of step 115.54 asks the surface to be exercised
/// across OAuth, token storage, API keys, sessions, permissions, webhook
/// authenticity, entitlement, payment redirects, and audit. The eight
/// canonical outputs are transcribed here in spec order and never invented:
///
/// `oauth_tests`, `vault_tests`, `key_tests`, `session_tests`,
/// `permission_tests`, `webhook_tests`, `entitlement_tests`, `audit_tests`.
///
/// Two buckets name capabilities that did not exist anywhere under
/// `lib/features/account` before this step:
///
/// 1. **Webhook authenticity.** A grep for `webhook`, `hmac`, and
///    `replay` across the whole feature tree returned nothing. A billing or
///    provider callback therefore had no signature check, no timestamp
///    window, and no replay guard: anything that reached the callback
///    handler was trusted. [signatureHeader] and [verifyWebhook] are that
///    missing boundary, and they are built on the same `Hmac(sha256, …)`
///    primitive the repo already uses in `core/security/crypto`, so this is
///    not a new dependency.
/// 2. **An entitlement issuance window.** [entitlementStateAt] below states
///    the rule the live model now enforces; the defect it locks is described
///    on `AccountCenterSubscriptionEntitlementModel.entitlementStateAt`.
///
/// The matrix is fail-closed like its siblings (115.49 – 115.53):
///
/// * a bucket outside the canonical set is rejected with [ArgumentError];
/// * a canonical bucket that was never recorded is rejected with [StateError];
/// * a bucket that claims `pass` without a concrete check, or with a check
///   that did not hold, is rejected with [ArgumentError] — an unverified pass
///   is a rubber stamp;
/// * a bucket that is not passing must say why, and a `blocked` bucket may
///   never carry checks, so an external boundary cannot be dressed up as a
///   local pass;
/// * [AccountVerificationReport.isPass] only turns true when every canonical
///   bucket passed, and [verdict] must be repeated verbatim in the committed
///   manifest.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

/// How a security & billing bucket was evaluated.
enum AccountVerificationBucketStatus {
  /// The bucket ran locally and every recorded check held.
  pass,

  /// The bucket ran locally and at least one check failed.
  fail,

  /// The bucket cannot be evaluated locally (external boundary).
  blocked,

  /// Recorded as a target but not yet run.
  pending,
}

/// Outcome of verifying one provider callback.
enum AccountWebhookDecision {
  /// Signature, timestamp, and replay window all held.
  verified,

  /// The header is not a well-formed `sha256=<hex>` signature.
  malformedSignature,

  /// The body was altered after it was signed, or signed by another secret.
  signatureMismatch,

  /// The signed timestamp is outside the accepted tolerance.
  stale,

  /// This delivery id was already accepted inside the window.
  replayed,
}

/// One recorded check inside a security & billing bucket.
final class AccountVerificationCheck {
  AccountVerificationCheck({required this.name, required this.held}) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Check must be named.');
    }
  }

  /// What was asserted, e.g. `reauth_before_replace_key`.
  final String name;

  /// Whether the assertion actually held in the recorded run.
  final bool held;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'name': name,
    'held': held,
  };
}

/// One recorded bucket of the security & billing matrix.
final class AccountVerificationBucket {
  AccountVerificationBucket({
    required this.bucket,
    required this.status,
    required List<AccountVerificationCheck> checks,
    this.note = '',
  }) : checks = List<AccountVerificationCheck>.unmodifiable(checks) {
    if (bucket.trim().isEmpty) {
      throw ArgumentError.value(bucket, 'bucket', 'Bucket must be named.');
    }
    if (note.trim().length < 30 &&
        status != AccountVerificationBucketStatus.pass) {
      throw ArgumentError.value(
        note,
        'note',
        'A non-passing bucket must explain itself in at least 30 characters.',
      );
    }
  }

  /// Canonical bucket name; must match its report key.
  final String bucket;

  final AccountVerificationBucketStatus status;

  /// Concrete local checks. Empty for `blocked` and `pending`.
  final List<AccountVerificationCheck> checks;

  /// Why the bucket is not passing, or a scope clarification for a passing one.
  final String note;

  /// Number of concrete checks recorded by the run.
  int get measured => checks.length;

  /// True when this bucket is a local pass with every check holding.
  bool get allHeld =>
      status == AccountVerificationBucketStatus.pass &&
      checks.isNotEmpty &&
      checks.every((check) => check.held);

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'bucket': bucket,
    'status': status.name,
    'measured': measured,
    'checks': checks
        .map((check) => check.toPublicJson())
        .toList(growable: false),
    'note': note,
  };
}

/// The validated matrix for canonical step 115.54.
final class AccountVerificationReport {
  AccountVerificationReport._(this.results);

  /// Recorded buckets in canonical order.
  final Map<String, AccountVerificationBucket> results;

  /// True when every canonical bucket has a recorded, non-pending row.
  bool get isComplete => results.values.every(
    (row) => row.status != AccountVerificationBucketStatus.pending,
  );

  int get passCount => results.values
      .where((row) => row.status == AccountVerificationBucketStatus.pass)
      .length;

  /// True only for a complete matrix whose every bucket passed.
  bool get isPass =>
      isComplete &&
      passCount ==
          AccountCenterSecurityBillingVerification.requiredBuckets.length;

  /// Machine-readable summary; the committed manifest must repeat this value.
  String get verdict => !isComplete
      ? 'INCOMPLETE'
      : isPass
      ? 'ALL_PASS'
      : 'COMPLETE_${passCount}_OF_'
            '${AccountCenterSecurityBillingVerification.requiredBuckets.length}_PASS';

  AccountVerificationBucketStatus statusOf(String bucket) =>
      results[bucket]!.status;
}

/// Remembers which delivery ids were already accepted, so a provider that
/// retries a callback cannot make the same event bill twice.
///
/// The window is explicit rather than implicit: a caller chooses how long a
/// delivery id is remembered. A guard with an unbounded set would be a
/// memory leak, and a guard with no window would refuse legitimate provider
/// retries, so the retention is the caller's declared tolerance.
final class AccountWebhookReplayGuard {
  AccountWebhookReplayGuard();

  final Map<String, DateTime> _accepted = <String, DateTime>{};

  /// True when [deliveryId] was already accepted and is still inside
  /// [retention]; the id is then dropped so the set cannot grow forever.
  bool isReplay(
    String deliveryId, {
    required DateTime now,
    required Duration retention,
  }) {
    final previous = _accepted[deliveryId];
    if (previous == null) return false;
    if (now.difference(previous) > retention) {
      _accepted.remove(deliveryId);
      return false;
    }
    return true;
  }

  /// Records [deliveryId] as accepted at [now].
  void remember(String deliveryId, DateTime now) {
    _accepted[deliveryId] = now;
  }

  /// Number of delivery ids currently held; used by the manifest check.
  int get tracked => _accepted.length;
}

/// An inbound provider callback, reduced to the fields authenticity depends on.
final class AccountVerificationWebhookRequest {
  AccountVerificationWebhookRequest({
    required this.deliveryId,
    required this.providerId,
    required this.timestamp,
    required this.signature,
    required this.body,
  }) {
    if (deliveryId.trim().isEmpty) {
      throw ArgumentError.value(deliveryId, 'deliveryId');
    }
    if (providerId.trim().isEmpty) {
      throw ArgumentError.value(providerId, 'providerId');
    }
    if (!timestamp.isUtc) {
      throw ArgumentError.value(timestamp, 'timestamp', 'Must be UTC.');
    }
  }

  /// Provider-supplied idempotency key; the replay key.
  final String deliveryId;
  final String providerId;
  final DateTime timestamp;
  final String signature;

  /// The exact bytes that were signed. Re-serializing here would let a
  /// whitespace difference change the meaning of a verified payload, so the
  /// body is carried verbatim.
  final String body;
}

/// A minimal entitlement grant shape, so the issuance rule is stated once
/// here and can be checked against the real
/// [EntitlementGrant] without importing the whole subscription model.
final class EntitlementGrantProbe {
  EntitlementGrantProbe({required this.grantedAt, this.expiresAt});

  final DateTime grantedAt;
  final DateTime? expiresAt;

  static EntitlementGrantProbe signed({
    required DateTime grantedAt,
    DateTime? expiresAt,
  }) => EntitlementGrantProbe(grantedAt: grantedAt, expiresAt: expiresAt);
}

/// Fail-closed Security & Billing Verification matrix for step 115.54.
abstract final class AccountCenterSecurityBillingVerification {
  /// Path of the committed evidence manifest.
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_security_billing_verification.json';

  /// `required_outputs` for canonical step 115.54, in spec order.
  static const List<String> requiredBuckets = <String>[
    'oauth_tests',
    'vault_tests',
    'key_tests',
    'session_tests',
    'permission_tests',
    'webhook_tests',
    'entitlement_tests',
    'audit_tests',
  ];

  /// Default acceptance window for a provider callback.
  ///
  /// Not a spec number. Five minutes is the common provider default; the
  /// manifest records it as a declared local bound, not a guarantee.
  static const Duration defaultWebhookTolerance = Duration(minutes: 5);

  /// The signed message: the timestamp and the body, joined by a separator
  /// that cannot be produced by moving content across the boundary.
  static String signedPayload({
    required DateTime timestamp,
    required String body,
  }) => 'v1:${timestamp.toUtc().toIso8601String()}:$body';

  /// The `sha256=<hex>` header a provider would send.
  static String signatureHeader({
    required String secret,
    required DateTime timestamp,
    required String body,
  }) {
    if (secret.isEmpty) {
      throw ArgumentError.value(
        secret,
        'secret',
        'A signature needs a secret.',
      );
    }
    final digest = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(signedPayload(timestamp: timestamp, body: body)));
    return 'sha256=$digest';
  }

  /// Verifies one provider callback, failing closed at every step.
  ///
  /// Order matters. A malformed header is rejected before any hashing, a
  /// mismatch before a staleness check, and the replay guard is consulted
  /// only for a request that is otherwise authentic — so a forged request
  /// can never evict a real delivery id from the guard and then be accepted
  /// on a later attempt.
  static AccountWebhookDecision verifyWebhook({
    required AccountVerificationWebhookRequest request,
    required String secret,
    Duration tolerance = defaultWebhookTolerance,
    AccountWebhookReplayGuard? replayGuard,
    DateTime? now,
  }) {
    if (secret.isEmpty) {
      throw ArgumentError.value(
        secret,
        'secret',
        'A verification needs a secret.',
      );
    }
    if (tolerance.isNegative) {
      throw ArgumentError.value(
        tolerance,
        'tolerance',
        'A tolerance must not be negative.',
      );
    }
    if (request.signature.isEmpty ||
        !request.signature.startsWith('sha256=') ||
        request.signature.length != 'sha256='.length + 64 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(request.signature.substring(7))) {
      return AccountWebhookDecision.malformedSignature;
    }
    final expected = signatureHeader(
      secret: secret,
      timestamp: request.timestamp,
      body: request.body,
    );
    if (!_constantTimeEquals(request.signature, expected)) {
      return AccountWebhookDecision.signatureMismatch;
    }
    final current = (now ?? DateTime.now()).toUtc();
    final drift = current.difference(request.timestamp.toUtc()).abs();
    if (drift > tolerance) {
      return AccountWebhookDecision.stale;
    }
    if (replayGuard != null) {
      if (replayGuard.isReplay(
        request.deliveryId,
        now: current,
        retention: tolerance,
      )) {
        return AccountWebhookDecision.replayed;
      }
      replayGuard.remember(request.deliveryId, current);
    }
    return AccountWebhookDecision.verified;
  }

  /// The entitlement state of [grant] at [at].
  ///
  /// Four states, evaluated in order: before issuance, after expiry, then the
  /// grant's own recorded state. The first rule is the one the live model
  /// was missing — an entitlement signed for 1 October must not read as
  /// granted on 1 January, whatever the caller's clock believes.
  static String entitlementStateAt({
    required EntitlementGrantProbe grant,
    required DateTime at,
  }) {
    if (!at.isUtc) {
      throw ArgumentError.value(at, 'at', 'Must be UTC.');
    }
    if (at.isBefore(grant.grantedAt.toUtc())) {
      return 'notYetIssued';
    }
    final expiresAt = grant.expiresAt;
    if (expiresAt != null && !at.isBefore(expiresAt.toUtc())) {
      return 'expired';
    }
    return 'granted';
  }

  /// Validates a bucket map against [requiredBuckets].
  static AccountVerificationReport buildReport(
    Map<String, AccountVerificationBucket> results,
  ) {
    for (final key in results.keys) {
      if (!requiredBuckets.contains(key)) {
        throw ArgumentError.value(
          key,
          'results',
          'Bucket outside the canonical required_outputs of step 115.54.',
        );
      }
    }
    final missing = requiredBuckets
        .where((bucket) => !results.containsKey(bucket))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError('Missing canonical bucket(s): ${missing.join(', ')}.');
    }
    final ordered = <String, AccountVerificationBucket>{
      for (final bucket in requiredBuckets) bucket: results[bucket]!,
    };
    for (final entry in ordered.entries) {
      _validate(entry.key, entry.value);
    }
    return AccountVerificationReport._(Map.unmodifiable(ordered));
  }

  static void _validate(String key, AccountVerificationBucket row) {
    if (row.bucket != key) {
      throw ArgumentError.value(
        row.bucket,
        'results',
        'Row labelled ${row.bucket} is stored under the canonical key $key.',
      );
    }
    final seen = <String>{};
    for (final check in row.checks) {
      if (!seen.add(check.name)) {
        throw ArgumentError.value(
          check.name,
          'results',
          'Bucket $key records the same check twice.',
        );
      }
    }
    switch (row.status) {
      case AccountVerificationBucketStatus.pass:
        if (row.checks.isEmpty) {
          throw ArgumentError.value(
            row.checks,
            'results',
            'Bucket $key claims pass without a recorded check.',
          );
        }
        final notHeld = row.checks
            .where((check) => !check.held)
            .map((check) => check.name)
            .toList(growable: false);
        if (notHeld.isNotEmpty) {
          throw ArgumentError.value(
            notHeld.join(', '),
            'results',
            'Bucket $key claims pass while ${notHeld.length} check(s) did not hold.',
          );
        }
      case AccountVerificationBucketStatus.fail:
      case AccountVerificationBucketStatus.blocked:
        if (trimmedNoteLength(row.note) < 30) {
          throw ArgumentError.value(
            row.note,
            'results',
            'Bucket $key must explain itself in at least 30 characters.',
          );
        }
        if (row.status == AccountVerificationBucketStatus.blocked &&
            row.checks.isNotEmpty) {
          throw ArgumentError.value(
            row.measured,
            'results',
            'Bucket $key is blocked and may not carry local checks.',
          );
        }
      case AccountVerificationBucketStatus.pending:
        if (row.checks.isNotEmpty) {
          throw ArgumentError.value(
            row.measured,
            'results',
            'Bucket $key is pending and may not claim a recorded check.',
          );
        }
    }
  }

  /// Length of [note] ignoring surrounding whitespace, so a padded blank
  /// string cannot pass as an explanation.
  static int trimmedNoteLength(String note) => note.trim().length;
}

/// Constant-time comparison for equal-length ASCII signatures.
///
/// The loop walks both strings to the same length and folds the difference of
/// every byte, so the time taken does not depend on how many leading
/// characters matched. Length is compared first because a length mismatch is
/// public information anyway.
bool _constantTimeEquals(String first, String second) {
  if (first.length != second.length) return false;
  var difference = 0;
  for (var index = 0; index < first.length; index++) {
    difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
  }
  return difference == 0;
}
