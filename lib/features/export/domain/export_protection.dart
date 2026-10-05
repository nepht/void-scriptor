library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

enum WatermarkMode { off, previewOnly, always }

enum ProtectedAssetKind { novel, image }

enum ExportUse {
  privateMaster,
  publicPreview,
  betaReview,
  marketplacePreview,
  publishedRelease,
  purchasedOriginal,
}

enum SubscriptionTier { free, pro }

enum WatermarkPosition {
  topLeft,
  topCenter,
  topRight,
  center,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class WatermarkStyle {
  const WatermarkStyle._({
    required this.text,
    required this.logoAssetId,
    required this.position,
    required this.opacity,
    required this.scalePercent,
    required this.repeated,
  });

  final String? text;
  final String? logoAssetId;
  final WatermarkPosition position;
  final double opacity;
  final double scalePercent;
  final bool repeated;

  factory WatermarkStyle.validated({
    String? text,
    String? logoAssetId,
    required WatermarkPosition position,
    required num opacity,
    required num scalePercent,
    bool repeated = false,
  }) {
    final normalizedText = _optionalNonEmpty(text, 'text');
    final normalizedLogo = _optionalNonEmpty(logoAssetId, 'logoAssetId');
    if (normalizedText == null && normalizedLogo == null) {
      throw ArgumentError('watermark requires text or logoAssetId');
    }
    if (!opacity.isFinite || opacity <= 0 || opacity > 1) {
      throw ArgumentError.value(opacity, 'opacity', 'must be in (0, 1]');
    }
    if (!scalePercent.isFinite || scalePercent <= 0 || scalePercent > 100) {
      throw ArgumentError.value(
        scalePercent,
        'scalePercent',
        'must be in (0, 100]',
      );
    }
    return WatermarkStyle._(
      text: normalizedText,
      logoAssetId: normalizedLogo,
      position: position,
      opacity: opacity.toDouble(),
      scalePercent: scalePercent.toDouble(),
      repeated: repeated,
    );
  }
}

class WatermarkPolicy {
  const WatermarkPolicy._({
    required this.mode,
    required this.style,
    required this.personalizeForRecipient,
    required this.watermarkFreeGeneratedImages,
  });

  final WatermarkMode mode;
  final WatermarkStyle style;
  final bool personalizeForRecipient;
  final bool watermarkFreeGeneratedImages;

  factory WatermarkPolicy.validated({
    required WatermarkMode mode,
    required WatermarkStyle style,
    bool personalizeForRecipient = false,
    bool watermarkFreeGeneratedImages = false,
  }) => WatermarkPolicy._(
    mode: mode,
    style: style,
    personalizeForRecipient: personalizeForRecipient,
    watermarkFreeGeneratedImages: watermarkFreeGeneratedImages,
  );
}

class OwnershipMetadata {
  const OwnershipMetadata._({
    required this.creatorId,
    required this.projectId,
    required this.copyrightHolder,
    required this.rightsStatement,
  });

  final String creatorId;
  final String projectId;
  final String copyrightHolder;
  final String rightsStatement;

  factory OwnershipMetadata.validated({
    required String creatorId,
    required String projectId,
    required String copyrightHolder,
    required String rightsStatement,
  }) {
    _nonEmpty(creatorId, 'creatorId');
    _nonEmpty(projectId, 'projectId');
    _nonEmpty(copyrightHolder, 'copyrightHolder');
    _nonEmpty(rightsStatement, 'rightsStatement');
    return OwnershipMetadata._(
      creatorId: creatorId,
      projectId: projectId,
      copyrightHolder: copyrightHolder,
      rightsStatement: rightsStatement,
    );
  }

  Map<String, String> toJson() => <String, String>{
    'creatorId': creatorId,
    'projectId': projectId,
    'copyrightHolder': copyrightHolder,
    'rightsStatement': rightsStatement,
  };
}

class ExportProtectionRequest {
  const ExportProtectionRequest._({
    required this.assetId,
    required this.kind,
    required this.use,
    required this.tier,
    required this.generatedByApp,
    required this.contentBytes,
    required this.ownership,
    required this.exportRevision,
    required this.recipientId,
  });

