enum TwinSyncStatus { pending, synchronized, conflict }

class DigitalTwin {
  const DigitalTwin({
    required this.realityId,
    required this.projectEntityId,
    required this.revision,
    required this.status,
  });

  final String realityId;
  final String projectEntityId;
  final int revision;
  final TwinSyncStatus status;

  bool get isValid =>
      realityId.trim().isNotEmpty &&
      projectEntityId.trim().isNotEmpty &&
      revision > 0;

  bool canApplyRevision(int candidateRevision) =>
      isValid && candidateRevision > revision;
}
