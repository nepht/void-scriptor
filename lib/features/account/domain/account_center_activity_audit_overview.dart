/// Sprint 115.31 — Activity & Audit Overview.
///
/// Local, redacted account audit metadata only. External audit backends,
/// provider telemetry, billing systems, and authorization remain outside this
/// seam.
library;

import 'dart:collection';

enum AccountAuditCategory {
  account,
  connection,
  sync,
  backup,
  security,
  billing,
  sensitiveAction,
}

enum AccountAuditResult { succeeded, failed, denied, partial, unknown }

final class AccountAuditActor {
  const AccountAuditActor({required this.id, required this.displayName});

  final String id;
  final String displayName;
}

final class AccountAuditEvent {
  AccountAuditEvent({
    required String id,
    required this.category,
    required this.occurredAt,
    required AccountAuditActor actor,
    required this.result,
    required Map<String, Object?> details,
    required Set<String> sensitiveDetailKeys,
    this.detailLink,
  }) : id = _required(id, 'id'),
       actor = AccountAuditActor(
         id: _required(actor.id, 'actor.id'),
         displayName: _required(actor.displayName, 'actor.displayName'),
       ),
       _details = Map.unmodifiable(details),
       _sensitiveDetailKeys = Set.unmodifiable(
         sensitiveDetailKeys.map((key) => _required(key, 'sensitiveDetailKey')),
       ) {
    if (!occurredAt.isUtc) {
      throw ArgumentError.value(occurredAt, 'occurredAt', 'Must be UTC.');
    }
    if (detailLink != null &&
        (!detailLink!.startsWith('/account/cloud-center') ||
            Uri.tryParse(detailLink!) == null)) {
      throw ArgumentError.value(detailLink, 'detailLink');
    }
    final unknownSensitiveKeys = _sensitiveDetailKeys.difference(
      _details.keys.toSet(),
    );
    if (unknownSensitiveKeys.isNotEmpty) {
      throw ArgumentError.value(
        unknownSensitiveKeys,
        'sensitiveDetailKeys',
        'Every sensitive key must identify an event detail.',
      );
    }
  }

  final String id;
  final AccountAuditCategory category;
  final DateTime occurredAt;
  final AccountAuditActor actor;
  final AccountAuditResult result;
  final Map<String, Object?> _details;
  final Set<String> _sensitiveDetailKeys;
  final String? detailLink;

  Map<String, Object?> get publicDetails => UnmodifiableMapView(
    _details.map(
      (key, value) => MapEntry(
        key,
        _sensitiveDetailKeys.contains(key) ? '[REDACTED]' : value,
      ),
    ),
  );

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'id': id,
    'category': category.name,
    'occurred_at': occurredAt.toIso8601String(),
    'actor': <String, Object?>{
      'id': actor.id,
      'display_name': actor.displayName,
    },
    'result': result.name,
    'details': publicDetails,
    'detail_link': detailLink,
  };
}

final class AccountAuditFilter {
  AccountAuditFilter({
    Set<AccountAuditCategory>? categories,
    Set<AccountAuditResult>? results,
    this.actorId,
    this.from,
    this.to,
  }) : categories = Set.unmodifiable(categories ?? AccountAuditCategory.values),
       results = Set.unmodifiable(results ?? AccountAuditResult.values) {
    if (this.categories.isEmpty || this.results.isEmpty) {
      throw ArgumentError('Audit filters must include a category and result.');
    }
    if (from != null && !from!.isUtc || to != null && !to!.isUtc) {
      throw ArgumentError('Audit filter timestamps must be UTC.');
    }
    if (from != null && to != null && from!.isAfter(to!)) {
      throw ArgumentError('Audit filter start must not follow its end.');
    }
  }

  final Set<AccountAuditCategory> categories;
  final Set<AccountAuditResult> results;
  final String? actorId;
  final DateTime? from;
  final DateTime? to;

  bool matches(AccountAuditEvent event) {
    final normalizedActor = actorId?.trim();
    return categories.contains(event.category) &&
        results.contains(event.result) &&
        (normalizedActor == null ||
            normalizedActor.isEmpty ||
            event.actor.id == normalizedActor) &&
        (from == null || !event.occurredAt.isBefore(from!)) &&
        (to == null || !event.occurredAt.isAfter(to!));
  }
}

final class AccountCenterActivityAuditOverview {
  AccountCenterActivityAuditOverview({
    required this.retention,
    required Iterable<AccountAuditEvent> events,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _events = List.unmodifiable(events) {
    if (retention <= Duration.zero) {
      throw ArgumentError.value(retention, 'retention');
    }
    _requireUnique(_events.map((event) => event.id), 'event.id');
  }

  final Duration retention;
  final DateTime Function() _now;
  final List<AccountAuditEvent> _events;

  DateTime get retentionCutoff => _now().toUtc().subtract(retention);

  List<AccountAuditEvent> get retainedEvents => _ordered(
    _events.where((event) => !event.occurredAt.isBefore(retentionCutoff)),
  );

  List<AccountAuditEvent> query(AccountAuditFilter filter) =>
      _ordered(retainedEvents.where(filter.matches));

  List<AccountAuditEvent> _ordered(Iterable<AccountAuditEvent> events) {
    final result = events.toList(growable: false)
      ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    return List.unmodifiable(result);
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

void _requireUnique(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ArgumentError.value(value, field, 'Must be unique.');
    }
  }
}
