/// Sprint 115.29 — Creative Tools Connections.
///
/// Local, manifest-driven connection and asset-rights metadata only. External
/// OAuth, asset transfer, credentials, and license certification stay outside
/// this seam.
library;

import 'dart:collection';

import 'account_center_provider_connector_manifest.dart';

enum CreativeAssetPermission { owned, licensed, publicDomain }

enum CreativeTransferScope { importOnly, exportOnly, importExport }

final class CreativeToolConnector {
  const CreativeToolConnector(this.manifestEntry);

  final ProviderConnectorEntry manifestEntry;

  String get providerId => manifestEntry.providerId;
  String get displayName => manifestEntry.displayName;
  ProviderConnectorAvailability get availability => manifestEntry.availability;
  bool get isConnectable => manifestEntry.isConnectable;
}

final class CreativeToolConnection {
  CreativeToolConnection({
    required String connectionId,
    required String providerId,
    required Iterable<CreativeAssetPermission> assetPermissions,
    required this.transferScope,
    String? attribution,
  }) : connectionId = _required(connectionId, 'connectionId'),
       providerId = _required(providerId, 'providerId').toLowerCase(),
       assetPermissions = UnmodifiableSetView(
         _validateAssetPermissions(assetPermissions),
       ),
       attribution = _optional(attribution) {
    if (this.assetPermissions.contains(CreativeAssetPermission.licensed) &&
        this.attribution == null) {
      throw ArgumentError.value(
        attribution,
        'attribution',
        'Licensed assets require attribution metadata.',
      );
    }
  }

  final String connectionId;
  final String providerId;
  final Set<CreativeAssetPermission> assetPermissions;
  final CreativeTransferScope transferScope;
  final String? attribution;
}

/// One action a creative connection took, kept without its rights material.
///
/// `audit_redaction` is a declared guarantee of the product spec, so a row
/// names what happened and to which connection and carries nothing else: no
/// asset permission, no transfer scope, and no attribution text.
final class CreativeToolAuditEvent {
  const CreativeToolAuditEvent({
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

final class AccountCenterCreativeToolsConnections {
  AccountCenterCreativeToolsConnections({
    required this.manifest,
    DateTime Function()? now,
    Future<bool> Function()? reauthenticate,
  }) : _now = now ?? DateTime.now,
       // Fail-closed. Ending an authorized connection is a sensitive action
       // the product spec declares, and a caller that supplies no gate has
       // not proven the user is present, so the default is refusal rather
       // than consent.
       _reauthenticate = reauthenticate ?? (() async => false);

  final ProviderConnectorManifest manifest;
  final DateTime Function() _now;

  /// The gate a sensitive action must pass. Never absent; the default refuses.
  final Future<bool> Function() _reauthenticate;
  final Map<String, CreativeToolConnection> _connections =
      <String, CreativeToolConnection>{};
  final List<CreativeToolAuditEvent> _audit = <CreativeToolAuditEvent>[];

  List<CreativeToolConnector> get connectors => List.unmodifiable(
    manifest.all
        .where((entry) => entry.category == ProviderConnectorCategory.creative)
        .map(CreativeToolConnector.new),
  );

  List<CreativeToolConnection> get activeConnections =>
      List.unmodifiable(_connections.values);

  List<CreativeToolAuditEvent> get audit => List.unmodifiable(_audit);

  CreativeToolConnection connect({
    required String providerId,
    required String connectionId,
    required Iterable<CreativeAssetPermission> assetPermissions,
    required CreativeTransferScope transferScope,
    String? attribution,
  }) {
    final entry = manifest.require(providerId);
    if (entry.category != ProviderConnectorCategory.creative ||
        !entry.isConnectable) {
      throw StateError(
        'Creative connector "${entry.providerId}" is unavailable.',
      );
    }
    final normalizedId = _required(connectionId, 'connectionId');
    if (_connections.containsKey(normalizedId)) {
      throw ArgumentError.value(connectionId, 'connectionId');
    }

    final connection = CreativeToolConnection(
      connectionId: normalizedId,
      providerId: entry.providerId,
      assetPermissions: assetPermissions,
      transferScope: transferScope,
      attribution: attribution,
    );
    _connections[connection.connectionId] = connection;
    _record('connect', connection);
    return connection;
  }

  /// Ends a creative connection.
  ///
  /// The product spec lists `disconnect_provider` among its sensitive actions
  /// and declares `reauth_before_sensitive_action` as one of its guarantees, so
  /// ending an authorized connection runs behind a gate. A caller-supplied
  /// `confirmed` flag is an assertion, not a proof that the user is present:
  /// with no gate at all, any caller could drop a connection that carries
  /// licensed assets and attribution obligations by passing `true`.
  ///
  /// A refusal is a decided outcome, not an absence, so it is recorded. Before
  /// this, a disconnect that was refused and a disconnect nobody attempted
  /// produced identical trails, which is the gap `audit_redaction` exists to
  /// close.
  Future<bool> disconnect(
    String connectionId, {
    required bool confirmed,
  }) async {
    if (!confirmed) {
      _recordRefusal(connectionId, 'denied_disconnect');
      return false;
    }
    final normalizedId = _required(connectionId, 'connectionId');
    final connection = _connections[normalizedId];
    if (connection == null) {
      throw StateError('Unknown creative connection: $normalizedId');
    }
    if (!await _reauthenticate()) {
      _recordRefusal(
        normalizedId,
        'denied_disconnect',
        providerId: connection.providerId,
      );
      return false;
    }
    _connections.remove(normalizedId);
    _record('disconnect', connection);
    return true;
  }

  void _record(String action, CreativeToolConnection connection) {
    _audit.add(
      CreativeToolAuditEvent(
        action: action,
        providerId: connection.providerId,
        connectionId: connection.connectionId,
        timestamp: _now().toUtc(),
      ),
    );
  }

  /// Records a refusal that names the connection it was refused against.
  ///
  /// `providerId` is unknown when the refusal happens before the connection is
  /// resolved, and the row says so with an empty provider rather than guessing
  /// one. The attempt itself is the fact worth keeping.
  void _recordRefusal(
    String connectionId,
    String action, {
    String providerId = '',
  }) {
    _audit.add(
      CreativeToolAuditEvent(
        action: action,
        providerId: providerId,
        connectionId: connectionId.trim(),
        timestamp: _now().toUtc(),
      ),
    );
  }
}

Set<CreativeAssetPermission> _validateAssetPermissions(
  Iterable<CreativeAssetPermission> values,
) {
  final permissions = values.toSet();
  if (permissions.isEmpty) {
    throw ArgumentError.value(values, 'assetPermissions');
  }
  return permissions;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
