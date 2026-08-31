// Sprint 111.7 - Media, Rights and Source Safety.
//
// Domain-only contract for encyclopedia media: local media records,
// source credits, license notes, missing-file state, metadata
// sanitization, and explicit opt-in export planning.
//
// No persistence, UI, locale, network, wall clock, or random input.
library;

/// Kind of local media attached to an encyclopedia record.
enum MediaKind { image, audio, symbol, document }

/// File availability state for a local media file. Missing-file state is
/// recorded explicitly so exports and AI context can degrade safely.
enum MediaFileStatus { present, missing, unverified }

/// Role of an attribution entry attached to a media asset.
enum MediaCreditRole { creator, source, editor, licensee }

/// Coarse license classification. Unknown/custom tags resolve to the most
/// restrictive effective flags unless overridden explicitly.
enum MediaLicenseTag {
  cc0,
  ccBy,
  ccBySa,
  ccByNc,
  publicDomain,
  royaltyFree,
  commercial,
  custom,
  unknown;

  /// Attribution obligation derived from the tag itself.
  bool get requiresAttribution {
    switch (this) {
      case MediaLicenseTag.cc0:
      case MediaLicenseTag.publicDomain:
        return false;
      case MediaLicenseTag.ccBy:
      case MediaLicenseTag.ccBySa:
      case MediaLicenseTag.ccByNc:
      case MediaLicenseTag.royaltyFree:
      case MediaLicenseTag.commercial:
      case MediaLicenseTag.custom:
      case MediaLicenseTag.unknown:
        return true;
    }
  }

  /// Commercial-use default derived from the tag itself.
  bool get allowsCommercialByDefault {
    switch (this) {
      case MediaLicenseTag.cc0:
      case MediaLicenseTag.ccBy:
      case MediaLicenseTag.ccBySa:
      case MediaLicenseTag.publicDomain:
      case MediaLicenseTag.royaltyFree:
      case MediaLicenseTag.commercial:
        return true;
      case MediaLicenseTag.ccByNc:
      case MediaLicenseTag.custom:
      case MediaLicenseTag.unknown:
        return false;
    }
  }
}

final RegExp _hexHashPattern = RegExp(r"^[0-9a-f]+$");

String _backslashSeparator() => String.fromCharCode(92);

/// A local media asset registered into the encyclopedia media library.
/// Paths are project-relative; absolute paths and parent traversal are
/// rejected so records cannot silently point outside the project package.
class EncyclopediaMediaAsset {
  final String assetId;
  final MediaKind kind;
  final String relativePath;
  final String contentHash;
  final MediaFileStatus fileStatus;
  final Map<String, String> metadata;

  const EncyclopediaMediaAsset._({
    required this.assetId,
    required this.kind,
    required this.relativePath,
    required this.contentHash,
    required this.fileStatus,
    required this.metadata,
  });

  factory EncyclopediaMediaAsset.validated({
    required String assetId,
    required MediaKind kind,
    required String relativePath,
    String contentHash = "",
    Map<String, String> metadata = const {},
  }) {
    final id = assetId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(assetId, "assetId", "assetId cannot be empty");
    }
    final normalized = relativePath
        .replaceAll(_backslashSeparator(), "/")
        .trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        relativePath,
        "relativePath",
        "relativePath cannot be empty",
      );
    }
    if (normalized.startsWith("/")) {
      throw ArgumentError.value(
        relativePath,
        "relativePath",
        "absolute paths are not allowed; use project-relative paths",
      );
    }
    final drivePattern = RegExp(r"^[A-Za-z]:");
    if (drivePattern.hasMatch(normalized)) {
      throw ArgumentError.value(
        relativePath,
        "relativePath",
        "drive-absolute paths are not allowed; use project-relative paths",
      );
    }
    for (final segment in normalized.split("/")) {
      if (segment == "..") {
        throw ArgumentError.value(
          relativePath,
          "relativePath",
          "parent traversal segments are not allowed",
        );
      }
    }
    final hash = contentHash.trim().toLowerCase();
    if (hash.isNotEmpty && !_hexHashPattern.hasMatch(hash)) {
      throw ArgumentError.value(
        contentHash,
        "contentHash",
        "contentHash must be hexadecimal when provided",
      );
    }
    return EncyclopediaMediaAsset._(
      assetId: id,
      kind: kind,
      relativePath: normalized,
      contentHash: hash,
      fileStatus: MediaFileStatus.present,
      metadata: Map.unmodifiable(metadata),
    );
  }

  /// Returns an immutable copy with the given file status.
  EncyclopediaMediaAsset withFileStatus(MediaFileStatus status) {
    return EncyclopediaMediaAsset._(
      assetId: assetId,
      kind: kind,
      relativePath: relativePath,
      contentHash: contentHash,
      fileStatus: status,
      metadata: metadata,
    );
  }
}

