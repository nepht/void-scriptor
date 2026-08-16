import '../studio/studio.dart';
import '../role/studio_role.dart';
import '../license/seat_license.dart';
import '../registry/studio_registry.dart';

/// Built-in demo studio setup (Step 37.20).
class DemoStudio {
  DemoStudio._();

  static final StudioRegistry registry =
      StudioRegistry(
          studio: const Studio(
            id: 'st-demo',
            name: 'Void Studio',
            plan: 'enterprise',
          ),
          seats: SeatLicense(maxSeats: 10),
        )
        ..addMember(userId: 'alice', role: StudioRole.admin)
        ..addMember(userId: 'bob', role: StudioRole.member)
        ..addMember(userId: 'carol', role: StudioRole.viewer);
}
