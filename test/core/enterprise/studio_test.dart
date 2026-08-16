import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/studio/studio.dart';
import 'package:void_scriptor/core/enterprise/role/studio_role.dart';
import 'package:void_scriptor/core/enterprise/role/permission.dart';

void main() {
  test('Studio holds identity', () {
    const studio = Studio(id: 'st1', name: 'Void Studio', plan: 'enterprise');
    expect(studio.name, 'Void Studio');
    expect(studio.plan, 'enterprise');
  });

  test('StudioRole permission matrix', () {
    expect(StudioRole.admin.can(Permission.manageMembers), isTrue);
    expect(StudioRole.admin.can(Permission.manageBilling), isTrue);
    expect(StudioRole.member.can(Permission.manageMembers), isFalse);
    expect(StudioRole.member.can(Permission.editContent), isTrue);
    expect(StudioRole.viewer.can(Permission.editContent), isFalse);
    expect(StudioRole.viewer.can(Permission.viewContent), isTrue);
  });

  test('Permission enum values', () {
    expect(Permission.values, hasLength(6));
  });
}