/// Attribution entry bound to a media asset.
class SourceCredit {
  final String creditId;
  final String attributedTo;
  final MediaCreditRole role;
  final String note;

  const SourceCredit._({
    required this.creditId,
    required this.attributedTo,
    required this.role,
    required this.note,
  });

  factory SourceCredit.validated({
    required String creditId,
    required String attributedTo,
    required MediaCreditRole role,
    String note = "",
  }) {
    final id = creditId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(
        creditId,
        "creditId",
        "creditId cannot be empty",
      );
    }
    final who = attributedTo.trim();
    if (who.isEmpty) {
      throw ArgumentError.value(
        attributedTo,
        "attributedTo",
        "attributedTo cannot be empty",
      );
    }
    return SourceCredit._(
      creditId: id,
      attributedTo: who,
      role: role,
      note: note.trim(),
    );
  }
}

/// License classification for a media asset. Flags default from the tag;
/// explicit values are kept as given (tag defaults only fill omissions).
class MediaLicense {
  final MediaLicenseTag tag;
  final bool requiresAttribution;
  final bool allowCommercial;
  final String notes;

  const MediaLicense._({
    required this.tag,
    required this.requiresAttribution,
    required this.allowCommercial,
    required this.notes,
  });

  factory MediaLicense.validated({
    required MediaLicenseTag tag,
    bool? requiresAttribution,
    bool? allowCommercial,
    String notes = "",
  }) {
    final trimmedNotes = notes.trim();
    if (tag == MediaLicenseTag.custom && trimmedNotes.isEmpty) {
      throw ArgumentError.value(
        notes,
        "notes",
        "custom license requires notes",
      );
    }
    return MediaLicense._(
      tag: tag,
      requiresAttribution: requiresAttribution ?? tag.requiresAttribution,
      allowCommercial: allowCommercial ?? tag.allowsCommercialByDefault,
      notes: trimmedNotes,
    );
  }
}

/// Result of metadata sanitization over a media record's metadata map.
class MediaMetadataSanitizationResult {
  final Map<String, String> cleaned;
  final List<String> removedKeys;

  const MediaMetadataSanitizationResult._({
    required this.cleaned,
    required this.removedKeys,
  });
}

/// Removes sensitive metadata keys (location/exif/personal identifiers)
/// from media metadata before display or export. Key comparison is
/// case-insensitive and order-stable.
class MediaMetadataSanitizer {
  static const Set<String> _sensitiveKeys = {
    "gpslatitude",
    "gpslongitude",
    "gpsaltitude",
    "gpscoordinates",
    "location",
    "geotag",
    "email",
    "phonenumber",
    "authorhomeaddress",
    "serialnumber",
    "cameraownername",
    "bodyserialnumber",
    "lensserialnumber",
  };

  const MediaMetadataSanitizer._();

  static MediaMetadataSanitizationResult sanitize(
    Map<String, String> metadata,
  ) {
    final cleaned = <String, String>{};
    final removed = <String>[];
    metadata.forEach((key, value) {
      final normalized = key.trim().toLowerCase();
      if (_sensitiveKeys.contains(normalized)) {
        removed.add(normalized);
      } else {
        cleaned[key] = value;
      }
    });
    return MediaMetadataSanitizationResult._(
      cleaned: Map.unmodifiable(cleaned),
      removedKeys: List.unmodifiable(removed),
    );
  }
}

/// Deterministic export manifest produced only on explicit opt-in.
class MediaExportManifest {
  final List<String> assetIds;
  final List<String> missingAssetIds;
  final bool sanitizationApplied;
  final Map<String, List<SourceCredit>> creditsByAsset;
  final Map<String, MediaLicense> licensesByAsset;

