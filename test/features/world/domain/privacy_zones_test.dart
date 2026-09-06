import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/privacy_zones.dart';

void main() {
  test('privacy zone denies capture inside sensitive bounds', () {
    const zone = PrivacyZone(
      id: 'home',
      minX: 0,
      maxX: 10,
      minY: 0,
      maxY: 10,
      sensitivity: PrivacySensitivity.restricted,
    );

    expect(zone.contains(5, 5), isTrue);
    expect(zone.contains(11, 5), isFalse);
    expect(zone.allowsCaptureAt(5, 5), isFalse);
    expect(zone.allowsCaptureAt(11, 5), isTrue);
  });

  test('privacy policy defaults to deny when zones overlap', () {
    const policy = PrivacyPolicy(
      zones: [
        PrivacyZone(
          id: 'restricted',
          minX: -1,
          maxX: 1,
          minY: -1,
          maxY: 1,
          sensitivity: PrivacySensitivity.restricted,
        ),
      ],
    );

    expect(policy.allowsCaptureAt(0, 0), isFalse);
    expect(policy.allowsCaptureAt(4, 4), isTrue);
  });
}
