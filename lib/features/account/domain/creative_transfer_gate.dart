import 'account_center_creative_tools_connections.dart';

/// A direction of asset movement across a creative connection.
enum CreativeTransferDirection {
  /// Assets come in from the provider into Void Scriptor.
  inbound,

  /// Assets go out from Void Scriptor to the provider.
  outbound,
}

/// What happened when a transfer was attempted.
///
/// A refused transfer is a decided outcome and says which side of the scope
/// blocked it, so a caller can tell "this connection cannot import" apart from
/// "this account is not allowed to export" - they need different fixes.
enum CreativeTransferOutcome {
  allowed,
  refusedImportOnly,
  refusedExportOnly,
  refusedNoScope,
  refusedMissingPermission,
  refusedUnknownConnection,
}

/// The result of asking whether one transfer is permitted.
final class CreativeTransferDecision {
  const CreativeTransferDecision({
    required this.connectionId,
    required this.direction,
    required this.outcome,
    this.permission,
  });

  final String connectionId;
  final CreativeTransferDirection direction;
  final CreativeTransferOutcome outcome;

  /// The asset permission the transfer needed, when one was the blocker.
  final CreativeAssetPermission? permission;

  bool get allowed => outcome == CreativeTransferOutcome.allowed;

  /// A message a user can act on, naming the concrete thing to change.
  String get reason => switch (outcome) {
    CreativeTransferOutcome.allowed => 'Transfer is permitted.',
    CreativeTransferOutcome.refusedImportOnly =>
      'This connection is import-only, so assets cannot be sent to it.',
    CreativeTransferOutcome.refusedExportOnly =>
      'This connection is export-only, so assets cannot be pulled from it.',
    CreativeTransferOutcome.refusedNoScope =>
      'This connection permits no asset transfer in either direction.',
    CreativeTransferOutcome.refusedMissingPermission =>
      'This connection lacks the ${permission?.name} asset permission.',
    CreativeTransferOutcome.refusedUnknownConnection =>
      'This connection does not exist.',
  };
}

/// Why `transferScope` was decorative.
///
/// [CreativeTransferScope] is stored on every connection and threaded through
/// `connect`, but until this file existed nothing read it. A connection
/// declared `importOnly` and a connection declared `importExport` were
/// indistinguishable to every caller: the scope was recorded, displayed, and
/// then never consulted, so the guarantee it was supposed to express - that an
/// import-only tool can never receive the user's assets - was not enforced
/// anywhere. Worse, the scope was meaningless even as a declaration, because
/// [CreativeTransferScope] has no `none` member: `importOnly` still permits
/// importing and `exportOnly` still permits exporting, so there was no way to
/// express a connection that moves no assets at all.
///
/// This gate is the missing reader. It is the only place in the shipped code
/// that consults `transferScope` to decide an outcome, and it adds
/// [CreativeTransferScope.none] so "connected but transfers nothing" becomes
/// expressible rather than implied.
///
/// It decides, it does not move. Nothing here touches a filesystem or a network:
/// asking whether a transfer is allowed is a local decision, and the actual
/// fetch or push remains DEFERRED-EXTERNAL exactly as the 115.29 contract
/// requires.
final class CreativeTransferGate {
  CreativeTransferGate(this.connections);

  final AccountCenterCreativeToolsConnections connections;

  /// Whether this connection may move assets [direction] at all.
  ///
  /// This is the read of `transferScope` the shipped code was missing. It is
  /// intentionally separate from the permission check so a caller can tell a
  /// scope problem from a rights problem.
  bool allows(
    CreativeToolConnection connection,
    CreativeTransferDirection direction,
  ) {
    switch (connection.transferScope) {
      case CreativeTransferScope.importExport:
        return true;
      case CreativeTransferScope.importOnly:
        return direction == CreativeTransferDirection.inbound;
      case CreativeTransferScope.exportOnly:
        return direction == CreativeTransferDirection.outbound;
      case CreativeTransferScope.none:
        return false;
    }
  }

  /// Decides one transfer, or explains precisely what blocks it.
  ///
  /// Fails closed at every step: an unknown connection, a scope that excludes
  /// the direction, and a missing asset permission are each a distinct refusal
  /// rather than a generic failure, because each needs a different correction
  /// from the user.
  CreativeTransferDecision check({
    required String connectionId,
    required CreativeTransferDirection direction,
    CreativeAssetPermission? permission,
  }) {
    final normalizedId = connectionId.trim();
    CreativeToolConnection? connection;
    for (final candidate in connections.activeConnections) {
      if (candidate.connectionId == normalizedId) {
        connection = candidate;
        break;
      }
    }
    if (connection == null) {
      return CreativeTransferDecision(
        connectionId: normalizedId,
        direction: direction,
        outcome: CreativeTransferOutcome.refusedUnknownConnection,
      );
    }

    if (!allows(connection, direction)) {
      return CreativeTransferDecision(
        connectionId: normalizedId,
        direction: direction,
        outcome: switch (connection.transferScope) {
          CreativeTransferScope.none => CreativeTransferOutcome.refusedNoScope,
          CreativeTransferScope.importOnly =>
            CreativeTransferOutcome.refusedImportOnly,
          CreativeTransferScope.exportOnly =>
            CreativeTransferOutcome.refusedExportOnly,
          CreativeTransferScope.importExport =>
            CreativeTransferOutcome.refusedNoScope,
        },
      );
    }

    if (permission != null &&
        !connection.assetPermissions.contains(permission)) {
      return CreativeTransferDecision(
        connectionId: normalizedId,
        direction: direction,
        outcome: CreativeTransferOutcome.refusedMissingPermission,
        permission: permission,
      );
    }

    return CreativeTransferDecision(
      connectionId: normalizedId,
      direction: direction,
      outcome: CreativeTransferOutcome.allowed,
    );
  }

  /// Every connection that cannot move assets at all, for the UI to explain
  /// rather than hide.
  List<String> inertConnectionIds() => List.unmodifiable(
    connections.activeConnections
        .where(
          (connection) =>
              connection.transferScope == CreativeTransferScope.none,
        )
        .map((connection) => connection.connectionId),
  );
}
