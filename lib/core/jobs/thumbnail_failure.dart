/// Thumbnail failure handling (Step 26.75) and retry policy (Step 26.76).
///
/// A corrupt source never heals via retries, so failure is cached for a
/// bounded time and surfaced as a broken-image placeholder instead of
/// triggering unbounded regeneration attempts.
enum ThumbnailFailureReason { corruptSource, unsupportedFormat, ioError }

class ThumbnailFailure {
  const ThumbnailFailure(this.reason);

  final ThumbnailFailureReason reason;
}

class ThumbnailFailureCache {
  final Map<String, ThumbnailFailure> _failures = {};

  bool isFailed(String cacheKey) => _failures.containsKey(cacheKey);

  ThumbnailFailure? failureFor(String cacheKey) => _failures[cacheKey];

  void markFailed(String cacheKey, {required ThumbnailFailureReason reason}) {
    _failures[cacheKey] = ThumbnailFailure(reason);
  }

  void clear(String cacheKey) => _failures.remove(cacheKey);

  void clearAll() => _failures.clear();
}

class JobRetryPolicy {
  const JobRetryPolicy({this.maxAttempts = 2});

  final int maxAttempts;

  bool shouldRetry(int attemptsSoFar) => attemptsSoFar < maxAttempts;
}
