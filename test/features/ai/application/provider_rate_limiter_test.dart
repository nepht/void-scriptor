import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/provider_rate_limiter.dart';

void main() {
  test('rate limiter allows requests within provider window', () {
    final limiter = AiProviderRateLimiter(
      limits: const {
        'provider': AiRateLimit(maxRequests: 2, window: Duration(seconds: 1)),
      },
    );
    final at = DateTime.utc(2026, 8, 21, 12);

    expect(limiter.allow('provider', now: at), isTrue);
    expect(limiter.allow('provider', now: at), isTrue);
    expect(limiter.allow('provider', now: at), isFalse);
    expect(limiter.retryAfter('provider', now: at), const Duration(seconds: 1));
  });

  test('rate limiter expires old requests and rejects unknown providers', () {
    final limiter = AiProviderRateLimiter(
      limits: const {
        'provider': AiRateLimit(maxRequests: 1, window: Duration(seconds: 1)),
      },
    );
    final at = DateTime.utc(2026, 8, 21, 12);

    expect(limiter.allow('provider', now: at), isTrue);
    expect(
      limiter.allow('provider', now: at.add(const Duration(milliseconds: 999))),
      isFalse,
    );
    expect(
      limiter.allow('provider', now: at.add(const Duration(seconds: 1))),
      isTrue,
    );
    expect(limiter.allow('unknown', now: at), isFalse);
  });

  test('rate limiter rejects invalid definitions', () {
    expect(
      () => AiProviderRateLimiter(
        limits: const {
          'bad': AiRateLimit(maxRequests: 0, window: Duration(seconds: 1)),
        },
      ),
      throwsArgumentError,
    );
  });
}
