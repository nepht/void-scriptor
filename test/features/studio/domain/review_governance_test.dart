import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/review_governance.dart';

void main() {
  test(
    'attention queue prioritizes urgent items and reviewers stay separate',
    () {
      final queue = AttentionQueue();
      queue.add(const AttentionItem(id: 'normal', priority: 1));
      queue.add(const AttentionItem(id: 'urgent', priority: 3));
      expect(queue.next()?.id, 'urgent');
      expect(ReviewerSeparation.canReview('author', 'author'), isFalse);
      expect(ReviewerSeparation.canReview('author', 'qc'), isTrue);
    },
  );

  test('resolves disagreement or escalates when unresolved', () {
    final resolver = ConflictResolver();
    expect(resolver.resolve(['yes', 'yes']), ReviewOutcome.accepted);
    expect(resolver.resolve(['yes', 'no']), ReviewOutcome.escalated);
  });
}
