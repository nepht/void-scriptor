enum CanonConflictSeverity { info, warning, error, critical }

class CanonConflict {
  const CanonConflict({
    required this.id,
    required this.projectId,
    required this.ruleId,
    required this.targetId,
    required this.message,
    required this.severity,
    this.resolved = false,
    this.resolutionNote = '',
  });

  final String id;
  final String projectId;
  final String ruleId;
  final String targetId;
  final String message;
  final CanonConflictSeverity severity;
  final bool resolved;
  final String resolutionNote;
}
