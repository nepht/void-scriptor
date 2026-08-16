import '../domain/release_channel.dart';
import '../manifest/publish_manifest.dart';
import '../record/publish_record.dart';

/// Distribution manager (Step 36.9).
class DistributionManager {
  final List<PublishRecord> _records = [];

  PublishRecord publish({
    required String id,
    required PublishManifest manifest,
    required ReleaseChannel channel,
  }) {
    final record = PublishRecord(
      id: id,
      manifest: manifest,
      channel: channel,
      state: PublishState.published,
      publishedAt: DateTime.now().toUtc(),
    );
    _records.add(record);
    return record;
  }

  PublishRecord? latestFor(ReleaseChannel channel) {
    PublishRecord? latest;
    for (final record in _records) {
      if (record.channel != channel) continue;
      if (latest == null ||
          record.manifest.version.compareTo(latest.manifest.version) > 0) {
        latest = record;
      }
    }
    return latest;
  }

  List<PublishRecord> recordsFor(ReleaseChannel channel) =>
      _records.where((r) => r.channel == channel).toList();
}
