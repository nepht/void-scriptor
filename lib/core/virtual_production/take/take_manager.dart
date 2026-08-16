import 'take_record.dart';

/// Manages takes per shot (Step 35.11–35.12).
class TakeManager {
  final List<TakeRecord> _takes = [];

  void record(TakeRecord take) => _takes.add(take);

  TakeRecord? latestFor(String shotId) {
    TakeRecord? latest;
    for (final take in _takes) {
      if (take.shotId == shotId) {
        if (latest == null || take.takeNumber > latest.takeNumber) {
          latest = take;
        }
      }
    }
    return latest;
  }

  void approve(String takeId) => _update(takeId, TakeState.approved);

  void reject(String takeId) => _update(takeId, TakeState.rejected);

  void _update(String takeId, TakeState state) {
    for (var i = 0; i < _takes.length; i++) {
      if (_takes[i].id == takeId) {
        _takes[i] = _takes[i].copyWith(state: state);
      }
    }
  }
}
