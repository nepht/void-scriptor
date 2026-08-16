import '../domain/semver.dart';
import '../domain/build_target.dart';

/// Publish manifest (Step 36.4–36.6).
class PublishManifest {
  PublishManifest({
    required this.version,
    required this.changelog,
    required this.checksum,
    required Map<BuildTarget, String> artifacts,
  }) : artifacts = Map.unmodifiable(artifacts) {
    if (changelog.trim().isEmpty) {
      throw ArgumentError('changelog must not be empty');
    }
  }

  final SemVer version;
  final String changelog;
  final String checksum;
  final Map<BuildTarget, String> artifacts;

  Map<String, dynamic> toJson() => {
    'version': version.toString(),
    'changelog': changelog,
    'checksum': checksum,
    'artifacts': {
      for (final entry in artifacts.entries) entry.key.name: entry.value,
    },
  };

  factory PublishManifest.fromJson(Map<String, dynamic> json) {
    final artifactsJson = (json['artifacts'] as Map<String, dynamic>?) ?? {};
    return PublishManifest(
      version: SemVer.parse(json['version'] as String),
      changelog: json['changelog'] as String,
      checksum: json['checksum'] as String,
      artifacts: {
        for (final entry in artifactsJson.entries)
          BuildTarget.values.firstWhere(
            (t) => t.name == entry.key,
            orElse: () => BuildTarget.package,
          ): entry.value as String,
      },
    );
  }
}
