import '../role/studio_role.dart';
import '../role/permission.dart';

enum MemberStatus { invited, active, suspended }

/// A studio team member (Step 37.4–37.6).
class TeamMember {
  const TeamMember({
    required this.userId,
    required this.role,
    required this.status,
  });

  final String userId;
  final StudioRole role;
  final MemberStatus status;

  bool can(Permission permission) => role.can(permission);
}
