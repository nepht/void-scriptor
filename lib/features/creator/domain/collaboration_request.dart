/// Sprint 43 — Step 43.26 Collaboration Request.
enum CollaborationRequestStatus { pending, active, declined, cancelled }

class CollaborationRequest {
  const CollaborationRequest({
    required this.id,
    required this.fromCreatorId,
    required this.toCreatorId,
    required this.projectId,
    required this.role,
    this.status = CollaborationRequestStatus.pending,
    this.acceptedAt,
  });

  final String id;
  final String fromCreatorId;
  final String toCreatorId;
  final String projectId;
  final String role;
  final CollaborationRequestStatus status;
  final DateTime? acceptedAt;

  CollaborationRequest accept() => CollaborationRequest(
    id: id,
    fromCreatorId: fromCreatorId,
    toCreatorId: toCreatorId,
    projectId: projectId,
    role: role,
    status: CollaborationRequestStatus.active,
    acceptedAt: DateTime.now(),
  );

  CollaborationRequest decline() => CollaborationRequest(
    id: id,
    fromCreatorId: fromCreatorId,
    toCreatorId: toCreatorId,
    projectId: projectId,
    role: role,
    status: CollaborationRequestStatus.declined,
    acceptedAt: acceptedAt,
  );
}
