import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/studio/studio.dart';
import 'package:void_scriptor/core/enterprise/role/studio_role.dart';
import 'package:void_scriptor/core/enterprise/member/team_member.dart';
import 'package:void_scriptor/core/enterprise/license/seat_license.dart';
import 'package:void_scriptor/core/enterprise/registry/studio_registry.dart';

void main() {
  test('StudioRegistry adds members with seat enforcement', () {
    final registry = StudioRegistry(
      studio: const Studio(id: 'st1', name: 'Void Studio', plan: 'enterprise'),
      seats: SeatLicense(maxSeats: 2),
    );

    expect(registry.addMember(userId: 'u1', role: StudioRole.member), isTrue);
    expect(registry.addMember(userId: 'u2', role: StudioRole.viewer), isTrue);
    // capacity reached
    expect(registry.addMember(userId: 'u3', role: StudioRole.viewer), isFalse);

    expect(registry.members, hasLength(2));
  });

  test('StudioRegistry audit logs membership changes', () {
    final registry = StudioRegistry(
      studio: const Studio(id: 'st1', name: 'Void Studio', plan: 'enterprise'),
      seats: SeatLicense(maxSeats: 5),
    );
    registry.addMember(userId: 'u1', role: StudioRole.member);
    expect(registry.audit.byAction('add-member'), hasLength(1));
  });
}
