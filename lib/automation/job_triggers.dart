/// Sprint 104 / 104.13 — job runtime trigger vocabulary over the
/// canonical BackgroundJobStatus stream. Facts are minimal and
/// identifier-only.
library;

enum JobRuntimeEvent {
  jobSucceeded,
  jobFailed,
  jobCancelled,
  jobRequiresAttention,
}

Map<String, Object> jobFacts(
  JobRuntimeEvent event, {
  required String jobId,
  required String projectId,
}) => {'job.event': event.name, 'job.id': jobId, 'project.id': projectId};
