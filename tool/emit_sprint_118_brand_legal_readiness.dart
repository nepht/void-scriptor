// Emit the 118.32 Brand & Legal Readiness record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_brand_legal_readiness.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_brand_legal_readiness.dart';

Map<String, Object?> _entry(Sprint118BrandLegalEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'asset_source': entry.assetSource,
      'permission': entry.permission,
      'trademark_rules': entry.trademarkRules,
      'attribution': entry.attribution,
      'license': entry.license,
      'listing_constraints': entry.listingConstraints,
      'logo_use_approved': entry.logoUseApproved,
      'naming_cleared': entry.namingCleared,
      'attribution_published': entry.attributionPublished,
      'license_granted': entry.licenseGranted,
      'trademark_cleared': entry.trademarkCleared,
      'listing_approved': entry.listingApproved,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118BrandLegalGate();
  final report = gate.evaluate();
  final anchor = const Sprint118BrandLegalLoader().loadAnchor();
  final record = Sprint118BrandLegalContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118BrandLegalContract.canonicalStep,
    'title': Sprint118BrandLegalContract.title,
    'document_role': 'brand-legal-readiness-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'readiness_verified': report.readinessVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118BrandLegalContract.requiredFields,
    'required_outputs': Sprint118BrandLegalContract.requiredOutputs,
    'expected_provider_count':
        Sprint118BrandLegalContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118BrandLegalContract.charterManifestPath,
      'snapshot': Sprint118BrandLegalContract.snapshotManifestPath,
      'approval_gate': Sprint118BrandLegalContract.approvalGateManifestPath,
      'icon_registry': Sprint118BrandLegalContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118BrandLegalContract.registryReconciliationManifestPath,
      'brand_asset_icon_certification':
          Sprint118BrandLegalContract.brandCertificationManifestPath,
      'creative_asset_rights':
          Sprint118BrandLegalContract.creativeAssetRightsManifestPath,
      'feature_availability':
          Sprint118BrandLegalContract.featureAvailabilityManifestPath,
    },
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_max_new_certified': anchor?.charterMaxNewCertified,
    'charter_currently_certified': anchor?.charterCurrentlyCertified,
    'charter_registered_providers': anchor?.charterRegisteredProviders,
    'snapshot_state': anchor?.snapshotState,
    'snapshot_verdict': anchor?.snapshotVerdict,
    'snapshot_certified': anchor?.snapshotCertified,
    'snapshot_registered': anchor?.snapshotRegistered,
    'registry_expected_count': anchor?.registryExpectedCount,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'brand_status': anchor?.brandStatus,
    'brand_verdict': anchor?.brandVerdict,
    'brand_external_gates': anchor?.brandExternalGates,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'asset_source_vocabulary': anchor?.assetSourceVocabulary,
    'permission_vocabulary': anchor?.permissionVocabulary,
    'trademark_rules_vocabulary': anchor?.trademarkRulesVocabulary,
    'attribution_vocabulary': anchor?.attributionVocabulary,
    'license_vocabulary': anchor?.licenseVocabulary,
    'listing_constraints_vocabulary': anchor?.listingConstraintsVocabulary,
    'reference_state_vocabulary':
        Sprint118BrandLegalContract.stateVocabulary(<List<String>>[
          anchor?.assetSourceVocabulary ?? const <String>[],
          anchor?.permissionVocabulary ?? const <String>[],
          anchor?.trademarkRulesVocabulary ?? const <String>[],
          anchor?.attributionVocabulary ?? const <String>[],
          anchor?.licenseVocabulary ?? const <String>[],
          anchor?.listingConstraintsVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118BrandLegalContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'logo_use_approved_providers': report.logoUseApprovedProviders,
    'listing_approved_providers': report.listingApprovedProviders,
    'logo_use_approved_count': report.logoUseApprovedCount,
    'listing_approved_count': report.listingApprovedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Brand & Legal Readiness over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 116.7 brand asset & icon certification, the committed 116.35 creative asset rights verification, and the committed 114.22 feature availability reconciliation. A pass does not verify a logo use, clear a naming, publish attribution, grant a license, clear a trademark, approve a marketplace listing, verify mark exposure, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The readiness review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the six canonical outputs (asset_source, permission, trademark_rules, attribution, license, listing_constraints) to a committed witness vocabulary, claims no live brand or legal readiness, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as brand & legally ready without live brand verification and an authorized release: the gate refuses any entry that claims a verified logo use, a cleared naming, a published attribution, a granted license, a cleared trademark, an approved marketplace listing, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A brand or legal value is never invented: each of the six outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Logo-use verification, naming clearance, attribution publication, license grants, trademark clearance, marketplace listing approval, mark exposure, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live logo-use verification',
      'live naming clearance',
      'live attribution publication',
      'live license grants',
      'live trademark clearance',
      'live marketplace listing approval',
      'mark exposure authorization',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118BrandLegalContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('logo_use_approved_count=${report.logoUseApprovedCount}');
  stdout.writeln('listing_approved_count=${report.listingApprovedCount}');
  stdout.writeln('written=${target.path}');
}
