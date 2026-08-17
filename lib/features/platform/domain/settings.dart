/// Sprint 50 — Step 50.51–50.52 Settings Architecture, Search Settings.
class SettingsGroup {
  const SettingsGroup({
    required this.id,
    required this.name,
    this.settings = const [],
  });

  final String id;
  final String name;
  final List<String> settings;
}

class SettingsValue {
  const SettingsValue({
    required this.id,
    required this.groupId,
    required this.value,
  });

  final String id;
  final String groupId;
  final Object value;
}

/// Step 50.58–50.62 Update Service, Channels, Integrity, Rollback.
enum UpdateChannel { stable, beta, dev, canary }

class UpdateManifest {
  const UpdateManifest({
    required this.id,
    required this.version,
    required this.channel,
    required this.digest,
  });

  final String id;
  final String version;
  final UpdateChannel channel;
  final String digest;

  bool get isStable => channel == UpdateChannel.stable;
}
