/// Approximate token counter (Step 28.4).
///
/// Uses the common characters/4 heuristic. This is an estimate for context
/// budgeting, not a billing-accurate tokenizer.
class TokenEstimator {
  const TokenEstimator({this.charsPerToken = 4});

  final int charsPerToken;

  int estimate(String text) {
    if (text.isEmpty) return 0;
    final count = (text.length / charsPerToken).ceil();
    return count < 1 ? 1 : count;
  }
}
