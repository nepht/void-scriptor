import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/domain/creator_metrics.dart';

void main() {
  group('CreatorMetrics', () {
    test('exposes the eight canonical metric labels', () {
      expect(CreatorMetrics.labels, hasLength(8));
      expect(CreatorMetrics.labels, [
        'Active Projects',
        'Published Works',
        'Portfolio Views',
        'Followers',
        'Collaborations',
        'Asset Sales',
        'AI Usage',
        'Storage',
      ]);
    });

    test('holds metric values and formats numbers', () {
      final metrics = CreatorMetrics(
        activeProjects: 3,
        publishedWorks: 12,
        portfolioViews: 345,
        followers: 128,
        collaborations: 5,
        assetSales: 42,
        aiUsage: 87,
        storageBytes: 5 * 1024 * 1024,
      );
      expect(metrics.portfolioViews, 345);
      expect(metrics.storageLabel, '5.0 MB');
    });

    test('privacy hides social stats', () {
      final metrics = CreatorMetrics.private();
      expect(metrics.followers, isNull);
      expect(metrics.collaborations, isNull);
      expect(metrics.assetSales, isNull);
      expect(metrics.activeProjects, isNotNull);
    });
  });
}
