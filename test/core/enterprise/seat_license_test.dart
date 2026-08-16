import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/license/seat_license.dart';

void main() {
  test('SeatLicense allocates and releases', () {
    final license = SeatLicense(maxSeats: 2);
    expect(license.usedSeats, 0);

    expect(license.allocate(), isTrue);
    expect(license.usedSeats, 1);

    expect(license.allocate(), isTrue);
    expect(license.usedSeats, 2);

    // over capacity
    expect(license.allocate(), isFalse);
    expect(license.usedSeats, 2);
  });

  test('SeatLicense release frees a seat', () {
    final license = SeatLicense(maxSeats: 1);
    expect(license.allocate(), isTrue);
    license.release();
    expect(license.usedSeats, 0);
  });

  test('SeatLicense isAtCapacity', () {
    final license = SeatLicense(maxSeats: 1);
    expect(license.isAtCapacity, isFalse);
    license.allocate();
    expect(license.isAtCapacity, isTrue);
  });
}
