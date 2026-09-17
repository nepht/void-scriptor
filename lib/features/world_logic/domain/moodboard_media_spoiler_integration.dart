/// Sprint 112.24 — integrasi moodboard, media, dan spoiler.
///
/// Boundary domain-only untuk memeriksa hubungan referensi visual dengan media
/// lokal, deskripsi canon, kredit sumber, spoiler policy, dan sanitasi metadata.
/// Tidak melakukan file IO, persistence, UI, jaringan, atau random input.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';

class MoodboardMediaSpoilerResult {
  const MoodboardMediaSpoilerResult({
    required this.mediaLinks,
    required this.visualContinuity,
    required this.sourceCredit,
    required this.spoilerRedaction,
    required this.metadataSanitization,
    required this.missingFileState,
  });

  final bool mediaLinks;
  final bool visualContinuity;
  final bool sourceCredit;
  final bool spoilerRedaction;
  final bool metadataSanitization;
  final bool missingFileState;

  bool get isValid =>
      mediaLinks &&
      visualContinuity &&
      sourceCredit &&
      spoilerRedaction &&
      metadataSanitization &&
      missingFileState;
}

class MoodboardMediaSpoilerIntegration {
  const MoodboardMediaSpoilerIntegration();

  MoodboardMediaSpoilerResult evaluate({
    required List<EncyclopediaMediaAsset> assets,
    required Map<String, List<SourceCredit>> credits,
    required SpoilerPolicy spoilerPolicy,
    required Map<String, String> canonDescriptions,
    Map<String, SpoilerLevel> spoilerLevels = const {},
  }) {
    final ids = assets.map((asset) => asset.assetId).toSet();
    final mediaLinks =
        assets.isNotEmpty &&
        assets.every((asset) => asset.relativePath.isNotEmpty);
    final visualContinuity =
        assets.isNotEmpty &&
        assets.every(
          (asset) =>
              canonDescriptions[asset.assetId]?.trim().isNotEmpty ?? false,
        );
    final sourceCredit =
        assets.isNotEmpty &&
        assets.every((asset) => credits[asset.assetId]?.isNotEmpty ?? false);
    final spoilerRedaction = ids.every(
      (id) => spoilerPolicy.allows(
        spoilerLevels[id] ?? SpoilerLevel.safe,
        recordKey: id,
      ),
    );
    final metadataSanitization = assets.every((asset) {
      final sanitized = MediaMetadataSanitizer.sanitize(asset.metadata);
      return !sanitized.cleaned.keys.any(
        (key) =>
            key.trim().toLowerCase() == 'gpslatitude' ||
            key.trim().toLowerCase() == 'gpslongitude' ||
            key.trim().toLowerCase() == 'location' ||
            key.trim().toLowerCase() == 'email',
      );
    });
    final missingFileState = assets.any(
      (asset) => asset.fileStatus == MediaFileStatus.missing,
    );

    return MoodboardMediaSpoilerResult(
      mediaLinks: mediaLinks,
      visualContinuity: visualContinuity,
      sourceCredit: sourceCredit,
      spoilerRedaction: spoilerRedaction,
      metadataSanitization: metadataSanitization,
      missingFileState: missingFileState,
    );
  }
}
