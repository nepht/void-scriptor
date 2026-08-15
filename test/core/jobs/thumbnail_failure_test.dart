import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/thumbnail_failure.dart';

void main() {
  test(
    'thumbnail failure caches error state and exposes broken image reason',
    () {
      final cache = ThumbnailFailureCache();
      const key = 'asset-1_256';

      expect(cache.isFailed(key), isFalse);
      cache.markFailed(key, reason: ThumbnailFailureReason.corruptSource);

      expect(cache.isFailed(key), isTrue);
      expect(
        cache.failureFor(key)?.reason,
        ThumbnailFailureReason.corruptSource,
      );
    },
  );

  test('retry policy defaults to 2 attempts and can count', () {
    const policy = JobRetryPolicy();
    expect(policy.maxAttempts, 2);

    var attempts = 0;
    final allowed = <bool>[];
    while (attempts < 5) {
      allowed.add(policy.shouldRetry(attempts));
      attempts++;
    }
    // attempt index 0 and 1 allowed (2 total attempts), rest not.
    expect(allowed, [true, true, false, false, false]);
  });

  test('clearing failure state allows regeneration', () {
    final cache = ThumbnailFailureCache();
    const key = 'asset-2_128';
    cache.markFailed(key, reason: ThumbnailFailureReason.unsupportedFormat);

    cache.clear(key);
    expect(cache.isFailed(key), isFalse);
    expect(cache.failureFor(key), isNull);
  });
}