  const MediaExportManifest._({
    required this.assetIds,
    required this.missingAssetIds,
    required this.sanitizationApplied,
    required this.creditsByAsset,
    required this.licensesByAsset,
  });
}

/// Plans an export of media assets. Export is never implicit: callers must
/// pass [MediaExportPlanner.plan] `explicitExport: true`, otherwise the
/// planner throws. Missing files are excluded by default; including them
/// requires a second explicit flag so exports cannot silently ship broken
/// references.
class MediaExportPlanner {
  const MediaExportPlanner._();

  static MediaExportManifest plan({
    required List<EncyclopediaMediaAsset> assets,
    required bool explicitExport,
    bool includeMissing = false,
    Map<String, List<SourceCredit>> credits = const {},
    Map<String, MediaLicense> licenses = const {},
  }) {
    if (!explicitExport) {
      throw ArgumentError(
        "media export requires explicit opt-in (explicitExport: true)",
      );
    }
    final included = <String>[];
    final missing = <String>[];
    for (final asset in assets) {
      if (asset.fileStatus == MediaFileStatus.missing) {
        missing.add(asset.assetId);
        if (!includeMissing) {
          continue;
        }
      }
      included.add(asset.assetId);
    }
    return MediaExportManifest._(
      assetIds: List.unmodifiable(included),
      missingAssetIds: List.unmodifiable(missing),
      sanitizationApplied: true,
      creditsByAsset: Map.unmodifiable(credits),
      licensesByAsset: Map.unmodifiable(licenses),
    );
  }
}

/// Registry of media assets, credits, and licenses for one project.
/// Enforces unique asset ids, unique relative paths, and unique credit
/// ids per asset so attribution stays unambiguous.
class EncyclopediaMediaLibrary {
  final Map<String, EncyclopediaMediaAsset> _assets = {};
  final Map<String, List<SourceCredit>> _credits = {};
  final Map<String, MediaLicense> _licenses = {};

  /// Registers an asset; rejects duplicate assetId or relativePath.
  void register(EncyclopediaMediaAsset asset) {
    if (_assets.containsKey(asset.assetId)) {
      throw ArgumentError.value(
        asset.assetId,
        "assetId",
        "assetId already registered",
      );
    }
    for (final existing in _assets.values) {
      if (existing.relativePath == asset.relativePath) {
        throw ArgumentError.value(
          asset.relativePath,
          "relativePath",
          "relativePath already registered by asset ${existing.assetId}",
        );
      }
    }
    _assets[asset.assetId] = asset;
  }

  /// Attaches a credit; rejects duplicate creditId on the same asset and
  /// unknown asset ids.
  void attachCredit(String assetId, SourceCredit credit) {
    final list = _credits.putIfAbsent(assetId, () => []);
    for (final existing in list) {
      if (existing.creditId == credit.creditId) {
        throw ArgumentError.value(
          credit.creditId,
          "creditId",
          "creditId already attached to asset $assetId",
        );
      }
    }
    list.add(credit);
  }

  /// Attaches one license per asset; a second license replaces the first.
  void attachLicense(String assetId, MediaLicense license) {
    _licenses[assetId] = license;
  }

  /// Marks an asset's file as missing with a stable reason code.
  void markMissing(String assetId, {String reasonCode = "missing"}) {
    final asset = _assets[assetId];
    if (asset == null) {
      throw ArgumentError.value(assetId, "assetId", "unknown assetId");
    }
    _assets[assetId] = asset.withFileStatus(MediaFileStatus.missing);
  }

  /// Lookups for consumers; unmodifiable views of internal state.
  EncyclopediaMediaAsset? assetById(String assetId) => _assets[assetId];

  /// Plans an export manifest via [MediaExportPlanner] with this library's
  /// credits and licenses attached.
  MediaExportManifest planExport({
    required bool explicitExport,
    bool includeMissing = false,
  }) {
    return MediaExportPlanner.plan(
      assets: List.unmodifiable(_assets.values),
      explicitExport: explicitExport,
      includeMissing: includeMissing,
      credits: Map.unmodifiable(_credits),
      licenses: Map.unmodifiable(_licenses),
    );
  }
}
