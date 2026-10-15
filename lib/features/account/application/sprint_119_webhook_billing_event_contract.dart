import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Signature algorithms accepted by the webhook and billing event contract.
///
/// The allow-list is closed: an unrecognized algorithm is refused rather than
/// downgraded, so a provider cannot negotiate a weaker scheme.
enum WebhookSignatureAlgorithm {
  /// HMAC-SHA256 over the timestamp-bound signing material.
  hmacSha256,

  /// An algorithm this build cannot verify. Always refused.
  unknown,
}

/// The disposition recorded for a delivered event.
enum WebhookDecision {
  /// The delivery passed every gate and was applied.
  accepted,

  /// The delivery failed at least one gate and was not applied.
  rejected,

  /// The delivery could not be decided yet and was held.
  deferred,
}

/// A provider delivery signature.
///
/// The digest is treated as a secret-equivalent value: [toJson] redacts it and
/// [toString] never renders it, so a signature cannot leak through logging.
final class WebhookSignature {
  const WebhookSignature({
    required this.algorithm,
    required this.keyId,
    required this.timestampUtc,
    required this.value,
  });

  /// The declared algorithm, matched against the closed allow-list.
  final WebhookSignatureAlgorithm algorithm;

  /// The provider key identifier the digest was produced with.
  final String keyId;

  /// The provider's signing timestamp, in UTC.
  final DateTime timestampUtc;

  /// The lowercase hex digest.
  final String value;

  /// A redacted projection safe for diagnostics and audit output.
  Map<String, Object?> toJson() => <String, Object?>{
    'algorithm': algorithm.name,
    'key_id': keyId,
    'timestamp': timestampUtc.toUtc().toIso8601String(),
    'signature': '[REDACTED]',
  };

  @override
  String toString() => 'WebhookSignature(${algorithm.name}, keyId: $keyId)';
}

/// A billing event delivery observed locally.
final class WebhookEvent {
  const WebhookEvent({
    required this.eventId,
    required this.sequence,
    required this.receivedAtUtc,
    required this.type,
  });

  /// The opaque provider event reference.
  final String eventId;

  /// The per-stream sequence assigned by the provider.
  final int sequence;

  /// When the delivery was observed locally.
  final DateTime receivedAtUtc;

  /// The event type, for example `invoice.paid`.
  final String type;

  @override
  String toString() => 'WebhookEvent($type, sequence: $sequence)';
}

/// The deterministic difference between local and provider event sets.
final class ReconciliationReport {
  const ReconciliationReport({
    required this.missingLocally,
    required this.unknownLocally,
  });

  /// Provider references this node never applied, sorted.
  final List<String> missingLocally;

  /// Local references the provider does not know about, sorted.
  final List<String> unknownLocally;

  /// Whether both sides agree exactly.
  bool get isConsistent => missingLocally.isEmpty && unknownLocally.isEmpty;

  @override
  String toString() =>
      'ReconciliationReport(missing: ${missingLocally.length}, '
      'unknown: ${unknownLocally.length})';
}

/// One append-only audit record.
final class WebhookAuditEntry {
  const WebhookAuditEntry({
    required this.sequence,
    required this.eventId,
    required this.decision,
    required this.reason,
    required this.atUtc,
  });

  /// The monotonic position of this record in the trail.
  final int sequence;

  /// The opaque provider event reference.
  final String eventId;

  /// The decision taken.
  final WebhookDecision decision;

  /// The stable reason key for the decision.
  final String reason;

  /// When the decision was recorded.
  final DateTime atUtc;

  /// A redacted projection; the event reference is never serialized.
  Map<String, Object?> toJson() => <String, Object?>{
    'sequence': sequence,
    'event_ref': '[REDACTED]',
    'decision': decision.name,
    'reason': reason,
    'at': atUtc.toUtc().toIso8601String(),
  };

  @override
  String toString() =>
      'WebhookAuditEntry(#$sequence, ${decision.name}, $reason)';
}

/// An append-only, ordered trail of webhook decisions.
final class WebhookAuditTrail {
  final List<WebhookAuditEntry> _entries = <WebhookAuditEntry>[];

  /// The recorded entries, in append order. Not modifiable.
  List<WebhookAuditEntry> get entries =>
      List<WebhookAuditEntry>.unmodifiable(_entries);

  /// Whether the recorded sequences increase strictly.
  bool get isOrdered => WebhookBillingEventContract.isOrderedAudit(_entries);

  /// Appends a decision. There is no update or delete path.
  void record({
    required String eventId,
    required WebhookDecision decision,
    required String reason,
    required DateTime atUtc,
  }) {
    _entries.add(
      WebhookAuditEntry(
        sequence: _entries.length + 1,
        eventId: eventId,
        decision: decision,
        reason: reason,
        atUtc: atUtc.toUtc(),
      ),
    );
  }
}

/// A process-local replay guard keyed on the provider event reference.
///
/// Registering a reference that was already seen is refused, which is how a
/// replayed delivery is stopped. Entries older than the freshness window can be
/// purged so the guard cannot grow without bound.
final class WebhookReplayGuard {
  WebhookReplayGuard({
    this.tolerance = WebhookBillingEventContract.signatureTolerance,
  });

