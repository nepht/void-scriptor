// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_job_dao.dart';

// ignore_for_file: type=lint
mixin _$BackgroundJobDaoMixin on DatabaseAccessor<ProjectDatabase> {
  $BackgroundJobsTable get backgroundJobs => attachedDatabase.backgroundJobs;
  BackgroundJobDaoManager get managers => BackgroundJobDaoManager(this);
}

class BackgroundJobDaoManager {
  final _$BackgroundJobDaoMixin _db;
  BackgroundJobDaoManager(this._db);
  $$BackgroundJobsTableTableManager get backgroundJobs =>
      $$BackgroundJobsTableTableManager(
        _db.attachedDatabase,
        _db.backgroundJobs,
      );
}
