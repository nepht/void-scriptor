import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/core/animation/persistence/animation_repository.dart';

void main() {
  test('saveTrack and listTracks roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AnimationRepository(database: db);

    await repo.saveTrack(
      clipId: 'clip1',
      id: 'track1',
      name: 'x',
      targetProperty: 'position.x',
      interpolation: 'linear',
      durationSeconds: 2.0,
    );
    final tracks = await repo.listTracks('clip1');
    expect(tracks, hasLength(1));
    expect(tracks.first.name, 'x');
    expect(tracks.first.durationSeconds, 2.0);
  });

  test('saveKeyframe and listKeyframes roundtrip', () async {
    final db = ProjectDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = AnimationRepository(database: db);

    await repo.saveKeyframe(
      id: 'k1',
      trackId: 't1',
      timeSeconds: 0.5,
      value: 42.0,
    );
    final keyframes = await repo.listKeyframes('t1');
    expect(keyframes, hasLength(1));
    expect(keyframes.first.timeSeconds, 0.5);
    expect(keyframes.first.value, 42.0);
  });

  test('restart persistence: close and reopen keeps tracks', () async {
    final dir = Directory.systemTemp.createTempSync('vs_anim_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/project.db');

    final db = ProjectDatabase(NativeDatabase(file));
    final repo = AnimationRepository(database: db);
    await repo.saveTrack(
      clipId: 'clip1',
      id: 'track1',
      name: 'x',
      targetProperty: 'position.x',
      interpolation: 'linear',
      durationSeconds: 2.0,
    );
    await repo.saveKeyframe(
      id: 'k1',
      trackId: 'track1',
      timeSeconds: 0.5,
      value: 42.0,
    );
    await db.close();

    final db2 = ProjectDatabase(NativeDatabase(file));
    addTearDown(db2.close);
    final repo2 = AnimationRepository(database: db2);
    expect((await repo2.listTracks('clip1')), hasLength(1));
    expect((await repo2.listKeyframes('track1')), hasLength(1));
  });
}
