import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/vfx/application/create_vfx_service.dart';
import 'package:void_scriptor/features/vfx/data/vfx_repository.dart';
import 'package:void_scriptor/features/vfx/domain/vfx_model.dart';

void main() {
  test('Void Portal states and intensity keyframes survive restart', () async {
    final root = await Directory.systemTemp.createTemp('vfx-persistence-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final project = await paths.project('project-vfx');
    await project.create(recursive: true);
    final dbPath = (await paths.database('project-vfx')).path;
    final service = ProjectDatabaseService();
    final database = await service.open(dbPath);
    final vfxId = await CreateVfxService(database, paths: paths).create(
      projectId: 'project-vfx',
      name: 'Void Portal',
      category: VfxCategory.portal,
      description: 'A controlled void gateway.',
      visualBehavior: 'Particles move inward toward a stable core.',
      colorPalette: 'Violet, black, electric blue',
      behavior: const VfxBehaviorProfile(
        originBehavior: 'Opens from a spatial tear',
        movementBehavior: 'Inward spiral',
        dissipationBehavior: 'Collapses into the core',
        environmentalInteraction: 'Casts violet light',
        defaultDurationSeconds: 4,
        emitsLight: true,
      ),
      states: const [
        VfxStateModel(id: 'opening', vfxId: '', name: 'Opening', sortOrder: 0),
        VfxStateModel(
          id: 'stable',
          vfxId: '',
          name: 'Stable',
          referenceSetId: 'portal-stable-set',
          sortOrder: 1,
        ),
        VfxStateModel(
          id: 'collapsing',
          vfxId: '',
          name: 'Collapsing',
          sortOrder: 2,
        ),
      ],
    );
    final repository = VfxRepository(database);
    await repository.saveClip(
      VfxTimelineClipModel(
        id: 'portal-clip',
        sceneId: 'scene-8',
        vfxAssetId: vfxId,
        startSeconds: 3,
        durationSeconds: 4,
        stateId: 'opening',
        attachedInstanceId: 'qowner-right-hand',
      ),
    );
    await repository.saveKeyframes(const [
      VfxKeyframeModel(
        id: 'kf-0',
        clipId: 'portal-clip',
        timeSeconds: 0,
        property: 'intensity',
        value: 0,
      ),
      VfxKeyframeModel(
        id: 'kf-1',
        clipId: 'portal-clip',
        timeSeconds: 0.5,
        property: 'intensity',
        value: 0.25,
      ),
      VfxKeyframeModel(
        id: 'kf-2',
        clipId: 'portal-clip',
        timeSeconds: 1,
        property: 'intensity',
        value: 1,
      ),
    ]);
    await database.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final restored = VfxRepository(second);
    expect(second.schemaVersion, 38);
    expect((await second.assetDao.getById(vfxId))?.type, 'vfx');
    expect((await restored.getVfx(vfxId))?.category, VfxCategory.portal);
    expect((await restored.getBehavior(vfxId))?.emitsLight, isTrue);
    expect((await restored.statesFor(vfxId)).map((state) => state.name), [
      'Opening',
      'Stable',
      'Collapsing',
    ]);
    expect(
      (await restored.clipsForScene('scene-8')).single.attachedInstanceId,
      'qowner-right-hand',
    );
    expect(
      (await restored.keyframesFor(
        'portal-clip',
      )).map((keyframe) => keyframe.value),
      [0, 0.25, 1],
    );
  });
}
