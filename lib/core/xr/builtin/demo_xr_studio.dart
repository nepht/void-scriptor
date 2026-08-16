import '../session/xr_session.dart';
import '../spatial/spatial_scene.dart';
import '../camera/stereoscopic_camera.dart';

/// Built-in demo XR studio (Step 41.20).
class DemoXrStudio {
  DemoXrStudio._();

  static final XrSession session = XrSession();
  static const StereoscopicCamera camera = StereoscopicCamera(ipd: 0.064);
  static final SpatialScene scene = SpatialScene()
    ..add(const SpatialAnchor(id: 'a1', x: 0, y: 0, z: -2, contentId: 'kael'))
    ..add(const SpatialAnchor(id: 'a2', x: 1, y: 0, z: -2, contentId: 'north'));
}
