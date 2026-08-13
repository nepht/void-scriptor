import 'package:flutter/material.dart';
import '../domain/generation_job.dart';

class AiGenerationQueueScreen extends StatelessWidget {
  const AiGenerationQueueScreen({super.key, this.jobs = const []});
  final List<GenerationJob> jobs;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI QUEUE')),
    body: jobs.isEmpty
        ? const Center(child: Text('No generation jobs yet.'))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: jobs.length,
            itemBuilder: (_, index) => Card(
              child: ListTile(
                title: Text(jobs[index].id),
                subtitle: Text(
                  '${jobs[index].providerId} • ${jobs[index].status.name}',
                ),
                trailing: jobs[index].status == GenerationJobStatus.running
                    ? SizedBox(
                        width: 90,
                        child: LinearProgressIndicator(
                          value: jobs[index].progress,
                        ),
                      )
                    : Text(jobs[index].status.name),
              ),
            ),
          ),
  );
}
