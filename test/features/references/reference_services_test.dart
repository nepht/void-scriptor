import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/application/reference_services.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';

void main() {
  const faceMaster = ReferenceModel(
    id: 'face-master',
    projectId: 'p',
    ownerAssetId: 'qowner',
    type: ReferenceType.face,
    source: ReferenceSource.imported,
    name: 'Master Face',
    filePath: 'assets/references/qowner/face/master.png',
    priority: 100,
    primary: true,
    enabled: true,
  );
  const hairDefault = ReferenceModel(
    id: 'hair-default',
    projectId: 'p',
    ownerAssetId: 'qowner',
    type: ReferenceType.hair,
    source: ReferenceSource.imported,
    name: 'White Long Hair',
    filePath: 'hair/default.png',
    priority: 90,
    primary: true,
    enabled: true,
  );
  const hairCombat = ReferenceModel(
    id: 'hair-combat',
    projectId: 'p',
    ownerAssetId: 'qowner',
    type: ReferenceType.hair,
    source: ReferenceSource.generated,
    name: 'Combat Tied Hair',
    filePath: 'hair/combat.png',
    priority: 95,
    primary: true,
    enabled: true,
  );

  test('mode and scene references override character defaults by type', () {
    final effective = const ReferenceSetResolver().resolve(
      characterReferences: [faceMaster, hairDefault],
      modeReferences: [hairCombat],
    );
    expect(effective[ReferenceType.face]?.id, 'face-master');
    expect(effective[ReferenceType.hair]?.id, 'hair-combat');
  });

  test(
    'priority selector prefers primary then priority and respects budget',
    () {
      final selected = const ReferencePrioritySelector().select(
        references: [hairDefault, faceMaster, hairCombat],
        maxItems: 2,
      );
      expect(selected.map((item) => item.id), ['face-master', 'hair-combat']);
    },
  );

  test(
    'consistency service reports broken files and aggregates review status',
    () {
      const service = ReferenceConsistencyService();
      expect(
        service.health(faceMaster, fileExists: false),
        ReferenceHealth.broken,
      );
      expect(
        service.aggregate([
          ConsistencyReviewStatus.passed,
          ConsistencyReviewStatus.reviewRequired,
        ]),
        ConsistencyReviewStatus.reviewRequired,
      );
      expect(
        service.aggregate([
          ConsistencyReviewStatus.passed,
          ConsistencyReviewStatus.failed,
        ]),
        ConsistencyReviewStatus.failed,
      );
    },
  );
}
