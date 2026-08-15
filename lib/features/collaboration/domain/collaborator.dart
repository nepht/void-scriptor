enum CollaboratorRole {
  owner,
  editor,
  viewer;

  bool get canEdit => this == owner || this == editor;
}

class Collaborator {
  const Collaborator({
    required this.projectId,
    required this.userId,
    required this.role,
    required this.invitedAt,
    this.acceptedAt,
  });

  final String projectId;
  final String userId;
  final CollaboratorRole role;
  final DateTime invitedAt;
  final DateTime? acceptedAt;
}

class ProjectComment {
  const ProjectComment({
    required this.id,
    required this.projectId,
    required this.authorId,
    required this.targetType,
    required this.targetId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String authorId;
  final String targetType;
  final String targetId;
  final String body;
  final DateTime createdAt;
}
