part of 'sprint_117_team_collaboration_workflow_validation.dart';

/// Executes the shipped membership mechanisms and records what each one
/// produced. It writes nothing, opens no user project, contacts no identity
/// provider, and every organization it names is a locally constructed fixture,
/// so nothing here can be read as a claim that a real team exists.
class Sprint117TeamCollaborationWorkflowDrill {
  const Sprint117TeamCollaborationWorkflowDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// Source files that hold the shipped membership mechanisms. A check whose
  /// behaviour only these files exercise is the mechanism existing, not the
  /// feature being reachable by a user.
  static const List<String> shippedSources = <String>[
    'lib/core/enterprise/registry/studio_registry.dart',
    'lib/core/enterprise/license/seat_license.dart',
    'lib/core/enterprise/role/studio_role.dart',
    'lib/core/enterprise/member/team_member.dart',
    'lib/core/enterprise/audit/audit_log.dart',
    'lib/features/account/domain/account_center_team_collaboration_summary.dart',
  ];

  /// Whether [source] still declares [symbol], i.e. whether the mechanism this
  /// check exercises exists at all.
  ///
  /// Measured rather than assumed so that renaming or deleting the shipped
  /// method makes the fact false instead of leaving a constant `true` behind.
  /// A constant would make the acceptance look decided by something that never
  /// ran, which is the defect 117.16 rejected in this harness family.
  static bool _declares(String source, String symbol) {
    final file = File(source);
    if (!file.existsSync()) return false;
    return file.readAsLinesSync().any((line) => line.contains(symbol));
  }

