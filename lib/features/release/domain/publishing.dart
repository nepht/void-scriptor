/// Sprint 49 — Step 49.69–49.86 Publishing Pipeline, Provenance, Approval Gate.
enum ReviewStatus { pending, inReview, changesRequested, approved, rejected }

class PublishingReview {
  const PublishingReview({
    required this.id,
    required this.releaseId,
    required this.status,
    this.reviewerId,
  });

  final String id;
  final String releaseId;
  final ReviewStatus status;
  final String? reviewerId;
}

class ModerationAction {
  const ModerationAction({
    required this.id,
    required this.releaseId,
    required this.type,
    this.note,
  });

  final String id;
  final String releaseId;
  final String type;
  final String? note;
}

class ReleaseProvenance {
  const ReleaseProvenance({
    required this.id,
    required this.releaseId,
    required this.builtAt,
    required this.toolchain,
    this.signerId,
  });

  final String id;
  final String releaseId;
  final DateTime builtAt;
  final String toolchain;
  final String? signerId;
}

class ReleaseSchedule {
  const ReleaseSchedule({
    required this.id,
    required this.releaseId,
    required this.scheduledAt,
    this.premiere = false,
  });

  final String id;
  final String releaseId;
  final DateTime scheduledAt;
  final bool premiere;
}

class PublishingAgent {
  const PublishingAgent({required this.id, required this.autoApprove});

  final String id;
  final bool autoApprove;

  bool get canPublishAutonomously => autoApprove;
}

/// Step 49.74–49.75 Artifact Signing, Release Secrets.
class ArtifactSignature {
  const ArtifactSignature({
    required this.id,
    required this.artifactId,
    required this.signerId,
    required this.signature,
  });

  final String id;
  final String artifactId;
  final String signerId;
  final String signature;
}
