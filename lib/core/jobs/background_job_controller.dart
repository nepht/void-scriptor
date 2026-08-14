import 'dart:async';

import 'package:flutter/foundation.dart';

import 'background_job.dart';
import 'background_job_queue.dart';

class BackgroundJobController extends ChangeNotifier {
  BackgroundJobController(this.queue) {
    _subscription = queue.updates.listen((_) {
      _sync();
      notifyListeners();
    });
    _sync();
  }

  final BackgroundJobQueue queue;
  late final StreamSubscription<BackgroundJob> _subscription;
  List<BackgroundJob> _jobs = const [];

  List<BackgroundJob> get jobs => List.unmodifiable(_jobs);
  int get activeCount => _jobs
      .where(
        (job) =>
            job.status == BackgroundJobStatus.queued ||
            job.status == BackgroundJobStatus.running,
      )
      .length;

  bool enqueue(BackgroundTask task) {
    final accepted = queue.enqueue(task);
    _sync();
    if (accepted) notifyListeners();
    return accepted;
  }

  Future<void> drain() => queue.drain();

  Future<bool> cancel(String id) async {
    final cancelled = await queue.cancel(id);
    _sync();
    if (cancelled) notifyListeners();
    return cancelled;
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _sync() {
    _jobs = queue.jobs.toList(growable: false);
  }
}
