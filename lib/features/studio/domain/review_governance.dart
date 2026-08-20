class AttentionItem {
  const AttentionItem({required this.id, required this.priority});
  final String id;
  final int priority;
}

class AttentionQueue {
  final List<AttentionItem> _items = [];
  void add(AttentionItem item) => _items.add(item);
  AttentionItem? next() {
    if (_items.isEmpty) return null;
    _items.sort((a, b) => b.priority.compareTo(a.priority));
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
