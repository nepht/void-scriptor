/// Canonical step 117.19 — Team & Collaboration Validation.
///
/// Objective (external canonical JSON): test organization, seats, invite,
/// roles, permission health, member removal, and audit.
///
/// The seven evidence items are the ways a collaboration surface can hand
/// authority to the wrong person, so the check and the drill are separate
/// classes, exactly as 117.5-117.18 did:
///
/// * [Sprint117TeamCollaborationWorkflowDrill] really executes the shipped
///   mechanisms in [StudioRegistry], [SeatLicense], [StudioRole], and
///   [AuditLog]: seat allocation under a capacity guard, the role permission
///   matrix, member removal, and the audit trail behind them. It writes
///   nothing, opens no user project, contacts no identity provider, and every
///   organization it names is a locally constructed fixture, never a claim
///   that a real team exists.
/// * [Sprint117TeamCollaborationWorkflowLoader] reads the committed manifests
///   and the external files they pin, and never invents a check or an
///   outcome.
/// * [Sprint117TeamCollaborationWorkflowGate] decides whether the recorded
///   evidence is coherent, synchronously and without side effects.
///
/// Four facts are measured rather than assumed, and all four shape the
/// verdict:
///
/// 1. This step found and fixed a real defect in shipped code. Removing a
///    member took no actor, consulted no permission, and asked nobody whether
///    the user was still there, even though the spec lists
///    `remove_team_member` among its sensitive actions and declares
///    `reauth_before_sensitive_action` and `audit_redaction` for it. Any
///    caller could drop a colleague from the organization; a refusal was
///    indistinguishable from an attempt never made; and the last
///    administrator could be removed, leaving nobody able to manage members or
///    billing. The drill re-measures all of it, so a regression in either
///    direction fails here.
/// 2. `invite` is decided against the account-level summary, not the studio
///    registry. `TeamInvitationStatus` exists and is exercised, but the studio
///    seam has no invitation lifecycle of its own and no shipped file
///    translates one into the other. That is reported as an open item rather
///    than dressed up as a delivered invite flow.
/// 3. `permission_health` is a field a caller supplies. No shipped code
///    computes it from the role matrix, so the value is a declaration by
///    whoever built the summary. The drill measures that the field is carried
///    and immutable, and reports the missing computation as an open item.
/// 4. Unlike 117.12-117.18, this seam IS reachable from `main.dart`
///    (`app_router` renders `StudioManagementPanel` from `DemoStudio.registry`),
///    so the Windows build is real slice evidence rather than a no-op. That is
///    measured, not assumed, by the same repository scan that reports the
///    other slices' missing callers.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:void_scriptor/core/enterprise/audit/audit_log.dart';
import 'package:void_scriptor/core/enterprise/license/seat_license.dart';
import 'package:void_scriptor/core/enterprise/role/permission.dart';
import 'package:void_scriptor/core/enterprise/role/studio_role.dart';
import 'package:void_scriptor/core/enterprise/registry/studio_registry.dart';
import 'package:void_scriptor/core/enterprise/studio/studio.dart';
import 'package:void_scriptor/features/account/domain/account_center_team_collaboration_summary.dart';

part 'sprint_117_team_collaboration_workflow_drill.dart';

enum Sprint117TeamCollaborationWorkflowState { pass, fail, blocked }

/// Immutable description of the contract, its sources, and its verdicts.
abstract final class Sprint117TeamCollaborationWorkflowContract {
  static const String canonicalStep = '117.19';

  /// 115.30 supplies the account-level collaboration summary: organization,
  /// seats, member roles, pending invites, access summary, permission health.
  static const String teamCollaborationSummary =
      'docs/planning/v1.2/sprint_115_team_collaboration_summary.json';

  /// 115.9 pins the product surface that names team collaboration as a
  /// destination, so the summary has somewhere to live.
  static const String informationArchitecture =
      'docs/planning/v1.2/sprint_115_global_information_architecture.json';

  /// 115.4 names team collaboration in the entry gate's own section list.
  static const String entryGateProductSpec =
      'docs/planning/v1.2/sprint_115_entry_gate_product_spec.json';

  /// Every committed source this validation decides from.
  static const List<String> sourceManifests = <String>[
    teamCollaborationSummary,
    informationArchitecture,
    entryGateProductSpec,
  ];

  /// The external files the committed manifests pin, with the sha256 they
  /// record. A pin that no longer matches is a contradiction of every decision
  /// derived from it, so it is measured, never assumed.
  static const Map<String, String> externalPins = <String, String>{
    'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
            'sprint_116.json':
        '94418211f73b9b318d57749a26bf8e6f1e92afb6c8942b2b003c99d6cef0e809',
    'C:/Users/nepht/Documents/Codex/2026-08-22/'
            'referenced-chatgpt-conversation-this-is-an-2/outputs/'
            'account_cloud_center_spec.json':
        'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a',
  };

