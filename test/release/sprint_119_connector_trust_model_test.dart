import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_connector_trust_model.dart';

Sprint119TrustModel _model({
  List<Sprint119TrustTierPolicy>? tiers,
  List<Sprint119TrustPermissionDefault>? permissionDefaults,
  List<Sprint119TrustReviewRequirement>? reviewRequirements,
  List<Sprint119TrustVisibilityRule>? visibility,
  List<Sprint119TrustSupportOwner>? supportOwners,
  List<Sprint119TrustRevocationRule>? revocation,
}) {
  return Sprint119TrustModel(
    tiers: tiers ?? Sprint119TrustModelContract.canonicalModel.tiers,
    permissionDefaults:
        permissionDefaults ??
        Sprint119TrustModelContract.canonicalModel.permissionDefaults,
    reviewRequirements:
        reviewRequirements ??
        Sprint119TrustModelContract.canonicalModel.reviewRequirements,
    visibility:
        visibility ?? Sprint119TrustModelContract.canonicalModel.visibility,
    supportOwners:
        supportOwners ??
        Sprint119TrustModelContract.canonicalModel.supportOwners,
    revocation:
        revocation ?? Sprint119TrustModelContract.canonicalModel.revocation,
  );
}

Sprint119TrustModelReport _run(
  Sprint119TrustModel model, {
  Sprint119TrustCharterAnchor? anchor,
}) {
  return const Sprint119TrustModelGate().evaluateWith(
    anchor ?? Sprint119TrustModelContract.canonicalAnchor,
    model,
  );
}

void main() {
  group('119.3 Connector Trust Model', () {
    test('declares the canonical step, tiers, and six acceptance areas', () {
      expect(Sprint119TrustModelContract.canonicalStep, '119.3');
      expect(Sprint119TrustModelContract.title, 'Connector Trust Model');
      expect(Sprint119TrustModelContract.requiredAreas, <String>[
        'tier_rules',
        'permission_defaults',
        'review_requirements',
        'visibility',
        'support_owner',
        'revocation',
      ]);
      expect(Sprint119TrustModelContract.trustTiers, <String>[
        'BUILT_IN',
        'VERIFIED_PARTNER',
        'COMMUNITY',
        'LOCAL_DEVELOPMENT',
      ]);
    });

    test('canonical model passes against the committed charter', () {
      final report = const Sprint119TrustModelGate().evaluate();
      expect(report.state, Sprint119TrustModelState.pass);
      expect(report.verdict, 'TRUST_MODEL_COMPLETE_LOCAL');
      expect(report.modelExecutable, isTrue);
      expect(report.missingAreas, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('emitted manifest preserves the six areas and fail-closed policy', () {
      final file = File(Sprint119TrustModelContract.manifestPath);
      expect(file.existsSync(), isTrue);
      final record =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(record['canonical_step'], '119.3');
      expect(record['state'], 'pass');
      expect(record['verdict'], 'TRUST_MODEL_COMPLETE_LOCAL');
      expect(record['permission_default'], 'DENY');
      expect(record['external_gates'], 'DEFERRED-EXTERNAL');
      for (final area in Sprint119TrustModelContract.requiredAreas) {
        expect(record[area], isA<List<dynamic>>());
        expect(record[area], isNotEmpty);
      }
    });

    test('missing area blocks execution', () {
      final report = _run(_model(tiers: const <Sprint119TrustTierPolicy>[]));
      expect(report.state, Sprint119TrustModelState.blocked);
      expect(report.verdict, 'SPRINT_119_TRUST_MODEL_FIELDS_MISSING');
      expect(report.missingAreas, <String>['tier_rules']);
      expect(report.modelExecutable, isFalse);
    });

    test('a charter that is not complete blocks the trust model', () {
      final report = _run(
        _model(),
        anchor: const Sprint119TrustCharterAnchor(
          charterState: 'blocked',
          charterVerdict: 'CHARTER_COMPLETE_LOCAL',
          executionAllowed: true,
        ),
      );
      expect(report.state, Sprint119TrustModelState.blocked);
      expect(report.verdict, 'SPRINT_119_TRUST_MODEL_CHARTER_BLOCKED');
      expect(report.blockers, contains('committed_charter_not_ready'));
    });

    test('all four tiers have distinct rules and review requirements', () {
      final report = _run(_model());
      final tiers = Sprint119TrustModelContract.canonicalModel.tiers;
      expect(tiers.map((item) => item.tier).toSet(), hasLength(4));
      expect(tiers.every((item) => item.rule.trim().isNotEmpty), isTrue);
      expect(tiers.every((item) => item.review.trim().isNotEmpty), isTrue);
      expect(report.state, Sprint119TrustModelState.pass);
    });

    test('permission defaults deny undeclared access', () {
      final defaults =
          Sprint119TrustModelContract.canonicalModel.permissionDefaults;
      expect(defaults.single.defaultDecision, 'DENY');
      expect(defaults.single.undeclaredCapabilities, 'DENY');
      expect(defaults.single.undeclaredDestinations, 'DENY');
    });

    test('duplicate tiers fail closed', () {
      final tier = Sprint119TrustModelContract.canonicalModel.tiers.first;
      final report = _run(
        _model(tiers: <Sprint119TrustTierPolicy>[tier, tier]),
      );
      expect(report.state, Sprint119TrustModelState.fail);
      expect(report.violations, contains('duplicate_tier:BUILT_IN'));
    });

    test('missing support owner is rejected', () {
      final report = _run(
        _model(supportOwners: const <Sprint119TrustSupportOwner>[]),
      );
      expect(report.state, Sprint119TrustModelState.blocked);
      expect(report.missingAreas, contains('support_owner'));
    });

    test('revocation must include disable, revoke, and audit', () {
      final revocation = Sprint119TrustModelContract.canonicalModel.revocation;
      expect(
        revocation.single.actions,
        containsAll(<String>['disable', 'revoke', 'audit']),
      );
      expect(revocation.single.failClosed, isTrue);
    });

    test('external publication remains deferred', () {
      final visibility = Sprint119TrustModelContract.canonicalModel.visibility;
      expect(visibility.single.publication, 'DEFERRED_EXTERNAL');
      expect(visibility.single.uncertified, 'WITHHELD');
    });
  });
}
