import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/presentation/project_persistence_providers.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_snapshot.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => const DashboardRepository(),
);

final dashboardSnapshotProvider =
    FutureProvider.autoDispose<DashboardSnapshot?>((ref) async {
      final session = ref.watch(projectSessionProvider).value;
      if (session == null) return null;
      return ref
          .watch(dashboardRepositoryProvider)
          .loadProjectSnapshot(session.database, session.manifest.id);
    });
