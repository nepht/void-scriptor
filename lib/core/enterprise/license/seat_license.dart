/// Seat allocation with over-capacity guard (Step 37.7–37.9).
class SeatLicense {
  SeatLicense({required this.maxSeats});

  final int maxSeats;
  int _usedSeats = 0;

  int get usedSeats => _usedSeats;

  bool get isAtCapacity => _usedSeats >= maxSeats;

  bool allocate() {
    if (isAtCapacity) return false;
    _usedSeats++;
    return true;
  }

  void release() {
    if (_usedSeats > 0) _usedSeats--;
  }
}
