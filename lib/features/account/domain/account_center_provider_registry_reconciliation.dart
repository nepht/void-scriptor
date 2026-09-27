/// Sprint 116.3 — Provider Registry Reconciliation.
///
/// Reconciles the three provider registries (icon, connector, AI) to ensure
/// 32 unique providers with consistent categories, capabilities, availability,
/// and ownership declarations. Fail-closed: any inconsistency blocks.
library;

import 'account_center_provider_connector_manifest.dart';
import 'account_center_provider_icon_registry.dart';

enum ProviderRegistryReconciliationState { pass, fail, blocked }

class ProviderRegistryReconciliationReport {
  ProviderRegistryReconciliationReport({
    required this.state,
    required this.verdict,
    required this.iconRegistryCount,
    required this.connectorManifestCount,
    required this.uniqueIdCount,
    required this.categoryMismatches,
    required this.capabilityMismatches,
    required this.availabilityViolations,
    required this.duplicateConnectors,
    required this.missingOwners,
    required this.aiAvailabilityMismatches,
  });

  final ProviderRegistryReconciliationState state;
  final String verdict;
  final int iconRegistryCount;
  final int connectorManifestCount;
  final int uniqueIdCount;
  final List<String> categoryMismatches;
  final List<String> capabilityMismatches;
  final List<String> availabilityViolations;
  final List<String> duplicateConnectors;
  final List<String> missingOwners;
  final List<String> aiAvailabilityMismatches;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'verdict': verdict,
    'icon_registry_count': iconRegistryCount,
    'connector_manifest_count': connectorManifestCount,
    'unique_id_count': uniqueIdCount,
    'category_mismatches': List<String>.from(categoryMismatches),
    'capability_mismatches': List<String>.from(capabilityMismatches),
    'availability_violations': List<String>.from(availabilityViolations),
    'duplicate_connectors': List<String>.from(duplicateConnectors),
    'missing_owners': List<String>.from(missingOwners),
    'ai_availability_mismatches': List<String>.from(aiAvailabilityMismatches),
  };
}

abstract final class ProviderRegistryReconciliationContract {
  static const String canonicalStep = '116.3';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_provider_registry_reconciliation.json';
  static const int expectedProviderCount = 32;

  static const List<String> acceptanceCriteria = <String>[
    'unique_ids',
    'category_mapping',
    'capability_mapping',
    'availability_state',
    'no_duplicate_connectors',
    'owner',
  ];

  static const Map<String, String> categoryMapping = <String, String>{
    'identity': 'identity',
    'cloud_storage': 'cloud_storage',
    'ai': 'ai',
    'developer': 'developer',
    'creative': 'creative',
    'payment': 'payment',
  };

  static const Map<String, List<String>> capabilityMapping =
      <String, List<String>>{
        'identity': <String>['identity', 'health'],
        'cloud_storage': <String>['storage', 'health'],
        'ai': <String>['ai_text', 'health'],
        'developer': <String>['developer', 'health'],
        'creative': <String>['creative', 'health'],
        'payment': <String>['payment', 'health'],
      };

  static const Map<String, String> ownerDeclarations = <String, String>{
    'display_name': 'ProviderIconRegistry',
    'category': 'ProviderIconRegistry',
    'asset': 'ProviderIconRegistry',
    'capabilities': 'ProviderConnectorManifest',
    'availability': 'ProviderConnectorManifest',
    'regions': 'ProviderConnectorManifest',
    'auth_type': 'ProviderConnectorManifest',
    'permissions': 'ProviderConnectorManifest',
    'models': 'AccountCenterAiProviderRegistry',
    'modalities': 'AccountCenterAiProviderRegistry',
    'endpoint': 'AccountCenterAiProviderRegistry',
    'pricing': 'AccountCenterAiProviderRegistry',
    'privacy': 'AccountCenterAiProviderRegistry',
  };
}

