/// Fail-closed trust policy for roadmap step 119.3 -- Connector Trust Model.
///
/// This local contract defines policy only. It does not certify, expose,
/// install, execute, publish, or release a connector.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint119TrustModelState { pass, fail, blocked }

class Sprint119TrustTierPolicy {
  const Sprint119TrustTierPolicy({
    required this.tier,
    required this.rule,
    required this.review,
    required this.visibility,
    required this.support,
  });

  final String tier;
  final String rule;
  final String review;
  final String visibility;
  final String support;
}

class Sprint119TrustPermissionDefault {
  const Sprint119TrustPermissionDefault({
    required this.defaultDecision,
    required this.undeclaredCapabilities,
    required this.undeclaredDestinations,
    required this.secretAccess,
  });

  final String defaultDecision;
  final String undeclaredCapabilities;
  final String undeclaredDestinations;
  final String secretAccess;
}

class Sprint119TrustReviewRequirement {
  const Sprint119TrustReviewRequirement({
    required this.reviewId,
    required this.requirement,
    required this.evidence,
  });

  final String reviewId;
  final String requirement;
  final String evidence;
}

class Sprint119TrustVisibilityRule {
  const Sprint119TrustVisibilityRule({
    required this.uncertified,
    required this.certified,
    required this.publication,
  });

  final String uncertified;
  final String certified;
  final String publication;
}

class Sprint119TrustSupportOwner {
  const Sprint119TrustSupportOwner({
    required this.ownerId,
    required this.scope,
    required this.escalation,
  });

  final String ownerId;
  final String scope;
  final String escalation;
}

class Sprint119TrustRevocationRule {
  const Sprint119TrustRevocationRule({
    required this.trigger,
    required this.actions,
    required this.failClosed,
  });

  final String trigger;
  final List<String> actions;
  final bool failClosed;
}

class Sprint119TrustModel {
  const Sprint119TrustModel({
    required this.tiers,
    required this.permissionDefaults,
    required this.reviewRequirements,
    required this.visibility,
    required this.supportOwners,
    required this.revocation,
  });

  final List<Sprint119TrustTierPolicy> tiers;
  final List<Sprint119TrustPermissionDefault> permissionDefaults;
  final List<Sprint119TrustReviewRequirement> reviewRequirements;
  final List<Sprint119TrustVisibilityRule> visibility;
  final List<Sprint119TrustSupportOwner> supportOwners;
  final List<Sprint119TrustRevocationRule> revocation;
}

class Sprint119TrustCharterAnchor {
  const Sprint119TrustCharterAnchor({
    required this.charterState,
    required this.charterVerdict,
    required this.executionAllowed,
  });

  final String charterState;
  final String charterVerdict;
  final bool executionAllowed;
}

class Sprint119TrustModelReport {
  const Sprint119TrustModelReport({
    required this.state,
    required this.verdict,
    required this.modelExecutable,
    required this.externalGates,
    this.missingAreas = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
  });

  final Sprint119TrustModelState state;
  final String verdict;
  final bool modelExecutable;
  final String externalGates;
  final List<String> missingAreas;
  final List<String> violations;
  final List<String> blockers;
}

class Sprint119TrustModelContract {
  const Sprint119TrustModelContract();

  static const String canonicalStep = '119.3';
  static const String title = 'Connector Trust Model';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_connector_trust_model.json';
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_119_connector_sdk_charter.json';
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const String permissionDefault = 'DENY';

  static const List<String> requiredAreas = <String>[
    'tier_rules',
    'permission_defaults',
    'review_requirements',
    'visibility',
    'support_owner',
    'revocation',
  ];

  static const List<String> trustTiers = <String>[
    'BUILT_IN',
    'VERIFIED_PARTNER',
    'COMMUNITY',
    'LOCAL_DEVELOPMENT',
  ];

  static const Sprint119TrustCharterAnchor canonicalAnchor =
      Sprint119TrustCharterAnchor(
        charterState: 'pass',
        charterVerdict: requiredCharterVerdict,
        executionAllowed: true,
      );