  static const String passVerdict =
      'TEAM_COLLABORATION_WORKFLOW_VALIDATED_LOCAL';
  static const String blockedVerdict =
      'TEAM_COLLABORATION_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE';
  static const String failVerdict = 'TEAM_COLLABORATION_WORKFLOW_INCONSISTENT';

  /// The seven evidence items canonical step 117.19 names, in canonical order.
  static const List<String> requiredChecks = <String>[
    'organization',
    'seats',
    'invite',
    'roles',
    'permissions',
    'member_removal',
    'audit',
  ];
}

/// One canonical check, the method that exercises it, and its outcome.
class Sprint117TeamCollaborationWorkflowCheck {
  Sprint117TeamCollaborationWorkflowCheck({
    required this.checkId,
    required this.method,
    required this.expectedOutcome,
    required this.observedOutcome,
    required this.sourceManifest,
    required this.liveProviderResult,
    required this.drilledAgainstLiveProvider,
  });

  /// The canonical check identity, e.g. `member_removal`.
  final String checkId;

  /// The step this validation runs. Empty means the check only wishes for it.
  final String method;

  /// What the method is expected to produce locally.
  final String expectedOutcome;

  /// What the local drill actually produced. Null while no drill has run.
  final String? observedOutcome;

  /// The upstream manifest that defines this check.
  final String sourceManifest;

  /// Whether a live provider produced this outcome. It never has.
  final bool liveProviderResult;

  /// Whether the check ran against a live provider. It never did.
  final bool drilledAgainstLiveProvider;

  bool get executed =>
      observedOutcome != null && observedOutcome!.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'method': method,
    'expected_outcome': expectedOutcome,
    'observed_outcome': observedOutcome,
    'executed': executed,
    'source_manifest': sourceManifest,
    'live_provider_result': liveProviderResult,
    'drilled_against_live_provider': drilledAgainstLiveProvider,
  };
}

/// The evidence this validation is allowed to decide from.
class Sprint117TeamCollaborationWorkflowAnchor {
  Sprint117TeamCollaborationWorkflowAnchor({
    required Map<String, String> declaredContractSizes,
    required Map<String, bool> boundariesDeclared,
    required this.teamAcceptanceDeclared,
    required this.seatCountDeclared,
    required this.pendingInvitesDeclared,
    required this.permissionHealthDeclared,
    required this.reauthBeforeSensitiveActionDeclared,
    required this.removeTeamMemberSensitiveAction,
    required this.auditRedactionDeclared,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
  }) : declaredContractSizes = Map<String, String>.unmodifiable(
         declaredContractSizes,
       ),
       boundariesDeclared = Map<String, bool>.unmodifiable(boundariesDeclared);

  /// How many contract items each committed source declares, by path.
  final Map<String, String> declaredContractSizes;

  /// Whether each committed source states where its own evidence stops.
  final Map<String, bool> boundariesDeclared;

  /// Whether 115.30 declares all six of its own acceptance items.
  final bool teamAcceptanceDeclared;

  /// Whether 115.30 declares the seat count item.
  final bool seatCountDeclared;

  /// Whether 115.30 declares the pending-invites item.
  final bool pendingInvitesDeclared;

  /// Whether 115.30 declares the permission-health item.
  final bool permissionHealthDeclared;

  /// Whether the product spec declares reauth before a sensitive action.
  final bool reauthBeforeSensitiveActionDeclared;

  /// Whether the product spec calls removing a team member a sensitive
  /// action.
  final bool removeTeamMemberSensitiveAction;

  /// Whether the product spec declares audit redaction.
  final bool auditRedactionDeclared;

  final int externalPinsMatched;
  final int externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117TeamCollaborationWorkflowContract.externalPins.length;

  bool get allExternalPinsMatch =>
      externalPinsResolved && externalPinsMatched == externalPinsChecked;
}

/// The decided-versus-observed input the gate reasons about.
class Sprint117TeamCollaborationWorkflowInput {
  const Sprint117TeamCollaborationWorkflowInput({
    this.rows,
    this.anchor,
    this.drillRun,
    this.externalPinDrift = false,
  });

  final List<Sprint117TeamCollaborationWorkflowCheck>? rows;
  final Sprint117TeamCollaborationWorkflowAnchor? anchor;
  final Sprint117TeamCollaborationWorkflowDrillRun? drillRun;

  /// Whether an external pin no longer matches what its manifest recorded.
  final bool externalPinDrift;
}

/// Whether a canonical acceptance could be satisfied by shipped code at all.
enum Sprint117TeamCollaborationWorkflowAcceptance { satisfied, mechanismAbsent }

/// One measured local observation behind a canonical check.
class Sprint117TeamCollaborationWorkflowObservation {
  Sprint117TeamCollaborationWorkflowObservation({
    required this.checkId,
    required this.outcome,
    required this.facts,
    required this.passed,
    this.acceptance = Sprint117TeamCollaborationWorkflowAcceptance.satisfied,
    this.unresolvable = const <String>[],
  });

  /// The canonical check this observation decides.
  final String checkId;

  /// Exactly what the executed method produced.
  final String outcome;

