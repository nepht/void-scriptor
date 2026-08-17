import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/domain/publishing.dart';
import 'package:void_scriptor/features/release/domain/analytics.dart';

void main() {
  group('PublishingReview', () {
    test('holds review pipeline state', () {
      const review = PublishingReview(
        id: 'pr1',
        releaseId: 'r1',
        status: ReviewStatus.pending,
      );
      expect(review.status, ReviewStatus.pending);
    });
  });

  group('ModerationAction', () {
    test('holds moderation actions', () {
      const action = ModerationAction(id: 'ma1', releaseId: 'r1', type: 'warn');
      expect(action.type, 'warn');
    });
  });

  group('ReleaseProvenance', () {
    test('holds provenance info', () {
      final prov = ReleaseProvenance(
        id: 'rp1',
        releaseId: 'r1',
        builtAt: DateTime.utc(2026, 1, 1),
        toolchain: 'flutter 3.24',
      );
      expect(prov.toolchain, contains('flutter'));
    });
  });

  group('ReleaseSchedule', () {
    test('holds scheduling info', () {
      final sched = ReleaseSchedule(
        id: 'rs1',
        releaseId: 'r1',
        scheduledAt: DateTime.utc(2026, 2, 1),
      );
      expect(sched.premiere, isFalse);
    });
  });

  group('ReleaseAnalytics', () {
    test('tracks release health', () {
      const a = ReleaseAnalytics(
        releaseId: 'r1',
        downloads: 1000,
        crashRate: 0.01,
      );
      expect(a.downloads, 1000);
      expect(a.crashRate, lessThan(0.05));
    });
  });

  group('PublishingAgent', () {
    test('requires human approval for publish', () {
      const agent = PublishingAgent(id: 'pa1', autoApprove: false);
      expect(agent.canPublishAutonomously, isFalse);
    });
  });
}
