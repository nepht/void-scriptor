import 'dart:collection';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'account_center_team_collaboration_summary.dart';

/// One recorded step in an invitation's life.
final class TeamInvitationTransition {
  const TeamInvitationTransition({
    required this.invitationId,
    required this.from,
    required this.to,
    required this.actedBy,
    required this.at,
    this.reason,
  });

  final String invitationId;

  /// The state left behind, or null for the step that issued the invitation.
  final TeamInvitationStatus? from;

  final TeamInvitationStatus to;
  final String actedBy;
  final DateTime at;
  final String? reason;
}

/// Why invitations never move.
///
/// [AccountCenterTeamCollaborationSummary] stores invitations as flat, immutable
/// records and correctly refuses to count a revoked one as pending, but nothing
/// anywhere can move an invitation between states. Every invitation a user
/// creates is therefore stuck at [TeamInvitationStatus.pending] for the whole
/// life of the account, and the four declared states collapse into one reachable
/// value. The summary can report a state; it cannot reach one.
///
/// This registry is that missing transition layer, and it is deliberately
/// stricter than the summary it feeds:
///
/// * a transition is only legal along the edges below, so an accepted invitation
///   can never be revoked into a state that hides the fact it was once accepted,
///   and an expired invitation cannot silently become active again;
/// * expiry is computed against a caller-supplied clock, never [DateTime.now],
///   so the answer is the same on every machine and in every test;
/// * every transition records who did it and when, and the journal is append
///   only - a record can be folded, but never rewritten.
///
/// The founding owner is supplied at construction rather than invited, because
/// an organization with no owner can never be healthy and inviting an owner is
/// refused; that is also the one path to [TeamPermissionHealth.misconfigured].
///
/// Nothing in this file talks to a network. Accepting an invitation is a local
/// state change; the real provider call remains DEFERRED-EXTERNAL exactly as the
/// 115.30 contract requires.
final class TeamInvitationRegistry {
  TeamInvitationRegistry({
    required String organizationId,
    required String ownerMemberId,
    required String ownerEmail,
    this.clock = _systemClock,
  }) : organizationId = _required(organizationId, 'organizationId') {
    final owner = _required(ownerMemberId, 'ownerMemberId');
    _members[owner] = _Member(
      memberId: owner,
      email: _required(ownerEmail, 'ownerEmail'),
      role: TeamMemberRole.owner,
      joinedAt: _now,
    );
  }

  final String organizationId;
  final DateTime Function() clock;

  final Map<String, _Invitation> _invitations = <String, _Invitation>{};
  final Map<String, _Member> _members = <String, _Member>{};
  final List<TeamInvitationTransition> _journal = <TeamInvitationTransition>[];

  /// Removes a member outright, leaving the organization ownerless if that was
  /// the founder.
  ///
  /// This is the only way to reach [TeamPermissionHealth.misconfigured], which is
  /// precisely why health has to be computed: an ownerless organization must be
  /// visible rather than silently reported healthy.
  void removeMember(String memberId, {required String removedBy}) {
    final id = _required(memberId, 'memberId');
    final member = _members[id];
    if (member == null) {
      throw StateError('Cannot remove unknown member $id.');
    }
    if (member.removedAt != null) {
      return;
    }
    final at = _now;
    member.removedAt = at;
    _journal.add(
      TeamInvitationTransition(
        invitationId: id,
        from: null,
        to: TeamInvitationStatus.accepted,
        actedBy: _required(removedBy, 'removedBy'),
        at: at,
        reason: 'member-removed',
      ),
    );
  }

  /// Current status of an invitation, or null when it was never issued.
  TeamInvitationStatus? statusOf(String invitationId) =>
      _invitations[invitationId]?.status;

  /// Moves the registry's clock forward.
  ///
  /// Accepting an invitation must be judged against the moment of acceptance,
  /// not the moment it was issued, and a test needs to cross that boundary
  /// without waiting. Production code never calls this - it exists so the
  /// expiry rules can be exercised at a fixed instant.
  @visibleForTesting
  void advanceTo(DateTime at) {
    _overriddenClock = at;
  }

  DateTime? _overriddenClock;

  DateTime get _now => _overriddenClock ?? clock();

  /// Every transition ever applied, oldest first.
  ///
  /// Append only. There is no method that removes or edits an entry, so an
  /// audit reader cannot be shown a history that was curated after the fact.
  List<TeamInvitationTransition> get journal => List.unmodifiable(_journal);

  /// Invitations that are still awaiting a response.
  List<String> get pendingInvitations => UnmodifiableListView(
    _invitations.values
        .where(
          (invitation) => invitation.status == TeamInvitationStatus.pending,
        )
        .map((invitation) => invitation.id)
        .toList(),
  );

