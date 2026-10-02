// Copyright 2026 Choirudin. All rights reserved.
//
// Sprint 117.38 — adapters that actually PERFORM the two action decisions of
// the step, so the gate's `actionResults` carry measured state instead of an
// assertion typed into a test.
//
// Canonical step 117.38 objective: "Menggabungkan issue dan memutus blocker,
// fix, flag-off, connector-disable, defer, or rollback." Two of those six
// decisions are actions against shipped state rather than verdicts about an
// issue. The gate therefore refuses to accept FLAG_OFF or DISABLE_CONNECTOR
// unless a seam reports what it observed.
//
// The mechanisms are pre-existing and shipped:
//   * FLAG_OFF           -> FeatureFlagRegistry.disable (110.8, persisted via
//                           FeatureFlagOverrideStore).
//   * DISABLE_CONNECTOR -> AccountConnectedAccountsManagement.unlink (115.14),
//                           which distinguishes a local drop from a revoke the
//                           provider actually confirmed.
//
// Both adapters report honestly: an action that did not change state yields
// `applied: false`, which the gate turns into `action_not_applied`. Neither
// adapter invents a flag name or a connection id.
library;

import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_issue_deduplication_triage.dart';

/// Turns a capability off and reports what the registry observed.
final class Sprint117FlagOffAction {
  Sprint117FlagOffAction(this._flags);

  final FeatureFlagRegistry _flags;

  /// The canonical decision this seam carries out.
  static const String decision = 'FLAG_OFF';

  /// Performs the action and reports whether the registry ended up OFF.
  ///
  /// A flag that was never on is reported as `applied: false` rather than as a
  /// successful flag-off: nothing changed, so nothing is proven.
  Sprint117TriageResolution disable(String flag) {
    final wasEnabled = _flags.isEnabled(flag);
    _flags.disable(flag);
    final isEnabled = _flags.isEnabled(flag);
    return Sprint117TriageResolution(
      decision: decision,
      applied: wasEnabled && !isEnabled,
      observed:
          'FeatureFlagRegistry.disable($flag): was_enabled=$wasEnabled '
          'is_enabled_after=$isEnabled '
          'enabled_flags_after=${_flags.enabledFlags.length}',
    );
  }
}

/// Drops a connector and reports whether the connection is really gone.
final class Sprint117DisableConnectorAction {
  Sprint117DisableConnectorAction(this._connections);

  final AccountConnectedAccountsManagement _connections;

  /// The canonical decision this seam carries out.
  static const String decision = 'DISABLE_CONNECTOR';

  /// Unlinks [connectionId] and reports the measured disconnect outcome.
  ///
  /// [revokeAtProvider] false means a local-only drop. Both are real disables
  /// of the connector, but the observation records which one happened so a
  /// local drop is never read as a provider-side revoke.
  Future<Sprint117TriageResolution> disable(
    String connectionId, {
    bool revokeAtProvider = false,
  }) async {
    final result = await _connections.unlink(
      connectionId,
      confirmed: true,
      revokeAtProvider: revokeAtProvider,
    );
    final stillPresent = _connections.connections.any(
      (account) => account.connectionId == connectionId,
    );
    return Sprint117TriageResolution(
      decision: decision,
      applied: result.localRemoved && !stillPresent,
      observed:
          'unlink($connectionId): localRemoved=${result.localRemoved} '
          'providerRevokeAttempted=${result.providerRevokeAttempted} '
          'providerRevoked=${result.providerRevoked} '
          'still_registered=$stillPresent',
    );
  }
}
