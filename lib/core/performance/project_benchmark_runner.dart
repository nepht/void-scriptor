import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../database/project/project_database.dart';
import 'large_project_benchmark.dart';

class ProjectBenchmarkReport {
  const ProjectBenchmarkReport({
    required this.referenceCount,
    required this.timelineClipCount,
    required this.referenceListMicros,
    required this.timelineRangeMicros,
  });

  final int referenceCount;
  final int timelineClipCount;
  final int referenceListMicros;
  final int timelineRangeMicros;

  int get totalMicros => referenceListMicros + timelineRangeMicros;
}

class ProjectBenchmarkRunner {
  ProjectBenchmarkRunner({
    this.profile = const LargeProjectBenchmarkProfile.defaultProfile(),
  });

  final LargeProjectBenchmarkProfile profile;

  Future<ProjectBenchmarkReport> run() async {
    final database = ProjectDatabase(NativeDatabase.memory());
    try {
      await database.initialize();

      await _seedReferences(database);
      await _seedTimelineClips(database);

      final referenceCount = (await database.references.select().get()).length;
      final timelineClipCount =
          (await database.timelineClips.select().get()).length;

      final referenceListMicros = await _timeMicros(
        () => database.references.select().get(),
      );
      final timelineRangeMicros = await _timeMicros(
        () =>
            (database.timelineClips.select()..where(
                  (row) =>
                      row.startSeconds.isBiggerOrEqualValue(10) &
                      row.startSeconds.isSmallerThanValue(20),
                ))
                .get(),
      );

      return ProjectBenchmarkReport(
        referenceCount: referenceCount,
        timelineClipCount: timelineClipCount,
        referenceListMicros: referenceListMicros,
        timelineRangeMicros: timelineRangeMicros,
      );
    } finally {
      await database.close();
    }
  }

  Future<void> _seedReferences(ProjectDatabase database) async {
    await database.batch((batch) {
      for (var i = 0; i < profile.references; i++) {
        final now = DateTime.now().toUtc();
        batch.insert(
          database.references,
          ReferencesCompanion.insert(
            id: 'ref-$i',
            projectId: 'benchmark',
            type: 'document',
            source: 'local',
            name: 'Reference $i',
            filePath: 'assets/ref-$i.png',
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
  }

  Future<void> _seedTimelineClips(ProjectDatabase database) async {
    await database.batch((batch) {
      for (var i = 0; i < profile.timelineClips; i++) {
        batch.insert(
          database.timelineClips,
          TimelineClipsCompanion.insert(
            id: 'clip-$i',
            timelineId: 'timeline-1',
            trackId: 'track-1',
            clipType: 'video',
            label: 'Clip $i',
            startSeconds: (i % 100).toDouble(),
            durationSeconds: 2,
          ),
        );
      }
    });
  }

  static Future<int> _timeMicros(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsedMicroseconds;
  }
}
