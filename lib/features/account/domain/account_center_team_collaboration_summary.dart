/// Sprint 115.30 — Team & Collaboration Summary.
///
/// Local account-level collaboration metadata only. Live organization,
/// invitation, identity, and authorization providers stay outside this seam.
library;

import 'dart:collection';

enum TeamMemberRole { owner, administrator, editor, viewer }

enum TeamInvitationStatus { pending, accepted, expired, revoked }

enum TeamPermissionHealth { unknown, healthy, reviewRequired, misconfigured }

final class TeamOrganization {
  const TeamOrganization({required this.id, required this.name})
    : assert(id != ''),
      assert(name != '');

  final String id;
  final String name;
}

final class TeamSeatSummary {
  TeamSeatSummary({required this.assigned, required this.total}) {
    if (assigned < 0 || total < 0 || assigned > total) {
      throw ArgumentError.value(<String, int>{
        'assigned': assigned,
        'total': total,
      }, 'seats');
    }
  }

  final int assigned;
  final int total;

  int get available => total - assigned;
}

final class TeamMemberSummary {
  const TeamMemberSummary({
    required this.memberId,
    required this.displayName,
    required this.role,
    required this.lastAccessedAt,
  }) : assert(memberId != ''),
       assert(displayName != '');

  final String memberId;
  final String displayName;
  final TeamMemberRole role;
  final DateTime? lastAccessedAt;
}

final class TeamInvitationSummary {
  const TeamInvitationSummary({
    required this.invitationId,
    required this.role,
    required this.status,
  }) : assert(invitationId != '');

  final String invitationId;
  final TeamMemberRole role;
  final TeamInvitationStatus status;
}

final class AccountCenterTeamCollaborationSummary {
  AccountCenterTeamCollaborationSummary({
    required this.organization,
    required this.seats,
    required Iterable<TeamMemberSummary> members,
    required Iterable<TeamInvitationSummary> invitations,
    required this.permissionHealth,
  }) : members = List.unmodifiable(members),
       invitations = List.unmodifiable(invitations) {
    _requireUnique(this.members.map((member) => member.memberId), 'memberId');
    _requireUnique(
      this.invitations.map((invitation) => invitation.invitationId),
      'invitationId',
    );
    if (seats.assigned != this.members.length) {
      throw ArgumentError.value(
        seats.assigned,
        'seats.assigned',
        'Assigned seats must equal the current member count.',
      );
    }
  }

  final TeamOrganization organization;
  final TeamSeatSummary seats;
  final List<TeamMemberSummary> members;
  final List<TeamInvitationSummary> invitations;
  final TeamPermissionHealth permissionHealth;

  Map<TeamMemberRole, int> get memberCountByRole {
    final counts = <TeamMemberRole, int>{};
    for (final member in members) {
      counts.update(member.role, (count) => count + 1, ifAbsent: () => 1);
    }
    return UnmodifiableMapView(counts);
  }

  List<TeamInvitationSummary> get pendingInvitations => List.unmodifiable(
    invitations.where(
      (invitation) => invitation.status == TeamInvitationStatus.pending,
    ),
  );

  DateTime? get mostRecentAccess {
    DateTime? latest;
    for (final member in members) {
      final accessedAt = member.lastAccessedAt;
      if (accessedAt != null &&
          (latest == null || accessedAt.isAfter(latest))) {
        latest = accessedAt;
      }
    }
    return latest;
  }
}

void _requireUnique(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      throw ArgumentError.value(value, field, 'Must be non-empty and unique.');
    }
  }
}
