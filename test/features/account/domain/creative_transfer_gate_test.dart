import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_creative_tools_connections.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/creative_transfer_gate.dart';

/// Closes the 117.18 open item. `transferScope` was stored on every creative
/// connection and threaded through `connect`, but no shipped code read it: an
/// `importOnly` connection and an `importExport` one were indistinguishable to
/// every caller, so the guarantee the scope was supposed to express - that an
/// import-only tool can never receive the user's assets - was enforced nowhere.
void main() {
  group('CreativeTransferGate reads the scope nothing else read', () {
    test('an import-only connection refuses an outbound transfer', () {
      final connections = _connected(
        scope: CreativeTransferScope.importOnly,
        permissions: const {
          CreativeAssetPermission.owned,
          CreativeAssetPermission.licensed,
        },
        attribution: 'Studio A licensed these assets.',
      );
      final gate = CreativeTransferGate(connections);

      final decision = gate.check(
        connectionId: 'figma/main',
        direction: CreativeTransferDirection.outbound,
      );

      expect(decision.allowed, isFalse);
      expect(decision.outcome, CreativeTransferOutcome.refusedImportOnly);
      expect(decision.reason, contains('import-only'));
    });

    test('the same connection still allows an inbound transfer', () {
      final connections = _connected(
        scope: CreativeTransferScope.importOnly,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);

      final decision = gate.check(
        connectionId: 'figma/main',
        direction: CreativeTransferDirection.inbound,
      );

      expect(decision.allowed, isTrue);
      expect(decision.outcome, CreativeTransferOutcome.allowed);
    });

    test('an export-only connection refuses an inbound transfer', () {
      final connections = _connected(
        scope: CreativeTransferScope.exportOnly,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);

      final decision = gate.check(
        connectionId: 'figma/main',
        direction: CreativeTransferDirection.inbound,
      );

      expect(decision.allowed, isFalse);
      expect(decision.outcome, CreativeTransferOutcome.refusedExportOnly);
      expect(decision.reason, contains('export-only'));
    });

    test('import-export allows both directions', () {
      final connections = _connected(
        scope: CreativeTransferScope.importExport,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);

      for (final direction in CreativeTransferDirection.values) {
        expect(
          gate.check(connectionId: 'figma/main', direction: direction).allowed,
          isTrue,
          reason: '$direction should be permitted',
        );
      }
    });

    test('none refuses both directions and is reported as inert', () {
      final connections = _connected(
        scope: CreativeTransferScope.none,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);

      for (final direction in CreativeTransferDirection.values) {
        final decision = gate.check(
          connectionId: 'figma/main',
          direction: direction,
        );
        expect(decision.allowed, isFalse, reason: '$direction must be refused');
        expect(decision.outcome, CreativeTransferOutcome.refusedNoScope);
      }
      expect(gate.inertConnectionIds(), ['figma/main']);
    });

    test('a scope refusal is distinct from a missing permission', () {
      final connections = _connected(
        scope: CreativeTransferScope.importExport,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);

      final decision = gate.check(
        connectionId: 'figma/main',
        direction: CreativeTransferDirection.inbound,
        permission: CreativeAssetPermission.publicDomain,
      );

      expect(
        decision.outcome,
        CreativeTransferOutcome.refusedMissingPermission,
      );
      expect(decision.permission, CreativeAssetPermission.publicDomain);
      expect(decision.reason, contains('publicDomain'));
    });

    test('an unknown connection fails closed with its own outcome', () {
      final connections = _connected(
        scope: CreativeTransferScope.importExport,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);

      final decision = gate.check(
        connectionId: 'ghost',
        direction: CreativeTransferDirection.inbound,
      );

      expect(decision.allowed, isFalse);
      expect(
        decision.outcome,
        CreativeTransferOutcome.refusedUnknownConnection,
      );
    });

    test('allows reads the same scope the decision does', () {
      final connections = _connected(
        scope: CreativeTransferScope.exportOnly,
        permissions: const {CreativeAssetPermission.owned},
      );
      final gate = CreativeTransferGate(connections);
      final connection = connections.activeConnections.single;

      expect(
        gate.allows(connection, CreativeTransferDirection.outbound),
        isTrue,
      );
      expect(
        gate.allows(connection, CreativeTransferDirection.inbound),
        isFalse,
      );
    });

    test('a disconnected connection stops being transfer-eligible', () async {
      final connections = AccountCenterCreativeToolsConnections(
        manifest: _manifest(),
        reauthenticate: () async => true,
      );
      connections.connect(
        providerId: 'figma',
        connectionId: 'figma/main',
        assetPermissions: const {CreativeAssetPermission.owned},
        transferScope: CreativeTransferScope.importExport,
      );
      final gate = CreativeTransferGate(connections);
      expect(
        gate
            .check(
              connectionId: 'figma/main',
              direction: CreativeTransferDirection.inbound,
            )
            .allowed,
        isTrue,
      );

      await connections.disconnect('figma/main', confirmed: true);

      // The gate must consult live state, not a snapshot taken at connect time.
      expect(
        gate
            .check(
              connectionId: 'figma/main',
              direction: CreativeTransferDirection.inbound,
            )
            .outcome,
        CreativeTransferOutcome.refusedUnknownConnection,
      );
    });

    test('a scope decision records no rights material in its reason', () {
      final connections = _connected(
        scope: CreativeTransferScope.importOnly,
        permissions: const {
          CreativeAssetPermission.owned,
          CreativeAssetPermission.licensed,
        },
        attribution: 'Studio A licensed these assets.',
      );
      final gate = CreativeTransferGate(connections);

      final decision = gate.check(
        connectionId: 'figma/main',
        direction: CreativeTransferDirection.outbound,
      );

      expect(decision.reason, isNot(contains('Studio A')));
      expect(decision.reason, isNot(contains('licensed')));
    });
  });

  group('CreativeTransferScope can express no transfer at all', () {
    test('none is a real member of the scope enum', () {
      expect(
        CreativeTransferScope.values,
        contains(CreativeTransferScope.none),
      );
    });

    test('every scope answers both directions deterministically', () {
      for (final scope in CreativeTransferScope.values) {
        final connections = _connected(
          scope: scope,
          permissions: const {CreativeAssetPermission.owned},
        );
        final gate = CreativeTransferGate(connections);
        final inbound = gate
            .check(
              connectionId: 'figma/main',
              direction: CreativeTransferDirection.inbound,
            )
            .allowed;
        final outbound = gate
            .check(
              connectionId: 'figma/main',
              direction: CreativeTransferDirection.outbound,
            )
            .allowed;

        switch (scope) {
          case CreativeTransferScope.none:
            expect(inbound, isFalse, reason: 'none must refuse inbound');
            expect(outbound, isFalse, reason: 'none must refuse outbound');
          case CreativeTransferScope.importOnly:
            expect(inbound, isTrue);
            expect(outbound, isFalse);
          case CreativeTransferScope.exportOnly:
            expect(inbound, isFalse);
            expect(outbound, isTrue);
          case CreativeTransferScope.importExport:
            expect(inbound, isTrue);
            expect(outbound, isTrue);
        }
      }
    });

    test('a none connection is stored faithfully and survives a read', () {
      final connections = _connected(
        scope: CreativeTransferScope.none,
        permissions: const {CreativeAssetPermission.owned},
      );

      expect(
        connections.activeConnections.single.transferScope,
        CreativeTransferScope.none,
      );
    });
  });
}

AccountCenterCreativeToolsConnections _connected({
  required CreativeTransferScope scope,
  required Set<CreativeAssetPermission> permissions,
  String? attribution,
}) {
  final connections = AccountCenterCreativeToolsConnections(
    manifest: _manifest(),
    reauthenticate: () async => true,
  );
  connections.connect(
    providerId: 'figma',
    connectionId: 'figma/main',
    assetPermissions: permissions,
    transferScope: scope,
    attribution: attribution,
  );
  return connections;
}

ProviderConnectorManifest _manifest() => ProviderConnectorManifest([
  ProviderConnectorEntry.fixture(
    'figma',
    category: ProviderConnectorCategory.creative,
    capabilities: const {ProviderConnectorCapability.creative},
    availability: ProviderConnectorAvailability.available,
  ),
]);
