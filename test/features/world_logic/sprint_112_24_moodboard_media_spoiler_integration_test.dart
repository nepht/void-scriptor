import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/moodboard_media_spoiler_integration.dart';

void main() {
  test('connects moodboard media, credits, spoiler, and safe export', () {
    final asset = EncyclopediaMediaAsset.validated(
      assetId: 'mood-1',
      kind: MediaKind.image,
      relativePath: 'assets/references/mood-1.png',
      metadata: const {'description': 'Ash coast', 'GPSLatitude': 'redact'},
    );
    final credit = SourceCredit.validated(
      creditId: 'credit-1',
      attributedTo: 'Choirudin',
      role: MediaCreditRole.creator,
    );
    final missingAsset = asset.withFileStatus(MediaFileStatus.missing);
    final result = const MoodboardMediaSpoilerIntegration().evaluate(
      assets: [asset, missingAsset],
      credits: {
        'mood-1': [credit],
      },
      spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
      canonDescriptions: const {'mood-1': 'Ash coast visual reference'},
    );

    expect(result.mediaLinks, isTrue);
    expect(result.visualContinuity, isTrue);
    expect(result.sourceCredit, isTrue);
    expect(result.spoilerRedaction, isTrue);
    expect(result.metadataSanitization, isTrue);
    expect(result.missingFileState, isTrue);
    expect(result.isValid, isTrue);
  });
}
