enum AutopilotMode { dryRun, supervised, active }

class AutopilotControl {
  AutopilotMode mode = AutopilotMode.dryRun;
  bool isRunning = false;
  void start() => isRunning = true;
  void pause() => isRunning = false;
  bool canExecute(String command) =>
      isRunning && mode != AutopilotMode.dryRun && command != 'delete';
}

enum ApprovalStatus { pending, approved, rejected }

class ApprovalGate {
  ApprovalGate({
    required this.id,
    required this.action,
    required this.important,
  }) : status = ApprovalStatus.pending;
  final String id;
  final String action;
  final bool important;
  ApprovalStatus status;
}

class ToolPermission {
  const ToolPermission(this.readAllowed);
  final bool readAllowed;
  bool allows(String action) => action == 'read' && readAllowed;
}

class GovernancePolicy {
  final Map<String, ApprovalGate> _gates = {};
  final Map<String, ToolPermission> _permissions = {
    'temporary-tool': const ToolPermission(true),
  };
  int _nextId = 0;

  ApprovalGate request(String action, {required bool important}) {
    final gate = ApprovalGate(
      id: 'approval-${_nextId++}',
      action: action,
      important: important,
    );
    _gates[gate.id] = gate;
    return gate;
  }

  void approve(String id) => _gates[id]?.status = ApprovalStatus.approved;
  bool execute(String id) => _gates[id]?.status == ApprovalStatus.approved;
  ToolPermission permission(String id) =>
      _permissions[id] ?? const ToolPermission(false);
}
