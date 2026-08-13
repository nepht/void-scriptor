import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/generation_queue.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';

void main() {
  test('queue runs jobs in priority order with bounded concurrency', () async {
    final completed = <String>[];
    final queue = GenerationQueue(
      maxConcurrentJobs: 1,
      executor: (job) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        completed.add(job.id);
      },
    );
    queue.enqueue(_job('low', GenerationPriority.low));
    queue.enqueue(_job('high', GenerationPriority.high));
    await queue.drain();
    expect(completed, ['high', 'low']);
  });

  test(
    'retry policy retries transient errors but not invalid requests',
    () async {
      const policy = RetryPolicy(maxAttempts: 3);
      expect(policy.shouldRetry(AiErrorType.network, 1), isTrue);
      expect(policy.shouldRetry(AiErrorType.timeout, 2), isTrue);
      expect(policy.shouldRetry(AiErrorType.invalidRequest, 1), isFalse);
      expect(policy.shouldRetry(AiErrorType.authentication, 1), isFalse);
    },
  );

  test('cancel marks queued job cancelled and prevents execution', () async {
    var executed = false;
    final queue = GenerationQueue(executor: (_) async => executed = true);
    final job = _job('cancelled', GenerationPriority.normal);
    queue.enqueue(job);
    expect(queue.cancel(job.id), isTrue);
    await queue.drain();
    expect(executed, isFalse);
    expect(queue.statusOf(job.id), GenerationJobStatus.cancelled);
  });

  test('failed job can be retried through the same queue', () async {
    var attempts = 0;
    final queue = GenerationQueue(
      executor: (_) async {
        attempts++;
        if (attempts == 1) throw StateError('transient');
      },
    );
    final job = _job('retry', GenerationPriority.normal);
    queue.enqueue(job);
    await queue.drain();
    expect(queue.statusOf(job.id), GenerationJobStatus.failed);
    expect(queue.retry(job.id), isTrue);
    await queue.drain();
    expect(queue.statusOf(job.id), GenerationJobStatus.completed);
    expect(attempts, 2);
  });
}

GenerationJob _job(String id, GenerationPriority priority) => GenerationJob(
  id: id,
  projectId: 'project',
  providerId: 'mock',
  promptHistoryId: 'history',
  status: GenerationJobStatus.queued,
  createdAt: DateTime.utc(2026),
  priority: priority,
);