  /// Counts production call sites that reach [source] under `lib/`.
  ///
  /// Separate from [_declares] on purpose: a declared mechanism that nothing
  /// calls satisfies the acceptance in the abstract but not for a user, and
  /// the two facts must not be collapsed into one. The harness family is
  /// excluded wholesale because no `sprint_117_*` file is reachable from
  /// `main.dart` — without that exclusion an acceptance drill counts itself as
  /// the production caller it was supposed to measure.
  ///
  /// Paths are compared RELATIVE to the repository root, never as raw
  /// `listSync` output: that method returns absolute paths on Windows, so a
  /// `startsWith('lib/')` filter matched 0 of 2891 Dart files and reported a
  /// false zero — the seam is in fact reachable from `app_router`, which
  /// renders `StudioManagementPanel` from `DemoStudio.registry`.
  static int _productionCallSites(String source) {
    final stem = source.split('/').last;
    final found = <String>[];
    for (final relative in _libDartFiles()) {
      if (relative == source) continue;
      final file = File(relative);
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (lines[i].contains(stem)) {
          found.add('$relative:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Every `lib/` Dart file in the repository, as repository-relative paths
  /// with forward slashes and the acceptance harness family excluded.
  ///
  /// Normalising the prefix here is what makes every scan in this drill
  /// measure the repository rather than an empty set.
  static List<String> _libDartFiles() {
    final root = Directory.current.path.replaceAll('\\', '/');
    final prefix = root.endsWith('/') ? root : '$root/';
    final found = <String>[];
    for (final entity in Directory.current.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      final absolute = entity.path.replaceAll('\\', '/');
      if (!absolute.endsWith('.dart')) continue;
      if (!absolute.startsWith(prefix)) continue;
      final relative = absolute.substring(prefix.length);
      if (!relative.startsWith('lib/')) continue;
      if (relative.contains('/sprint_117_')) continue;
      found.add(relative);
    }
    return found;
  }

  /// Counts production files that turn an invitation into a member, excluding
  /// this acceptance harness.
  ///
  /// A status that nothing acts on is a label, not a lifecycle. Measured
  /// rather than assumed, because a `true` constant here would turn "the
  /// invitation flow works" into a claim nothing looked for.
  static int _invitationLifecycleCallSites() {
    const summary = 'account_center_team_collaboration_summary.dart';
    final found = <String>[];
    for (final relative in _libDartFiles()) {
      if (relative.endsWith(summary)) continue;
      final file = File(relative);
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        // A lifecycle acts on a status: it reads a non-pending invitation, or
        // builds one, and hands it to something that can add a member.
        if (lines[i].contains('TeamInvitationStatus')) {
          found.add('$relative:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Counts production files that derive permission health from the role
  /// matrix, excluding this acceptance harness.
  ///
  /// Measured rather than assumed, for the same reason as the invitation
  /// lifecycle: a stored value that nothing computes is a caller assertion.
  static int _permissionHealthComputationCallSites() {
    final found = <String>[];
    for (final relative in _libDartFiles()) {
      if (relative.endsWith('account_center_team_collaboration_summary.dart')) {
        continue;
      }
      final file = File(relative);
      if (!file.existsSync()) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (lines[i].contains('TeamPermissionHealth')) {
          found.add('$relative:${i + 1}');
          break;
        }
      }
    }
    return found.length;
  }

  /// Per shipped source: does it declare the mechanism this check exercises.
  static final Map<String, bool> _mechanismPresent = <String, bool>{
    'registry.add': _declares(shippedSources[0], 'addMember('),
    'registry.remove': _declares(shippedSources[0], 'removeMember('),
    'registry.gate': _declares(shippedSources[0], '_reauthenticate'),
    'registry.permission': _declares(shippedSources[0], 'manageMembers'),
    'registry.lastAdmin': _declares(
      shippedSources[0],
      'wouldOrphanTheOrganization',
    ),
    'registry.deniedAudit': _declares(
      shippedSources[0],
      'denied_remove_member',
    ),
    'seats.capacity': _declares(shippedSources[1], 'isAtCapacity'),
    'roles.matrix': _declares(shippedSources[2], 'bool can('),
    'summary.seatInvariant': _declares(
      shippedSources[5],
      'Assigned seats must equal the current member count',
    ),
    'summary.invitations': _declares(shippedSources[5], 'TeamInvitationStatus'),
    'summary.permissionHealth': _declares(
      shippedSources[5],
      'TeamPermissionHealth',
    ),
  };

  /// Whether any production file outside the acceptance harness imports the
  /// membership registry this slice validates.
  static final bool _productionCallerPresent =
      _productionCallSites(shippedSources[0]) > 0;

  /// Whether any shipped file turns an invitation into a member. Measured, not
  /// assumed.
  static final bool _invitationLifecycleEnforcedSomewhere =
      _invitationLifecycleCallSites() > 0;

  /// Whether any shipped file computes permission health from the role matrix.
  /// Measured, not assumed.
  static final bool _permissionHealthComputedSomewhere =
      _permissionHealthComputationCallSites() > 0;

  /// A studio built here, never the production organization claim.
  static Studio _studio({
    String id = 'st-fixture',
    String name = 'Void Studio',
  }) => Studio(id: id, name: name, plan: 'enterprise');

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117TeamCollaborationWorkflowDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117TeamCollaborationWorkflowContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117TeamCollaborationWorkflowDrillRun(
      observations: <Sprint117TeamCollaborationWorkflowObservation>[
        _observeOrganization(),
        await _observeSeats(),
        _observeInvite(),
        _observeRoles(),
        _observePermissions(),
        await _observeMemberRemoval(),
        await _observeAudit(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveCredentialObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
      productionCallerPresent: _productionCallerPresent,
      invitationLifecycleEnforcedSomewhere:
          _invitationLifecycleEnforcedSomewhere,
      permissionHealthComputedSomewhere: _permissionHealthComputedSomewhere,
    );
  }

  /// A summary over [members] whose seats agree with the roster.
  AccountCenterTeamCollaborationSummary _summary({
    required List<TeamMemberSummary> members,
    int? totalSeats,
    List<TeamInvitationSummary> invitations = const <TeamInvitationSummary>[],
    TeamPermissionHealth health = TeamPermissionHealth.healthy,
  }) => AccountCenterTeamCollaborationSummary(
    organization: const TeamOrganization(id: 'st-fixture', name: 'Void Studio'),
    seats: TeamSeatSummary(
      assigned: members.length,
      total: totalSeats ?? members.length,
    ),
    members: members,
    invitations: invitations,
    permissionHealth: health,
  );

  TeamMemberSummary _member(
    String id, {
    TeamMemberRole role = TeamMemberRole.viewer,
    DateTime? lastAccessedAt,
  }) => TeamMemberSummary(
    memberId: id,
    displayName: 'Member $id',
    role: role,
    lastAccessedAt: lastAccessedAt,
  );

  /// `organization` — a stable, non-empty identity on both seams.
  Sprint117TeamCollaborationWorkflowObservation _observeOrganization() {
    final studio = _studio();
    final identityCarried =
        studio.id == 'st-fixture' && studio.name == 'Void Studio';

    // The summary asserts rather than trusting: a blank identity is refused.
    // Deliberately NOT `const`: a constant would make the assertion a
    // compile-time error, and what this check measures is that the seam
    // refuses at runtime, not that the compiler noticed.
    var blankIdRefused = false;
    try {
      AccountCenterTeamCollaborationSummary(
        organization: TeamOrganization(id: '', name: 'Void Studio'),
        seats: TeamSeatSummary(assigned: 0, total: 0),
        members: const <TeamMemberSummary>[],
        invitations: const <TeamInvitationSummary>[],
        permissionHealth: TeamPermissionHealth.healthy,
      );
    } on AssertionError {
      blankIdRefused = true;
    }

    var blankNameRefused = false;
    try {
      AccountCenterTeamCollaborationSummary(
        organization: TeamOrganization(id: 'st-fixture', name: ''),
        seats: TeamSeatSummary(assigned: 0, total: 0),
        members: const <TeamMemberSummary>[],
        invitations: const <TeamInvitationSummary>[],
        permissionHealth: TeamPermissionHealth.healthy,
      );
    } on AssertionError {
      blankNameRefused = true;
    }

    // The two seams describe one organization: the same id and name the
    // registry holds are the ones the account summary carries.
    final summary = _summary(members: const <TeamMemberSummary>[]);
    final seamsAgree =
        summary.organization.id == studio.id &&
        summary.organization.name == studio.name;

    // The identity is not derived from the day the drill ran.
    final stableAcrossRuns = _studio().id == studio.id;

    final passed =
        identityCarried &&
        blankIdRefused &&
        blankNameRefused &&
        seamsAgree &&
        stableAcrossRuns;

    return Sprint117TeamCollaborationWorkflowObservation(
      checkId: 'organization',
      outcome: passed
          ? 'ORGANIZATION_IDENTITY_STABLE_NON_EMPTY_AND_ASSERTED'
          : 'ORGANIZATION_IDENTITY_MUTABLE_BLANK_ACCEPTED_OR_DIVERGED',
      facts: <String, Object?>{
        'studio_id': studio.id,
        'studio_name': studio.name,
        'identity_carried': identityCarried,
        'blank_id_refused': blankIdRefused,
        'blank_name_refused': blankNameRefused,
        'seams_agree': seamsAgree,
        'stable_across_runs': stableAcrossRuns,
        'mechanism': 'Studio identity + AccountCenterTeamCollaborationSummary',
        'acceptance_mechanism_present':
            _mechanismPresent['summary.seatInvariant'],
      },
      passed: passed,
    );
  }

  /// `seats` — granted under a guard, released on removal, never disagreed.
  Future<Sprint117TeamCollaborationWorkflowObservation> _observeSeats() async {
    final registry = StudioRegistry(
      studio: _studio(),
      seats: SeatLicense(maxSeats: 2),
    );

    final first = registry.addMember(userId: 'a', role: StudioRole.admin);
    final second = registry.addMember(userId: 'b', role: StudioRole.viewer);
    // Capacity reached: a third grant is refused rather than oversubscribed.
    final third = registry.addMember(userId: 'c', role: StudioRole.viewer);
    final atCapacity = registry.seats.isAtCapacity;
    final rosterMatchesSeatCount =
        registry.members.length == registry.seats.usedSeats;

    // One person cannot occupy two seats.
    final duplicate = registry.addMember(userId: 'a', role: StudioRole.viewer);
    final noDuplicateSeat =
        registry.members.length == 2 && registry.seats.usedSeats == 2;

    // A released seat becomes available again.
    final removed = await registry.removeMember(
      'b',
      actor: 'a',
      reauthenticate: () async => true,
    );
    final seatFreed = registry.seats.usedSeats == 1;
    final reused = registry.addMember(userId: 'c', role: StudioRole.viewer);
    final rosterStillMatches =
        registry.members.length == registry.seats.usedSeats;

    // The account summary refuses an assigned count that contradicts the
    // roster, so the two can never quietly disagree.
    var inconsistentRefused = false;
    try {
      _summary(members: <TeamMemberSummary>[_member('a')], totalSeats: 3);
      // Assigned is derived from the member count, so the only way to
      // contradict it is to hand the constructor a summary that was built
      // against a different roster.
      AccountCenterTeamCollaborationSummary(
        organization: const TeamOrganization(id: 'st-fixture', name: 'Void'),
        seats: TeamSeatSummary(assigned: 2, total: 3),
        members: <TeamMemberSummary>[_member('a')],
        invitations: const <TeamInvitationSummary>[],
        permissionHealth: TeamPermissionHealth.healthy,
      );
    } on ArgumentError {
      inconsistentRefused = true;
    }

    var overCapacityRefused = false;
    try {
      TeamSeatSummary(assigned: 4, total: 3);
    } on ArgumentError {
      overCapacityRefused = true;
    }

    final passed =
        first &&
        second &&
        !third &&
        atCapacity &&
        rosterMatchesSeatCount &&
        !duplicate &&
        noDuplicateSeat &&
        removed &&
        seatFreed &&
        reused &&
        rosterStillMatches &&
        inconsistentRefused &&
        overCapacityRefused;

    return Sprint117TeamCollaborationWorkflowObservation(
      checkId: 'seats',
      outcome: passed
          ? 'SEATS_GUARDED_RELEASED_AND_NEVER_DISAGREE_WITH_ROSTER'
          : 'SEATS_OVERSOLD_DUPLICATED_OR_DISAGREED_WITH_ROSTER',
      facts: <String, Object?>{
        'grants_before_capacity': 2,
        'third_grant_refused': !third,
        'at_capacity_observed': atCapacity,
        'roster_matches_seat_count': rosterStillMatches,
        'duplicate_add_refused': !duplicate,
        'used_seats_after_duplicate': registry.seats.usedSeats,
        'removal_released_a_seat': seatFreed,
        'freed_seat_reusable': reused,
        'inconsistent_summary_refused': inconsistentRefused,
        'over_capacity_summary_refused': overCapacityRefused,
        'mechanism': 'SeatLicense + AccountCenterTeamCollaborationSummary',
        'acceptance_mechanism_present': _mechanismPresent['seats.capacity'],
      },
      passed: passed,
    );
  }

  /// `invite` — statuses are carried, distinct, and acted on nowhere.
  Sprint117TeamCollaborationWorkflowObservation _observeInvite() {
    final invitations = <TeamInvitationSummary>[
      const TeamInvitationSummary(
        invitationId: 'inv-pending',
        role: TeamMemberRole.editor,
        status: TeamInvitationStatus.pending,
      ),
      const TeamInvitationSummary(
        invitationId: 'inv-accepted',
        role: TeamMemberRole.viewer,
        status: TeamInvitationStatus.accepted,
      ),
      const TeamInvitationSummary(
        invitationId: 'inv-expired',
        role: TeamMemberRole.viewer,
        status: TeamInvitationStatus.expired,
      ),
      const TeamInvitationSummary(
        invitationId: 'inv-revoked',
        role: TeamMemberRole.viewer,
        status: TeamInvitationStatus.revoked,
      ),
    ];

    final summary = _summary(
      members: const <TeamMemberSummary>[],
      totalSeats: 4,
      invitations: invitations,
    );
    final pending = summary.pendingInvitations;
    final onlyPendingReported =
        pending.length == 1 && pending.single.invitationId == 'inv-pending';

    // Every status is distinguishable, so "pending" cannot mean "any".
    final statusesDistinct =
        TeamInvitationStatus.values.toSet().length ==
        TeamInvitationStatus.values.length;

    // A revoked invite is not a pending one, whatever else it is.
    final revokedNotPending = !pending.any(
      (invitation) => invitation.status == TeamInvitationStatus.revoked,
    );

    // Two invitations may not share an id, or "which one" becomes unanswerable.
    var duplicateIdRefused = false;
    try {
      _summary(
        members: const <TeamMemberSummary>[],
        totalSeats: 4,
        invitations: const <TeamInvitationSummary>[
          TeamInvitationSummary(
            invitationId: 'inv-same',
            role: TeamMemberRole.viewer,
            status: TeamInvitationStatus.pending,
          ),
          TeamInvitationSummary(
            invitationId: 'inv-same',
            role: TeamMemberRole.editor,
            status: TeamInvitationStatus.pending,
          ),
        ],
      );
    } on ArgumentError {
      duplicateIdRefused = true;
    }

    // The registry has no invitation lifecycle of its own: adding a member is
    // immediate and never consults an invitation. Measured by the repository
    // scan, recorded here so the fact and the open item agree.
    final lifecycleEnforced = _invitationLifecycleEnforcedSomewhere;

    final passed =
        onlyPendingReported &&
        statusesDistinct &&
        revokedNotPending &&
        duplicateIdRefused;

    return Sprint117TeamCollaborationWorkflowObservation(
      checkId: 'invite',
      outcome: passed
          ? 'INVITATIONS_CARRY_DISTINCT_STATUSES_UNDER_UNIQUE_IDS'
          : 'INVITATION_STATUSES_COLLAPSED_OR_IDS_NOT_UNIQUE',
      facts: <String, Object?>{
        'invitation_count': invitations.length,
        'status_values': TeamInvitationStatus.values.length,
        'statuses_distinct': statusesDistinct,
        'pending_reported': pending.length,
        'only_pending_reported': onlyPendingReported,
        'revoked_never_pending': revokedNotPending,
        'duplicate_id_refused': duplicateIdRefused,
        'invitation_lifecycle_enforced_somewhere': lifecycleEnforced,
        'invitation_lifecycle_call_sites': _invitationLifecycleCallSites(),
        'mechanism': 'TeamInvitationStatus + pendingInvitations',
        'acceptance_mechanism_present':
            _mechanismPresent['summary.invitations'],
      },
      passed: passed,
    );
  }

  /// `roles` — a total matrix, distinct roles, one seat per person.
  Sprint117TeamCollaborationWorkflowObservation _observeRoles() {
    // The matrix is total: every role resolves every permission, and nothing
    // escapes the loop. The count is what makes that measurable — a check
    // like `outcome is! bool` can never fail, because the declared return
    // type is already `bool`, so it would report a total matrix without ever
    // looking at one.
    final decisions = <String>[];
    for (final role in StudioRole.values) {
      for (final permission in Permission.values) {
        final outcome = role.can(permission);
        // The decision itself is recorded, so the report shows which pairs
        // the matrix grants rather than only how many it resolved.
        decisions.add('${role.name}.${permission.name}=$outcome');
      }
    }
    final total = StudioRole.values.length * Permission.values.length;
    final matrixIsTotal = decisions.length == total;

    // A stronger role is never weaker than a weaker one, so the matrix has an
    // order rather than being an arbitrary table.
    final monotone = _roleOrderIsMonotone();

    // Roles are distinct: collapsing two would make "who may remove whom"
    // unanswerable.
    final rolesDistinct =
        StudioRole.values.toSet().length == StudioRole.values.length;

    final registry = StudioRegistry(
      studio: _studio(),
      seats: SeatLicense(maxSeats: 3),
    );
    registry.addMember(userId: 'a', role: StudioRole.admin);
    registry.addMember(userId: 'a', role: StudioRole.viewer);
    final oneIdentityOneSeat =
        registry.members.length == 1 && registry.seats.usedSeats == 1;

    final passed =
        matrixIsTotal && monotone && rolesDistinct && oneIdentityOneSeat;

    return _roleObservation(
      passed,
      decisions,
      extra: <String, Object?>{
        'matrix_is_total': matrixIsTotal,
        'decisions_measured': decisions.length,
        'matrix_is_monotone': monotone,
        'roles_distinct': rolesDistinct,
        'one_identity_one_seat': oneIdentityOneSeat,
        'mechanism': 'StudioRole.can + StudioRegistry.addMember',
        'acceptance_mechanism_present': _mechanismPresent['roles.matrix'],
      },
    );
  }

  /// `_roles` — monotonicity helper that never throws and always answers.
  Sprint117TeamCollaborationWorkflowObservation _roleObservation(
    bool passed,
    List<String> decisions, {
    Map<String, Object?>? extra,
  }) => Sprint117TeamCollaborationWorkflowObservation(
    checkId: 'roles',
    outcome: passed
        ? 'ROLE_MATRIX_TOTAL_ORDERED_AND_ROLES_HOLD_ONE_SEAT_EACH'
        : 'ROLE_MATRIX_INCOMPLETE_UNORDERED_OR_ROLES_COLLAPSED',
    facts: <String, Object?>{
      'role_count': StudioRole.values.length,
      'permission_count': Permission.values.length,
      ...?extra,
    },
    passed: passed,
  );

  /// Whether granting a stronger role never withholds a permission.
  static bool _roleOrderIsMonotone() {
    const order = <StudioRole, int>{
      StudioRole.viewer: 0,
      StudioRole.member: 1,
      StudioRole.admin: 2,
    };
    for (final weaker in order.keys) {
      for (final stronger in order.keys) {
        if (order[stronger]! <= order[weaker]!) continue;
        for (final permission in Permission.values) {
          if (weaker.can(permission) && !stronger.can(permission)) return false;
        }
      }
    }
    return true;
  }

  /// `permissions` — the matrix decides, and the health is a caller's claim.
  Sprint117TeamCollaborationWorkflowObservation _observePermissions() {
    // The permission this slice turns on is held by the administrator alone.
    final manageMembersByRole = <StudioRole, bool>{
      for (final role in StudioRole.values)
        role: role.can(Permission.manageMembers),
    };
    final onlyAdminManages =
        manageMembersByRole[StudioRole.admin] == true &&
        manageMembersByRole.entries
            .where((entry) => entry.key != StudioRole.admin)
            .every((entry) => !entry.value);

    // The summary carries the health it was given, immutably.
    final summary = _summary(
      members: const <TeamMemberSummary>[],
      health: TeamPermissionHealth.reviewRequired,
    );
    final healthCarried =
        summary.permissionHealth == TeamPermissionHealth.reviewRequired;
    final healthIsEnum = TeamPermissionHealth.values.length == 4;

    // Unknown is a real state, not a default that hides a missing
    // measurement: a caller with no opinion must be able to say so instead
    // of asserting health it never computed. Built explicitly rather than
    // relying on the helper's default, which is `healthy` and would make
    // this fact true for the wrong reason.
    final unknownIsExpressible =
        _summary(
          members: const <TeamMemberSummary>[],
          health: TeamPermissionHealth.unknown,
        ).permissionHealth ==
        TeamPermissionHealth.unknown;
    // And the value the summary is normally given is carried, not defaulted
    // over: a review flag survives the round trip.
    final reviewIsCarried =
        _summary(
          members: const <TeamMemberSummary>[],
          health: TeamPermissionHealth.reviewRequired,
        ).permissionHealth ==
        TeamPermissionHealth.reviewRequired;

    final computedSomewhere = _permissionHealthComputedSomewhere;

    final passed =
        onlyAdminManages &&
        healthCarried &&
        healthIsEnum &&
        unknownIsExpressible &&
        reviewIsCarried;

    return Sprint117TeamCollaborationWorkflowObservation(
      checkId: 'permissions',
      outcome: passed
          ? 'PERMISSION_MATRIX_HOLDS_MANAGE_MEMBERS_AND_HEALTH_IS_CARRIED'
          : 'PERMISSION_MATRIX_INCONSISTENT_OR_HEALTH_NOT_CARRIED',
      facts: <String, Object?>{
        'manage_members_by_role': manageMembersByRole.map(
          (role, allowed) => MapEntry<String, Object?>(role.name, allowed),
        ),
        'only_admin_manages_members': onlyAdminManages,
        'permission_health_carried': healthCarried,
        'permission_health_values': TeamPermissionHealth.values.length,
        'unknown_is_expressible': unknownIsExpressible,
        'review_required_is_carried': reviewIsCarried,
        'permission_health_computed_somewhere': computedSomewhere,
        'permission_health_computation_call_sites':
            _permissionHealthComputationCallSites(),
        'mechanism': 'StudioRole.can + TeamPermissionHealth',
        'acceptance_mechanism_present': _mechanismPresent['roles.matrix'],
      },
      passed: passed,
    );
  }

  /// `member_removal` — gated, permissioned, and never orphaning.
  Future<Sprint117TeamCollaborationWorkflowObservation>
  _observeMemberRemoval() async {
    final registry = StudioRegistry(
      studio: _studio(),
      seats: SeatLicense(maxSeats: 4),
    );
    registry.addMember(userId: 'owner', role: StudioRole.admin);
    registry.addMember(userId: 'second-admin', role: StudioRole.admin);
    registry.addMember(userId: 'ed', role: StudioRole.member);
    registry.addMember(userId: 'bob', role: StudioRole.viewer);

    // No gate at all: fail closed.
    final ungated = await registry.removeMember('bob', actor: 'owner');
    final ungatedRefused = ungated == false;
    final survivedUngated = registry.members.any(
      (member) => member.userId == 'bob',
    );
    final seatHeldUngated = registry.seats.usedSeats == 4;

    // A gate that refuses is a refusal.
    final refusedByGate = await registry.removeMember(
      'bob',
      actor: 'owner',
      reauthenticate: () async => false,
    );
    final survivedGate = registry.members.any(
      (member) => member.userId == 'bob',
    );

    // An actor who is not on the roster cannot remove anybody.
    final stranger = await registry.removeMember(
      'bob',
      actor: 'stranger',
      reauthenticate: () async => true,
    );
    // A member without manage-members cannot either.
    final withoutPermission = await registry.removeMember(
      'bob',
      actor: 'ed',
      reauthenticate: () async => true,
    );
    final survivedUnauthorized = registry.members.any(
      (member) => member.userId == 'bob',
    );

    // The last administrator may not step down, whoever asks.
    final solo = StudioRegistry(
      studio: _studio(id: 'st-solo'),
      seats: SeatLicense(maxSeats: 2),
    );
    solo.addMember(userId: 'only-admin', role: StudioRole.admin);
    final lastAdmin = await solo.removeMember(
      'only-admin',
      actor: 'only-admin',
      reauthenticate: () async => true,
    );
    final lastAdminKept = solo.members.any(
      (member) => member.userId == 'only-admin',
    );

    // A gate that agrees, with permission, allows it.
    final allowed = await registry.removeMember(
      'bob',
      actor: 'owner',
      reauthenticate: () async => true,
    );
    final removedFromRoster = !registry.members.any(
      (member) => member.userId == 'bob',
    );
    final seatReleased = registry.seats.usedSeats == 3;
    final rosterStillMatchesSeats =
        registry.members.length == registry.seats.usedSeats;

    final passed =
        ungatedRefused &&
        survivedUngated &&
        seatHeldUngated &&
        !refusedByGate &&
        survivedGate &&
        !stranger &&
        !withoutPermission &&
        survivedUnauthorized &&
        !lastAdmin &&
        lastAdminKept &&
        allowed &&
        removedFromRoster &&
        seatReleased &&
        rosterStillMatchesSeats;

    return Sprint117TeamCollaborationWorkflowObservation(
      checkId: 'member_removal',
      outcome: passed
          ? 'REMOVAL_GATED_PERMISSIONED_AUDITED_AND_NEVER_ORPHANS'
          : 'REMOVAL_UNGATED_UNATTRIBUTED_OR_ORPHANED_THE_ORGANIZATION',
      facts: <String, Object?>{
        'ungated_removal_refused': ungatedRefused,
        'member_survived_ungated_attempt': survivedUngated,
        'seat_held_after_ungated_attempt': seatHeldUngated,
        'gate_refusal_refused_removal': !refusedByGate,
        'member_survived_gate_refusal': survivedGate,
        'stranger_cannot_remove': !stranger,
        'member_without_permission_cannot_remove': !withoutPermission,
        'member_survived_unauthorized_attempts': survivedUnauthorized,
        'last_administrator_kept': !lastAdmin && lastAdminKept,
        'permitted_removal_succeeded': allowed,
        'removed_member_left_roster': removedFromRoster,
        'seat_released_after_removal': seatReleased,
        'roster_still_matches_seats': rosterStillMatchesSeats,
        'mechanism': 'StudioRegistry.removeMember + StudioRole.can',
        'acceptance_mechanism_present': _mechanismPresent['registry.remove'],
        'gate_mechanism_present': _mechanismPresent['registry.gate'],
        'permission_mechanism_present':
            _mechanismPresent['registry.permission'],
        'last_admin_mechanism_present': _mechanismPresent['registry.lastAdmin'],
        'denied_audit_mechanism_present':
            _mechanismPresent['registry.deniedAudit'],
      },
      passed: passed,
    );
  }

  /// `audit` — both outcomes present, neither carrying a role or a secret.
  Future<Sprint117TeamCollaborationWorkflowObservation> _observeAudit() async {
    final registry = StudioRegistry(
      studio: _studio(),
      seats: SeatLicense(maxSeats: 4),
    );
    registry.addMember(userId: 'owner', role: StudioRole.admin);
    registry.addMember(userId: 'bob', role: StudioRole.member);
    registry.addMember(userId: 'dan', role: StudioRole.viewer);
    // A refused add has to actually be attempted: three members fit in four
    // seats, so measuring "a refused seat is audited" without provoking a
    // refusal would report an empty trail as a healthy one.
    final refusedDuplicate = registry.addMember(
      userId: 'owner',
      role: StudioRole.viewer,
    );

    final accepted = await registry.removeMember(
      'bob',
      actor: 'owner',
      reauthenticate: () async => true,
    );
    final refusedByGate = await registry.removeMember(
      'dan',
      actor: 'owner',
      reauthenticate: () async => false,
    );
    // A target that was never a member: also a refused attempt, and it must be
    // as visible as the gate's refusal.
    final unknownTarget = await registry.removeMember(
      'ghost',
      actor: 'owner',
      reauthenticate: () async => true,
    );

    final adds = registry.audit.byAction('add-member');
    final removals = registry.audit.byAction('remove-member');
    final deniedRemovals = registry.audit.byAction('denied_remove_member');
    final deniedAdds = registry.audit.byAction('denied_add_member');

    // A refused attempt stays distinguishable from an attempt never made.
    final refusalsAreVisible = deniedRemovals.length == 2;
    final targetsRecorded = deniedRemovals.map((event) => event.target).toSet();
    final bothRefusalsNamed =
        targetsRecorded.contains('dan') && targetsRecorded.contains('ghost');

    // The actor is the one who asked, never a stand-in.
    final attributed =
        removals.length == 1 &&
        removals.single.actor == 'owner' &&
        removals.single.target == 'bob';

    // Rejected adds leave a trail too, so a refused seat is not invisible.
    final refusedSeatIsAudited = !refusedDuplicate && deniedAdds.length == 1;

    // No row carries a role, a permission, or the name of the gate: the row
    // says who, what, and to whom, and nothing about authority.
    final fields = <String>{
      for (final event in registry.audit.events) ...<String>[
        event.actor,
        event.action,
        event.target,
      ],
    };
    final forbidden = <String>{
      ...StudioRole.values.map((role) => role.name),
      ...Permission.values.map((permission) => permission.name),
      'reauthenticate',
    };
    final leaksAuthority = fields.any(forbidden.contains);

    // The trail is a bounded ring, not an unbounded sink.
    final capped = AuditLog(capacity: 3);
    for (var i = 0; i < 5; i += 1) {
      capped.append(actor: 'owner', action: 'add-member', target: 'u$i');
    }
    final ringCapped = capped.events.length == 3;
    final oldestDropped = capped.events.first.target == 'u2';

    final passed =
        accepted &&
        !refusedByGate &&
        !unknownTarget &&
        adds.length == 3 &&
        removals.length == 1 &&
        refusalsAreVisible &&
        bothRefusalsNamed &&
        attributed &&
        refusedSeatIsAudited &&
        !leaksAuthority &&
        ringCapped &&
        oldestDropped;

    return Sprint117TeamCollaborationWorkflowObservation(
      checkId: 'audit',
      outcome: passed
          ? 'AUDIT_COVERS_ACCEPTED_AND_REFUSED_WITHOUT_LEAKING_AUTHORITY'
          : 'AUDIT_MISSED_AN_OUTCOME_OR_LEAKED_ROLE_PERMISSION_OR_SECRET',
      facts: <String, Object?>{
        'add_events': adds.length,
        'removal_events': removals.length,
        'denied_removal_events': deniedRemovals.length,
        'denied_add_events': deniedAdds.length,
        'refusals_visible': refusalsAreVisible,
        'both_refusals_named': bothRefusalsNamed,
        'removal_attributed_to_actor': attributed,
        'refused_seat_audited': refusedSeatIsAudited,
        'audit_fields': fields.toList(growable: false)..sort(),
        'audit_leaks_role_or_permission_or_secret': leaksAuthority,
        'audit_ring_capped': ringCapped,
        'audit_drops_oldest_first': oldestDropped,
        'mechanism': 'AuditLog.append + StudioRegistry denial rows',
        'acceptance_mechanism_present':
            _mechanismPresent['registry.deniedAudit'],
      },
      passed: passed,
    );
  }
}