  static const Sprint119TrustModel canonicalModel = Sprint119TrustModel(
    tiers: <Sprint119TrustTierPolicy>[
      Sprint119TrustTierPolicy(
        tier: 'BUILT_IN',
        rule: 'first-party code is reviewed as part of the application release',
        review: 'owner review, security gate, and regression evidence',
        visibility:
            'visible to eligible local users after the application gate',
        support: 'Void Scriptor core support owner',
      ),
      Sprint119TrustTierPolicy(
        tier: 'VERIFIED_PARTNER',
        rule: 'partner code stays scoped to an approved manifest and publisher',
        review:
            'publisher identity, contract tests, security review, and recheck date',
        visibility: 'WITHHELD until authorized certification evidence exists',
        support: 'named partner owner plus core escalation',
      ),
      Sprint119TrustTierPolicy(
        tier: 'COMMUNITY',
        rule:
            'community code is isolated and receives no implicit capability grant',
        review: 'automated contract checks and explicit operator review',
        visibility:
            'local development visibility only; publication is deferred',
        support: 'community maintainer with incident escalation path',
      ),
      Sprint119TrustTierPolicy(
        tier: 'LOCAL_DEVELOPMENT',
        rule:
            'local fixtures and mocks cannot make production or provider claims',
        review:
            'developer-owned tests with an explicit non-production boundary',
        visibility: 'developer-only and never exposed as certified',
        support: 'local developer; no production support commitment',
      ),
    ],
    permissionDefaults: <Sprint119TrustPermissionDefault>[
      Sprint119TrustPermissionDefault(
        defaultDecision: 'DENY',
        undeclaredCapabilities: 'DENY',
        undeclaredDestinations: 'DENY',
        secretAccess: 'opaque references only; plaintext is DENIED',
      ),
    ],
    reviewRequirements: <Sprint119TrustReviewRequirement>[
      Sprint119TrustReviewRequirement(
        reviewId: 'trust_review_before_exposure',
        requirement:
            'tier, publisher, capabilities, destinations, and support owner must be reviewed',
        evidence:
            'committed manifest, deterministic contract tests, and dated review record',
      ),
    ],
    visibility: <Sprint119TrustVisibilityRule>[
      Sprint119TrustVisibilityRule(
        uncertified: 'WITHHELD',
        certified:
            'LOCAL_ONLY until external authorization and evidence are present',
        publication: 'DEFERRED_EXTERNAL',
      ),
    ],
    supportOwners: <Sprint119TrustSupportOwner>[
      Sprint119TrustSupportOwner(
        ownerId: 'connector_support_owner',
        scope: 'triage, incident intake, disable, revoke, and audit handoff',
        escalation:
            'unresolved security or provider incidents escalate to the operator',
      ),
    ],
    revocation: <Sprint119TrustRevocationRule>[
      Sprint119TrustRevocationRule(
        trigger:
            'policy violation, expired review, security incident, or operator request',
        actions: <String>['disable', 'revoke', 'audit'],
        failClosed: true,
      ),
    ],
  );
}

class Sprint119TrustModelLoader {
  const Sprint119TrustModelLoader();

  Sprint119TrustCharterAnchor? loadAnchor() {
    final file = File(Sprint119TrustModelContract.charterManifestPath);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) return null;
      return Sprint119TrustCharterAnchor(
        charterState: _text(decoded['state']),
        charterVerdict: _text(decoded['verdict']),
        executionAllowed: decoded['charter_executable'] == true,
      );
    } on Object {
      return null;
    }
  }
}

class Sprint119TrustModelGate {
  const Sprint119TrustModelGate();

  Sprint119TrustModelReport evaluate() => evaluateWith(
    const Sprint119TrustModelLoader().loadAnchor(),
    Sprint119TrustModelContract.canonicalModel,
  );

