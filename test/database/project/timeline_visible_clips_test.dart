import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/daos/timeline_dao.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory root;
  late File databaseFile;
  late ProjectDatabase db;
  late TimelineDao dao;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-s26-timeline-');
    databaseFile = File('${root.path}/project.db');
    await ProjectDatabaseService().create(databaseFile.path);
    db = await ProjectDatabaseService().open(databaseFile.path);
    dao = TimelineDao(db);
  });

  tearDown(() async {
    await db.close();
    await root.delete(recursive: true);
  });

  test(
    'getVisibleClips returns only clips intersecting the viewport',
    () async {
      const timelineId = 't1';
      const trackId = 'track-1';
      final now = DateTime.now().toUtc();

      await db
          .into(db.timelines)
          .insert(
            TimelinesCompanion.insert(
              id: timelineId,
              projectId: 'project-1',
              sceneId: 'scene-1',
              durationSeconds: 120,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db
          .into(db.timelineTracks)
          .insert(
            TimelineTracksCompanion.insert(
              id: trackId,
              timelineId: timelineId,
              trackType: 'video',
              name: 'Track',
              sortOrder: const Value(0),
            ),
          );

      // Clips: at 0-5s, 20-30s (outside), 95-110s, 200-210s (outside)
      Future<void> insertClip(String id, double start, double dur) => db
          .into(db.timelineClips)
          .insert(
            TimelineClipsCompanion.insert(
              id: id,
              timelineId: timelineId,
              trackId: trackId,
              clipType: 'video',
              label: id,
              startSeconds: start,
              durationSeconds: dur,
            ),
          );

      await insertClip('clip-a', 0, 5); // outside (ends 5, before viewport 9)
      await insertClip('clip-b', 20, 10); // visible (20-30)
      await insertClip('clip-c', 95, 15); // visible (95-110)
      await insertClip('clip-d', 200, 10); // outside

      // Viewport [10, 100], overscan 1s => query [9, 101]
      final visible = await dao.getVisibleClips(
        timelineId: timelineId,
        startSeconds: 10,
        endSeconds: 100,
        overscanSeconds: 1,
      );

      expect(visible.map((c) => c.id).toSet(), {'clip-b', 'clip-c'});
    },
  );

  test('getVisibleClips respects a track filter', () async {
    const timelineId = 't2';
    final now = DateTime.now().toUtc();
    await db
        .into(db.timelines)
        .insert(
          TimelinesCompanion.insert(
            id: timelineId,
            projectId: 'project-1',
            sceneId: 'scene-2',
            durationSeconds: 120,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.timelineTracks)
        .insert(
          TimelineTracksCompanion.insert(
            id: 'track-a',
            timelineId: timelineId,
            trackType: 'video',
            name: 'A',
            sortOrder: const Value(0),
          ),
        );
    await db
        .into(db.timelineTracks)
        .insert(
          TimelineTracksCompanion.insert(
            id: 'track-b',
            timelineId: timelineId,
            trackType: 'video',
            name: 'B',
            sortOrder: const Value(1),
          ),
        );
    await db
        .into(db.timelineClips)
        .insert(
          TimelineClipsCompanion.insert(
            id: 'clip-a',
            timelineId: timelineId,
            trackId: 'track-a',
            clipType: 'video',
            label: 'A',
            startSeconds: 5,
            durationSeconds: 5,
          ),
        );
    await db
        .into(db.timelineClips)
        .insert(
          TimelineClipsCompanion.insert(
            id: 'clip-b',
            timelineId: timelineId,
            trackId: 'track-b',
            clipType: 'video',
            label: 'B',
            startSeconds: 6,
            durationSeconds: 5,
          ),
        );

    final visible = await dao.getVisibleClips(
      timelineId: timelineId,
      startSeconds: 0,
      endSeconds: 20,
      trackId: 'track-b',
    );

    expect(visible.map((c) => c.id).toSet(), {'clip-b'});
  });
}
