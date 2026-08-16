import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/role/studio_role.dart';
import 'package:void_scriptor/core/enterprise/role/permission.dart';
import 'package:void_scriptor/core/enterprise/member/team_member.dart';

void main() {
  test('TeamMember holds identity and role', () {
    final member = TeamMember(
      userId: 'u1',
      role: StudioRole.member,
      status: MemberStatus.active,
    );
    expect(member.userId, 'u1');
    expect(member.role, StudioRole.member);
    expect(member.status, MemberStatus.active);
  });

  test('MemberStatus enum values', () {
    expect(MemberStatus.values, hasLength(3));
    expect(MemberStatus.invited.name, 'invited');
  });

  test('TeamMember.can delegates to role', () {
    final member = TeamMember(
      userId: 'u1',
      role: StudioRole.member,
      status: MemberStatus.active,
    );
    expect(member.can(Permission.editContent), isTrue);
    expect(member.can(Permission.manageBilling), isFalse);
  });
}