  /// The measured values behind [outcome]. Never a restatement of the prose.
  final Map<String, Object?> facts;

  /// Whether the shipped mechanism behaved as the canonical source requires.
  final bool passed;

  /// Whether shipped code can satisfy this acceptance at all.
  final Sprint117TeamCollaborationWorkflowAcceptance acceptance;

  /// References this validation could not resolve, reported rather than
  /// silently dropped.
  final List<String> unresolvable;

  Map<String, Object?> toJson() => <String, Object?>{
    'check_id': checkId,
    'outcome': outcome,
    'passed': passed,
    'acceptance': acceptance.name,
    'facts': Map<String, Object?>.from(facts),
    'unresolvable': List<String>.from(unresolvable),
  };
}

/// Everything one measured run produced.
class Sprint117TeamCollaborationWorkflowDrillRun {
  Sprint117TeamCollaborationWorkflowDrillRun({
    required List<Sprint117TeamCollaborationWorkflowObservation> observations,
    required this.liveProviderTouched,
    required this.userProjectTouched,
    required this.liveCredentialObserved,
    required this.externalPinsMatched,
    required this.externalPinsChecked,
    this.productionCallerPresent = true,
    this.invitationLifecycleEnforcedSomewhere = true,
    this.permissionHealthComputedSomewhere = true,
    this.invitationLifecycleCallSites = 1,
    this.permissionHealthComputationCallSites = 1,
  }) : observations =
           List<Sprint117TeamCollaborationWorkflowObservation>.unmodifiable(
             observations,
           );

  final List<Sprint117TeamCollaborationWorkflowObservation> observations;

  /// Whether any identity provider or network endpoint was contacted. Never.
  final bool liveProviderTouched;

  /// Whether any user project was opened. It never is.
  final bool userProjectTouched;

  /// Whether any real credential was observed. It never is.
  final bool liveCredentialObserved;

  final int externalPinsMatched;
  final int externalPinsChecked;

  /// Whether any production file outside this acceptance harness imports the
  /// membership mechanisms the checks above exercise.
  ///
  /// Defaults to true so a hand-built run is never charged with an integration
  /// gap it never measured; only the repository scan can clear it.
  final bool productionCallerPresent;

  /// Whether any shipped file outside this acceptance harness turns an
  /// invitation into a member.
  ///
  /// Defaults to true for the same reason: an unmeasured run must not be
  /// charged with a missing lifecycle it never looked for.
  final bool invitationLifecycleEnforcedSomewhere;

  /// Whether any shipped file computes permission health from the role matrix
  /// rather than storing a caller-supplied value.
  ///
  /// Defaults to true for the same reason.
  final bool permissionHealthComputedSomewhere;

  /// How many shipped files the scan counted as enforcing the invitation
  /// lifecycle. Exposed so a test can assert the measured total instead of
  /// only its boolean consequence: a boolean alone cannot distinguish "the
  /// scan found one lifecycle" from "the scan found nine" or "the scan never
  /// ran and the default answered".
  final int invitationLifecycleCallSites;

  /// How many shipped files the scan counted as computing permission health
  /// from the role matrix. Same reason as [invitationLifecycleCallSites].
  final int permissionHealthComputationCallSites;

  bool get allPassed => observations.every((entry) => entry.passed);

  bool get allExternalPinsMatchForDrill =>
      externalPinsChecked > 0 && externalPinsMatched == externalPinsChecked;

  bool get externalPinsResolved =>
      externalPinsChecked ==
      Sprint117TeamCollaborationWorkflowContract.externalPins.length;

  List<String> get acceptanceSatisfied => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117TeamCollaborationWorkflowAcceptance.satisfied)
        entry.checkId,
  ];

  List<String> get acceptanceUnmet => <String>[
    for (final entry in observations)
      if (entry.acceptance ==
          Sprint117TeamCollaborationWorkflowAcceptance.mechanismAbsent)
        entry.checkId,
  ];

  List<String> get unresolvableReferences => <String>[
    for (final entry in observations) ...entry.unresolvable,
  ];

  Sprint117TeamCollaborationWorkflowObservation? observationFor(
    String checkId,
  ) {
    for (final entry in observations) {
      if (entry.checkId == checkId) return entry;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'live_provider_touched': liveProviderTouched,
    'user_project_touched': userProjectTouched,
    'live_credential_observed': liveCredentialObserved,
    'external_pins_matched': externalPinsMatched,
    'external_pins_checked': externalPinsChecked,
    'production_caller_present': productionCallerPresent,
    'invitation_lifecycle_enforced_somewhere':
        invitationLifecycleEnforcedSomewhere,
    'permission_health_computed_somewhere': permissionHealthComputedSomewhere,
    'observations': <Map<String, Object?>>[
      for (final entry in observations) entry.toJson(),
    ],
  };
}

/// Reads the committed manifests and never invents a subject.
class Sprint117TeamCollaborationWorkflowLoader {
  const Sprint117TeamCollaborationWorkflowLoader();

