import 'package:drift/drift.dart';

import '../project_database.dart';
import '../tables/background_jobs.dart';

part 'background_job_dao.g.dart';

@DriftAccessor(tables: [BackgroundJobs])
class BackgroundJobDao extends DatabaseAccessor<ProjectDatabase>
    with _$BackgroundJobDaoMixin {
  BackgroundJobDao(super.db);

  Future<void> insertJob(BackgroundJobsCompanion job) =>
      into(backgroundJobs).insert(job);

  Future<void> updateJob(BackgroundJobsCompanion job) =>
      update(backgroundJobs).replace(job);

  Future<BackgroundJob?> getJob(String id) => (select(
    backgroundJobs,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<List<BackgroundJob>> listProjectJobs(String projectId) =>
      (select(backgroundJobs)
            ..where((row) => row.projectId.equals(projectId))
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .get();

  Future<int> deleteJob(String id) =>
      (delete(backgroundJobs)..where((row) => row.id.equals(id))).go();
}