  /// How long a reference stays memorable.
  final Duration tolerance;

  final Map<String, DateTime> _seen = <String, DateTime>{};

  /// How many references are currently memorable.
  int get trackedCount => _seen.length;

  /// Whether the reference has already been registered.
  bool hasSeen(String eventId) => _seen.containsKey(eventId);

  /// Registers a delivery. Returns `false` when it is a replay.
  bool register({required String eventId, required DateTime atUtc}) {
    if (_seen.containsKey(eventId)) {
      return false;
    }
    _seen[eventId] = atUtc.toUtc();
    return true;
  }

  /// Drops entries at or before the freshness cutoff, returning how many went.
  int purgeExpired(DateTime now) {
    final cutoff = now.toUtc().subtract(tolerance);
    final expired = _seen.entries
        .where(
          (MapEntry<String, DateTime> entry) => !entry.value.isAfter(cutoff),
        )
        .map((MapEntry<String, DateTime> entry) => entry.key)
        .toList(growable: false);
    for (final key in expired) {
      _seen.remove(key);
    }
    return expired.length;
  }
}

/// A process-local idempotency ledger.
///
/// A key may be claimed once. While claimed but incomplete the entry is
/// pending; once completed the recorded outcome is replayable instead of the
/// effect being applied a second time.
final class IdempotencyLedger {
  final Map<String, String?> _entries = <String, String?>{};

  /// Whether any claimed key has not completed yet.
  bool get hasPending => _entries.values.any((String? value) => value == null);

  /// Claims a key. Returns `false` when it was already claimed.
  bool begin(String key) {
    if (_entries.containsKey(key)) {
      return false;
    }
    _entries[key] = null;
    return true;
  }

  /// Records the outcome for a claimed key. Unknown keys are ignored.
  void complete(String key, String outcome) {
    if (_entries.containsKey(key)) {
      _entries[key] = outcome;
    }
  }

  /// The recorded outcome, or `null` while pending or unclaimed.
  String? outcomeFor(String key) => _entries[key];
}

/// The local webhook and billing event contract for roadmap step 119.18.
///
/// Every gate is fail-closed: an unverifiable signature, a replayed reference,
/// a repeated idempotency key, an out-of-order sequence, or a permanent error
/// all refuse the delivery instead of guessing. Nothing in this contract stores
/// a signing secret, a digest, a payload, or a provider credential.
abstract final class WebhookBillingEventContract {
  /// The manifest describing this step.
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_webhook_billing_event_contract.json';

  /// The canonical step identifier.
  static const String canonicalStep = '119.18';

  /// How far a delivery timestamp may drift before it is refused.
  static const Duration signatureTolerance = Duration(minutes: 5);

  /// The first retry delay.
  static const Duration retryBase = Duration(seconds: 2);

  /// The largest retry delay the schedule will ever produce.
  static const Duration retryCap = Duration(minutes: 5);

  /// The largest backoff exponent applied before the cap takes over.
  static const int maxBackoffExponent = 8;

  /// The acceptance points this contract must satisfy.
  static const List<String> requiredAcceptance = <String>[
    'signature',
    'replay_protection',
    'idempotency',
    'ordering',
    'retry',
    'reconciliation',
    'audit',
  ];

  /// Steps that do not add named methods, such as this contract, declare none.
  static const List<String> requiredMethods = <String>[];

  static final RegExp _hexDigest = RegExp(r'^[0-9a-f]{64}$');

  static final RegExp _eventRef = RegExp(
    r'^evtref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _idempotencyRef = RegExp(
    r'^idemref:[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}$',
  );

  static final RegExp _secretRef = RegExp(
    r'\b(?:evtref|idemref|payref|chkref|invref|modelref|assetref|orgref|'
    r'resref|jobref|projref|repo_ref|whsec|sk_live|pk_live)'
    r':[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}\b',
    caseSensitive: false,
  );

  /// The raw HMAC-SHA256 of [data] under [key], as lowercase hex.
  ///
  /// Exposed so the primitive can be checked against published vectors.
  static String hmacSha256Hex({required String key, required String data}) =>
      Hmac(sha256, utf8.encode(key)).convert(utf8.encode(data)).toString();

  /// The material a delivery signature is computed over.
  ///
  /// The timestamp is bound into the material, so a signature cannot be reused
  /// with a different timestamp to walk around the freshness window.
  static String signedMaterial({
    required WebhookSignature signature,
    required String payload,
  }) => '${signature.timestampUtc.toUtc().toIso8601String()}.$payload';

  /// Computes the expected digest for a delivery.
  static String computeSignature({
    required String key,
    required WebhookSignature signature,
    required String payload,
  }) => hmacSha256Hex(
    key: key,
    data: signedMaterial(signature: signature, payload: payload),
  );

