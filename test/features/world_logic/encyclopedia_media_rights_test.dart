// Sprint 111.7 - Media, Rights and Source Safety.
//
// Domain-only contract for encyclopedia media: local media records,
// source credits, license notes, missing-file state, metadata
// sanitization, and explicit opt-in export planning.
//
// No persistence, UI, locale, network, wall clock, or random input.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart";

void main() {
  group("EncyclopediaMediaAsset validated", () {
    test("rejects empty assetId", () {
      expect(
        () => EncyclopediaMediaAsset.validated(
          assetId: "  ",
          kind: MediaKind.image,
          relativePath: "assets/brands/x.webp",
        ),
        throwsArgumentError,
      );
    });

    test("rejects absolute posix path", () {
      expect(
        () => EncyclopediaMediaAsset.validated(
          assetId: "m1",
          kind: MediaKind.image,
          relativePath: "/etc/passwd",
        ),
        throwsArgumentError,
      );
    });

    test("rejects windows drive-absolute path", () {
      expect(
        () => EncyclopediaMediaAsset.validated(
          assetId: "m1",
          kind: MediaKind.audio,
          relativePath: r"C:/Users/leak.mp3",
        ),
        throwsArgumentError,
      );
    });

    test("rejects parent traversal segments", () {
      expect(
        () => EncyclopediaMediaAsset.validated(
          assetId: "m1",
          kind: MediaKind.symbol,
          relativePath: "assets/../secret.svg",
        ),
        throwsArgumentError,
      );
    });

    test("rejects non-hex contentHash", () {
      expect(
        () => EncyclopediaMediaAsset.validated(
          assetId: "m1",
          kind: MediaKind.image,
          relativePath: "assets/x.webp",
          contentHash: "xyz-not-hex",
        ),
        throwsArgumentError,
      );
    });

    test("withFileStatus returns immutable copy", () {
      final present = EncyclopediaMediaAsset.validated(
        assetId: "m1",
        kind: MediaKind.image,
        relativePath: "assets/a.webp",
      );
      final missing = present.withFileStatus(MediaFileStatus.missing);
      expect(present.fileStatus, MediaFileStatus.present);
      expect(missing.fileStatus, MediaFileStatus.missing);
      expect(identical(present, missing), isFalse);
    });
  });

  group("SourceCredit", () {
    test("rejects empty attributedTo", () {
      expect(
        () => SourceCredit.validated(
          creditId: "c1",
          attributedTo: "",
          role: MediaCreditRole.creator,
        ),
        throwsArgumentError,
      );
    });

    test("keeps role and attribution", () {
      final credit = SourceCredit.validated(
        creditId: "c1",
        attributedTo: "Studio Name",
        role: MediaCreditRole.source,
      );
      expect(credit.role, MediaCreditRole.source);
      expect(credit.attributedTo, "Studio Name");
    });
  });

  group("MediaLicense", () {
    test("custom tag without notes is rejected", () {
      expect(
        () => MediaLicense.validated(tag: MediaLicenseTag.custom),
        throwsArgumentError,
      );
    });

    test("unknown tag defaults to restrictive flags", () {
      final license = MediaLicense.validated(tag: MediaLicenseTag.unknown);
      expect(license.allowCommercial, isFalse);
      expect(license.requiresAttribution, isTrue);
    });

    test("ccBy keeps attribution requirement", () {
      final license = MediaLicense.validated(
        tag: MediaLicenseTag.ccBy,
        allowCommercial: true,
      );
      expect(license.requiresAttribution, isTrue);
      expect(license.allowCommercial, isTrue);
    });
  });

  group("MediaMetadataSanitizer", () {
    test("removes sensitive keys", () {
      final result = MediaMetadataSanitizer.sanitize(const {
        "caption": "Pole of Creation",
        "GPSLatitude": "6.2",
        "email": "someone@example.com",
      });
      expect(result.cleaned.containsKey("GPSLatitude"), isFalse);
      expect(result.cleaned.containsKey("email"), isFalse);
      expect(result.cleaned["caption"], "Pole of Creation");
      expect(result.removedKeys, containsAll(["gpslatitude", "email"]));
    });

    test("preserves metadata without sensitive keys unchanged", () {
      final result = MediaMetadataSanitizer.sanitize(const {
        "caption": "x",
        "dimensions": "1024x1024",
      });
      expect(result.removedKeys, isEmpty);
      expect(result.cleaned.length, 2);
    });
  });

  group("MediaExportPlanner", () {
    EncyclopediaMediaAsset asset(String id) => EncyclopediaMediaAsset.validated(
      assetId: id,
      kind: MediaKind.image,
      relativePath: "assets/$id.webp",
    );

    test("throws without explicit export opt-in", () {
      expect(
        () => MediaExportPlanner.plan(
          assets: [asset("a"), asset("b")],
          explicitExport: false,
        ),
        throwsArgumentError,
      );
    });

    test("plans ordered manifest on explicit opt-in", () {
      final manifest = MediaExportPlanner.plan(
        assets: [asset("b"), asset("a")],
        explicitExport: true,
      );
      expect(manifest.assetIds, ["b", "a"]);
      expect(manifest.missingAssetIds, isEmpty);
      expect(manifest.sanitizationApplied, isTrue);
    });

    test("excludes missing files by default and includes on flag", () {
      final missing = asset("gone").withFileStatus(MediaFileStatus.missing);
      final excluded = MediaExportPlanner.plan(
        assets: [asset("a"), missing],
        explicitExport: true,
      );
      expect(excluded.assetIds, ["a"]);
      expect(excluded.missingAssetIds, ["gone"]);

      final included = MediaExportPlanner.plan(
        assets: [asset("a"), missing],
        explicitExport: true,
        includeMissing: true,
      );
      expect(included.assetIds, ["a", "gone"]);
      expect(included.missingAssetIds, ["gone"]);
    });
  });

  group("EncyclopediaMediaLibrary", () {
    test("rejects duplicate assetId", () {
      final library = EncyclopediaMediaLibrary()
        ..register(
          EncyclopediaMediaAsset.validated(
            assetId: "m1",
            kind: MediaKind.image,
            relativePath: "assets/a.webp",
          ),
        );
      expect(
        () => library.register(
          EncyclopediaMediaAsset.validated(
            assetId: "m1",
            kind: MediaKind.audio,
            relativePath: "assets/b.mp3",
          ),
        ),
        throwsArgumentError,
      );
    });

    test("rejects duplicate relativePath across assets", () {
      final library = EncyclopediaMediaLibrary()
        ..register(
          EncyclopediaMediaAsset.validated(
            assetId: "m1",
            kind: MediaKind.image,
            relativePath: "assets/a.webp",
          ),
        );
      expect(
        () => library.register(
          EncyclopediaMediaAsset.validated(
            assetId: "m2",
            kind: MediaKind.image,
            relativePath: "assets/a.webp",
          ),
        ),
        throwsArgumentError,
      );
    });

    test("rejects duplicate creditId on the same asset", () {
      final library = EncyclopediaMediaLibrary()
        ..register(
          EncyclopediaMediaAsset.validated(
            assetId: "m1",
            kind: MediaKind.image,
            relativePath: "assets/a.webp",
          ),
        )
        ..attachCredit(
          "m1",
          SourceCredit.validated(
            creditId: "c1",
            attributedTo: "A",
            role: MediaCreditRole.creator,
          ),
        );
      expect(
        () => library.attachCredit(
          "m1",
          SourceCredit.validated(
            creditId: "c1",
            attributedTo: "B",
            role: MediaCreditRole.source,
          ),
        ),
        throwsArgumentError,
      );
    });

    test("markMissing records missing-file state for export", () {
      final library = EncyclopediaMediaLibrary()
        ..register(
          EncyclopediaMediaAsset.validated(
            assetId: "m1",
            kind: MediaKind.image,
            relativePath: "assets/a.webp",
          ),
        )
        ..markMissing("m1", reasonCode: "file-not-found");
      expect(library.assetById("m1")!.fileStatus, MediaFileStatus.missing);
      final manifest = library.planExport(explicitExport: true);
      expect(manifest.missingAssetIds, ["m1"]);
    });

    test("end-to-end: register, credit, license, export manifest", () {
      final library = EncyclopediaMediaLibrary()
        ..register(
          EncyclopediaMediaAsset.validated(
            assetId: "m1",
            kind: MediaKind.symbol,
            relativePath: "assets/symbols/void.svg",
          ),
        )
        ..attachCredit(
          "m1",
          SourceCredit.validated(
            creditId: "c1",
            attributedTo: "Void Studio",
            role: MediaCreditRole.creator,
          ),
        )
        ..attachLicense(
          "m1",
          MediaLicense.validated(tag: MediaLicenseTag.ccBy),
        );
      final manifest = library.planExport(explicitExport: true);
      expect(manifest.assetIds, ["m1"]);
      expect(manifest.creditsByAsset["m1"]!.single.attributedTo, "Void Studio");
      expect(manifest.licensesByAsset["m1"]!.tag, MediaLicenseTag.ccBy);
    });
  });
}
