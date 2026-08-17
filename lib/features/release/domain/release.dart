/// Sprint 49 — Step 49.1–49.7 Release Entity, Status, Versioning, Notes, Snapshot.
enum ReleaseStatus { draft, validating, ready, published, archived, failed }

class Release {
  const Release({
    required this.id,
    required this.projectId,
    required this.version,
    required this.status,
    this.releaseNotes,
    this.snapshotId,
    this.publishedAt,
  });

  final String id;
  final String projectId;
  final String version;
  final ReleaseStatus status;
  final String? releaseNotes;
  final String? snapshotId;
  final DateTime? publishedAt;

  /// Compare semantic versions (major.minor.patch). Returns -1/0/1.
  int compareSemverTo(Release other) {
    final partsA = _parseVersion(version);
    final partsB = _parseVersion(other.version);
    for (var i = 0; i < 3; i++) {
      if (partsA[i] != partsB[i]) return partsA[i].compareTo(partsB[i]);
    }
    return 0;
  }

  List<int> _parseVersion(String v) {
    final cleaned = v.split('-').first;
    final parts = cleaned.split('.');
    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }
}

class ReleaseNotes {
  const ReleaseNotes({
    required this.id,
    required this.releaseId,
    required this.changes,
    this.breaking = const [],
  });

  final String id;
  final String releaseId;
  final List<String> changes;
  final List<String> breaking;
}

class ReleaseSnapshot {
  const ReleaseSnapshot({
    required this.id,
    required this.releaseId,
    required this.contentHash,
    required this.createdAt,
  });

  final String id;
  final String releaseId;
  final String contentHash;
  final DateTime createdAt;
}
