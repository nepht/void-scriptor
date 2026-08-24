/// Sprint 104 / 104.11 — project lifecycle trigger vocabulary. Five
/// canonical events with identifier-only fact payloads (names are
/// metadata and allowed; diagnostics payloads never travel here).
library;

enum ProjectLifecycleEvent {
  projectOpened,
  projectSaved,
  projectClosed,
  recoveryCompleted,
  healthIssueDetected,
}

Map<String, Object> lifecycleFacts(
  ProjectLifecycleEvent event, {
  required String projectId,
  String? projectName,
  String? severity,
}) {
  final facts = <String, Object>{
    'project.event': event.name,
    'project.id': projectId,
  };
  final name = projectName;
  if (name != null && name.isNotEmpty) facts['project.name'] = name;
  final sev = severity;
  if (sev != null && sev.isNotEmpty) facts['severity'] = sev;
  return facts;
}
