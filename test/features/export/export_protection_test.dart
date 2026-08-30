import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/export/domain/export_protection.dart';

void main() {
  WatermarkStyle style() => WatermarkStyle.validated(
    text: 'Created with Void Scriptor',
    logoAssetId: 'void-scriptor-mark',
    position: WatermarkPosition.bottomRight,
    opacity: 0.18,
    scalePercent: 12,
    repeated: false,
  );

  OwnershipMetadata ownership() => OwnershipMetadata.validated(
    creatorId: 'creator-1',
    projectId: 'novel-1',
    copyrightHolder: 'Choirudin',
    rightsStatement: 'All rights reserved',
  );

  ExportProtectionRequest request({
    ProtectedAssetKind kind = ProtectedAssetKind.novel,
    ExportUse use = ExportUse.publicPreview,
    SubscriptionTier tier = SubscriptionTier.free,
    bool generatedByApp = false,
    String? recipientId,
  }) => ExportProtectionRequest.validated(
    assetId: kind == ProtectedAssetKind.novel ? 'chapter-1' : 'cover-1',
    kind: kind,
    use: use,
    tier: tier,
    generatedByApp: generatedByApp,
    contentBytes: utf8.encode('canonical source bytes'),
    ownership: ownership(),
    exportRevision: 'export-r1',
    recipientId: recipientId,
  );

  test('private novel master remains clean even when policy is always', () {
    final decision = const ExportProtectionPlanner().plan(
      request(use: ExportUse.privateMaster),
      WatermarkPolicy.validated(mode: WatermarkMode.always, style: style()),
    );

    expect(decision.applyWatermark, isFalse);
    expect(decision.reason, contains('master'));
    expect(decision.sourceContentPreserved, isTrue);
  });

  test('preview-only policy watermarks a public novel preview', () {
    final decision = const ExportProtectionPlanner().plan(
      request(),
      WatermarkPolicy.validated(
        mode: WatermarkMode.previewOnly,
        style: style(),
      ),
    );

    expect(decision.applyWatermark, isTrue);
    expect(decision.overlay?.text, 'Created with Void Scriptor');
    expect(decision.overlay?.position, WatermarkPosition.bottomRight);
  });

  test('marketplace image preview receives the configured image overlay', () {
    final decision = const ExportProtectionPlanner().plan(
      request(
        kind: ProtectedAssetKind.image,
        use: ExportUse.marketplacePreview,
      ),
      WatermarkPolicy.validated(
        mode: WatermarkMode.previewOnly,
        style: style(),
      ),
    );

    expect(decision.applyWatermark, isTrue);
    expect(decision.manifest.assetKind, ProtectedAssetKind.image);
    expect(decision.overlay?.logoAssetId, 'void-scriptor-mark');
  });

  test('off mode keeps output clean while retaining ownership metadata', () {
    final decision = const ExportProtectionPlanner().plan(
      request(tier: SubscriptionTier.pro),
      WatermarkPolicy.validated(mode: WatermarkMode.off, style: style()),
    );

    expect(decision.applyWatermark, isFalse);
    expect(decision.manifest.ownership.copyrightHolder, 'Choirudin');
    expect(decision.manifest.contentSha256, hasLength(64));
    expect(decision.manifest.manifestSha256, hasLength(64));
  });

  test('beta-reader watermark uses an anonymized recipient token', () {
    final decision = const ExportProtectionPlanner().plan(
      request(use: ExportUse.betaReview, recipientId: 'reader@example.com'),
      WatermarkPolicy.validated(
        mode: WatermarkMode.previewOnly,
        style: style(),
        personalizeForRecipient: true,
      ),
    );

    expect(decision.applyWatermark, isTrue);
    expect(decision.overlay?.recipientToken, hasLength(12));
    expect(decision.overlay?.text, isNot(contains('reader@example.com')));
    expect(decision.manifest.recipientToken, decision.overlay?.recipientToken);
  });

  test('free app-generated image is watermarked unless it is a master', () {
    final decision = const ExportProtectionPlanner().plan(
      request(kind: ProtectedAssetKind.image, generatedByApp: true),
      WatermarkPolicy.validated(
        mode: WatermarkMode.off,
        style: style(),
        watermarkFreeGeneratedImages: true,
      ),
    );

    expect(decision.applyWatermark, isTrue);
    expect(decision.reason, contains('free'));
  });

  test('ownership manifest and digest are deterministic', () {
    const planner = ExportProtectionPlanner();
    final policy = WatermarkPolicy.validated(
      mode: WatermarkMode.previewOnly,
      style: style(),
    );

    final first = planner.plan(request(), policy).manifest;
    final second = planner.plan(request(), policy).manifest;

    expect(first.toJson(), second.toJson());
    expect(first.manifestSha256, second.manifestSha256);
  });

  test('validation rejects unsafe style values and missing recipient', () {
    expect(
      () => WatermarkStyle.validated(
        text: '',
        position: WatermarkPosition.center,
        opacity: 2,
        scalePercent: 10,
      ),
      throwsArgumentError,
    );
    expect(
      () => const ExportProtectionPlanner().plan(
        request(use: ExportUse.betaReview),
        WatermarkPolicy.validated(
          mode: WatermarkMode.previewOnly,
          style: style(),
          personalizeForRecipient: true,
        ),
      ),
      throwsArgumentError,
    );
  });
}
