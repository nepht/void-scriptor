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

final class AccountCenterCreativeToolsConnections {
  AccountCenterCreativeToolsConnections({required this.manifest});

  final ProviderConnectorManifest manifest;
  final Map<String, CreativeToolConnection> _connections =
      <String, CreativeToolConnection>{};

  List<CreativeToolConnector> get connectors => List.unmodifiable(
    manifest.all
        .where((entry) => entry.category == ProviderConnectorCategory.creative)
        .map(CreativeToolConnector.new),
  );

  List<CreativeToolConnection> get activeConnections =>
      List.unmodifiable(_connections.values);

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
    return connection;
  }

  bool disconnect(String connectionId, {required bool confirmed}) {
    if (!confirmed) return false;
    final normalizedId = _required(connectionId, 'connectionId');
    if (_connections.remove(normalizedId) == null) {
      throw StateError('Unknown creative connection: $normalizedId');
    }
    return true;
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
