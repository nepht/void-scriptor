enum TakeState { pending, review, approved, rejected }

/// A single take of a shot (Step 35.10).
class TakeRecord {
  const TakeRecord({
    required this.id,
    required this.shotId,
    required this.takeNumber,
    required this.state,
    this.notes = '',
  });

  final String id;
  final String shotId;
  final int takeNumber;
  final TakeState state;
  final String notes;

  TakeRecord copyWith({TakeState? state, String? notes}) => TakeRecord(
    id: id,
    shotId: shotId,
    takeNumber: takeNumber,
    state: state ?? this.state,
    notes: notes ?? this.notes,
  );
}
