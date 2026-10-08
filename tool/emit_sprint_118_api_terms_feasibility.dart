// Emit the 118.31 API, SDK & Terms Feasibility Refresh record from the gate's
// own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_api_terms_feasibility.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_api_terms_feasibility.dart';

Map<String, Object?> _entry(Sprint118ApiTermsFeasibilityEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'primary_sources': entry.primarySources,
      'verification_date': entry.verificationDate,
      'api_version': entry.apiVersion,
      'sdk_version': entry.sdkVersion,
      'deprecations': entry.deprecations,
      'auth_scopes': entry.authScopes,
      'terms_limits': entry.termsLimits,
      'refreshed': entry.refreshed,
      'verified': entry.verified,
      'deprecations_confirmed': entry.deprecationsConfirmed,
      'scopes_granted': entry.scopesGranted,
      'terms_accepted': entry.termsAccepted,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118ApiTermsFeasibilityGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ApiTermsFeasibilityLoader().loadAnchor();
  final record = Sprint118ApiTermsFeasibilityContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ApiTermsFeasibilityContract.canonicalStep,
    'title': Sprint118ApiTermsFeasibilityContract.title,
    'document_role': 'api-terms-feasibility-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'feasibility_verified': report.feasibilityVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118ApiTermsFeasibilityContract.requiredFields,
    'required_outputs': Sprint118ApiTermsFeasibilityContract.requiredOutputs,
    'expected_provider_count':
        Sprint118ApiTermsFeasibilityContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118ApiTermsFeasibilityContract.charterManifestPath,
      'snapshot': Sprint118ApiTermsFeasibilityContract.snapshotManifestPath,
      'approval_gate':
          Sprint118ApiTermsFeasibilityContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118ApiTermsFeasibilityContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118ApiTermsFeasibilityContract
          .registryReconciliationManifestPath,
      'api_sdk_verification':
          Sprint118ApiTermsFeasibilityContract.apiSdkVerificationManifestPath,
      'oauth_reauth_health':
          Sprint118ApiTermsFeasibilityContract.oauthReauthHealthManifestPath,
      'expansion_inventory':
          Sprint118ApiTermsFeasibilityContract.expansionInventoryManifestPath,
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
    'api_sdk_status': anchor?.apiSdkStatus,
    'api_sdk_verdict': anchor?.apiSdkVerdict,
    'api_sdk_external_gates': anchor?.apiSdkExternalGates,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'primary_sources_vocabulary': anchor?.primarySourcesVocabulary,
    'verification_date_vocabulary': anchor?.verificationDateVocabulary,
    'api_version_vocabulary': anchor?.apiVersionVocabulary,
    'sdk_version_vocabulary': anchor?.sdkVersionVocabulary,
    'deprecations_vocabulary': anchor?.deprecationsVocabulary,
    'auth_scopes_vocabulary': anchor?.authScopesVocabulary,
    'terms_limits_vocabulary': anchor?.termsLimitsVocabulary,
    'reference_state_vocabulary':
        Sprint118ApiTermsFeasibilityContract.stateVocabulary(<List<String>>[
          anchor?.primarySourcesVocabulary ?? const <String>[],
          anchor?.verificationDateVocabulary ?? const <String>[],
          anchor?.apiVersionVocabulary ?? const <String>[],
          anchor?.sdkVersionVocabulary ?? const <String>[],
          anchor?.deprecationsVocabulary ?? const <String>[],
          anchor?.authScopesVocabulary ?? const <String>[],
          anchor?.termsLimitsVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ApiTermsFeasibilityContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'refreshed_providers': report.refreshedProviders,
    'verified_providers': report.verifiedProviders,
    'refreshed_count': report.refreshedCount,
    'verified_count': report.verifiedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local API, SDK & Terms Feasibility Refresh over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 116.4 current API & SDK verification, the committed 118 oauth reauth health, and the committed 118.29 provider expansion evidence inventory. A pass does not review primary documentation, read an API or SDK version, confirm a deprecation, grant an auth scope, accept a term, check a region or plan, read a quota, access a credential, certify a connector, expose a provider, refresh a provider live, authorize a release, or publish.',
      'The refresh is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical outputs (primary_sources, verification_date, api_version, sdk_version, deprecations, auth_scopes, terms_limits) to a committed witness vocabulary, claims no live refresh and no live verification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as API/SDK/terms-feasible without live primary documentation review and an authorized release: the gate refuses any entry that claims a live refresh, a live verification, a confirmed deprecation, a granted auth scope, an accepted term, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never refreshed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A feasibility value is never invented: each of the seven outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Primary-documentation review, version and deprecation reads, auth scope grants, terms acceptance, region and plan checks, quota reads, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live primary documentation review',
      'live API and SDK version reads',
      'live deprecation review',
      'live auth scope grants',
      'live terms acceptance',
      'live region and plan checks',
      'live quota reads',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118ApiTermsFeasibilityContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('refreshed_count=${report.refreshedCount}');
  stdout.writeln('verified_count=${report.verifiedCount}');
  stdout.writeln('written=${target.path}');
}
