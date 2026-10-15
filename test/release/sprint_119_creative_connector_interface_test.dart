import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_creative_connector_interface.dart';

void main() {
  final now = DateTime.utc(2026, 3, 1, 12);
  final heroImage = CreativeAsset(
    ref: AssetRef.tryParse('assetref:studio:hero-image')!,
    kind: CreativeAssetKind.image,
    rights: const CreativeRights(
      license: CreativeLicense.ccBy,
      holder: 'Studio Nine',
      allowsDerivatives: true,
      allowsCommercial: true,
    ),
    attribution: const CreativeAttribution(
      isRequired: true,
      text: 'Photo by Studio Nine',
    ),
  );
  final backgroundAudio = CreativeAsset(
    ref: AssetRef.tryParse('assetref:studio:bg-audio')!,
    kind: CreativeAssetKind.audio,
    rights: const CreativeRights(
      license: CreativeLicense.proprietary,
      holder: 'Studio Nine',
      allowsDerivatives: false,
      allowsCommercial: false,
    ),
    attribution: const CreativeAttribution(isRequired: false),
  );
  final orphanAsset = CreativeAsset(
    ref: AssetRef.tryParse('assetref:studio:orphan')!,
    kind: CreativeAssetKind.image,
    rights: const CreativeRights(
      license: CreativeLicense.unknown,
      holder: '',
      allowsDerivatives: false,
      allowsCommercial: false,
    ),
    attribution: const CreativeAttribution(isRequired: false),
  );

  const allScopes = <CreativeScope>{
    CreativeScope.read,
    CreativeScope.import,
    CreativeScope.export,
    CreativeScope.transform,
  };

  group('119.16 Creative Connector Interface', () {
    test('asset references are opaque and malformed values are rejected', () {
      expect(heroImage.ref.value, 'assetref:studio:hero-image');
      expect(heroImage.ref.toString(), '[REDACTED]');
      expect(AssetRef.tryParse('studio/hero.png'), isNull);
      expect(AssetRef.tryParse('resref:acme:tracker'), isNull);
      expect(AssetRef.tryParse('assetref:studio:hero-image'), heroImage.ref);
    });

    test('listAssets filters by kind and sorts deterministically', () {
      final listed = CreativeConnectorInterface.listAssets(<CreativeAsset>[
        backgroundAudio,
        orphanAsset,
        heroImage,
      ], kind: CreativeAssetKind.image);

      expect(listed.map((a) => a.ref.value).toList(), <String>[
        'assetref:studio:hero-image',
        'assetref:studio:orphan',
      ]);
      expect(
        CreativeConnectorInterface.listAssets(<CreativeAsset>[
          heroImage,
        ], kind: CreativeAssetKind.video),
        isEmpty,
      );
    });

    test(
      'metadata serialization redacts the asset reference and reports rights',
      () {
        final metadata = CreativeConnectorInterface.metadata(
          asset: heroImage,
          now: now,
        );

        expect(metadata['asset_ref'], '[REDACTED]');
        expect(metadata['kind'], 'image');
        expect(metadata['rights_diagnostics'], isEmpty);
        expect(
          metadata.toString(),
          isNot(contains('assetref:studio:hero-image')),
        );

        final orphanMetadata = CreativeConnectorInterface.metadata(
          asset: orphanAsset,
          now: now,
        );
        expect(
          orphanMetadata['rights_diagnostics'],
          containsAll(<String>['license_unknown', 'rights_holder_missing']),
        );
      },
    );

    test(
      'rights are validated for unknown licence, missing holder, and expiry',
      () {
        expect(
          CreativeConnectorInterface.validateRights(heroImage.rights, now: now),
          isEmpty,
        );
        expect(
          CreativeConnectorInterface.validateRights(
            const CreativeRights(
              license: CreativeLicense.cc0,
              holder: 'Studio Nine',
              allowsDerivatives: true,
              allowsCommercial: true,
              expiresAtUtc: null,
            ),
            now: now,
          ),
          isEmpty,
        );
        expect(
          CreativeConnectorInterface.validateRights(
            CreativeRights(
              license: CreativeLicense.proprietary,
              holder: 'Studio Nine',
              allowsDerivatives: false,
              allowsCommercial: false,
              expiresAtUtc: DateTime.utc(2026, 1, 1),
            ),
            now: now,
          ),
          contains('rights_expired'),
        );
      },
    );

    test(
      'attribution obligations are explicit and only satisfied by real text',
      () {
        expect(heroImage.attribution.isSatisfied, isTrue);
        expect(
          const CreativeAttribution(isRequired: true).isSatisfied,
          isFalse,
        );
        expect(
          const CreativeAttribution(isRequired: true, text: '   ').isSatisfied,
          isFalse,
        );
        expect(
          const CreativeAttribution(isRequired: false).isSatisfied,
          isTrue,
        );
      },
    );

    test('import is denied without a declared source or valid rights', () {
      expect(
        CreativeConnectorInterface.importAsset(
          asset: null,
          sourceDeclared: true,
          now: now,
        ),
        CreativeOperationResult.deniedUnknownAsset,
      );
      expect(
        CreativeConnectorInterface.importAsset(
          asset: heroImage,
          sourceDeclared: false,
          now: now,
        ),
        CreativeOperationResult.deniedUnknownSource,
      );
      expect(
        CreativeConnectorInterface.importAsset(
          asset: orphanAsset,
          sourceDeclared: true,
          now: now,
        ),
        CreativeOperationResult.deniedMissingRights,
      );
      expect(
        CreativeConnectorInterface.importAsset(
          asset: heroImage,
          sourceDeclared: true,
          now: now,
        ),
        CreativeOperationResult.ok,
      );
    });

    test(
      'export is denied without scope, attribution, or commercial rights',
      () {
        expect(
          CreativeConnectorInterface.exportWhenGranted(
            asset: heroImage,
            callerScopes: const <CreativeScope>{CreativeScope.read},
            destination: CreativeDestination.local,
            now: now,
          ),
          CreativeOperationResult.deniedMissingScope,
        );
        expect(
          CreativeConnectorInterface.exportWhenGranted(
            asset: CreativeAsset(
              ref: AssetRef.tryParse('assetref:studio:no-credit')!,
              kind: CreativeAssetKind.image,
              rights: const CreativeRights(
                license: CreativeLicense.ccBy,
                holder: 'Studio Nine',
                allowsDerivatives: true,
                allowsCommercial: true,
              ),
              attribution: const CreativeAttribution(isRequired: true),
            ),
            callerScopes: allScopes,
            destination: CreativeDestination.local,
            now: now,
          ),
          CreativeOperationResult.deniedAttributionRequired,
        );
        expect(
          CreativeConnectorInterface.exportWhenGranted(
            asset: backgroundAudio,
            callerScopes: allScopes,
            destination: CreativeDestination.commercial,
            now: now,
          ),
          CreativeOperationResult.deniedMissingRights,
        );
        expect(
          CreativeConnectorInterface.exportWhenGranted(
            asset: backgroundAudio,
            callerScopes: allScopes,
            destination: CreativeDestination.published,
            now: now,
          ),
          CreativeOperationResult.ok,
        );
      },
    );

    test(
      'transform_when_granted respects derivative rights and records lineage',
      () {
        expect(
          CreativeConnectorInterface.transformWhenGranted(
            asset: backgroundAudio,
            callerScopes: allScopes,
            now: now,
          ),
          CreativeOperationResult.deniedDerivativesNotPermitted,
        );
        expect(
          CreativeConnectorInterface.transformWhenGranted(
            asset: heroImage,
            callerScopes: const <CreativeScope>{CreativeScope.read},
            now: now,
          ),
          CreativeOperationResult.deniedMissingScope,
        );
        expect(
          CreativeConnectorInterface.transformWhenGranted(
            asset: heroImage,
            callerScopes: allScopes,
            now: now,
          ),
          CreativeOperationResult.ok,
        );

        final lineage = CreativeLineage();
        lineage.record(
          const CreativeTransform(
            id: 'crop',
            operation: 'crop_16_9',
            reversible: true,
          ),
        );
        lineage.record(
          const CreativeTransform(
            id: 'grade',
            operation: 'colour_grade',
            reversible: false,
          ),
        );

        expect(lineage.steps.map((s) => s.id).toList(), <String>[
          'crop',
          'grade',
        ]);
        expect(lineage.isOrdered, isTrue);
        expect(lineage.steps.last.reversible, isFalse);
        expect(
          () => lineage.steps.add(
            const CreativeTransform(id: 'x', operation: 'x', reversible: true),
          ),
          throwsUnsupportedError,
        );

        final duplicate = CreativeLineage()
          ..record(
            const CreativeTransform(
              id: 'crop',
              operation: 'crop',
              reversible: true,
            ),
          )
          ..record(
            const CreativeTransform(
              id: 'crop',
              operation: 'crop',
              reversible: true,
            ),
          );
        expect(duplicate.isOrdered, isFalse);
      },
    );

    test('health reports unavailable, degraded, and ok deterministically', () {
      expect(
        CreativeConnectorInterface.health(
          reachable: false,
          authorized: true,
          rightsResolved: true,
        ),
        CreativeHealth.unavailable,
      );
      expect(
        CreativeConnectorInterface.health(
          reachable: true,
          authorized: true,
          rightsResolved: false,
        ),
        CreativeHealth.degraded,
      );
      expect(
        CreativeConnectorInterface.health(
          reachable: true,
          authorized: true,
          rightsResolved: true,
        ),
        CreativeHealth.ok,
      );
    });

    test('diagnostics redact asset references', () {
      expect(
        CreativeConnectorInterface.redact('denied assetref:studio:hero-image'),
        'denied [REDACTED]',
      );
    });

    test('validates the canonical manifest and rejects missing methods', () {
      expect(CreativeConnectorInterface.validateCanonicalManifest(), isEmpty);

      final missing = <String, dynamic>{
        'canonical_step': '119.16',
        'unknown_field_policy': 'REJECT',
        'required_methods': <String>['list_assets'],
        'acceptance': <String, dynamic>{},
      };
      expect(
        CreativeConnectorInterface.validateManifest(missing),
        containsAll(<String>[
          'method_missing:export_when_granted',
          'method_missing:transform_when_granted',
          'method_missing:health',
          'acceptance_missing:rights',
        ]),
      );
    });
  });
}
