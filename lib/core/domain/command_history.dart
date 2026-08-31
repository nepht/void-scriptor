/// Core-owned command history value types (ADR-0001).
///
/// Moved from
/// `features/project_resilience/application/command_history_repository.dart`
/// so the Core command registry does not depend on the Project Resilience
/// feature. The Drift-backed repository remains feature-owned and re-exposes
/// these types through its file.
enum CommandHistoryStatus { applied, undone, abandoned }

class CommandHistoryRecord {
  const CommandHistoryRecord({
    required this.id,
    required this.projectId,
    required this.commandType,
    required this.label,
    required this.payload,
    required this.undoPayload,
    required this.sequence,
    required this.source,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String commandType;
  final String label;
  final Map<String, dynamic> payload;
  final Map<String, dynamic>? undoPayload;
  final int sequence;
  final String source;
  final CommandHistoryStatus status;
  final DateTime createdAt;
}
