import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/job_triggers.dart';

/// Sprint 104 / 104.13 — job runtime trigger vocabulary over the
/// canonical BackgroundJobStatus values.
void main() {
  test('all four canonical job events exist', () {
    expect(JobRuntimeEvent.values.length, 4);
    expect(
      JobRuntimeEvent.values.map((e) => e.name).toSet(),
      containsAll(['jobSucceeded', 'jobRequiresAttention']),
    );
  });

  test('facts expose job identity and status, never payloads', () {
    final facts = jobFacts(
      JobRuntimeEvent.jobFailed,
      jobId: 'j-7',
      projectId: 'p-1',
    );
    expect(facts['job.event'], 'jobFailed');
    expect(facts['job.id'], 'j-7');
    expect(facts['project.id'], 'p-1');
    expect(facts.length, 3, reason: 'minimal identifier-only shape');
  });
}
