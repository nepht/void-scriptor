import '../shot/shot.dart';
import '../shot/shot_list.dart';

/// Built-in demo virtual production scene (Step 35.20).
class DemoVirtualProduction {
  DemoVirtualProduction._();

  static final ShotList shotList = ShotList()
    ..add(
      const Shot(
        id: 's1',
        name: 'opening',
        startSeconds: 0,
        durationSeconds: 5,
        cameraId: 'cam1',
      ),
    )
    ..add(
      const Shot(
        id: 's2',
        name: 'conflict',
        startSeconds: 5,
        durationSeconds: 8,
        cameraId: 'cam2',
      ),
    )
    ..add(
      const Shot(
        id: 's3',
        name: 'resolution',
        startSeconds: 13,
        durationSeconds: 7,
        cameraId: 'cam1',
      ),
    );
}
