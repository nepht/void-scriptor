import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/asset_triggers.dart';

/// Sprint 104 / 104.12 — asset pipeline trigger vocabulary.
void main() {
  test('all five canonical asset events exist', () {
    expect(AssetPipelineEvent.values.length, 5);
    expect(
      AssetPipelineEvent.values.map((e) => e.name).toSet(),
      containsAll(['assetImported', 'assetMissing', 'assetRelinked']),
    );
  });

  test('facts are minimal and identifier-only', () {
    final facts = assetFacts(
      AssetPipelineEvent.assetImported,
      assetId: 'a-1',
      projectId: 'p-1',
    );
    expect(facts['asset.event'], 'assetImported');
    expect(facts['asset.id'], 'a-1');
    expect(facts.length <= 4, isTrue);
  });

  test('thumbnail-ready exposes the relative path key only when provided', () {
    final withPath = assetFacts(
      AssetPipelineEvent.thumbnailReady,
      assetId: 'a-2',
      projectId: 'p-1',
      thumbnailPath: 'assets/thumbs/a-2.png',
    );
    expect(withPath['thumbnail.path'], 'assets/thumbs/a-2.png');

    final without = assetFacts(
      AssetPipelineEvent.thumbnailReady,
      assetId: 'a-3',
      projectId: 'p-1',
    );
    expect(without.containsKey('thumbnail.path'), isFalse);
  });
}
