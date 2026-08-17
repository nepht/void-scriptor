/// Sprint 48 — Step 48.1–48.9 Cinematic Project, Timeline, Tracks, Shots.
enum CinematicType { film, episode, cutscene, trailer, interactive, machinima }

class CinematicProject {
  CinematicProject({
    required this.id,
    required this.name,
    required this.type,
    this.shots = const [],
    this.timelineIds = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final CinematicType type;
  final List<String> shots;
  final List<String> timelineIds;
  final DateTime? createdAt;
}

class CinematicShot {
  const CinematicShot({
    required this.id,
    required this.cinematicId,
    required this.name,
    required this.order,
    required this.durationSeconds,
    this.cameraPreset,
    this.trackIds = const [],
  });

  final String id;
  final String cinematicId;
  final String name;
  final int order;
  final double durationSeconds;
  final CameraPreset? cameraPreset;
  final List<String> trackIds;
}

enum CameraPreset {
  wide,
  medium,
  closeUp,
  extremeCloseUp,
  overShoulder,
  pov,
  aerial,
  establishing,
}

enum TrackType { video, camera, audio, dialogue, vfx, subtitle }

class CinematicTrack {
  const CinematicTrack({
    required this.id,
    required this.parentSequenceId,
    required this.type,
    required this.order,
  });

  final String id;
  final String parentSequenceId;
  final TrackType type;
  final int order;
}
