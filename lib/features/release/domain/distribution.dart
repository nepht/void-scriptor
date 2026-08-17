/// Sprint 49 — Step 49.31–49.43 Patch, Download, Distribution Storage, Library.
class PatchManifest {
  const PatchManifest({
    required this.id,
    required this.releaseId,
    this.files = const [],
  });

  final String id;
  final String releaseId;
  final List<String> files;
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.artifactId,
    required this.totalBytes,
    required this.downloadedBytes,
  });

  final String id;
  final String artifactId;
  final int totalBytes;
  final int downloadedBytes;

  double get progress => totalBytes <= 0 ? 0 : downloadedBytes / totalBytes;

  bool get resumable => downloadedBytes > 0;
}

class ContentHash {
  const ContentHash({
    required this.artifactId,
    required this.algorithm,
    required this.digest,
  });

  final String artifactId;
  final String algorithm;
  final String digest;

  bool matches(String other) => digest == other;
}

/// Step 49.39–49.40 Package Classes, Immutable Artifact Paths.
class DistributionPackage {
  const DistributionPackage({
    required this.id,
    required this.packageClass,
    required this.artifactPath,
  });

  final String id;
  final String packageClass;
  final String artifactPath;
}

/// Step 49.41–49.43 Library, Continue Experience, Cloud Progress.
class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.projectId,
    required this.lastPlayedAt,
    this.progress = 0.0,
  });

  final String id;
  final String projectId;
  final DateTime lastPlayedAt;
  final double progress;
}
