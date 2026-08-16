import '../studio/studio.dart';
import '../role/studio_role.dart';
import '../member/team_member.dart';
import '../license/seat_license.dart';
import '../audit/audit_log.dart';

/// Studio registry: org + members + audit + seats (Step 37.13–37.14).
class StudioRegistry {
  StudioRegistry({required this.studio, required this.seats, AuditLog? audit})
    : audit = audit ?? AuditLog(capacity: 200);

  final Studio studio;
  final SeatLicense seats;
  final AuditLog audit;
  final List<TeamMember> _members = [];

  List<TeamMember> get members => List.unmodifiable(_members);

  bool addMember({required String userId, required StudioRole role}) {
    if (!seats.allocate()) return false;
    _members.add(
      TeamMember(userId: userId, role: role, status: MemberStatus.active),
    );
    audit.append(actor: 'system', action: 'add-member', target: userId);
    return true;
  }

  bool removeMember(String userId) {
    final index = _members.indexWhere((m) => m.userId == userId);
    if (index < 0) return false;
    _members.removeAt(index);
    seats.release();
    audit.append(actor: 'system', action: 'remove-member', target: userId);
    return true;
  }
}
