import 'package:flutter/material.dart';

import 'background_job.dart';
import 'background_job_controller.dart';

class TaskCenterScreen extends StatelessWidget {
  const TaskCenterScreen({super.key, required this.controller});

  final BackgroundJobController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final jobs = controller.jobs;
      return Scaffold(
        appBar: AppBar(title: const Text('TASK CENTER')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Tasks ${controller.activeCount}'),
            const SizedBox(height: 12),
            if (jobs.isEmpty) const Text('No background tasks'),
            for (final job in jobs) _TaskTile(job: job, controller: controller),
          ],
        ),
      );
    },
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.job, required this.controller});

  final BackgroundJob job;
  final BackgroundJobController controller;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(job.label),
      subtitle: Text(job.status.name.toUpperCase()),
      trailing: switch (job.status) {
        BackgroundJobStatus.queued || BackgroundJobStatus.running => IconButton(
          tooltip: 'Cancel task',
          icon: const Icon(Icons.close),
          onPressed: () => controller.cancel(job.id),
        ),
        _ => null,
      },
    ),
  );
}
