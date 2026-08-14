import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../application/ai_generation_runtime.dart';
import '../domain/generation_job.dart';

final aiGenerationRuntimeProvider =
    FutureProvider.autoDispose<AiGenerationRuntime?>((ref) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;
      final runtime = await AiGenerationRuntime.open(
        database: session.database,
        package: session.package,
      );
      ref.onDispose(runtime.dispose);
      return runtime;
    });

class AiGenerationQueueScreen extends ConsumerWidget {
  const AiGenerationQueueScreen({
    super.key,
    this.jobs,
    this.onCancel,
    this.onRetry,
    this.onRunQueue,
  });

  final List<GenerationJob>? jobs;
  final Future<void> Function(String jobId)? onCancel;
  final Future<void> Function(String jobId)? onRetry;
  final Future<void> Function()? onRunQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobs != null) {
      return _QueueScaffold(
        jobs: jobs!,
        onCancel: onCancel,
        onRetry: onRetry,
        onRunQueue: onRunQueue,
      );
    }
    final runtime = ref.watch(aiGenerationRuntimeProvider);
    return runtime.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('AI QUEUE')),
        body: Center(child: Text('Queue error: $error')),
      ),
      data: (runtime) {
        if (runtime == null) {
          return const Scaffold(
            body: Center(child: Text('Open a project to view its AI queue.')),
          );
        }
        return StreamBuilder<List<GenerationJob>>(
          stream: runtime.watchJobs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('AI QUEUE')),
                body: Center(child: Text('Queue error: ${snapshot.error}')),
              );
            }
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _QueueScaffold(
              jobs: snapshot.data!,
              onCancel: (id) async {
                await runtime.cancel(id);
              },
              onRetry: (id) async {
                if (await runtime.retry(id)) await runtime.runQueue();
              },
              onRunQueue: runtime.runQueue,
            );
          },
        );
      },
    );
  }
}

class _QueueScaffold extends StatelessWidget {
  const _QueueScaffold({
    required this.jobs,
    this.onCancel,
    this.onRetry,
    this.onRunQueue,
  });

  final List<GenerationJob> jobs;
  final Future<void> Function(String jobId)? onCancel;
  final Future<void> Function(String jobId)? onRetry;
  final Future<void> Function()? onRunQueue;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('AI QUEUE'),
      actions: [
        if (onRunQueue != null)
          TextButton.icon(
            onPressed: () => onRunQueue!(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Run Queue'),
          ),
      ],
    ),
    body: jobs.isEmpty
        ? const Center(child: Text('No generation jobs yet.'))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: jobs.length,
            itemBuilder: (_, index) {
              final job = jobs[index];
              return Card(
                child: ListTile(
                  title: Text(job.id),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${job.providerId} • ${job.status.name}'),
                      if (job.error != null)
                        Text(
                          job.error!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: _JobAction(
                    job: job,
                    onCancel: onCancel,
                    onRetry: onRetry,
                  ),
                ),
              );
            },
          ),
  );
}

class _JobAction extends StatelessWidget {
  const _JobAction({required this.job, this.onCancel, this.onRetry});

  final GenerationJob job;
  final Future<void> Function(String jobId)? onCancel;
  final Future<void> Function(String jobId)? onRetry;

  @override
  Widget build(BuildContext context) {
    if (job.status == GenerationJobStatus.running) {
      return SizedBox(
        width: 150,
        child: Row(
          children: [
            Expanded(child: LinearProgressIndicator(value: job.progress)),
            if (onCancel != null)
              IconButton(
                tooltip: 'Cancel ${job.id}',
                onPressed: () => onCancel!(job.id),
                icon: const Icon(Icons.stop_circle_outlined),
              ),
          ],
        ),
      );
    }
    if (job.status == GenerationJobStatus.queued && onCancel != null) {
      return IconButton(
        tooltip: 'Cancel ${job.id}',
        onPressed: () => onCancel!(job.id),
        icon: const Icon(Icons.cancel_outlined),
      );
    }
    if (job.status == GenerationJobStatus.failed && onRetry != null) {
      return IconButton(
        tooltip: 'Retry ${job.id}',
        onPressed: () => onRetry!(job.id),
        icon: const Icon(Icons.refresh_rounded),
      );
    }
    return Text(job.status.name);
  }
}
