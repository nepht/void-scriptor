import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_async_job_event_contract.dart';

void main() {
  group('119.11 Async Job & Event Contract', () {
    test('job handles are opaque and reject malformed values', () {
      final id = AsyncJobId.tryParse('jobref:export:primary');
      expect(id, isNotNull);
      expect(id!.value, 'jobref:export:primary');
      expect(id.toString(), '[REDACTED]');
      expect(AsyncJobId.tryParse('raw-job'), isNull);
      expect(AsyncJobId.tryParse('credref:github:primary'), isNull);
    });

    test('progress is normalized into the closed 0..1 interval', () {
      expect(JobProgress(0.5).fraction, 0.5);
      expect(JobProgress(-3).fraction, 0.0);
      expect(JobProgress(4).fraction, 1.0);
      expect(JobProgress(double.nan).fraction, 0.0);
      expect(JobProgress(1).isComplete, isTrue);
      expect(JobProgress(0.9).isComplete, isFalse);
    });

    test('cancel and resume fail closed without reauthentication', () {
      final job = AsyncJob(id: AsyncJobId.tryParse('jobref:export:primary')!);

      expect(
        job.cancel(reauthenticated: false),
        AsyncJobResult.deniedReauthentication,
      );
      expect(job.state, AsyncJobState.queued);
      expect(
        job.resume(reauthenticated: false),
        AsyncJobResult.deniedReauthentication,
      );
      expect(job.state, AsyncJobState.queued);

      expect(job.resume(reauthenticated: true), AsyncJobResult.resumed);
      expect(job.state, AsyncJobState.running);
      expect(job.cancel(reauthenticated: true), AsyncJobResult.cancelled);
      expect(job.state, AsyncJobState.cancelled);
    });

    test('in-flight state is not durable while settled states are', () {
      expect(DurableJobState.isDurable(AsyncJobState.running), isFalse);
      expect(DurableJobState.isDurable(AsyncJobState.queued), isTrue);
      expect(DurableJobState.isDurable(AsyncJobState.paused), isTrue);
      expect(DurableJobState.isDurable(AsyncJobState.completed), isTrue);
      expect(DurableJobState.isDurable(AsyncJobState.cancelled), isTrue);
      expect(DurableJobState.isDurable(AsyncJobState.failed), isTrue);
    });

    test('durable snapshots expose no plaintext job payload', () {
      final job = AsyncJob(id: AsyncJobId.tryParse('jobref:export:primary')!);
      job.record(
        AsyncJobEvent(
          kind: AsyncJobEventKind.progress,
          sequence: 1,
          idempotencyKey: 'idem-0001',
          progress: 0.5,
        ),
      );

      final snapshot = job.toDurableSnapshot();
      expect(snapshot['job_id'], '[REDACTED]');
      expect(snapshot['state'], 'queued');
      expect(snapshot['progress'], 0.5);
      expect(snapshot['last_sequence'], 1);
      expect(snapshot.toString(), isNot(contains('jobref:export:primary')));
    });

    test('events must arrive in strictly increasing sequence order', () {
      final job = AsyncJob(id: AsyncJobId.tryParse('jobref:export:primary')!);

      expect(
        job.record(
          AsyncJobEvent(
            kind: AsyncJobEventKind.queued,
            sequence: 5,
            idempotencyKey: 'idem-0001',
          ),
        ),
        isTrue,
      );
      expect(
        job.record(
          AsyncJobEvent(
            kind: AsyncJobEventKind.progress,
            sequence: 4,
            idempotencyKey: 'idem-0002',
          ),
        ),
        isFalse,
      );
      expect(job.events.length, 1);
      expect(job.events.single.sequence, 5);
    });

    test('duplicate events are rejected by idempotency key', () {
      final job = AsyncJob(id: AsyncJobId.tryParse('jobref:export:primary')!);
      final event = AsyncJobEvent(
        kind: AsyncJobEventKind.progress,
        sequence: 1,
        idempotencyKey: 'idem-0001',
        progress: 0.25,
      );

      expect(job.record(event), isTrue);
      expect(
        job.record(
          AsyncJobEvent(
            kind: AsyncJobEventKind.progress,
            sequence: 2,
            idempotencyKey: 'idem-0001',
            progress: 0.75,
          ),
        ),
        isFalse,
      );
      expect(job.events.length, 1);
      expect(job.progress.fraction, 0.25);
    });

    test('event serialization redacts the idempotency key', () {
      final event = AsyncJobEvent(
        kind: AsyncJobEventKind.progress,
        sequence: 2,
        idempotencyKey: 'idem-secret-0001',
        progress: 0.5,
      );

      final json = event.toRedactedJson();
      expect(json, contains('"sequence":2'));
      expect(json, contains('"idempotency_key":"[REDACTED]"'));
      expect(json, isNot(contains('idem-secret-0001')));
    });

    test('validates the canonical manifest and rejects missing acceptance', () {
      expect(AsyncJobEventContract.validateCanonicalManifest(), isEmpty);
      final missing = <String, dynamic>{
        'canonical_step': '119.11',
        'unknown_field_policy': 'REJECT',
        'acceptance': <String, dynamic>{},
      };
      expect(
        AsyncJobEventContract.validateManifest(missing),
        containsAll(<String>[
          'acceptance_missing:job_id',
          'acceptance_missing:event_order',
          'acceptance_missing:deduplication',
        ]),
      );
      expect(
        AsyncJobEventContract.validateManifest(<String, dynamic>{
          'canonical_step': '119.10',
          'unknown_field_policy': 'ALLOW',
          'acceptance': <String, dynamic>{},
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
        ]),
      );
    });
  });
}
