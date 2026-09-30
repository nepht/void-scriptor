import '../studio/studio.dart';
import '../role/studio_role.dart';
import '../role/permission.dart';
import '../member/team_member.dart';
import '../license/seat_license.dart';
import '../audit/audit_log.dart';

/// Studio registry: org + members + audit + seats (Step 37.13–37.14).
class StudioRegistry {
  StudioRegistry({
    required this.studio,
    required this.seats,
    AuditLog? audit,
    Future<bool> Function()? reauthenticate,
  }) : audit = audit ?? AuditLog(capacity: 200),
       // Fail closed. A sensitive action with nobody to ask is a sensitive
       // action that does not happen.
       _reauthenticate = reauthenticate ?? _refuseReauthentication;

  final Studio studio;
  final SeatLicense seats;
  final AuditLog audit;
  final Future<bool> Function() _reauthenticate;
  final List<TeamMember> _members = [];

  static Future<bool> _refuseReauthentication() async => false;

  List<TeamMember> get members => List.unmodifiable(_members);

  bool addMember({required String userId, required StudioRole role}) {
    final normalized = userId.trim();
    // One person occupies one seat. A repeated add would spend a second seat
    // on the same member and make the roster disagree with the seat count.
    if (normalized.isEmpty ||
        _members.any((member) => member.userId == normalized) ||
        !seats.allocate()) {
      audit.append(
        actor: 'system',
        action: 'denied_add_member',
        target: normalized.isEmpty ? userId : normalized,
      );
      return false;
    }
    _members.add(
      TeamMember(userId: normalized, role: role, status: MemberStatus.active),
    );
    audit.append(actor: 'system', action: 'add-member', target: normalized);
    return true;
  }

  /// Removes [userId] from the organization.
  ///
  /// The product spec lists `remove_team_member` among its sensitive actions
  /// and declares `reauth_before_sensitive_action` and `audit_redaction` for
  /// it, so this is a gated, attributed, audited action rather than a bare
  /// list operation. Every refusal is recorded as `denied_remove_member`, so
  /// an attempt the gate turned down stays distinguishable from an attempt
  /// nobody made.
  Future<bool> removeMember(
    String userId, {
    required String actor,
    Future<bool> Function()? reauthenticate,
  }) async {
    final normalized = userId.trim();
    final requester = _requester(actor);
    final index = _members.indexWhere((member) => member.userId == normalized);
    final administratorCount = _members
        .where((member) => member.role == StudioRole.admin)
        .length;
    // Removing the last administrator would leave the organization with
    // nobody who can manage members, manage billing, or remove anybody.
    final wouldOrphanTheOrganization =
        index >= 0 &&
        _members[index].role == StudioRole.admin &&
        administratorCount == 1;

    if (requester == null ||
        !requester.can(Permission.manageMembers) ||
        index < 0 ||
        wouldOrphanTheOrganization ||
        !(await (reauthenticate ?? _reauthenticate)())) {
      audit.append(
        actor: actor.trim().isEmpty ? actor : actor.trim(),
        action: 'denied_remove_member',
        target: normalized.isEmpty ? userId : normalized,
      );
      return false;
    }

    _members.removeAt(index);
    seats.release();
    audit.append(
      actor: actor.trim().isEmpty ? actor : actor.trim(),
      action: 'remove-member',
      target: normalized,
    );
    return true;
  }

  /// The member [actor] names, or null when the actor is not on the roster.
  TeamMember? _requester(String actor) {
    final normalized = actor.trim();
    for (final member in _members) {
      if (member.userId == normalized) return member;
    }
    return null;
  }
}