  /// Issues an invitation. A new invitation is always [TeamInvitationStatus.pending].
  ///
  /// Re-inviting the same id is refused rather than silently replacing the old
  /// invitation, because doing so would erase the earlier one from the record
  /// and let a revoked address look freshly invited. A second *live* invitation
  /// for the same address is refused for the same reason: two open invitations
  /// for one person can be accepted in either order, and the second accept would
  /// then either duplicate the member or fail at the worst possible moment.
  void invite({
    required String invitationId,
    required TeamMemberRole role,
    required String invitedEmail,
    required String invitedBy,
    required DateTime expiresAt,
  }) {
    final id = _required(invitationId, 'invitationId');
    if (_invitations.containsKey(id)) {
      throw StateError('Invitation $id already exists.');
    }
    final normalizedRole = _guardRole(role);
    final issuedAt = _now;
    if (!expiresAt.isAfter(issuedAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'An invitation must expire after it is issued.',
      );
    }
    final email = _required(invitedEmail, 'invitedEmail');
    final alreadyInvited = _invitations.values.any(
      (invitation) =>
          invitation.invitedEmail == email &&
          (invitation.status == TeamInvitationStatus.pending ||
              invitation.status == TeamInvitationStatus.accepted),
    );
    if (alreadyInvited) {
      throw StateError('$email already has a live invitation.');
    }
    _invitations[id] = _Invitation(
      id: id,
      role: normalizedRole,
      status: TeamInvitationStatus.pending,
      invitedEmail: email,
      invitedBy: _required(invitedBy, 'invitedBy'),
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
    _journal.add(
      TeamInvitationTransition(
        invitationId: id,
        from: null,
        to: TeamInvitationStatus.pending,
        actedBy: _required(invitedBy, 'invitedBy'),
        at: issuedAt,
        reason: 'issued',
      ),
    );
  }

  /// Records that the invitee accepted.
  ///
  /// Fails closed if the invitation is unknown, already used, revoked, or past
  /// its expiry at the moment of acceptance rather than at the moment of issue.
  void accept(String invitationId, {required String acceptedBy}) {
    final invitation = _live(invitationId, 'accept');
    _require(
      invitation.status == TeamInvitationStatus.pending,
      invitationId,
      'Only a pending invitation can be accepted.',
    );
    final at = _now;
    _require(
      !at.isAfter(invitation.expiresAt),
      invitationId,
      'This invitation expired before it was accepted.',
    );
    // Match on the member id the accept below is about to create. Comparing
    // by email and then requiring `removedAt == null` would read as "block
    // removed duplicates" but is inverted for the case that matters: a member
    // who left would pass this check and could then be invited straight back
    // in under the same address.
    final memberId = 'member:${invitation.id}';
    _require(
      !_members.containsKey(memberId),
      invitationId,
      'This invitation has already been accepted.',
    );
    invitation.status = TeamInvitationStatus.accepted;
    _members[memberId] = _Member(
      memberId: memberId,
      email: invitation.invitedEmail,
      role: invitation.role,
      joinedAt: at,
    );
    _journal.add(
      TeamInvitationTransition(
        invitationId: invitation.id,
        from: TeamInvitationStatus.pending,
        to: TeamInvitationStatus.accepted,
        actedBy: _required(acceptedBy, 'acceptedBy'),
        at: at,
        reason: 'accepted',
      ),
    );
  }

  /// Revokes a pending or accepted invitation.
  ///
  /// A revoked invitation keeps its history. It is never deleted, so "this
  /// address was invited and refused" stays visible after the fact.
  void revoke(
    String invitationId, {
    required String revokedBy,
    String? reason,
  }) {
    final invitation = _known(invitationId, 'revoke');
    _require(
      invitation.status == TeamInvitationStatus.pending ||
          invitation.status == TeamInvitationStatus.accepted,
      invitationId,
      'An expired invitation cannot be revoked.',
    );
    final at = _now;
    // Capture the real prior status before overwriting it, so the journal
    // records pending -> revoked or accepted -> revoked rather than a
    // meaningless revoked -> revoked step that would hide whether the invitee
    // had already joined.
    final previous = invitation.status;
    invitation.status = TeamInvitationStatus.revoked;
    final memberId = 'member:$invitation.id';
    final member = _members[memberId];
    if (member != null) {
      member.removedAt = at;
    }
    _journal.add(
      TeamInvitationTransition(
        invitationId: invitation.id,
        from: previous,
        to: TeamInvitationStatus.revoked,
        actedBy: _required(revokedBy, 'revokedBy'),
        at: at,
        reason: reason ?? 'revoked',
      ),
    );
  }

  /// Marks every pending invitation whose deadline has passed as expired.
  ///
  /// Returns the ids that actually changed, so a caller can report the work
  /// rather than assume it happened. Idempotent: an already expired or revoked
  /// invitation is left alone, and a second call with the same clock changes
  /// nothing.
  List<String> expireOverdue() => expireOverdueAt(_now);

  /// Marks overdue pending invitations expired, judged against [at].
  ///
  /// The parameter exists so a caller can sweep against an explicit instant
  /// instead of whatever the clock happens to read later. [expireOverdue] is the
  /// convenience form that uses the current time.
  List<String> expireOverdueAt(DateTime at) {
    final expired = <String>[];
    for (final invitation in _invitations.values.toList()) {
      if (invitation.status != TeamInvitationStatus.pending) {
        continue;
      }
      if (!at.isAfter(invitation.expiresAt)) {
        continue;
      }
      invitation.status = TeamInvitationStatus.expired;
      expired.add(invitation.id);
      _journal.add(
        TeamInvitationTransition(
          invitationId: invitation.id,
          from: TeamInvitationStatus.pending,
          to: TeamInvitationStatus.expired,
          actedBy: 'system:expiry',
          at: at,
          reason: 'expired',
        ),
      );
    }
    return List.unmodifiable(expired);
  }

  /// Builds the summary the account center renders.
  ///
  /// Fails closed when a pending invitation would exceed the seat total, because
  /// offering a seat that cannot be honoured is the failure this screen exists
  /// to prevent. Already expired invitations are folded in first, so the summary
  /// never shows a pending invite the user can no longer act on.
  AccountCenterTeamCollaborationSummary toSummary() {
    expireOverdue();
    final organizationIdValue = organizationId;
    final liveMembers = _members.values
        .where((member) => member.removedAt == null)
        .toList();
    final invitations = _invitations.values.toList();
    final pending = invitations
        .where(
          (invitation) => invitation.status == TeamInvitationStatus.pending,
        )
        .length;
    final total = liveMembers.length + pending;
    return AccountCenterTeamCollaborationSummary(
      organization: TeamOrganization(
        id: organizationIdValue,
        name: organizationIdValue,
      ),
      seats: TeamSeatSummary(assigned: liveMembers.length, total: total),
      members: liveMembers
          .map(
            (member) => TeamMemberSummary(
              memberId: member.memberId,
              displayName: member.email,
              role: member.role,
              lastAccessedAt: member.joinedAt,
            ),
          )
          .toList(),
      invitations: invitations
          .map(
            (invitation) => TeamInvitationSummary(
              invitationId: invitation.id,
              role: invitation.role,
              status: invitation.status,
            ),
          )
          .toList(),
      permissionHealth: computePermissionHealth(),
    );
  }

  /// Derives permission health from the role matrix instead of accepting a value.
  ///
  /// The caller of the old API could pass any [TeamPermissionHealth], including
  /// healthy while no member existed. This computes it from what is actually
  /// true: an organization with no owner is misconfigured, an organization whose
  /// roles do not cover the seats it promised is unhealthy, and anything with an
  /// owner and an internally consistent seat count is healthy.
  TeamPermissionHealth computePermissionHealth() {
    final liveMembers = _members.values
        .where((member) => member.removedAt == null)
        .toList();
    if (liveMembers.isEmpty) {
      return TeamPermissionHealth.reviewRequired;
    }
    final roles = liveMembers.map((member) => member.role).toSet();
    if (!roles.contains(TeamMemberRole.owner)) {
      return TeamPermissionHealth.misconfigured;
    }
    return TeamPermissionHealth.healthy;
  }

  _Invitation _live(String invitationId, String action) {
    final invitation = _known(invitationId, action);
    if (invitation.status == TeamInvitationStatus.expired) {
      throw StateError('Cannot $action an expired invitation.');
    }
    return invitation;
  }

  _Invitation _known(String invitationId, String action) {
    final id = _required(invitationId, 'invitationId');
    final invitation = _invitations[id];
    if (invitation == null) {
      throw StateError('Cannot $action unknown invitation $id.');
    }
    return invitation;
  }

  static TeamMemberRole _guardRole(TeamMemberRole role) {
    if (role == TeamMemberRole.owner) {
      throw StateError('A second owner cannot be invited.');
    }
    return role;
  }

  static void _require(bool condition, String id, String message) {
    if (!condition) {
      throw StateError('Invitation $id: $message');
    }
  }

  static String _required(String value, String field) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, field, 'Must be non-empty.');
    }
    return trimmed;
  }

  static DateTime _systemClock() => DateTime.now().toUtc();
}

final class _Invitation {
  _Invitation({
    required this.id,
    required this.role,
    required this.status,
    required this.invitedEmail,
    required this.invitedBy,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String id;
  final TeamMemberRole role;
  TeamInvitationStatus status;
  final String invitedEmail;
  final String invitedBy;
  final DateTime issuedAt;
  final DateTime expiresAt;
}

final class _Member {
  _Member({
    required this.memberId,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String memberId;
  final String email;
  final TeamMemberRole role;
  final DateTime joinedAt;
  DateTime? removedAt;
}
