import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/application/ai_usage_log_repository.dart';
import '../../project_resilience/application/project_storage_analyzer.dart';
import '../../projects/presentation/project_persistence_providers.dart';

class AccountOperationalMetrics {
  const AccountOperationalMetrics({
    required this.promptTokens,
    required this.completionTokens,
    required this.estimatedCost,
    required this.totalStorageBytes,
    required this.storageBytesByCategory,
  });

  final int promptTokens;
  final int completionTokens;
  final double estimatedCost;
  final int totalStorageBytes;
  final Map<String, int> storageBytesByCategory;

  int get totalTokens => promptTokens + completionTokens;
}

final accountOperationalMetricsProvider =
    FutureProvider<AccountOperationalMetrics?>((ref) async {
      final session = ref.watch(projectSessionProvider).valueOrNull;
      if (session == null) return null;

      final now = DateTime.now().toUtc();
      final usage = await AiUsageLogRepository(
        session.database,
      ).forProject(session.manifest.id);
      final currentMonth = usage.where((entry) {
        final createdAt = entry.createdAt.toUtc();
        return createdAt.year == now.year && createdAt.month == now.month;
      });

      var promptTokens = 0;
      var completionTokens = 0;
      var estimatedCost = 0.0;
      for (final entry in currentMonth) {
        promptTokens += entry.promptTokens;
        completionTokens += entry.completionTokens;
        estimatedCost += entry.cost;
      }

      final storage = await ProjectStorageAnalyzer(session.package).analyze();
      final bytesByCategory = <String, int>{};
      for (final category in ProjectStorageCategory.values) {
        final bytes = storage.bytesFor(category);
        if (bytes > 0) {
          bytesByCategory[_categoryLabel(category)] = bytes;
        }
      }

      return AccountOperationalMetrics(
        promptTokens: promptTokens,
        completionTokens: completionTokens,
        estimatedCost: estimatedCost,
        totalStorageBytes: storage.totalBytes,
        storageBytesByCategory: Map.unmodifiable(bytesByCategory),
      );
    });

String _categoryLabel(ProjectStorageCategory category) => switch (category) {
  ProjectStorageCategory.database => 'Database',
  ProjectStorageCategory.reference => 'References',
  ProjectStorageCategory.image => 'Images',
  ProjectStorageCategory.video => 'Video',
  ProjectStorageCategory.audio => 'Audio',
  ProjectStorageCategory.generated => 'Generated',
  ProjectStorageCategory.export => 'Exports',
  ProjectStorageCategory.backup => 'Backups',
  ProjectStorageCategory.cache => 'Cache',
  ProjectStorageCategory.other => 'Other',
};