  Sprint117TeamCollaborationWorkflowInput load() =>
      Sprint117TeamCollaborationWorkflowInput(
        rows: _loadRows(),
        anchor: _loadAnchor(),
      );

  /// Folds the measured drill into the committed record.
  Sprint117TeamCollaborationWorkflowInput loadWithDrill(
    Sprint117TeamCollaborationWorkflowDrillRun run,
  ) => Sprint117TeamCollaborationWorkflowInput(
    rows: _loadRows(run),
    anchor: _loadAnchor(),
    drillRun: run,
    // A run that could not read every pin cannot prove drift either; only a
    // readable pin that no longer matches is a contradiction.
    externalPinDrift:
        run.externalPinsResolved && !run.allExternalPinsMatchForDrill,
  );

  Sprint117TeamCollaborationWorkflowAnchor? _loadAnchor() {
    final declared = <String, String>{};
    final boundaries = <String, bool>{};
    for (final path
        in Sprint117TeamCollaborationWorkflowContract.sourceManifests) {
      final source = _readJsonFile(path);
      if (source == null) return null;
      declared[path] = _declaredContractSize(source);
      boundaries[path] = _declaresBoundary(source);
    }

    // The guarantees themselves live in the external product spec, which the
    // committed manifests point at rather than embed. Reading
    // `security_contract` out of a manifest instead of out of the spec it pins
    // yields nothing, which would silently leave every guarantee unmeasured.
    final spec = _readJsonFile(
      Sprint117TeamCollaborationWorkflowContract.externalPins.keys.last,
    );
    if (spec == null) return null;
    final secrets = spec['security_contract']?['secrets'];
    final sensitive = spec['security_contract']?['sensitive_actions'];

    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117TeamCollaborationWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }

