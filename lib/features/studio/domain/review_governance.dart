class AttentionItem {
  const AttentionItem({required this.id, required this.priority});
  final String id;
  final int priority;
}

class AttentionQueue {
  final List<AttentionItem> _items = [];

  /// Keeps the list sorted by descending priority at insertion so retrieval
  /// stays O(1). Equal priorities keep insertion order.
  void add(AttentionItem item) {
    var low = 0;
    var high = _items.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_items[mid].priority >= item.priority) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    _items.insert(low, item);
  }

  AttentionItem? next() {
    if (_items.isEmpty) return null;
    return _items.removeAt(0);
  }
}

class ReviewerSeparation {
  static bool canReview(String authorId, String reviewerId) =>
      authorId.trim().isNotEmpty &&
      reviewerId.trim().isNotEmpty &&
      authorId != reviewerId;
}

enum ReviewOutcome { accepted, escalated }

class ConflictResolver {
  ReviewOutcome resolve(List<String> votes) {
    if (votes.isEmpty) return ReviewOutcome.escalated;
    return votes.every((vote) => vote == votes.first)
        ? ReviewOutcome.accepted
        : ReviewOutcome.escalated;
  }
}
