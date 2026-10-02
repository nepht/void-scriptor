import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_team_collaboration_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_team_invitation_registry.dart';

/// Closes the 117.19 open item: invitation lifecycle and permission health were
/// declared but never enforced. The four statuses were unreachable in practice
/// and permission health was a value the caller supplied rather than a fact
/// computed from the role matrix.
void main() {
  group('TeamInvitationRegistry moves invitations through real states', () {
    test('an invitation is issued pending and recorded in the journal', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'writer@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );

      expect(registry.statusOf('inv-1'), TeamInvitationStatus.pending);
      expect(registry.pendingInvitations, ['inv-1']);

      final issued = registry.journal.single;
      expect(issued.from, isNull);
      expect(issued.to, TeamInvitationStatus.pending);
      expect(issued.actedBy, 'owner-1');
      expect(issued.at, _t(0));
      expect(issued.reason, 'issued');
    });

    test('accepting moves pending to accepted and creates the member', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'writer@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );

      registry.accept('inv-1', acceptedBy: 'writer@example.com');
      expect(registry.statusOf('inv-1'), TeamInvitationStatus.accepted);
      expect(registry.pendingInvitations, isEmpty);

      final step = registry.journal.last;
      expect(step.from, TeamInvitationStatus.pending);
      expect(step.to, TeamInvitationStatus.accepted);
      expect(step.reason, 'accepted');
    });

    test('the summary no longer lists an accepted invite as pending', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'writer@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.accept('inv-1', acceptedBy: 'writer@example.com');

      final summary = registry.toSummary();
      expect(summary.pendingInvitations, isEmpty);
      // The founding owner is a member too, so accepting one invite makes two.
      expect(summary.seats.assigned, 2);
      expect(summary.members, hasLength(2));
      expect(
        summary.members.map((member) => member.displayName),
        containsAll(<String>['owner@example.com', 'writer@example.com']),
      );
    });

    test('an overdue invitation expires and only that one changes', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'stale',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(1),
      );
      registry.invite(
        invitationId: 'fresh',
        role: TeamMemberRole.viewer,
        invitedEmail: 'b@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(30),
      );

      final expired = registry.expireOverdueAt(_t(5));

      expect(expired, ['stale']);
      expect(registry.statusOf('stale'), TeamInvitationStatus.expired);
      expect(registry.statusOf('fresh'), TeamInvitationStatus.pending);

      // Idempotent: a second pass with the same clock changes nothing.
      expect(registry.expireOverdueAt(_t(5)), isEmpty);
    });

    test('an invitation that expired first can no longer be accepted', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'stale',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(1),
      );
      registry.expireOverdueAt(_t(5));

      expect(
        () => registry.accept('stale', acceptedBy: 'a@example.com'),
        throwsStateError,
      );
    });

    test('accepting after the deadline fails even though issue was legal', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(1),
      );
      // Move the clock past the deadline without running the sweep.
      registry.advanceTo(_t(5));

      expect(
        () => registry.accept('inv-1', acceptedBy: 'a@example.com'),
        throwsStateError,
      );
      expect(registry.statusOf('inv-1'), TeamInvitationStatus.pending);
    });

    test('revoking records the real prior status, not revoked to revoked', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.revoke('inv-1', revokedBy: 'owner-1');

      final step = registry.journal.last;
      expect(step.from, TeamInvitationStatus.pending);
      expect(step.to, TeamInvitationStatus.revoked);
    });

    test('revoking an accepted invitation keeps the join in the journal', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.accept('inv-1', acceptedBy: 'a@example.com');
      registry.revoke('inv-1', revokedBy: 'owner-1');

      final reasons = registry.journal.map((step) => step.reason).toList();
      expect(reasons, ['issued', 'accepted', 'revoked']);
      expect(registry.journal.last.from, TeamInvitationStatus.accepted);
      expect(registry.statusOf('inv-1'), TeamInvitationStatus.revoked);
    });

    test('a revoked invitation cannot be accepted afterwards', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.revoke('inv-1', revokedBy: 'owner-1');

      expect(
        () => registry.accept('inv-1', acceptedBy: 'a@example.com'),
        throwsStateError,
      );
    });

    test('an expired invitation cannot be revoked', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'stale',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(1),
      );
      registry.expireOverdueAt(_t(5));

      expect(
        () => registry.revoke('stale', revokedBy: 'owner-1'),
        throwsStateError,
      );
    });

    test('re-inviting the same id is refused so history is not erased', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.revoke('inv-1', revokedBy: 'owner-1');

      expect(
        () => registry.invite(
          invitationId: 'inv-1',
          role: TeamMemberRole.editor,
          invitedEmail: 'a@example.com',
          invitedBy: 'owner-1',
          expiresAt: _t(9),
        ),
        throwsStateError,
      );
      // The revoked record is still the one on file.
      expect(registry.statusOf('inv-1'), TeamInvitationStatus.revoked);
      expect(registry.journal, hasLength(2));
    });

    test('a second owner cannot be invited', () {
      final registry = _registry(now: _t(0));
      expect(
        () => registry.invite(
          invitationId: 'inv-owner',
          role: TeamMemberRole.owner,
          invitedEmail: 'rival@example.com',
          invitedBy: 'owner-1',
          expiresAt: _t(7),
        ),
        throwsStateError,
      );
      expect(registry.statusOf('inv-owner'), isNull);
    });

    test('an invitation that expires before it is issued is refused', () {
      final registry = _registry(now: _t(10));
      expect(
        () => registry.invite(
          invitationId: 'inv-1',
          role: TeamMemberRole.editor,
          invitedEmail: 'a@example.com',
          invitedBy: 'owner-1',
          expiresAt: _t(5),
        ),
        throwsArgumentError,
      );
    });

    test('acting on an unknown invitation fails closed', () {
      final registry = _registry(now: _t(0));
      expect(() => registry.accept('ghost', acceptedBy: 'x'), throwsStateError);
      expect(() => registry.revoke('ghost', revokedBy: 'x'), throwsStateError);
    });

    test('a second live invitation for the same address is refused', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );

      expect(
        () => registry.invite(
          invitationId: 'inv-2',
          role: TeamMemberRole.viewer,
          invitedEmail: 'a@example.com',
          invitedBy: 'owner-1',
          expiresAt: _t(7),
        ),
        throwsStateError,
      );
      expect(registry.statusOf('inv-2'), isNull);
    });

    test(
      'an accepted address cannot be invited again while it is a member',
      () {
        final registry = _registry(now: _t(0));
        registry.invite(
          invitationId: 'inv-1',
          role: TeamMemberRole.editor,
          invitedEmail: 'a@example.com',
          invitedBy: 'owner-1',
          expiresAt: _t(7),
        );
        registry.accept('inv-1', acceptedBy: 'a@example.com');

        expect(
          () => registry.invite(
            invitationId: 'inv-2',
            role: TeamMemberRole.viewer,
            invitedEmail: 'a@example.com',
            invitedBy: 'owner-1',
            expiresAt: _t(7),
          ),
          throwsStateError,
        );
      },
    );

    test('a revoked or expired address may be invited again', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.revoke('inv-1', revokedBy: 'owner-1');

      // The old record is still there, but it is no longer live, so a fresh
      // invitation is legitimate and is recorded as a separate step.
      registry.invite(
        invitationId: 'inv-2',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(9),
      );

      expect(registry.statusOf('inv-1'), TeamInvitationStatus.revoked);
      expect(registry.statusOf('inv-2'), TeamInvitationStatus.pending);
      expect(registry.journal, hasLength(3));
    });
  });

  group('permission health is computed, not supplied', () {
    test('an organization with no members needs review', () {
      final registry = _registry(now: _t(0));
      registry.removeMember('owner-1', removedBy: 'owner-1');

      expect(
        registry.computePermissionHealth(),
        TeamPermissionHealth.reviewRequired,
      );
    });

    test('a live member without an owner is misconfigured', () {
      final registry = _registry(now: _t(0));
      registry.removeMember('owner-1', removedBy: 'owner-1');
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.accept('inv-1', acceptedBy: 'a@example.com');

      expect(
        registry.computePermissionHealth(),
        TeamPermissionHealth.misconfigured,
      );
    });

    test('an organization with an owner is healthy', () {
      final registry = _registry(now: _t(0));

      expect(registry.computePermissionHealth(), TeamPermissionHealth.healthy);
      expect(
        registry.toSummary().permissionHealth,
        TeamPermissionHealth.healthy,
      );
    });

    test('pending invitations do not make a healthy org look broken', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );

      expect(registry.computePermissionHealth(), TeamPermissionHealth.healthy);
    });

    test('the summary counts a pending invitation as an unassigned seat', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.accept('inv-1', acceptedBy: 'a@example.com');
      registry.invite(
        invitationId: 'inv-2',
        role: TeamMemberRole.viewer,
        invitedEmail: 'b@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );

      final summary = registry.toSummary();
      expect(summary.seats.assigned, 2);
      expect(summary.seats.total, 3);
      expect(summary.seats.available, 1);
      expect(summary.pendingInvitations.single.invitationId, 'inv-2');
      expect(summary.memberCountByRole[TeamMemberRole.owner], 1);
      expect(summary.memberCountByRole[TeamMemberRole.editor], 1);
      expect(summary.mostRecentAccess, _t(0));
    });

    test('a removed member stops counting toward assigned seats', () {
      final registry = _registry(now: _t(0));
      registry.invite(
        invitationId: 'inv-1',
        role: TeamMemberRole.editor,
        invitedEmail: 'a@example.com',
        invitedBy: 'owner-1',
        expiresAt: _t(7),
      );
      registry.accept('inv-1', acceptedBy: 'a@example.com');
      expect(registry.toSummary().seats.assigned, 2);

      registry.removeMember('member:inv-1', removedBy: 'owner-1');

      final summary = registry.toSummary();
      expect(summary.seats.assigned, 1);
      expect(summary.members, hasLength(1));
      expect(registry.computePermissionHealth(), TeamPermissionHealth.healthy);
    });

    test('removing an unknown member fails closed', () {
      final registry = _registry(now: _t(0));
      expect(
        () => registry.removeMember('ghost', removedBy: 'owner-1'),
        throwsStateError,
      );
    });

    test('member removal is recorded once, never silently repeated', () {
      final registry = _registry(now: _t(0));
      registry.removeMember('owner-1', removedBy: 'owner-1');
      final length = registry.journal.length;

      registry.removeMember('owner-1', removedBy: 'owner-1');

      expect(registry.journal, hasLength(length));
      expect(registry.journal.last.reason, 'member-removed');
    });
  });
}

DateTime _t(int days) => DateTime.utc(2026, 10, 1).add(Duration(days: days));

TeamInvitationRegistry _registry({required DateTime now}) {
  return TeamInvitationRegistry(
    organizationId: 'org-1',
    ownerMemberId: 'owner-1',
    ownerEmail: 'owner@example.com',
    clock: () => now,
  );
}