    return Sprint117TeamCollaborationWorkflowAnchor(
      declaredContractSizes: declared,
      boundariesDeclared: boundaries,
      teamAcceptanceDeclared: _declares(
        Sprint117TeamCollaborationWorkflowContract.teamCollaborationSummary,
        const <String>[
          'organization',
          'seat_count',
          'member_roles',
          'pending_invites',
          'access_summary',
          'permission_health',
        ],
      ),
      seatCountDeclared: _declares(
        Sprint117TeamCollaborationWorkflowContract.teamCollaborationSummary,
        const <String>['seat_count'],
      ),
      pendingInvitesDeclared: _declares(
        Sprint117TeamCollaborationWorkflowContract.teamCollaborationSummary,
        const <String>['pending_invites'],
      ),
      permissionHealthDeclared: _declares(
        Sprint117TeamCollaborationWorkflowContract.teamCollaborationSummary,
        const <String>['permission_health'],
      ),
      reauthBeforeSensitiveActionDeclared:
          secrets is List && secrets.contains('reauth_before_sensitive_action'),
      removeTeamMemberSensitiveAction:
          sensitive is List && sensitive.contains('remove_team_member'),
      auditRedactionDeclared:
          secrets is List && secrets.contains('audit_redaction'),
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// Whether the committed source at [path] declares every item in [items].
  ///
  /// Measured by reading the source's own `required_fields` or `acceptance`
  /// list, not by comparing against a copy of that list written here. A
  /// constant list would be the same defect 117.16 rejected: it makes the
  /// guarantee look declared by something that never looked at the file.
  static bool _declares(String path, List<String> items) {
    final source = _readJsonFile(path);
    if (source == null) return false;
    for (final key in const <String>['required_fields', 'acceptance']) {
      final declared = source[key];
      if (declared is! List<dynamic>) continue;
      final names = declared.map((entry) => entry.toString()).toSet();
      if (items.every(names.contains)) return true;
    }
    return false;
  }

  List<Sprint117TeamCollaborationWorkflowCheck>? _loadRows([
    Sprint117TeamCollaborationWorkflowDrillRun? run,
  ]) {
    if (_loadAnchor() == null) return null;
    return <Sprint117TeamCollaborationWorkflowCheck>[
      for (final checkId
          in Sprint117TeamCollaborationWorkflowContract.requiredChecks)
        if (_defined(checkId))
          Sprint117TeamCollaborationWorkflowCheck(
            checkId: checkId,
            method: _method(checkId),
            expectedOutcome: _expectedOutcome(checkId),
            // Only the measured drill may supply an outcome. With no drill the
            // check stays undetermined rather than borrowing a verdict.
            observedOutcome: run?.observationFor(checkId)?.outcome,
            sourceManifest: _sourceFor(checkId),
            liveProviderResult: false,
            drilledAgainstLiveProvider: false,
          ),
    ];
  }

  /// A check exists only where its source records a contract, so a manifest
  /// that never declared the item cannot silently produce a passing row.
  static bool _defined(String checkId) {
    final source = _readJsonFile(_sourceFor(checkId));
    if (source == null) return false;
    return _declaredContractSize(source).isNotEmpty;
  }

  /// The committed manifest that owns a check.
  static String _sourceFor(String checkId) => switch (checkId) {
    'organization' || 'seats' || 'invite' || 'roles' || 'permissions' =>
      Sprint117TeamCollaborationWorkflowContract.teamCollaborationSummary,
    'member_removal' ||
    'audit' => Sprint117TeamCollaborationWorkflowContract.entryGateProductSpec,
    _ => '',
  };

  /// The step this validation runs for a check.
  static String _method(String checkId) => switch (checkId) {
    'organization' =>
      'build the shipped registry and the account summary and record that an '
          'organization carries a stable non-empty id and name, that the '
          'summary refuses a blank id or name, and that the two agree about '
          'which organization they describe',
    'seats' =>
      'allocate seats under the capacity guard and record that a grant is '
          'refused at capacity, that a released seat becomes available '
          'again, that the roster and the seat count never disagree, and '
          'that the account summary refuses an assigned count that '
          'contradicts the member list',
    'invite' =>
      'record invitations under each status and record that only pending '
          'ones are reported as pending, that a summary cannot carry two '
          'invitations under one id, and that the registry exposes no '
          'invitation lifecycle of its own',
    'roles' =>
      'apply the shipped role matrix and record that every role resolves '
          'every permission without throwing, that the roles are distinct, '
          'and that the roster can never hold two members under one id',
    'permissions' =>
      'read the shipped role matrix and record that manage-members is held '
          'by the administrator and withheld from the others, that the '
          'account summary carries the permission health it was given '
          'immutably, and that no shipped file computes that value from the '
          'matrix',
    'member_removal' =>
      'end a membership and record that it is refused when the '
          'reauthentication gate refuses, refused when no gate is supplied, '
          'refused for an actor who may not manage members, refused for the '
          'last administrator, that a refused attempt leaves the member and '
          'the seat intact, and that both outcomes are audited with the '
          'actor that asked',
    'audit' =>
      'read the audit trail after membership changes and record that every '
          'accepted and every refused action is present, that a refused '
          'attempt stays distinguishable from an attempt never made, and '
          'that no row carries a role, a permission, or any secret',
    _ => '',
  };

  /// What the method is expected to produce locally.
  static String _expectedOutcome(String checkId) => switch (checkId) {
    'organization' =>
      'an organization carries a stable non-empty identity and the summary '
          'refuses a blank one',
    'seats' =>
      'seats are granted under a capacity guard, released on removal, and '
          'the roster and the seat count never disagree',
    'invite' =>
      'invitations carry a status and only pending ones are reported as '
          'pending, under a unique id',
    'roles' =>
      'the role matrix is total and a person occupies one seat under one '
          'identity',
    'permissions' =>
      'manage-members is held by the administrator alone and the permission '
          'health is carried immutably',
    'member_removal' =>
      'ending a membership requires the gate, the permission, and a second '
          'administrator to exist, and is audited either way',
    'audit' =>
      'every accepted and every refused membership action is audited with '
          'its actor and carries no role or secret',
    _ => '',
  };

  /// How many contract items a source declares, or empty when it declares none.
  ///
  /// Key names are read from the sources themselves, not from the names this
  /// harness first guessed: 115.3 spells its coverage `acceptance_coverage`
  /// and its limits `evidence_limits`, and 115.1 spells its invariants
  /// `acceptance_invariants`. Demanding `acceptance` or `limitations` of them
  /// reported two healthy manifests as silent — the same false zero 117.17
  /// hit on a subtree name.
  static String _declaredContractSize(Map<String, dynamic> source) {
    for (final key in const <String>[
      'acceptance',
      'acceptance_invariants',
      'acceptance_coverage',
      'required_fields',
      'required_states',
      'required_outputs',
      'sections',
    ]) {
      final declared = source[key];
      if (declared is List<dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
      if (declared is Map<String, dynamic> && declared.isNotEmpty) {
        return 'DECLARED:$key:${declared.length}';
      }
    }
    final records = source['records'];
    if (records is List<dynamic> && records.isNotEmpty) {
      return 'DECLARED:records:${records.length}';
    }
    return '';
  }

  /// Whether a source states where its own evidence stops.
  static bool _declaresBoundary(Map<String, dynamic> source) {
    for (final key in const <String>[
      'boundary',
      'evidence_boundary',
      'external_gates',
    ]) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return true;
    }
    for (final key in const <String>[
      'limitations',
      'evidence_limits',
      'deferred_scope',
      'deferred_external',
    ]) {
      final value = source[key];
      if (value is List<dynamic> && value.isNotEmpty) return true;
      if (value is Map<String, dynamic> && value.isNotEmpty) return true;
    }
    return false;
  }
}

/// Decides whether the recorded team collaboration evidence is coherent.
class Sprint117TeamCollaborationWorkflowGate {
  const Sprint117TeamCollaborationWorkflowGate();

  /// Runs the drill, then decides from its measured output.
  Future<Sprint117TeamCollaborationWorkflowReport> evaluateWithDrill([
    Sprint117TeamCollaborationWorkflowDrillRun? run,
  ]) async {
    final measured =
        run ?? await const Sprint117TeamCollaborationWorkflowDrill().run();
    return evaluateWith(
      const Sprint117TeamCollaborationWorkflowLoader().loadWithDrill(measured),
    );
  }

