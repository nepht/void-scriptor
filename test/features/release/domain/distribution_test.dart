import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/domain/distribution.dart';
import 'package:void_scriptor/features/release/domain/discovery.dart';
import 'package:void_scriptor/features/release/domain/monetization.dart';

void main() {
  group('PatchManifest', () {
    test('holds patch files', () {
      const patch = PatchManifest(
        id: 'pm1',
        releaseId: 'r1',
        files: ['data/game.dat', 'data/levels/1.bin'],
      );
      expect(patch.files, hasLength(2));
    });
  });

  group('DownloadTask', () {
    test('supports resume', () {
      const task = DownloadTask(
        id: 'd1',
        artifactId: 'a1',
        totalBytes: 1000,
        downloadedBytes: 400,
      );
      expect(task.progress, 0.4);
      expect(task.resumable, isTrue);
    });
  });

  group('ContentHash', () {
    test('validates content integrity', () {
      const hash = ContentHash(
        artifactId: 'a1',
        algorithm: 'sha256',
        digest: 'abc123',
      );
      expect(hash.algorithm, 'sha256');
      expect(hash.matches('abc123'), isTrue);
      expect(hash.matches('other'), isFalse);
    });
  });

  group('DiscoveryResult', () {
    test('ranks discovery results', () {
      const result = DiscoveryResult(id: 'dr1', projectId: 'p1', score: 0.9);
      expect(result.score, greaterThan(0.8));
    });
  });

  group('Review', () {
    test('holds review dimensions', () {
      const review = Review(
        id: 'rv1',
        projectId: 'p1',
        authorId: 'u1',
        rating: 4.5,
        dimensions: {'story': 5.0, 'art': 4.0},
      );
      expect(review.rating, 4.5);
      expect(review.dimensions['story'], 5.0);
    });
  });

  group('MonetizationType', () {
    test('exposes monetization types', () {
      expect(MonetizationType.values.map((e) => e.name), [
        'free',
        'paid',
        'freemium',
        'subscription',
        'donation',
      ]);
    });
  });

  group('RevenueBreakdown', () {
    test('sums revenue sources', () {
      const breakdown = RevenueBreakdown(
        id: 'rb1',
        projectId: 'p1',
        sources: {'sales': 100.0, 'tips': 25.5},
      );
      expect(breakdown.total, 125.5);
    });
  });
}
