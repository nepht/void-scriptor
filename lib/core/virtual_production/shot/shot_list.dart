import 'shot.dart';

/// Ordered shot list (Step 35.3).
class ShotList {
  final List<Shot> _shots = [];

  List<Shot> get shots => List.unmodifiable(_shots);

  void add(Shot shot) => _shots.add(shot);

  Shot? find(String id) {
    for (final shot in _shots) {
      if (shot.id == id) return shot;
    }
    return null;
  }

  double get totalDuration =>
      _shots.fold(0.0, (sum, shot) => sum + shot.durationSeconds);
}
