import '../domain/presence.dart';

/// In-memory presence tracker for active collaborators (Step 29.13).
class PresenceTracker {
  final _presence = <String, PresenceEntry>{};

  void set(String projectId, String userId, PresenceState state) {
    _presence['$projectId:$userId'] = PresenceEntry(
      projectId: projectId,
      userId: userId,
      state: state,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  List<PresenceEntry> forProject(String projectId) {
    return _presence.values
        .where((entry) => entry.projectId == projectId)
        .toList();
  }
}
