class AudioImportResult {
  const AudioImportResult({
    required this.audioFileId,
    required this.projectRelativePath,
    required this.contentHash,
    required this.waveformCacheId,
  });
  final String audioFileId, projectRelativePath, contentHash, waveformCacheId;
}

class AudioHealthResult {
  const AudioHealthResult({
    required this.audioFileId,
    required this.exists,
    required this.hashMatches,
  });
  final String audioFileId;
  final bool exists, hashMatches;
  bool get healthy => exists && hashMatches;
}