  Sprint119TrustModelReport evaluateWith(
    Sprint119TrustCharterAnchor? anchor,
    Sprint119TrustModel model,
  ) {
    if (anchor == null) {
      return const Sprint119TrustModelReport(
        state: Sprint119TrustModelState.blocked,
        verdict: 'SPRINT_119_TRUST_MODEL_CHARTER_UNREADABLE',
        modelExecutable: false,
        externalGates: Sprint119TrustModelContract.externalGates,
        blockers: <String>['committed_charter_evidence_unreadable'],
      );
    }
    if (anchor.charterState != 'pass' ||
        anchor.charterVerdict !=
            Sprint119TrustModelContract.requiredCharterVerdict ||
        !anchor.executionAllowed) {
      return const Sprint119TrustModelReport(
        state: Sprint119TrustModelState.blocked,
        verdict: 'SPRINT_119_TRUST_MODEL_CHARTER_BLOCKED',
        modelExecutable: false,
        externalGates: Sprint119TrustModelContract.externalGates,
        blockers: <String>['committed_charter_not_ready'],
      );
    }

    final lengths = <String, int>{
      'tier_rules': model.tiers.length,
      'permission_defaults': model.permissionDefaults.length,
      'review_requirements': model.reviewRequirements.length,
      'visibility': model.visibility.length,
      'support_owner': model.supportOwners.length,
      'revocation': model.revocation.length,
    };
    final missing = Sprint119TrustModelContract.requiredAreas
        .where((area) => (lengths[area] ?? 0) == 0)
        .toList();
    if (missing.isNotEmpty) {
      return Sprint119TrustModelReport(
        state: Sprint119TrustModelState.blocked,
        verdict: 'SPRINT_119_TRUST_MODEL_FIELDS_MISSING',
        modelExecutable: false,
        externalGates: Sprint119TrustModelContract.externalGates,
        missingAreas: missing,
      );
    }

    final violations = <String>[];
    _duplicates(violations, 'tier', model.tiers.map((item) => item.tier));
    final tierIds = model.tiers.map((item) => item.tier).toSet();
    for (final tier in Sprint119TrustModelContract.trustTiers) {
      if (!tierIds.contains(tier)) violations.add('tier_missing:$tier');
    }
    for (final tier in model.tiers) {
      if (_blank(tier.rule) ||
          _blank(tier.review) ||
          _blank(tier.visibility) ||
          _blank(tier.support)) {
        violations.add('tier_definition_missing:${tier.tier}');
      }
    }
    final defaults = model.permissionDefaults.single;
    if (defaults.defaultDecision !=
            Sprint119TrustModelContract.permissionDefault ||
        defaults.undeclaredCapabilities != 'DENY' ||
        defaults.undeclaredDestinations != 'DENY' ||
        !_containsIgnoreCase(defaults.secretAccess, 'opaque')) {
      violations.add('permission_default_not_fail_closed');
    }
    final review = model.reviewRequirements.single;
    if (_blank(review.requirement) || _blank(review.evidence)) {
      violations.add('review_requirement_incomplete:${review.reviewId}');
    }
    final visibility = model.visibility.single;
    if (visibility.uncertified != 'WITHHELD' ||
        visibility.publication != 'DEFERRED_EXTERNAL') {
      violations.add('visibility_not_deferred');
    }
    final owner = model.supportOwners.single;
    if (_blank(owner.ownerId) ||
        _blank(owner.scope) ||
        _blank(owner.escalation)) {
      violations.add('support_owner_incomplete');
    }
    final revoke = model.revocation.single;
    if (!revoke.failClosed ||
        !revoke.actions.toSet().containsAll(<String>{
          'disable',
          'revoke',
          'audit',
        })) {
      violations.add('revocation_not_fail_closed');
    }
    if (violations.isNotEmpty) {
      return Sprint119TrustModelReport(
        state: Sprint119TrustModelState.fail,
        verdict: 'SPRINT_119_TRUST_MODEL_INVALID',
        modelExecutable: false,
        externalGates: Sprint119TrustModelContract.externalGates,
        violations: violations,
      );
    }
    return const Sprint119TrustModelReport(
      state: Sprint119TrustModelState.pass,
      verdict: 'TRUST_MODEL_COMPLETE_LOCAL',
      modelExecutable: true,
      externalGates: Sprint119TrustModelContract.externalGates,
    );
  }
}

void _duplicates(
  List<String> violations,
  String label,
  Iterable<String> values,
) {
  final seen = <String>{};
  final reported = <String>{};
  for (final value in values) {
    if (!seen.add(value) && reported.add(value)) {
      violations.add('duplicate_$label:$value');
    }
  }
}

bool _blank(String value) => value.trim().isEmpty;
bool _containsIgnoreCase(String value, String needle) =>
    value.toLowerCase().contains(needle.toLowerCase());
String _text(Object? value) => value is String ? value : '';