  /// Verifies a delivery signature and returns the diagnostics that failed.
  ///
  /// An empty result means the delivery is authentic within the freshness
  /// window. Any other result means it must not be applied. The comparison is
  /// best-effort constant time; Dart offers no constant-time primitive and no
  /// timing-attack guarantee is claimed.
  static List<String> verifySignature({
    required WebhookSignature signature,
    required String payload,
    required String key,
    required DateTime now,
    Duration tolerance = signatureTolerance,
  }) {
    final diagnostics = <String>[];

    if (signature.algorithm != WebhookSignatureAlgorithm.hmacSha256) {
      diagnostics.add('algorithm_unsupported');
    }
    if (signature.keyId.trim().isEmpty) {
      diagnostics.add('key_id_missing');
    }
    if (!_hexDigest.hasMatch(signature.value)) {
      diagnostics.add('signature_shape_invalid');
    }

    final age = now.toUtc().difference(signature.timestampUtc.toUtc()).abs();
    if (age > tolerance) {
      diagnostics.add('timestamp_outside_tolerance');
    }

    if (diagnostics.isEmpty) {
      final expected = computeSignature(
        key: key,
        signature: signature,
        payload: payload,
      );
      if (!_constantTimeEquals(expected, signature.value)) {
        diagnostics.add('signature_mismatch');
      }
    }

    return diagnostics;
  }

  /// Whether [value] is a well-formed opaque idempotency handle.
  static bool isValidIdempotencyKey(String value) =>
      _idempotencyRef.hasMatch(value);

  /// Whether [value] is a well-formed opaque event reference.
  static bool isValidEventId(String value) => _eventRef.hasMatch(value);

  /// Whether the event sequences increase strictly. An empty set is not
  /// ordered, so a missing stream cannot masquerade as a consistent one.
  static bool isOrdered(Iterable<WebhookEvent> events) {
    var previous = -1;
    var count = 0;
    for (final event in events) {
      if (event.sequence <= previous) {
        return false;
      }
      previous = event.sequence;
      count++;
    }
    return count > 0;
  }

  /// Whether the audit entries increase strictly.
  static bool isOrderedAudit(Iterable<WebhookAuditEntry> entries) {
    var previous = 0;
    var count = 0;
    for (final entry in entries) {
      if (entry.sequence <= previous) {
        return false;
      }
      previous = entry.sequence;
      count++;
    }
    return count > 0;
  }

  /// Whether an incoming sequence may be applied over the last applied one.
  static bool shouldAcceptSequence({
    required int incoming,
    required int lastApplied,
  }) => incoming > lastApplied;

  /// The deterministic exponential backoff delay for [attempt], one-based.
  static Duration retryDelay({required int attempt}) {
    final safeAttempt = attempt < 1 ? 1 : attempt;
    final rawExponent = safeAttempt - 1;
    final exponent = rawExponent > maxBackoffExponent
        ? maxBackoffExponent
        : rawExponent;
    final millis = retryBase.inMilliseconds * (1 << exponent);
    return Duration(
      milliseconds: millis > retryCap.inMilliseconds
          ? retryCap.inMilliseconds
          : millis,
    );
  }

  /// Whether another attempt is warranted. A permanent error never retries.
  static bool shouldRetry({
    required int attempt,
    required bool retryable,
    required int maxAttempts,
  }) => retryable && attempt < maxAttempts;

  /// Diffs local deliveries against the provider's event references.
  ///
  /// The difference is reported, never auto-merged: a reference the provider
  /// claims but this node never applied, and a reference this node applied but
  /// the provider does not know about, are both surfaced for a human.
  static ReconciliationReport reconcile({
    required Iterable<WebhookEvent> local,
    required Set<String> providerEventIds,
  }) {
    final localIds = local.map((WebhookEvent event) => event.eventId).toSet();
    final missing = providerEventIds.difference(localIds).toList()..sort();
    final unknown = localIds.difference(providerEventIds).toList()..sort();
    return ReconciliationReport(
      missingLocally: missing,
      unknownLocally: unknown,
    );
  }

  /// Replaces opaque references in [text] so a diagnostic cannot leak one.
  static String redact(String text) =>
      text.replaceAll(_secretRef, '[REDACTED]');

  /// Validates a manifest against this step's contract.
  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];

    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final acceptance = manifest['acceptance'];
    final declared = acceptance is Map
        ? acceptance.keys.map((Object? key) => '$key').toSet()
        : const <String>{};
    for (final required in requiredAcceptance) {
      if (!declared.contains(required)) {
        diagnostics.add('acceptance_missing:$required');
      }
    }

    if (requiredMethods.isNotEmpty) {
      final methods = manifest['required_methods'];
      final declaredMethods = methods is List
          ? methods.map((Object? method) => '$method').toSet()
          : const <String>{};
      for (final required in requiredMethods) {
        if (!declaredMethods.contains(required)) {
          diagnostics.add('method_missing:$required');
        }
      }
    }

    return diagnostics;
  }

  /// Validates the committed canonical manifest for this step.
  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      return <String>['manifest_missing:$manifestPath'];
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return <String>['manifest_not_an_object:$manifestPath'];
    }
    return validateManifest(decoded);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var difference = 0;
    for (var index = 0; index < a.length; index++) {
      difference |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }
    return difference == 0;
  }
}
