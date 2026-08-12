import '../domain/dashboard_snapshot.dart';

class DashboardRepository {
  const DashboardRepository();

  DashboardSnapshot loadDummySnapshot() {
    return const DashboardSnapshot(
      projects: 2,
      characters: 12,
      wardrobes: 27,
      weapons: 14,
      environments: 8,
      assets: 324,
    );
  }
}
