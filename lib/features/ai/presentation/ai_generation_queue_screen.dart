import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../application/ai_generation_runtime.dart';
import '../domain/generation_job.dart';
import '../domain/prompt_target.dart';

typedef AiPromptSubmission =
    Future<void> Function({required String prompt, required String providerId});

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
    this.mediaTarget = PromptTarget.image,
    this.imageProviderIds = const ['openai', 'comfyui'],
    this.videoProviderIds = const [],
    this.onSubmitImage,
    this.onSubmitVideo,
  });

  final List<GenerationJob>? jobs;
  final Future<void> Function(String jobId)? onCancel;
  final Future<void> Function(String jobId)? onRetry;
  final Future<void> Function()? onRunQueue;
  final PromptTarget mediaTarget;
  final List<String> imageProviderIds;
  final List<String> videoProviderIds;
  final AiPromptSubmission? onSubmitImage;
  final AiPromptSubmission? onSubmitVideo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerIds = mediaTarget == PromptTarget.video
        ? videoProviderIds
        : imageProviderIds;
    final suppliedSubmit = mediaTarget == PromptTarget.video
        ? onSubmitVideo
        : onSubmitImage;
    final screenTitle = mediaTarget == PromptTarget.video
        ? 'Video Generator'
        : 'Image Generator';
    if (jobs != null) {
      return _QueueScaffold(
        jobs: jobs!,
        onCancel: onCancel,
        onRetry: onRetry,
        onRunQueue: onRunQueue,
        mediaTarget: mediaTarget,
        providerIds: providerIds,
        onSubmit: suppliedSubmit,
      );
    }
    final runtime = ref.watch(aiGenerationRuntimeProvider);
    return runtime.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(screenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(screenTitle)),
        body: Center(child: Text('Queue error: $error')),
      ),
      data: (runtime) {
        if (runtime == null) {
          return Scaffold(
            appBar: AppBar(title: Text(screenTitle)),
            body: const Center(
              child: Text('Open a project to use this AI generator.'),
            ),
          );
        }
        return StreamBuilder<List<GenerationJob>>(
          stream: runtime.watchJobs(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: Text(screenTitle)),
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
              mediaTarget: mediaTarget,
              providerIds: providerIds,
              onSubmit: ({required prompt, required providerId}) =>
                  runtime.submitPrompt(
                    target: mediaTarget,
                    prompt: prompt,
                    providerId: providerId,
                  ),
            );
          },
        );
      },
    );
  }
}

class _QueueScaffold extends StatefulWidget {
  const _QueueScaffold({
    required this.jobs,
    required this.mediaTarget,
    required this.providerIds,
    this.onCancel,
    this.onRetry,
    this.onRunQueue,
    this.onSubmit,
  });

  final List<GenerationJob> jobs;
  final PromptTarget mediaTarget;
  final List<String> providerIds;
  final Future<void> Function(String jobId)? onCancel;
  final Future<void> Function(String jobId)? onRetry;
  final Future<void> Function()? onRunQueue;
  final AiPromptSubmission? onSubmit;

  @override
  State<_QueueScaffold> createState() => _QueueScaffoldState();
}

class _QueueScaffoldState extends State<_QueueScaffold> {
  final _prompt = TextEditingController();
  String? _providerId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _providerId = widget.providerIds.firstOrNull;
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final callback = widget.onSubmit;
    final providerId = _providerId;
    final prompt = _prompt.text.trim();
    if (callback == null || providerId == null || prompt.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await callback(prompt: prompt, providerId: providerId);
      if (!mounted) return;
      _prompt.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.mediaTarget == PromptTarget.video ? 'Video' : 'Image'} '
            'generation submitted.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.mediaTarget == PromptTarget.video
            ? 'Video Generator'
            : 'Image Generator',
      ),
      actions: [
        if (widget.onRunQueue != null)
          TextButton.icon(
            onPressed: () => widget.onRunQueue!(),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Run Queue'),
          ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.mediaTarget == PromptTarget.video &&
            widget.providerIds.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No video generation provider is configured yet.'),
            ),
          ),
        if (widget.mediaTarget == PromptTarget.video &&
            widget.providerIds.isEmpty)
          const SizedBox(height: 16),
        if (widget.onSubmit != null && widget.providerIds.isNotEmpty)
          _MediaSubmissionCard(
            mediaTarget: widget.mediaTarget,
            prompt: _prompt,
            providerIds: widget.providerIds,
            selectedProviderId: _providerId,
            submitting: _submitting,
            onProviderChanged: (value) => setState(() => _providerId = value),
            onSubmit: _submit,
          ),
        if (widget.onSubmit != null && widget.providerIds.isNotEmpty)
          const SizedBox(height: 16),
        if (widget.jobs.isEmpty)
          const Center(child: Text('No generation jobs yet.'))
        else
          for (final job in widget.jobs)
            Card(
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
                  onCancel: widget.onCancel,
                  onRetry: widget.onRetry,
                ),
              ),
            ),
      ],
    ),
  );
}

class _MediaSubmissionCard extends StatelessWidget {
  const _MediaSubmissionCard({
    required this.mediaTarget,
    required this.prompt,
    required this.providerIds,
    required this.selectedProviderId,
    required this.submitting,
    required this.onProviderChanged,
    required this.onSubmit,
  });

  final PromptTarget mediaTarget;
  final TextEditingController prompt;
  final List<String> providerIds;
  final String? selectedProviderId;
  final bool submitting;
  final ValueChanged<String?> onProviderChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isVideo = mediaTarget == PromptTarget.video;
    final mediaLabel = isVideo ? 'Video' : 'Image';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate $mediaLabel',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prompt,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '$mediaLabel prompt',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: selectedProviderId,
                  items: [
                    for (final id in providerIds)
                      DropdownMenuItem(value: id, child: Text(id)),
                  ],
                  onChanged: submitting ? null : onProviderChanged,
                ),
                FilledButton.icon(
                  onPressed: submitting ? null : onSubmit,
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isVideo
                              ? Icons.movie_creation_outlined
                              : Icons.image_outlined,
                        ),
                  label: Text('Generate $mediaLabel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
