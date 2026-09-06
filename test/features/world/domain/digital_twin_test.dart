import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/digital_twin.dart';

void main() {
  test('digital twin links reality and project identities with revision', () {
    const twin = DigitalTwin(
      realityId: 'scan-1',
      projectEntityId: 'asset-1',
      revision: 2,
      status: TwinSyncStatus.synchronized,
    );

    expect(twin.isValid, isTrue);
    expect(twin.canApplyRevision(3), isTrue);
    expect(twin.canApplyRevision(2), isFalse);
  });

  test('twin revision rejects invalid identity or stale revision', () {
    const twin = DigitalTwin(
      realityId: '',
      projectEntityId: 'asset-1',
      revision: 0,
      status: TwinSyncStatus.pending,
    );

    expect(twin.isValid, isFalse);
    expect(twin.canApplyRevision(0), isFalse);
  });
}
