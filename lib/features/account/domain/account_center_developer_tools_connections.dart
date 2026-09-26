/// Sprint 115.28 — Developer Tools Connections.
///
/// Local, manifest-driven connection metadata only. External OAuth, repository
/// discovery, credentials, and provider certification remain outside this seam.
library;

import 'dart:collection';

import 'account_center_provider_connector_manifest.dart';

enum DeveloperRepositoryAccess { none, readOnly, readWrite }

final class DeveloperToolConnector {
  const DeveloperToolConnector(this.manifestEntry);

  final ProviderConnectorEntry manifestEntry;

  String get providerId => manifestEntry.providerId;
  String get displayName => manifestEntry.displayName;
  ProviderConnectorAvailability get availability => manifestEntry.availability;
  bool get isConnectable => manifestEntry.isConnectable;
}

final class DeveloperToolConnection {
  DeveloperToolConnection({
    required String connectionId,
    required String providerId,
    required Iterable<String> scopes,
    required this.repositoryAccess,
  }) : connectionId = _required(connectionId, 'connectionId'),
       providerId = _required(providerId, 'providerId').toLowerCase(),
       scopes = UnmodifiableSetView(_normalizeScopes(scopes));

  final String connectionId;
  final String providerId;
  final Set<String> scopes;
  final DeveloperRepositoryAccess repositoryAccess;
}

final class DeveloperToolAuditEvent {
  const DeveloperToolAuditEvent({
    required this.action,
    required this.providerId,
    required this.connectionId,
    required this.timestamp,
  });

  final String action;
  final String providerId;
  final String connectionId;
  final DateTime timestamp;

  Map<String, Object?> toJson() => <String, Object?>{
    'action': action,
    'provider_id': providerId,
    'connection_id': connectionId,
    'timestamp': timestamp.toIso8601String(),
  };
}

final class AccountCenterDeveloperToolsConnections {
  AccountCenterDeveloperToolsConnections({
    required this.manifest,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ProviderConnectorManifest manifest;
  final DateTime Function() _now;
  final Map<String, DeveloperToolConnection> _connections =
      <String, DeveloperToolConnection>{};
  final List<DeveloperToolAuditEvent> _audit = <DeveloperToolAuditEvent>[];

  List<DeveloperToolConnector> get connectors => List.unmodifiable(
    manifest.all
        .where((entry) => entry.category == ProviderConnectorCategory.developer)
        .map(DeveloperToolConnector.new),
  );

  List<DeveloperToolConnection> get activeConnections =>
      List.unmodifiable(_connections.values);

  List<DeveloperToolAuditEvent> get audit => List.unmodifiable(_audit);

  DeveloperToolConnection connect({
    required String providerId,
    required String connectionId,
    required Iterable<String> scopes,
    required DeveloperRepositoryAccess repositoryAccess,
  }) {
    final entry = manifest.require(providerId);
    if (entry.category != ProviderConnectorCategory.developer ||
        !entry.isConnectable) {
      throw StateError(
        'Developer connector "${entry.providerId}" is unavailable.',
      );
    }
    if (_connections.containsKey(connectionId.trim())) {
      throw ArgumentError.value(connectionId, 'connectionId');
    }

    final normalizedScopes = _normalizeScopes(scopes);
    _validateRepositoryAccess(normalizedScopes, repositoryAccess);
    final connection = DeveloperToolConnection(
      connectionId: connectionId,
      providerId: entry.providerId,
      scopes: normalizedScopes,
      repositoryAccess: repositoryAccess,
    );
    _connections[connection.connectionId] = connection;
    _record('connect', connection);
    return connection;
  }

  bool disconnect(String connectionId, {required bool confirmed}) {
    if (!confirmed) return false;
    final normalizedId = _required(connectionId, 'connectionId');
    final connection = _connections.remove(normalizedId);
    if (connection == null) {
      throw StateError('Unknown developer connection: $normalizedId');
    }
    _record('disconnect', connection);
    return true;
  }

  void _record(String action, DeveloperToolConnection connection) {
    _audit.add(
      DeveloperToolAuditEvent(
        action: action,
        providerId: connection.providerId,
        connectionId: connection.connectionId,
        timestamp: _now().toUtc(),
      ),
    );
  }
}

void _validateRepositoryAccess(
  Set<String> scopes,
  DeveloperRepositoryAccess access,
) {
  final hasRead = scopes.contains('repo:read') || scopes.contains('repo:write');
  final hasWrite = scopes.contains('repo:write');
  final valid = switch (access) {
    DeveloperRepositoryAccess.none => !hasRead,
    DeveloperRepositoryAccess.readOnly => hasRead && !hasWrite,
    DeveloperRepositoryAccess.readWrite => hasWrite,
  };
  if (!valid) throw ArgumentError.value(scopes, 'scopes');
}

Set<String> _normalizeScopes(Iterable<String> values) {
  final normalized = values
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
  if (normalized.isEmpty) throw ArgumentError.value(values, 'scopes');
  return normalized;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}
