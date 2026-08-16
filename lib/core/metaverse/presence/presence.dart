/// Presence of an avatar in a zone (Step 42.5–42.6).
///
/// [now] disuntikkan agar test deterministik (tidak flaky).
class Presence {
  Presence({
    required this.avatarId,
    required this.zoneId,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        _lastSeen = (now ?? DateTime.now)();

  final String avatarId;
  String zoneId;
  final DateTime Function() _now;
  DateTime _lastSeen;

  DateTime get lastSeen => _lastSeen;

  void moveTo(String newZoneId) {
    zoneId = newZoneId;
    _lastSeen = _now();
  }
}