  Sprint117TeamCollaborationWorkflowReport evaluate() =>
      evaluateWith(const Sprint117TeamCollaborationWorkflowLoader().load());

  Sprint117TeamCollaborationWorkflowReport evaluateWith(
    Sprint117TeamCollaborationWorkflowInput input,
  ) {
    final missing = <String>{};
    final violations = <String>{};

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('team_collaboration_anchor');
    } else {
      for (final entry in anchor.declaredContractSizes.entries) {
        if (entry.value.trim().isEmpty) {
          missing.add('contract_not_declared:${entry.key}');
        }
      }
      for (final entry in anchor.boundariesDeclared.entries) {
        if (!entry.value) {
          violations.add('external_boundary_not_declared:${entry.key}');
        }
      }
      if (!anchor.teamAcceptanceDeclared) {
        missing.add('team_collaboration_acceptance');
      }
      if (!anchor.seatCountDeclared) {
        missing.add('seat_count_acceptance');
      }
      if (!anchor.pendingInvitesDeclared) {
        missing.add('pending_invites_acceptance');
      }
      if (!anchor.permissionHealthDeclared) {
        missing.add('permission_health_acceptance');
      }
      if (!anchor.reauthBeforeSensitiveActionDeclared) {
        missing.add('reauth_before_sensitive_action_acceptance');
      }
      if (!anchor.removeTeamMemberSensitiveAction) {
        missing.add('remove_team_member_sensitive_action');
      }
      if (!anchor.auditRedactionDeclared) {
        missing.add('audit_redaction_acceptance');
      }
      if (!anchor.externalPinsResolved) {
        missing.add('external_pin_unreadable');
      } else if (!anchor.allExternalPinsMatch) {
        violations.add('external_source_drift');
      }
    }

    // An external file whose hash no longer matches the committed pin
    // contradicts every decision derived from it, whether the loader saw it
    // or only the drill did.
    if (input.externalPinDrift) violations.add('external_source_drift');

    final drillRun = input.drillRun;
    if (drillRun == null) {
      // Without a measured run there is no observed outcome to decide from, so
      // the report is blocked rather than passed on prose.
      missing.add('drill_run');
    } else {
      if (drillRun.liveProviderTouched) violations.add('live_provider_touched');
      if (drillRun.userProjectTouched) violations.add('user_project_touched');
      if (drillRun.liveCredentialObserved) {
        violations.add('live_credential_observed');
      }
      if (drillRun.externalPinsResolved &&
          !drillRun.allExternalPinsMatchForDrill) {
        violations.add('external_source_drift');
      }
      if (!drillRun.allPassed) {
        for (final observation in drillRun.observations) {
          if (!observation.passed) {
            violations.add('drill_observation_failed:${observation.checkId}');
            violations.add('drill_outcome:${observation.outcome}');
          }
        }
      }
      // A check whose own recorded fact says the mechanism is absent must not
      // also be reported as acceptance-satisfied: the two claims contradict.
      for (final observation in drillRun.observations) {
        if (!observation.passed) continue;
        final acceptance = observation.facts['acceptance_mechanism_present'];
        if (acceptance == false &&
            observation.acceptance ==
                Sprint117TeamCollaborationWorkflowAcceptance.satisfied) {
          violations.add(
            'acceptance_claimed_without_mechanism:${observation.checkId}',
          );
        }
      }
    }

    final rows = input.rows;
    final rowIds = <String>{};
    final checks = <Sprint117TeamCollaborationWorkflowCheck>[];
    final undetermined = <String>[];

    if (rows == null || rows.isEmpty) {
      missing.add('check_rows');
    } else {
      for (final row in rows) {
        final checkId = row.checkId.trim();
        if (checkId.isEmpty) {
          violations.add('check_id_blank');
          continue;
        }
        if (!rowIds.add(checkId)) {
          violations.add('check_duplicate:$checkId');
          continue;
        }
        checks.add(row);
        _checkCheck(row, drillRun, missing, violations);
        if (!row.executed) {
          undetermined.add(checkId);
          if (drillRun != null) {
            missing.add('check_observed_outcome:$checkId');
          }
        }
      }
    }

    final unmapped = <String>[];
    if (anchor != null && !missing.contains('team_collaboration_anchor')) {
      for (final checkId
          in Sprint117TeamCollaborationWorkflowContract.requiredChecks) {
        if (!rowIds.contains(checkId)) unmapped.add(checkId);
      }
      for (final checkId in unmapped) {
        violations.add('check_unmapped:$checkId');
      }
    }

    // Coverage counts canonical checks the evidence has actually decided, not
    // rows a manifest happened to declare. Without an anchor nothing is bound
    // to a committed source, so nothing counts as decided however green the
    // rows look: a full-coverage report would otherwise be reachable while the
    // evidence it claims to rest on is unreadable.
    final anchorResolved =
        anchor != null && !missing.contains('team_collaboration_anchor');
    var decidedCount = 0;
    for (final row in checks) {
      if (row.executed && anchorResolved) decidedCount += 1;
    }
    final total =
        Sprint117TeamCollaborationWorkflowContract.requiredChecks.length;
    final coverage = total == 0 ? 0.0 : decidedCount / total;