  final String assetId;
  final ProtectedAssetKind kind;
  final ExportUse use;
  final SubscriptionTier tier;
  final bool generatedByApp;
  final List<int> contentBytes;
  final OwnershipMetadata ownership;
  final String exportRevision;
  final String? recipientId;

  factory ExportProtectionRequest.validated({
    required String assetId,
    required ProtectedAssetKind kind,
    required ExportUse use,
    required SubscriptionTier tier,
    required bool generatedByApp,
    required List<int> contentBytes,
    required OwnershipMetadata ownership,
    required String exportRevision,
    String? recipientId,
  }) {
    _nonEmpty(assetId, 'assetId');
    _nonEmpty(exportRevision, 'exportRevision');
    if (contentBytes.isEmpty) {
      throw ArgumentError.value(
        contentBytes,
        'contentBytes',
        'must not be empty',
      );
    }
    for (final byte in contentBytes) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(byte, 'contentBytes', 'invalid byte');
      }
    }
    return ExportProtectionRequest._(
      assetId: assetId,
      kind: kind,
      use: use,
      tier: tier,
      generatedByApp: generatedByApp,
      contentBytes: List<int>.unmodifiable(contentBytes),
      ownership: ownership,
      exportRevision: exportRevision,
      recipientId: _optionalNonEmpty(recipientId, 'recipientId'),
    );
  }
}

class WatermarkOverlay {
  const WatermarkOverlay({
    required this.text,
    required this.logoAssetId,
    required this.position,
    required this.opacity,
    required this.scalePercent,
    required this.repeated,
    required this.recipientToken,
  });

  final String? text;
  final String? logoAssetId;
  final WatermarkPosition position;
  final double opacity;
  final double scalePercent;
  final bool repeated;
  final String? recipientToken;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'logoAssetId': logoAssetId,
    'position': position.name,
    'opacity': opacity,
    'scalePercent': scalePercent,
    'repeated': repeated,
    'recipientToken': recipientToken,
  };
}

class ExportOwnershipManifest {
  const ExportOwnershipManifest._({
    required this.assetId,
    required this.assetKind,
    required this.exportUse,
    required this.exportRevision,
    required this.contentSha256,
    required this.watermarkApplied,
    required this.watermarkMode,
    required this.recipientToken,
    required this.ownership,
    required this.manifestSha256,
  });

  final String assetId;
  final ProtectedAssetKind assetKind;
  final ExportUse exportUse;
  final String exportRevision;
  final String contentSha256;
  final bool watermarkApplied;
  final WatermarkMode watermarkMode;
  final String? recipientToken;
  final OwnershipMetadata ownership;
  final String manifestSha256;

  Map<String, Object?> toJson() => <String, Object?>{
    ..._payload(
      assetId: assetId,
      assetKind: assetKind,
      exportUse: exportUse,
      exportRevision: exportRevision,
      contentSha256: contentSha256,
      watermarkApplied: watermarkApplied,
      watermarkMode: watermarkMode,
      recipientToken: recipientToken,
      ownership: ownership,
    ),
    'manifestSha256': manifestSha256,
  };

  static ExportOwnershipManifest create({
    required String assetId,
    required ProtectedAssetKind assetKind,
    required ExportUse exportUse,
    required String exportRevision,
    required String contentSha256,
    required bool watermarkApplied,
    required WatermarkMode watermarkMode,
    required String? recipientToken,
    required OwnershipMetadata ownership,
  }) {
    final payload = _payload(
      assetId: assetId,
      assetKind: assetKind,
      exportUse: exportUse,
      exportRevision: exportRevision,
      contentSha256: contentSha256,
      watermarkApplied: watermarkApplied,
      watermarkMode: watermarkMode,
      recipientToken: recipientToken,
      ownership: ownership,
    );
    return ExportOwnershipManifest._(
      assetId: assetId,
      assetKind: assetKind,
      exportUse: exportUse,
      exportRevision: exportRevision,
      contentSha256: contentSha256,
      watermarkApplied: watermarkApplied,
      watermarkMode: watermarkMode,
      recipientToken: recipientToken,
      ownership: ownership,
      manifestSha256: sha256
          .convert(utf8.encode(jsonEncode(payload)))
          .toString(),
    );
  }

