import '../domain/release_channel.dart';
import '../manifest/publish_manifest.dart';

enum PublishState { draft, review, published, rejected }

/// A single publish record (Step 36.7–36.8).
class PublishRecord {
  PublishRecord({
    required this.id,
    required this.manifest,
    required this.channel,
    required this.state,
    this.publishedAt,
  });

  final String id;
  final PublishManifest manifest;
  final ReleaseChannel channel;
  final PublishState state;
  final DateTime? publishedAt;

  PublishRecord copyWith({PublishState? state, DateTime? publishedAt}) =>
      PublishRecord(
        id: id,
        manifest: manifest,
        channel: channel,
        state: state ?? this.state,
        publishedAt: publishedAt ?? this.publishedAt,
      );
}
