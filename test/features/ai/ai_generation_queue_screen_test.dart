import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_queue_screen.dart';

void main() {
  testWidgets('queue screen exposes live run cancel and retry actions', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AiGenerationQueueScreen(
            jobs: [
              _job('queued', GenerationJobStatus.queued),
              _job('failed', GenerationJobStatus.failed),
            ],
            onRunQueue: () async => actions.add('run'),
            onCancel: (id) async => actions.add('cancel:$id'),
            onRetry: (id) async => actions.add('retry:$id'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Run Queue'));
    await tester.tap(find.byTooltip('Cancel queued'));
    await tester.tap(find.byTooltip('Retry failed'));
    await tester.pump();

    expect(actions, ['run', 'cancel:queued', 'retry:failed']);
  });
}

GenerationJob _job(String id, GenerationJobStatus status) => GenerationJob(
  id: id,
  projectId: 'p1',
  providerId: 'mock',
  promptHistoryId: 'history',
  status: status,
  error: status == GenerationJobStatus.failed ? 'failed safely' : null,
  createdAt: DateTime.utc(2026),
);