  static Map<String, Object?> _payload({
    required String assetId,
    required ProtectedAssetKind assetKind,
    required ExportUse exportUse,
    required String exportRevision,
    required String contentSha256,
    required bool watermarkApplied,
    required WatermarkMode watermarkMode,
    required String? recipientToken,
    required OwnershipMetadata ownership,
  }) => <String, Object?>{
    'assetId': assetId,
    'assetKind': assetKind.name,
    'exportUse': exportUse.name,
    'exportRevision': exportRevision,
    'contentSha256': contentSha256,
    'watermarkApplied': watermarkApplied,
    'watermarkMode': watermarkMode.name,
    'recipientToken': recipientToken,
    'ownership': ownership.toJson(),
  };
}

class ExportProtectionDecision {
  const ExportProtectionDecision({
    required this.applyWatermark,
    required this.overlay,
    required this.reason,
    required this.sourceContentPreserved,
    required this.manifest,
  });

  final bool applyWatermark;
  final WatermarkOverlay? overlay;
  final String reason;
  final bool sourceContentPreserved;
  final ExportOwnershipManifest manifest;
}

class ExportProtectionPlanner {
  const ExportProtectionPlanner();

  ExportProtectionDecision plan(
    ExportProtectionRequest request,
    WatermarkPolicy policy,
  ) {
    final isOriginal =
        request.use == ExportUse.privateMaster ||
        request.use == ExportUse.purchasedOriginal;
    final freeGeneratedImage =
        policy.watermarkFreeGeneratedImages &&
        request.kind == ProtectedAssetKind.image &&
        request.generatedByApp &&
        request.tier == SubscriptionTier.free;
    final previewUse =
        request.use == ExportUse.publicPreview ||
        request.use == ExportUse.betaReview ||
        request.use == ExportUse.marketplacePreview;

    final bool applyWatermark;
    final String reason;
    if (isOriginal) {
      applyWatermark = false;
      reason = 'private master and purchased original must remain clean';
    } else if (freeGeneratedImage) {
      applyWatermark = true;
      reason = 'free app-generated image requires attribution watermark';
    } else {
      applyWatermark =
          policy.mode == WatermarkMode.always ||
          (policy.mode == WatermarkMode.previewOnly && previewUse);
      reason = applyWatermark
          ? 'watermark required by ${policy.mode.name} policy'
          : 'watermark not required for this export use';
    }

    String? recipientToken;
    if (applyWatermark && policy.personalizeForRecipient) {
      final recipientId = request.recipientId;
      if (recipientId == null) {
        throw ArgumentError(
          'recipientId is required for personalized watermarking',
        );
      }
      recipientToken = sha256
          .convert(utf8.encode(recipientId))
          .toString()
          .substring(0, 12);
    }

    final overlay = applyWatermark
        ? WatermarkOverlay(
            text: _personalizedText(policy.style.text, recipientToken),
            logoAssetId: policy.style.logoAssetId,
            position: policy.style.position,
            opacity: policy.style.opacity,
            scalePercent: policy.style.scalePercent,
            repeated: policy.style.repeated,
            recipientToken: recipientToken,
          )
        : null;
    final contentSha256 = sha256.convert(request.contentBytes).toString();
    final manifest = ExportOwnershipManifest.create(
      assetId: request.assetId,
      assetKind: request.kind,
      exportUse: request.use,
      exportRevision: request.exportRevision,
      contentSha256: contentSha256,
      watermarkApplied: applyWatermark,
      watermarkMode: policy.mode,
      recipientToken: recipientToken,
      ownership: request.ownership,
    );
    return ExportProtectionDecision(
      applyWatermark: applyWatermark,
      overlay: overlay,
      reason: reason,
      sourceContentPreserved: true,
      manifest: manifest,
    );
  }

  static String? _personalizedText(String? text, String? recipientToken) {
    if (recipientToken == null) return text;
    final prefix = text ?? 'Review copy';
    return '$prefix · Recipient $recipientToken';
  }
}

String? _optionalNonEmpty(String? value, String name) {
  if (value == null) return null;
  _nonEmpty(value, name);
  return value.trim();
}

void _nonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must be non-empty');
  }
}
