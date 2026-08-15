import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/close_prompt.dart';
import 'package:void_scriptor/core/jobs/dashboard_status.dart';
import 'package:void_scriptor/core/jobs/task_notification.dart';

void main() {
  test('close prompt decision distinguishes running export', () {
    const running = ClosePromptResult.running(
      activeLabel: 'Portable project export',
      activeJobType: BackgroundJobKind.export,
    );

    expect(running.needsDecision, isTrue);
    expect(running.activeLabel, 'Portable project export');
    expect(running.options, ['Keep Project Open', 'Cancel & Close']);

    const none = ClosePromptResult.none();
    expect(none.needsDecision, isFalse);
  });

  test('task notification models a small non-modal completion notice', () {
    const notification = TaskNotification(
      title: 'Export completed',
      message: 'Portable project export completed.',
      kind: TaskNotificationKind.completed,
    );

    expect(notification.title, 'Export completed');
    expect(notification.kind, TaskNotificationKind.completed);
    expect(notification.isModal, isFalse);
  });

  test('dashboard status aggregates running and queued counts', () {
    const status = DashboardBackgroundStatus(
      runningJobs: 2,
      queuedJobs: 5,
      thumbnailCachePercent: 72,
      searchIndexReady: true,
    );

    expect(status.runningJobs, 2);
    expect(status.queuedJobs, 5);
    expect(status.thumbnailCachePercent, 72);
    expect(status.searchIndexReady, isTrue);
    expect(status.totalJobs, 7);
  });
}
