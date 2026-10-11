// Emit the 119.3 Connector Trust Model from the fail-closed evaluator.
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_119_connector_trust_model.dart';

Map<String, Object?> _tier(Sprint119TrustTierPolicy item) => <String, Object?>{
  'tier': item.tier,
  'rule': item.rule,
  'review': item.review,
  'visibility': item.visibility,
  'support': item.support,
};

Map<String, Object?> _permission(Sprint119TrustPermissionDefault item) =>
    <String, Object?>{
      'default_decision': item.defaultDecision,
      'undeclared_capabilities': item.undeclaredCapabilities,
      'undeclared_destinations': item.undeclaredDestinations,
      'secret_access': item.secretAccess,
    };

Map<String, Object?> _review(Sprint119TrustReviewRequirement item) =>
    <String, Object?>{
      'review_id': item.reviewId,
      'requirement': item.requirement,
      'evidence': item.evidence,
    };

Map<String, Object?> _visibility(Sprint119TrustVisibilityRule item) =>
    <String, Object?>{
      'uncertified': item.uncertified,
      'certified': item.certified,
      'publication': item.publication,
    };

Map<String, Object?> _owner(Sprint119TrustSupportOwner item) =>
    <String, Object?>{
      'owner_id': item.ownerId,
      'scope': item.scope,
      'escalation': item.escalation,
    };

Map<String, Object?> _revocation(Sprint119TrustRevocationRule item) =>
    <String, Object?>{
      'trigger': item.trigger,
      'actions': item.actions,
      'fail_closed': item.failClosed,
    };

void main() {
  const gate = Sprint119TrustModelGate();
  final report = gate.evaluate();
  final anchor = const Sprint119TrustModelLoader().loadAnchor();
  final model = Sprint119TrustModelContract.canonicalModel;
  final record = <String, Object?>{
    'canonical_step': Sprint119TrustModelContract.canonicalStep,
    'title': Sprint119TrustModelContract.title,
    'document_role': 'trust-model-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'model_executable': report.modelExecutable,
    'required_areas': Sprint119TrustModelContract.requiredAreas,
    'permission_default': Sprint119TrustModelContract.permissionDefault,
    'missing_areas': report.missingAreas,
    'violations': report.violations,
    'blockers': report.blockers,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_execution_allowed': anchor?.executionAllowed,
    'tier_rules': model.tiers.map(_tier).toList(),
    'permission_defaults': model.permissionDefaults.map(_permission).toList(),
    'review_requirements': model.reviewRequirements.map(_review).toList(),
    'visibility': model.visibility.map(_visibility).toList(),
    'support_owner': model.supportOwners.map(_owner).toList(),
    'revocation': model.revocation.map(_revocation).toList(),
    'claim_boundary': <String>[
      'This local record defines trust policy; it does not certify, expose, install, execute, publish, or release a connector.',
      'Trust tiers, permission defaults, review, visibility, support, and revocation are policy boundaries, not live provider observations.',
      'Certification, provider exposure, external telemetry, signing, publication, and release remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': Sprint119TrustModelContract.externalGates,
  };
  final target = File(Sprint119TrustModelContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('model_executable=${report.modelExecutable}');
  stdout.writeln(
    'required_areas=${Sprint119TrustModelContract.requiredAreas.length}',
  );
  stdout.writeln('missing_areas=${report.missingAreas.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
