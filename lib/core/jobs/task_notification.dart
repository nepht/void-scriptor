/// Task Center notification (Step 26.96).
///
/// A small, non-modal notice for when a background task finishes while the
/// user is in a different workspace. Only modal when a user decision is
/// actually required.
enum TaskNotificationKind { completed, failed, needsDecision }

class TaskNotification {
  const TaskNotification({
    required this.title,
    required this.message,
    this.kind = TaskNotificationKind.completed,
  });

  final String title;
  final String message;
  final TaskNotificationKind kind;

  bool get isModal => kind == TaskNotificationKind.needsDecision;
}
