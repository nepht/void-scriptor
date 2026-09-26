/// Sprint 115.32 — Security Center Summary.
///
/// Local account-security metadata only. Identity providers, secure-storage
/// backends, session revocation, and alert delivery remain injected/external.
library;

import 'dart:collection';

enum SecuritySignalStatus { healthy, attention, critical, unknown, unavailable }

enum SecurityAlertSeverity { info, warning, critical }

final class MfaSecuritySummary {
  MfaSecuritySummary({
    required this.status,
    required Set<String> enrolledMethods,
    required this.recoveryCodesRemaining,
  }) : enrolledMethods = Set.unmodifiable(enrolledMethods) {
    if (recoveryCodesRemaining != null && recoveryCodesRemaining! < 0) {
      throw ArgumentError.value(
        recoveryCodesRemaining,
        'recoveryCodesRemaining',
      );
    }
    if (_requiresKnownValues(status) && enrolledMethods.isEmpty) {
      throw ArgumentError('Known MFA status requires an enrolled method.');
    }
  }

  final SecuritySignalStatus status;
  final Set<String> enrolledMethods;
  final int? recoveryCodesRemaining;
}

final class PasswordSecuritySummary {
  PasswordSecuritySummary({required this.status, required this.changedAt}) {
    if (changedAt != null && !changedAt!.isUtc) {
      throw ArgumentError.value(changedAt, 'changedAt', 'Must be UTC.');
    }
  }

  final SecuritySignalStatus status;
  final DateTime? changedAt;
}

final class DeviceSecuritySummary {
  DeviceSecuritySummary({required this.status, required this.count}) {
    _validateOptionalCount(count, status, 'count');
  }

  final SecuritySignalStatus status;
  final int? count;
}

final class SessionSecuritySummary {
  SessionSecuritySummary({
    required this.status,
    required this.activeCount,
    required this.suspiciousCount,
  }) {
    _validateOptionalCount(activeCount, status, 'activeCount');
    _validateOptionalCount(suspiciousCount, status, 'suspiciousCount');
    if (activeCount != null &&
        suspiciousCount != null &&
        suspiciousCount! > activeCount!) {
      throw ArgumentError('Suspicious sessions cannot exceed active sessions.');
    }
  }

  final SecuritySignalStatus status;
  final int? activeCount;
  final int? suspiciousCount;
}

final class SecureStoreSecuritySummary {
  SecureStoreSecuritySummary({
    required this.status,
    required this.backend,
    required this.lastCheckedAt,
  }) {
    if (backend != null && backend!.trim().isEmpty) {
      throw ArgumentError.value(backend, 'backend');
    }
    if (lastCheckedAt != null && !lastCheckedAt!.isUtc) {
      throw ArgumentError.value(lastCheckedAt, 'lastCheckedAt', 'Must be UTC.');
    }
    if (_requiresKnownValues(status) &&
        (backend == null || lastCheckedAt == null)) {
      throw ArgumentError(
        'Known secure-store status requires backend and check timestamp.',
      );
    }
  }

  final SecuritySignalStatus status;
  final String? backend;
  final DateTime? lastCheckedAt;
}

final class SecurityCenterAlert {
  SecurityCenterAlert({
    required String id,
    required this.severity,
    required String title,
    required this.occurredAt,
  }) : id = _required(id, 'id'),
       title = _required(title, 'title') {
    if (!occurredAt.isUtc) {
      throw ArgumentError.value(occurredAt, 'occurredAt', 'Must be UTC.');
    }
  }

  final String id;
  final SecurityAlertSeverity severity;
  final String title;
  final DateTime occurredAt;
}

final class SecurityRecommendedAction {
  SecurityRecommendedAction({
    required this.id,
    required this.title,
    required this.priority,
    required this.route,
  }) {
    if (id.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Security action id and title are required.');
    }
    if (priority < 0) throw ArgumentError.value(priority, 'priority');
    if (!route.startsWith('/account/cloud-center') ||
        Uri.tryParse(route) == null) {
      throw ArgumentError.value(route, 'route');
    }
  }

  final String id;
  final String title;
  final int priority;
  final String route;
}

final class AccountCenterSecuritySummary {
  AccountCenterSecuritySummary({
    required this.mfa,
    required this.password,
    required this.trustedDevices,
    required this.sessions,
    required this.secureStore,
    required Iterable<SecurityCenterAlert> alerts,
    required Iterable<SecurityRecommendedAction> actions,
  }) : _alerts = List.unmodifiable(alerts),
       _actions = List.unmodifiable(actions) {
    _requireUnique(_alerts.map((alert) => alert.id), 'alert.id');
    _requireUnique(_actions.map((action) => action.id), 'action.id');
  }

  final MfaSecuritySummary mfa;
  final PasswordSecuritySummary password;
  final DeviceSecuritySummary trustedDevices;
  final SessionSecuritySummary sessions;
  final SecureStoreSecuritySummary secureStore;
  final List<SecurityCenterAlert> _alerts;
  final List<SecurityRecommendedAction> _actions;

  List<SecurityCenterAlert> get alerts {
    final result = _alerts.toList(growable: false)
      ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));
    return UnmodifiableListView(result);
  }

  List<SecurityRecommendedAction> get actions {
    final result = _actions.toList(growable: false)
      ..sort((left, right) {
        final priority = left.priority.compareTo(right.priority);
        return priority != 0 ? priority : left.id.compareTo(right.id);
      });
    return UnmodifiableListView(result);
  }

  SecuritySignalStatus get overallStatus {
    final signals = <SecuritySignalStatus>[
      mfa.status,
      password.status,
      trustedDevices.status,
      sessions.status,
      secureStore.status,
      ..._alerts.map(_statusForAlert),
    ];
    if (signals.contains(SecuritySignalStatus.critical)) {
      return SecuritySignalStatus.critical;
    }
    if (signals.contains(SecuritySignalStatus.attention)) {
      return SecuritySignalStatus.attention;
    }
    if (signals.contains(SecuritySignalStatus.healthy)) {
      return SecuritySignalStatus.healthy;
    }
    if (signals.contains(SecuritySignalStatus.unknown)) {
      return SecuritySignalStatus.unknown;
    }
    return SecuritySignalStatus.unavailable;
  }
}

SecuritySignalStatus _statusForAlert(SecurityCenterAlert alert) =>
    switch (alert.severity) {
      SecurityAlertSeverity.info => SecuritySignalStatus.healthy,
      SecurityAlertSeverity.warning => SecuritySignalStatus.attention,
      SecurityAlertSeverity.critical => SecuritySignalStatus.critical,
    };

bool _requiresKnownValues(SecuritySignalStatus status) =>
    status == SecuritySignalStatus.healthy ||
    status == SecuritySignalStatus.attention ||
    status == SecuritySignalStatus.critical;

void _validateOptionalCount(
  int? value,
  SecuritySignalStatus status,
  String field,
) {
  if (value != null && value < 0) throw ArgumentError.value(value, field);
  if (_requiresKnownValues(status) && value == null) {
    throw ArgumentError('$field is required for a known security status.');
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
