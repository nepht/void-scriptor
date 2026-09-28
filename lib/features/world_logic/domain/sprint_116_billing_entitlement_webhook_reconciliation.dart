import 'dart:convert';
import 'dart:io';

enum Sprint116ReconciliationState { pass, fail, blocked }

class Sprint116WebhookEvent {
  const Sprint116WebhookEvent({
    required this.eventId,
    required this.providerId,
    required this.sequence,
    required this.occurredAtEpochMs,
    required this.signatureStatus,
    required this.eventType,
    this.retryCount = 0,
    this.periodEndEpochMs,
    this.graceEndEpochMs,
    this.cancelAtPeriodEnd = false,
  });

  final String eventId;
  final String providerId;
  final int sequence;
  final int occurredAtEpochMs;
  final String signatureStatus;
  final String eventType;
  final int retryCount;
  final int? periodEndEpochMs;
  final int? graceEndEpochMs;
  final bool cancelAtPeriodEnd;
}

class Sprint116OfflineEntitlement {
  const Sprint116OfflineEntitlement({
    required this.status,
    required this.entitlementUntilEpochMs,
    required this.asOfEpochMs,
  });

  final String status;
  final int entitlementUntilEpochMs;
  final int asOfEpochMs;
}

class Sprint116ReconciliationReport {
  Sprint116ReconciliationReport({
    required this.state,
    required this.invalidRecords,
    required this.appliedOrder,
    required this.dedupedEventIds,
    required this.rejectedEventIds,
    required this.effectiveStatus,
    required this.entitlementUntilEpochMs,
    required this.asOfEpochMs,
  });

  final Sprint116ReconciliationState state;
  final List<String> invalidRecords;
  final List<String> appliedOrder;
  final List<String> dedupedEventIds;
  final List<String> rejectedEventIds;
  final String effectiveStatus;
  final int? entitlementUntilEpochMs;
  final int asOfEpochMs;

  String get externalGates =>
      Sprint116BillingReconciliationContract.externalGates;
}

abstract final class Sprint116BillingReconciliationContract {
  static const String canonicalStep = '116.40';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> requiredAcceptance = <String>[
    'idempotency',
    'signature',
    'event_order',
    'retry',
    'grace_period',
    'cancellation',
    'refund',
    'entitlement_consistency',
  ];
  static const List<String> supportedEventTypes = <String>[
    'renewal',
    'payment_failed',
    'cancellation',
    'refund',
  ];
  static const String verifiedSignature = 'VERIFIED';
  static const int maxRetryCount = 5;
  static const String offlineConsistencyLabel =
      'entitlement_consistency:offline';
}

