import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_team_collaboration_summary.dart';

void main() {
  group('AccountCenterTeamCollaborationSummary', () {
    test('manifest preserves every canonical 115.30 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_team_collaboration_summary.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.30');
      expect(manifest['acceptance'], <String>[
        'organization',
        'seat_count',
        'member_roles',
        'pending_invites',
        'access_summary',
        'permission_health',
      ]);
    });

    test('summarizes organization seats members roles and pending invites', () {
      final summary = AccountCenterTeamCollaborationSummary(
        organization: const TeamOrganization(id: 'org-1', name: 'Void Studio'),
        seats: TeamSeatSummary(assigned: 2, total: 3),
        members: const [
          TeamMemberSummary(
            memberId: 'member-1',
            displayName: 'Owner',
            role: TeamMemberRole.owner,
            lastAccessedAt: null,
          ),
          TeamMemberSummary(
            memberId: 'member-2',
            displayName: 'Editor',
            role: TeamMemberRole.editor,
            lastAccessedAt: null,
          ),
        ],
        invitations: const [
          TeamInvitationSummary(
            invitationId: 'invite-1',
            role: TeamMemberRole.viewer,
            status: TeamInvitationStatus.pending,
          ),
        ],
        permissionHealth: TeamPermissionHealth.healthy,
      );

      expect(summary.organization.name, 'Void Studio');
      expect(summary.seats.available, 1);
      expect(summary.memberCountByRole, {
        TeamMemberRole.owner: 1,
        TeamMemberRole.editor: 1,
      });
      expect(summary.pendingInvitations, hasLength(1));
    });

    test('reports the most recent access without inventing missing access', () {
      final summary = AccountCenterTeamCollaborationSummary(
        organization: const TeamOrganization(id: 'org-1', name: 'Void Studio'),
        seats: TeamSeatSummary(assigned: 2, total: 2),
        members: [
          TeamMemberSummary(
            memberId: 'member-1',
            displayName: 'Owner',
            role: TeamMemberRole.owner,
            lastAccessedAt: DateTime.utc(2026, 9, 25, 10),
          ),
          TeamMemberSummary(
            memberId: 'member-2',
            displayName: 'Editor',
            role: TeamMemberRole.editor,
            lastAccessedAt: DateTime.utc(2026, 9, 26, 3),
          ),
        ],
        invitations: const [],
        permissionHealth: TeamPermissionHealth.reviewRequired,
      );

      expect(summary.mostRecentAccess, DateTime.utc(2026, 9, 26, 3));
      expect(summary.permissionHealth, TeamPermissionHealth.reviewRequired);

      final neverAccessed = AccountCenterTeamCollaborationSummary(
        organization: const TeamOrganization(id: 'org-2', name: 'Local Team'),
        seats: TeamSeatSummary(assigned: 1, total: 1),
        members: const [
          TeamMemberSummary(
            memberId: 'member-3',
            displayName: 'New Member',
            role: TeamMemberRole.viewer,
            lastAccessedAt: null,
          ),
        ],
        invitations: const [],
        permissionHealth: TeamPermissionHealth.unknown,
      );
      expect(neverAccessed.mostRecentAccess, isNull);
    });

    test('exposes immutable member invitation and role summaries', () {
      final summary = AccountCenterTeamCollaborationSummary(
        organization: const TeamOrganization(id: 'org-1', name: 'Void Studio'),
        seats: TeamSeatSummary(assigned: 1, total: 2),
        members: const [
          TeamMemberSummary(
            memberId: 'member-1',
            displayName: 'Owner',
            role: TeamMemberRole.owner,
            lastAccessedAt: null,
          ),
        ],
        invitations: const [
          TeamInvitationSummary(
            invitationId: 'invite-1',
            role: TeamMemberRole.editor,
            status: TeamInvitationStatus.pending,
          ),
        ],
        permissionHealth: TeamPermissionHealth.healthy,
      );

      expect(
        () => summary.members.add(summary.members.single),
        throwsUnsupportedError,
      );
      expect(() => summary.invitations.clear(), throwsUnsupportedError);
      expect(
        () => summary.memberCountByRole[TeamMemberRole.owner] = 2,
        throwsUnsupportedError,
      );
    });

    test(
      'fails closed for invalid seats duplicate ids and inconsistent totals',
      () {
        expect(
          () => TeamSeatSummary(assigned: 3, total: 2),
          throwsArgumentError,
        );
        expect(
          () => AccountCenterTeamCollaborationSummary(
            organization: const TeamOrganization(
              id: 'org-1',
              name: 'Void Studio',
            ),
            seats: TeamSeatSummary(assigned: 1, total: 3),
            members: const [
              TeamMemberSummary(
                memberId: 'member-1',
                displayName: 'Owner',
                role: TeamMemberRole.owner,
                lastAccessedAt: null,
              ),
              TeamMemberSummary(
                memberId: 'member-1',
                displayName: 'Duplicate',
                role: TeamMemberRole.editor,
                lastAccessedAt: null,
              ),
            ],
            invitations: const [],
            permissionHealth: TeamPermissionHealth.healthy,
          ),
          throwsArgumentError,
        );
        expect(
          () => AccountCenterTeamCollaborationSummary(
            organization: const TeamOrganization(
              id: 'org-1',
              name: 'Void Studio',
            ),
            seats: TeamSeatSummary(assigned: 2, total: 3),
            members: const [
              TeamMemberSummary(
                memberId: 'member-1',
                displayName: 'Owner',
                role: TeamMemberRole.owner,
                lastAccessedAt: null,
              ),
            ],
            invitations: const [],
            permissionHealth: TeamPermissionHealth.healthy,
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