    final complete = missing.isEmpty && violations.isEmpty;
    final state = violations.isNotEmpty
        ? Sprint117TeamCollaborationWorkflowState.fail
        : (complete
              ? Sprint117TeamCollaborationWorkflowState.pass
              : Sprint117TeamCollaborationWorkflowState.blocked);

    return Sprint117TeamCollaborationWorkflowReport(
      status: state,
      verdict: switch (state) {
        Sprint117TeamCollaborationWorkflowState.pass =>
          Sprint117TeamCollaborationWorkflowContract.passVerdict,
        Sprint117TeamCollaborationWorkflowState.fail =>
          Sprint117TeamCollaborationWorkflowContract.failVerdict,
        Sprint117TeamCollaborationWorkflowState.blocked =>
          Sprint117TeamCollaborationWorkflowContract.blockedVerdict,
      },
      missingFields: missing.toList(growable: false)..sort(),
      violations: violations.toList(growable: false)..sort(),
      unmappedChecks: unmapped.toList(growable: false)..sort(),
      undeterminedChecks: undetermined.toList(growable: false)..sort(),
      coverage: coverage,
      // Canonical order for both, so a reader can line the report up against
      // the canonical evidence list position by position instead of comparing
      // two differently sorted lists.
      acceptanceSatisfied: _inCanonicalOrderOf(
        drillRun?.acceptanceSatisfied ?? const <String>[],
      ),
      acceptanceUnmet: _inCanonicalOrderOf(
        drillRun?.acceptanceUnmet ?? const <String>[],
      ),
      // Canonical order, not the order the gate happened to collect the rows
      // in: a reader comparing this report against the canonical evidence
      // list has to be able to line the two up position by position.
      checks: _inCanonicalOrder(checks),
      anchor: anchor,
      openItems: _openItems(drillRun, undetermined),
    );
  }

  /// [checks] reordered to the canonical evidence order, with anything the
  /// contract does not name kept after it rather than dropped.
  static List<Sprint117TeamCollaborationWorkflowCheck> _inCanonicalOrder(
    List<Sprint117TeamCollaborationWorkflowCheck> checks,
  ) {
    final byId = <String, Sprint117TeamCollaborationWorkflowCheck>{
      for (final check in checks) check.checkId: check,
    };
    final ordered = <Sprint117TeamCollaborationWorkflowCheck>[
      for (final checkId
          in Sprint117TeamCollaborationWorkflowContract.requiredChecks)
        ?byId.remove(checkId),
    ];
    ordered.addAll(byId.values);
    return ordered;
  }

  /// [ids] reordered to the canonical evidence order, with anything the
  /// contract does not name kept after it rather than dropped.
  static List<String> _inCanonicalOrderOf(Iterable<String> ids) {
    final remaining = <String>{...ids};
    final ordered = <String>[
      for (final checkId
          in Sprint117TeamCollaborationWorkflowContract.requiredChecks)
        if (remaining.remove(checkId)) checkId,
    ];
    ordered.addAll(remaining.toList(growable: false)..sort());
    return ordered;
  }

  void _checkCheck(
    Sprint117TeamCollaborationWorkflowCheck row,
    Sprint117TeamCollaborationWorkflowDrillRun? drillRun,
    Set<String> missing,
    Set<String> violations,
  ) {
    final checkId = row.checkId.trim();
    if (row.method.trim().isEmpty) missing.add('check_method:$checkId');
    if (row.expectedOutcome.trim().isEmpty) {
      missing.add('check_expected_outcome:$checkId');
    }
    if (row.sourceManifest.trim().isEmpty) {
      missing.add('check_source_manifest:$checkId');
    } else if (!File(row.sourceManifest).existsSync()) {
      missing.add('check_source_manifest_missing:$checkId');
    }
    if (row.liveProviderResult) violations.add('live_provider_claim:$checkId');
    if (row.drilledAgainstLiveProvider) {
      violations.add('live_provider_claim:$checkId');
    }
    if (row.observedOutcome == null) {
      // Nothing has run, so the check stays undetermined — an open item, never
      // a violation this gate invents an observation for.
      return;
    }
    final measured = drillRun?.observationFor(checkId);
    if (measured == null) {
      violations.add('check_observation_unsourced:$checkId');
    } else if (row.observedOutcome != measured.outcome) {
      violations.add('check_outcome_contradicts_drill:$checkId');
      violations.add('recorded_outcome:${row.observedOutcome}');
      violations.add('measured_outcome:${measured.outcome}');
    }
  }