class Sprint116BillingReconciliation {
  Sprint116ReconciliationReport reconcile({
    List<Sprint116WebhookEvent>? events,
    Sprint116OfflineEntitlement? offlineEntitlement,
  }) {
    // Manifest fallback only applies in default mode: callers that supply
    // their own event queue must also supply the offline snapshot, otherwise
    // consistency would silently borrow a fixture that never applied.
    final manifestMode = events == null;
    final effective = events ?? _readManifestEvents();
    final offline =
        offlineEntitlement ??
        (manifestMode ? _readManifestOfflineEntitlement() : null);

    if (effective.isEmpty) {
      return Sprint116ReconciliationReport(
        state: Sprint116ReconciliationState.blocked,
        invalidRecords: const <String>['events'],
        appliedOrder: const <String>[],
        dedupedEventIds: const <String>[],
        rejectedEventIds: const <String>[],
        effectiveStatus: 'none',
        entitlementUntilEpochMs: null,
        asOfEpochMs: 0,
      );
    }

    final invalid = <String>[];
    final deduped = <String>[];
    final rejected = <String>[];
    final applied = <Sprint116WebhookEvent>[];
    final processed = <String>{};

    // Arrival order is never trusted: the queue is replayed in provider
    // sequence order so an out-of-order webhook cannot reorder entitlement.
    final ordered = List<Sprint116WebhookEvent>.of(effective)
      ..sort((a, b) {
        if (a.sequence != b.sequence) {
          return a.sequence.compareTo(b.sequence);
        }
        if (a.occurredAtEpochMs != b.occurredAtEpochMs) {
          return a.occurredAtEpochMs.compareTo(b.occurredAtEpochMs);
        }
        return a.eventId.compareTo(b.eventId);
      });

    var maxOccurred = 0;
    for (final event in ordered) {
      if (event.occurredAtEpochMs > maxOccurred) {
        maxOccurred = event.occurredAtEpochMs;
      }
      final id = event.eventId.trim();
      if (id.isEmpty) {
        invalid.add('event_id:${event.sequence}');
        continue;
      }
      // Fail-closed idempotency: an event id is consumed exactly once, so a
      // provider retry or duplicate delivery can never replay an effect.
      if (!processed.add(id)) {
        deduped.add(id);
        continue;
      }
      if (event.signatureStatus.trim().toUpperCase() !=
          Sprint116BillingReconciliationContract.verifiedSignature) {
        rejected.add(id);
        invalid.add('signature:$id');
        continue;
      }
      if (event.retryCount >
          Sprint116BillingReconciliationContract.maxRetryCount) {
        rejected.add(id);
        invalid.add('retry:$id');
        continue;
      }
      final type = event.eventType.trim();
      if (!Sprint116BillingReconciliationContract.supportedEventTypes.contains(
        type,
      )) {
        invalid.add('event_type:$id');
        continue;
      }
      if (type == 'renewal' && event.periodEndEpochMs == null) {
        invalid.add('period_end:$id');
        continue;
      }
      if (type == 'payment_failed' && event.graceEndEpochMs == null) {
        invalid.add('grace_end:$id');
        continue;
      }
      if (type == 'cancellation' &&
          event.cancelAtPeriodEnd &&
          event.periodEndEpochMs == null) {
        invalid.add('period_end:$id');
        continue;
      }
      applied.add(event);
    }

    var base = 'none';
    int? until;
    int? graceEnd;
    for (final event in applied) {
      if (event.eventType == 'renewal') {
        base = 'active';
        until = event.periodEndEpochMs;
        graceEnd = null;
      } else if (event.eventType == 'payment_failed') {
        base = 'grace';
        until = event.graceEndEpochMs;
        graceEnd = event.graceEndEpochMs;
      } else if (event.eventType == 'cancellation') {
        graceEnd = null;
        if (event.cancelAtPeriodEnd) {
          base = 'cancelled_scheduled';
          until = event.periodEndEpochMs;
        } else {
          base = 'revoked';
          until = event.occurredAtEpochMs;
        }
      } else if (event.eventType == 'refund') {
        base = 'revoked';
        until = event.occurredAtEpochMs;
        graceEnd = null;
      }
    }

    final asOf = offline?.asOfEpochMs ?? maxOccurred;
    final String effectiveStatus;
    if (base == 'grace') {
      final bound = graceEnd ?? until;
      effectiveStatus = bound != null && asOf <= bound
          ? 'active_grace'
          : 'lapsed';
    } else if (base == 'active' || base == 'cancelled_scheduled') {
      effectiveStatus = until != null && asOf > until ? 'expired' : base;
    } else {
      effectiveStatus = base;
    }

    // Offline entitlement must mirror the reconciled provider state exactly;
    // a stale or optimistic local snapshot fails instead of silently passing.
    if (offline == null ||
        offline.status.trim() != effectiveStatus ||
        offline.entitlementUntilEpochMs != until) {
      invalid.add(
        Sprint116BillingReconciliationContract.offlineConsistencyLabel,
      );
    }

    return Sprint116ReconciliationReport(
      state: invalid.isEmpty
          ? Sprint116ReconciliationState.pass
          : Sprint116ReconciliationState.fail,
      invalidRecords: invalid,
      appliedOrder: applied
          .map((event) => event.eventId)
          .toList(growable: false),
      dedupedEventIds: deduped,
      rejectedEventIds: rejected,
      effectiveStatus: effectiveStatus,
      entitlementUntilEpochMs: until,
      asOfEpochMs: asOf,
    );
  }

  Map<String, dynamic>? _readManifest() {
    final file = File(Sprint116BillingReconciliationContract.manifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<Sprint116WebhookEvent> _readManifestEvents() {
    final raw = _readManifest()?['events'];
    if (raw is! List) return <Sprint116WebhookEvent>[];
    return raw
        .whereType<Map>()
        .map(
          (item) => Sprint116WebhookEvent(
            eventId: item['event_id']?.toString() ?? '',
            providerId: item['provider_id']?.toString() ?? '',
            sequence: (item['sequence'] as num?)?.toInt() ?? 0,
            occurredAtEpochMs:
                (item['occurred_at_epoch_ms'] as num?)?.toInt() ?? 0,
            signatureStatus: item['signature_status']?.toString() ?? '',
            eventType: item['event_type']?.toString() ?? '',
            retryCount: (item['retry_count'] as num?)?.toInt() ?? 0,
            periodEndEpochMs: (item['period_end_epoch_ms'] as num?)?.toInt(),
            graceEndEpochMs: (item['grace_end_epoch_ms'] as num?)?.toInt(),
            cancelAtPeriodEnd: item['cancel_at_period_end'] == true,
          ),
        )
        .toList(growable: false);
  }

  Sprint116OfflineEntitlement? _readManifestOfflineEntitlement() {
    final raw = _readManifest()?['offline_entitlement'];
    if (raw is! Map) return null;
    final status = raw['status'];
    final until = raw['entitlement_until_epoch_ms'];
    final asOf = raw['as_of_epoch_ms'];
    if (status is! String || until is! num || asOf is! num) return null;
    return Sprint116OfflineEntitlement(
      status: status,
      entitlementUntilEpochMs: until.toInt(),
      asOfEpochMs: asOf.toInt(),
    );
  }
}
