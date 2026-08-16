/// Presence of an avatar in a zone (Step 42.5–42.6).
class Presence {
  Presence({required this.avatarId, required this.zoneId})
      : _lastSeen = DateTime.now();

  final String avatarId;
  String zoneId;
  DateTime _lastSeen;

  DateTime get lastSeen => _lastSeen;

  void moveTo(String newZoneId) {
    zoneId = newZoneId;
    _lastSeen = DateTime.now();
  }
}