  List<String> _openItems(
    Sprint117TeamCollaborationWorkflowDrillRun? drillRun,
    List<String> undetermined,
  ) {
    final items = <String>{
      for (final checkId in undetermined)
        'check_observed_outcome_null:$checkId',
      for (final checkId in drillRun?.acceptanceUnmet ?? const <String>[])
        'check_acceptance_unmet:$checkId',
      for (final reference
          in drillRun?.unresolvableReferences ?? const <String>[])
        'unresolvable_reference:$reference',
      // Measured, not asserted: whether any file under `lib/` outside the
      // acceptance harness imports the membership registry. A run without a
      // drill measured nothing, so it claims nothing.
      if (drillRun != null && !drillRun.productionCallerPresent)
        'no_shipped_consumer_for_membership_registry',
      // Measured: `TeamInvitationStatus` exists and is exercised, but no
      // shipped file turns an invitation into a member, so the invite
      // acceptance is satisfied only at the summary's own level.
      if (drillRun != null && !drillRun.invitationLifecycleEnforcedSomewhere)
        'invitation_status_declared_but_no_lifecycle_enforces_it',
      // Measured: `TeamPermissionHealth` is a field the summary's caller
      // supplies, and no shipped file derives it from the role matrix, so
      // the health a screen shows is a declaration rather than a
      // measurement.
      if (drillRun != null && !drillRun.permissionHealthComputedSomewhere)
        'permission_health_supplied_by_caller_never_computed_from_role_matrix',
      'team_collaboration_workflow_defined_not_executed_live',
      'external_identity_provider_outside_repository',
    };
    return items.toList(growable: false)..sort();
  }
}

/// The gate's verdict, with the evidence it decided from.
class Sprint117TeamCollaborationWorkflowReport {
  Sprint117TeamCollaborationWorkflowReport({
    required this.status,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required List<String> unmappedChecks,
    required List<String> undeterminedChecks,
    required this.coverage,
    required List<String> acceptanceSatisfied,
    required List<String> acceptanceUnmet,
    required List<Sprint117TeamCollaborationWorkflowCheck> checks,
    required this.anchor,
    required List<String> openItems,
  }) : acceptanceSatisfied = List<String>.unmodifiable(acceptanceSatisfied),
       acceptanceUnmet = List<String>.unmodifiable(acceptanceUnmet),
       missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       unmappedChecks = List<String>.unmodifiable(unmappedChecks),
       undeterminedChecks = List<String>.unmodifiable(undeterminedChecks),
       checks = List<Sprint117TeamCollaborationWorkflowCheck>.unmodifiable(
         checks,
       ),
       openItems = List<String>.unmodifiable(openItems);

  final Sprint117TeamCollaborationWorkflowState status;

  /// The decision this report carries.
  final String verdict;

  final List<String> missingFields;
  final List<String> violations;
  final List<String> unmappedChecks;

  /// Checks that are defined but that no drill has decided yet.
  final List<String> undeterminedChecks;

  /// Fraction of the canonical checks the evidence decided.
  final double coverage;

  /// Canonical acceptances shipped code satisfies.
  final List<String> acceptanceSatisfied;

  /// Canonical acceptances shipped code cannot satisfy, reported rather than
  /// folded into a passing row.
  final List<String> acceptanceUnmet;

  final List<Sprint117TeamCollaborationWorkflowCheck> checks;
  final Sprint117TeamCollaborationWorkflowAnchor? anchor;

  /// What this report leaves open, including every deferred external gate.
  final List<String> openItems;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': Sprint117TeamCollaborationWorkflowContract.canonicalStep,
    'status': status.name,
    'verdict': verdict,
    'coverage': coverage,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'unmapped_checks': List<String>.from(unmappedChecks),
    'undetermined_checks': List<String>.from(undeterminedChecks),
    'acceptance_satisfied': List<String>.from(acceptanceSatisfied),
    'acceptance_unmet': List<String>.from(acceptanceUnmet),
    'open_items': List<String>.from(openItems),
    'checks': <Map<String, Object?>>[
      for (final entry in checks) entry.toJson(),
    ],
    'anchor': anchor == null
        ? null
        : <String, Object?>{
            'declared_contract_sizes': Map<String, String>.from(
              anchor!.declaredContractSizes,
            ),
            'boundaries_declared': Map<String, bool>.from(
              anchor!.boundariesDeclared,
            ),
            'team_acceptance_declared': anchor!.teamAcceptanceDeclared,
            'seat_count_declared': anchor!.seatCountDeclared,
            'pending_invites_declared': anchor!.pendingInvitesDeclared,
            'permission_health_declared': anchor!.permissionHealthDeclared,
            'reauth_before_sensitive_action_declared':
                anchor!.reauthBeforeSensitiveActionDeclared,
            'remove_team_member_sensitive_action':
                anchor!.removeTeamMemberSensitiveAction,
            'audit_redaction_declared': anchor!.auditRedactionDeclared,
            'external_pins_matched': anchor!.externalPinsMatched,
            'external_pins_checked': anchor!.externalPinsChecked,
          },
  };
}

Map<String, dynamic>? _readJsonFile(String path) {
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

String? _sha256OfFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return sha256.convert(file.readAsBytesSync()).toString();
  } on FileSystemException {
    return null;
  }
}