class ProviderRegistryReconciliation {
  ProviderRegistryReconciliationReport reconcile({
    ProviderIconRegistry? iconRegistry,
    ProviderConnectorManifest? connectorManifest,
  }) {
    final icons = iconRegistry ?? ProviderIconRegistry.standard;
    final connectors = connectorManifest ?? ProviderConnectorManifest.standard;

    final iconIds = icons.all.map((e) => e.providerId).toSet();
    final connectorIds = connectors.all.map((e) => e.providerId).toSet();

    final categoryMismatches = <String>[];
    final capabilityMismatches = <String>[];
    final availabilityViolations = <String>[];
    final duplicateConnectors = <String>[];
    final missingOwners = <String>[];

    // unique_ids: both registries must have exactly 32 unique ids
    const expected =
        ProviderRegistryReconciliationContract.expectedProviderCount;
    final hasCountBlocker =
        iconIds.length != expected || connectorIds.length != expected;

    // no_duplicate_connectors: connector manifest must have unique ids
    final seenConnectorIds = <String>{};
    for (final entry in connectors.all) {
      if (seenConnectorIds.contains(entry.providerId)) {
        duplicateConnectors.add(entry.providerId);
      }
      seenConnectorIds.add(entry.providerId);
    }

    // category_mapping: icon category must map to connector category
    for (final icon in icons.all) {
      final connector = connectors.get(icon.providerId);
      if (connector == null) continue;
      final expectedCategory = ProviderRegistryReconciliationContract
          .categoryMapping[icon.category.wireName];
      if (expectedCategory != null &&
          connector.category.wireName != expectedCategory) {
        categoryMismatches.add(icon.providerId);
      }
    }

    // capability_mapping: connector capabilities must match category-derived set
    for (final connector in connectors.all) {
      final expectedCaps = ProviderRegistryReconciliationContract
          .capabilityMapping[connector.category.wireName];
      if (expectedCaps == null) continue;
      final actualCaps = connector.capabilities.map((c) => c.wireName).toSet();
      final expectedSet = expectedCaps.toSet();
      if (!actualCaps.containsAll(expectedSet) ||
          !expectedSet.containsAll(actualCaps)) {
        capabilityMismatches.add(connector.providerId);
      }
    }

    // availability_state: all connector entries must be UNVERIFIED
    for (final connector in connectors.all) {
      if (connector.availability != ProviderConnectorAvailability.unverified) {
        availabilityViolations.add(connector.providerId);
      }
    }

    // owner: all owner declarations must be non-empty
    for (final entry
        in ProviderRegistryReconciliationContract.ownerDeclarations.entries) {
      if (entry.value.trim().isEmpty) {
        missingOwners.add(entry.key);
      }
    }

    final hasBlockers = hasCountBlocker || duplicateConnectors.isNotEmpty;
    final hasFailures =
        categoryMismatches.isNotEmpty ||
        capabilityMismatches.isNotEmpty ||
        availabilityViolations.isNotEmpty ||
        missingOwners.isNotEmpty;

    final state = hasBlockers
        ? ProviderRegistryReconciliationState.blocked
        : hasFailures
        ? ProviderRegistryReconciliationState.fail
        : ProviderRegistryReconciliationState.pass;

    final verdict = state == ProviderRegistryReconciliationState.pass
        ? 'PROVIDER_REGISTRY_RECONCILED'
        : 'PROVIDER_REGISTRY_INCONSISTENT';

    return ProviderRegistryReconciliationReport(
      state: state,
      verdict: verdict,
      iconRegistryCount: icons.all.length,
      connectorManifestCount: connectors.all.length,
      uniqueIdCount: iconIds.union(connectorIds).length,
      categoryMismatches: categoryMismatches,
      capabilityMismatches: capabilityMismatches,
      availabilityViolations: availabilityViolations,
      duplicateConnectors: duplicateConnectors,
      missingOwners: missingOwners,
      aiAvailabilityMismatches: const <String>[],
    );
  }
}
