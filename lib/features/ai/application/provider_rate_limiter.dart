class AiRateLimit {
  const AiRateLimit({required this.maxRequests, required this.window});

  final int maxRequests;
  final Duration window;
}

class AiProviderRateLimiter {
  AiProviderRateLimiter({required Map<String, AiRateLimit> limits}) {
    for (final entry in limits.entries) {
      if (entry.key.isEmpty ||
          entry.value.maxRequests <= 0 ||
          entry.value.window <= Duration.zero) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'Invalid rate limit.',
        );
      }
    }
    _limits = Map.unmodifiable(limits);
  }

  late final Map<String, AiRateLimit> _limits;
  final Map<String, List<DateTime>> _requests = {};

  bool allow(String providerId, {required DateTime now}) {
    final limit = _limits[providerId];
    if (limit == null) return false;
    final requests = _activeRequests(providerId, now, limit);
    if (requests.length >= limit.maxRequests) return false;
    requests.add(now);
    return true;
  }

  Duration? retryAfter(String providerId, {required DateTime now}) {
    final limit = _limits[providerId];
    if (limit == null) return null;
    final requests = _activeRequests(providerId, now, limit);
    if (requests.length < limit.maxRequests) return Duration.zero;
    final wait = requests.first.add(limit.window).difference(now);
    return wait.isNegative ? Duration.zero : wait;
  }

  List<DateTime> _activeRequests(
    String providerId,
    DateTime now,
    AiRateLimit limit,
  ) {
    final requests = _requests.putIfAbsent(providerId, () => <DateTime>[]);
    requests.removeWhere(
      (timestamp) => !timestamp.add(limit.window).isAfter(now),
    );
    return requests;
  }
}
