// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vfx_repository.dart';

// ignore_for_file: type=lint
mixin _$VfxRepositoryMixin on DatabaseAccessor<ProjectDatabase> {
  $VfxAssetsTable get vfxAssets => attachedDatabase.vfxAssets;
  $VfxBehaviorProfilesTable get vfxBehaviorProfiles =>
      attachedDatabase.vfxBehaviorProfiles;
  $VfxStatesTable get vfxStates => attachedDatabase.vfxStates;
  $VfxTimelineClipsTable get vfxTimelineClips =>
      attachedDatabase.vfxTimelineClips;
  $VfxKeyframesTable get vfxKeyframes => attachedDatabase.vfxKeyframes;
  VfxRepositoryManager get managers => VfxRepositoryManager(this);
}

class VfxRepositoryManager {
  final _$VfxRepositoryMixin _db;
  VfxRepositoryManager(this._db);
  $$VfxAssetsTableTableManager get vfxAssets =>
      $$VfxAssetsTableTableManager(_db.attachedDatabase, _db.vfxAssets);
  $$VfxBehaviorProfilesTableTableManager get vfxBehaviorProfiles =>
      $$VfxBehaviorProfilesTableTableManager(
        _db.attachedDatabase,
        _db.vfxBehaviorProfiles,
      );
  $$VfxStatesTableTableManager get vfxStates =>
      $$VfxStatesTableTableManager(_db.attachedDatabase, _db.vfxStates);
  $$VfxTimelineClipsTableTableManager get vfxTimelineClips =>
      $$VfxTimelineClipsTableTableManager(
        _db.attachedDatabase,
        _db.vfxTimelineClips,
      );
  $$VfxKeyframesTableTableManager get vfxKeyframes =>
      $$VfxKeyframesTableTableManager(_db.attachedDatabase, _db.vfxKeyframes);
}
