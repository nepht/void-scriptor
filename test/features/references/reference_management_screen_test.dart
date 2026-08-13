import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/references/presentation/reference_management_screen.dart';

void main() {
  testWidgets(
    'management workspace exposes sets locks rules and reports responsively',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: ReferenceManagementScreen(
            ownerAssetId: 'qowner',
            initialTab: 1,
            sets: [
              ReferenceSetModel(
                id: 'set',
                projectId: 'p',
                ownerAssetId: 'qowner',
                name: 'Combat',
                defaultSet: true,
                referenceIds: ['face'],
              ),
            ],
            locks: [
              PreservationLockModel(
                id: 'lock',
                assetId: 'qowner',
                type: PreservationLockType.face,
                enabled: true,
                priority: 100,
                instruction: 'Preserve jawline.',
              ),
            ],
            rules: [
              ConsistencyRuleModel(
                id: 'rule',
                assetId: 'qowner',
                type: ConsistencyRuleType.identity,
                description: 'Face must match canon',
                severity: ConsistencySeverity.critical,
              ),
            ],
            reviews: [
              ConsistencyReviewModel(
                id: 'review',
                generationOutputId: 'output',
                assetId: 'qowner',
                status: ConsistencyReviewStatus.reviewRequired,
              ),
            ],
          ),
        ),
      );
      expect(find.text('Identity Locks'), findsOneWidget);
      expect(find.text('Preserve jawline.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
