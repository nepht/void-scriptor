// Sprint 111.39 — Import, Export & Portability (domain-only).
//
// Acceptance canonical: json_export, json_import, schema_validation,
// media_manifest, spoiler_sanitization, round_trip.
//
// Konsumsi TANPA duplikasi tipe:
//  - EncyclopediaRecord/EncyclopediaDomain/CanonStatus/
//    SharedEncyclopediaSchema 111.6 (shared_encyclopedia_schema.dart)
//  - EncyclopediaMediaLibrary/MediaExportPlanner/SourceCredit/
//    MediaLicense 111.7 (encyclopedia_media_rights.dart)
//  - SpoilerPolicy/SpoilerLevel 111.8 (encyclopedia_spoiler_accessibility)
//  - EncyclopediaSearchDocument + toJson/fromJson 111.37
//    (encyclopedia_unified_search.dart)
//
// Domain-only: deterministik, tanpa persistence/UI/wall-clock/random/
// network. Tidak ada file IO nyata — media manifest adalah kontrak
// domain (D-SCHEMA-01 tetap OPEN).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_portability.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

EncyclopediaRecord rec(
  String id,
  EncyclopediaDomain domain,
  String title, {
  String? category,
  CanonStatus canon = CanonStatus.canon,
  List<String> regions = const [],
}) {
  return EncyclopediaRecord.validated(
    recordId: id,
    domain: domain,
    title: title,
    taxonomyCategoryId: category,
    canonStatus: canon,
    scopeLocations: regions,
  );
}

EncyclopediaSearchDocument doc(
  String id,
  EncyclopediaDomain domain,
  String title, {
  List<String> aliases = const [],
  SpoilerLevel spoiler = SpoilerLevel.safe,
  String? category,
}) {
  return EncyclopediaSearchDocument.validated(
    record: rec(id, domain, title, category: category),
    aliases: aliases,
    spoilerLevel: spoiler,
  );
}

final keepOptions = EncyclopediaExportOptions(explicitExport: true);

EncyclopediaMediaLibrary mediaLib({bool markOneMissing = false}) {
  final lib = EncyclopediaMediaLibrary();
  lib.register(
    EncyclopediaMediaAsset.validated(
      assetId: 'm1',
      kind: MediaKind.image,
      relativePath: 'assets/references/m1.png',
      contentHash: 'abc123',
    ),
  );
  lib.register(
    EncyclopediaMediaAsset.validated(
      assetId: 'm2',
      kind: MediaKind.document,
      relativePath: 'assets/references/m2.txt',
    ),
  );
  lib.attachCredit(
    'm1',
    SourceCredit.validated(
      creditId: 'c1',
      attributedTo: 'Studio Void',
      role: MediaCreditRole.creator,
    ),
  );
  lib.attachLicense('m1', MediaLicense.validated(tag: MediaLicenseTag.ccBy));
  if (markOneMissing) {
    lib.markMissing('m2');
  }
  return lib;
}

void main() {
  group('format contract', () {
    test('current format version is a stable literal', () {
      expect(EncyclopediaPortabilityFormat.currentVersion, '1.0');
      expect(
        EncyclopediaPortabilityFormat.supportedVersions,
        contains(EncyclopediaPortabilityFormat.currentVersion),
      );
    });

    test('major version support check', () {
      expect(EncyclopediaPortabilityFormat.isVersionSupported('1.0'), isTrue);
      expect(EncyclopediaPortabilityFormat.isVersionSupported('1.4'), isTrue);
      expect(EncyclopediaPortabilityFormat.isVersionSupported('2.0'), isFalse);
      expect(EncyclopediaPortabilityFormat.isVersionSupported('0.9'), isFalse);
      expect(EncyclopediaPortabilityFormat.isVersionSupported('nope'), isFalse);
    });
  });

  group('export options (explicit opt-in)', () {
    test('export requires explicit opt-in', () {
      EncyclopediaExportOptions(explicitExport: false);
      expect(
        () => EncyclopediaPortabilityService.buildBundle(
          documents: [doc('r1', EncyclopediaDomain.herbology, 'Void Fern')],
          options: EncyclopediaExportOptions(explicitExport: false),
        ),
        throwsArgumentError,
      );
    });

    test('mask and drop require a spoiler policy', () {
      expect(
        () => EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
        ),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.drop,
        ),
        throwsArgumentError,
      );
    });

    test('keep ignores missing policy', () {
      final options = EncyclopediaExportOptions(explicitExport: true);
      expect(options.spoilerMode, SpoilerSanitizationMode.keep);
      expect(options.spoilerPolicy, isNull);
    });
  });

  group('json_export: bundle construction', () {
    test('documents are sorted by recordId, not insertion order', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc('zeta', EncyclopediaDomain.idioms, 'Zzz'),
          doc('alpha', EncyclopediaDomain.bestiary, 'Aaa'),
        ],
        options: keepOptions,
      );
      expect(bundle.recordIds, ['alpha', 'zeta']);
    });

    test('duplicate record ids are rejected', () {
      expect(
        () => EncyclopediaPortabilityService.buildBundle(
          documents: [
            doc('dup', EncyclopediaDomain.names, 'One'),
            doc('dup', EncyclopediaDomain.mythTheology, 'Two'),
          ],
          options: keepOptions,
        ),
        throwsStateError,
      );
    });

    test('empty bundle is a legal export', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: const [],
        options: keepOptions,
      );
      expect(bundle.documents, isEmpty);
      expect(bundle.mediaManifest.assetIds, isEmpty);
    });

    test('exportText produces decodable JSON with all six sections', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r1', EncyclopediaDomain.herbology, 'Void Fern')],
        options: keepOptions,
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      final map = jsonDecode(text) as Map<String, Object?>;
      expect(
        map.keys,
        containsAll(<String>[
          'formatVersion',
          'documents',
          'mediaManifest',
          'spoilerSanitization',
          'checksum',
        ]),
      );
      expect(map['formatVersion'], '1.0');
    });

    test('input documents are never mutated by export (no-auto-canon)', () {
      final original = [
        doc(
          'r1',
          EncyclopediaDomain.herbology,
          'Void Fern',
          aliases: const ['fern'],
        ),
        doc(
          'r2',
          EncyclopediaDomain.bestiary,
          'Cube Beast',
          spoiler: SpoilerLevel.ending,
        ),
      ];
      final before = original.map((d) => jsonEncode(d.toJson())).toList();
      EncyclopediaPortabilityService.buildBundle(
        documents: original,
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.mild),
        ),
      );
      final after = original.map((d) => jsonEncode(d.toJson())).toList();
      expect(after, before);
    });
  });

  group('media_manifest', () {
    test('manifest carries explicit planner output incl. credits/licenses', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: const [],
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      final manifest = bundle.mediaManifest;
      expect(manifest.assetIds, ['m1', 'm2']);
      expect(manifest.missingAssetIds, isEmpty);
      expect(manifest.sanitizationApplied, isTrue);
      expect(manifest.creditsByAsset['m1'], hasLength(1));
      expect(manifest.licensesByAsset['m1']!.tag, MediaLicenseTag.ccBy);
    });

    test('missing assets are excluded by default and listed separately', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: const [],
        options: keepOptions,
        mediaLibrary: mediaLib(markOneMissing: true),
      );
      expect(bundle.mediaManifest.assetIds, ['m1']);
      expect(bundle.mediaManifest.missingAssetIds, ['m2']);
    });

    test('includeMissingMedia keeps them exported with a warning', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: const [],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          includeMissingMedia: true,
        ),
        mediaLibrary: mediaLib(markOneMissing: true),
      );
      expect(bundle.mediaManifest.assetIds, containsAll(['m1', 'm2']));
      expect(bundle.mediaManifest.missingAssetIds, ['m2']);
      expect(bundle.mediaManifest.includedMissing, contains('m2'));
    });

    test('manifest validated rejects duplicate asset ids', () {
      expect(
        () => ExportMediaManifest.validated(
          assetIds: const ['a', 'a'],
          sanitizationApplied: true,
        ),
        throwsArgumentError,
      );
    });

    test('manifest requires sanitizationApplied true (media safety gate)', () {
      expect(
        () => ExportMediaManifest.validated(
          assetIds: const ['a'],
          sanitizationApplied: false,
        ),
        throwsArgumentError,
      );
    });

    test('license without any credit is an attribution warning', () {
      final manifest = ExportMediaManifest.validated(
        assetIds: const ['a'],
        licensesByAsset: {
          'a': MediaLicense.validated(tag: MediaLicenseTag.ccBy),
        },
      );
      expect(manifest.attributionWarnings, ['a']);
      final clean = ExportMediaManifest.validated(
        assetIds: const ['a'],
        creditsByAsset: {
          'a': [
            SourceCredit.validated(
              creditId: 'c',
              attributedTo: 'X',
              role: MediaCreditRole.creator,
            ),
          ],
        },
        licensesByAsset: {
          'a': MediaLicense.validated(tag: MediaLicenseTag.ccBy),
        },
      );
      expect(clean.attributionWarnings, isEmpty);
    });

    test('manifest JSON round-trip is byte-identical', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: const [],
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      final map = bundle.mediaManifest.toJson();
      final back = ExportMediaManifest.fromJson(map);
      expect(jsonEncode(back.toJson()), jsonEncode(map));
      expect(back.assetIds, bundle.mediaManifest.assetIds);
      expect(back.licensesByAsset['m1']!.requiresAttribution, isTrue);
    });
  });

  group('spoiler_sanitization', () {
    test('mask hides title and aliases of records above policy', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc('safe', EncyclopediaDomain.mythTheology, 'Hearth Myth'),
          doc(
            'end',
            EncyclopediaDomain.mythTheology,
            'Void Truth',
            aliases: const ['the last page'],
            spoiler: SpoilerLevel.ending,
          ),
        ],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.mild),
        ),
      );
      expect(bundle.spoilerSanitization.maskedRecordIds, ['end']);
      expect(bundle.spoilerSanitization.droppedRecordIds, isEmpty);
      final masked = bundle.documentFor('end')!;
      expect(masked.title, kEncyclopediaSpoilerMaskTitle);
      expect(masked.aliases, isEmpty);
      expect(masked.record.domain, EncyclopediaDomain.mythTheology);
      expect(bundle.documentFor('safe')!.title, 'Hearth Myth');
    });

    test('per-record override beats the default during sanitization', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc(
            'end',
            EncyclopediaDomain.artifacts,
            'The Ring',
            spoiler: SpoilerLevel.ending,
          ),
        ],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(
            defaultLevel: SpoilerLevel.safe,
            overrides: const {'end': SpoilerLevel.ending},
          ),
        ),
      );
      expect(bundle.spoilerSanitization.maskedRecordIds, isEmpty);
      expect(bundle.documentFor('end')!.title, 'The Ring');
    });

    test('masking is idempotent (sanitized level becomes safe)', () {
      final first = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc(
            'end',
            EncyclopediaDomain.artifacts,
            'The Ring',
            aliases: const ['one'],
            spoiler: SpoilerLevel.ending,
          ),
        ],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
        ),
      );
      final again = EncyclopediaPortabilityService.buildBundle(
        documents: first.documents,
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
        ),
      );
      expect(again.spoilerSanitization.maskedRecordIds, isEmpty);
      expect(again.documentFor('end')!.title, kEncyclopediaSpoilerMaskTitle);
    });

    test('drop removes records entirely and logs them', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc('safe', EncyclopediaDomain.idioms, 'Proverb'),
          doc(
            'big',
            EncyclopediaDomain.idioms,
            'Regicide Saying',
            spoiler: SpoilerLevel.major,
          ),
        ],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.drop,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
        ),
      );
      expect(bundle.recordIds, ['safe']);
      expect(bundle.spoilerSanitization.droppedRecordIds, ['big']);
      expect(bundle.documentFor('big'), isNull);
    });

    test('keep mode leaves everything visible', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc(
            'end',
            EncyclopediaDomain.bestiary,
            'Final Boss',
            spoiler: SpoilerLevel.ending,
          ),
        ],
        options: keepOptions,
      );
      expect(bundle.documentFor('end')!.title, 'Final Boss');
      expect(bundle.spoilerSanitization.mode, SpoilerSanitizationMode.keep);
    });

    test('section JSON round-trip and unknown mode rejection', () {
      final section = SpoilerSanitizationSection.validated(
        mode: SpoilerSanitizationMode.mask,
        maskedRecordIds: ['a', 'b'],
      );
      final map = section.toJson();
      expect(SpoilerSanitizationSection.fromJson(map).maskedRecordIds, [
        'a',
        'b',
      ]);
      expect(
        () => SpoilerSanitizationSection.fromJson({
          'mode': 'teleport',
          'maskedRecordIds': <String>[],
        }),
        throwsArgumentError,
      );
      expect(
        () => SpoilerSanitizationSection.validated(
          mode: SpoilerSanitizationMode.keep,
          maskedRecordIds: const ['a'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('canonical json + checksum', () {
    test('canonical text is stable across rebuilds', () {
      final a = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc('r2', EncyclopediaDomain.names, 'B'),
          doc('r1', EncyclopediaDomain.herbology, 'A'),
        ],
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      final b = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc('r1', EncyclopediaDomain.herbology, 'A'),
          doc('r2', EncyclopediaDomain.names, 'B'),
        ],
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      expect(
        EncyclopediaPortabilityService.exportText(a),
        EncyclopediaPortabilityService.exportText(b),
      );
      expect(a.checksum, b.checksum);
    });

    test('top-level keys appear in sorted order', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r1', EncyclopediaDomain.herbology, 'A')],
        options: keepOptions,
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      final idx = <String>[
        'checksum',
        'documents',
        'formatVersion',
        'mediaManifest',
        'spoilerSanitization',
      ].map(text.indexOf).toList();
      final sorted = [...idx]..sort();
      expect(idx, sorted);
    });

    test('checksum is 16 lowercase hex chars and verifiable', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r1', EncyclopediaDomain.herbology, 'A')],
        options: keepOptions,
      );
      expect(bundle.checksum, matches(RegExp(r'^[0-9a-f]{16}$')));
      final text = EncyclopediaPortabilityService.exportText(bundle);
      expect(EncyclopediaPortabilityService.verifyChecksum(text), isTrue);
    });

    test('tampering payload breaks checksum verification', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r1', EncyclopediaDomain.herbology, 'A')],
        options: keepOptions,
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      final tampered = text.replaceAll('"A"', '"B"');
      expect(EncyclopediaPortabilityService.verifyChecksum(tampered), isFalse);
    });
  });

  group('schema_validation report', () {
    PortabilityValidationReport validate(Map<String, Object?> json) =>
        EncyclopediaPortabilityService.validateJson(jsonEncode(json));

    test('healthy bundle has no issues', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r1', EncyclopediaDomain.herbology, 'A')],
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      final report = EncyclopediaPortabilityService.validateJsonText(
        EncyclopediaPortabilityService.exportText(bundle),
      );
      expect(report.hasBlockingIssues, isFalse);
      expect(report.issues, isEmpty);
    });

    test('unsupported format version is blocking', () {
      final report = validate({
        'formatVersion': '9.9',
        'documents': <Object?>[],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': true,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': <String, Object?>{},
        },
        'spoilerSanitization': {
          'mode': 'keep',
          'maskedRecordIds': <Object?>[],
          'droppedRecordIds': <Object?>[],
        },
      });
      expect(report.hasBlockingIssues, isTrue);
      expect(
        report
            .issuesOfKind(PortabilityValidationKind.unsupportedFormat)
            .single
            .severity,
        PortabilitySeverity.blocking,
      );
    });

    test('missing required sections are reported', () {
      final report = validate({'formatVersion': '1.0'});
      final paths = report.issues.map((i) => i.path).toList();
      expect(paths, containsAll(['documents', 'mediaManifest']));
    });

    test('malformed document entry reported at index path', () {
      final report = validate({
        'formatVersion': '1.0',
        'documents': [
          {'recordId': 'ok', 'domainId': 'herbology', 'title': 'T'},
          {'recordId': 'bad'},
        ],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': true,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': <String, Object?>{},
        },
        'spoilerSanitization': {
          'mode': 'keep',
          'maskedRecordIds': <Object?>[],
          'droppedRecordIds': <Object?>[],
        },
      });
      final paths = report.issues
          .where((i) => i.path.startsWith('documents['))
          .map((i) => i.path)
          .toList();
      expect(paths, contains('documents[1]'));
    });

    test('duplicate record ids inside payload are blocking', () {
      final report = validate({
        'formatVersion': '1.0',
        'documents': [
          doc('d1', EncyclopediaDomain.herbology, 'A').toJson(),
          doc('d1', EncyclopediaDomain.herbology, 'B').toJson(),
        ],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': true,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': <String, Object?>{},
        },
        'spoilerSanitization': {
          'mode': 'keep',
          'maskedRecordIds': <Object?>[],
          'droppedRecordIds': <Object?>[],
        },
      });
      expect(
        report.issuesOfKind(PortabilityValidationKind.duplicateRecord),
        isNotEmpty,
      );
    });

    test('masked ids must exist among documents', () {
      final report = validate({
        'formatVersion': '1.0',
        'documents': <Object?>[],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': true,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': <String, Object?>{},
        },
        'spoilerSanitization': {
          'mode': 'mask',
          'maskedRecordIds': ['ghost'],
          'droppedRecordIds': <Object?>[],
        },
      });
      expect(
        report.issuesOfKind(PortabilityValidationKind.sanitizationIntegrity),
        isNotEmpty,
      );
    });

    test('dropped ids must NOT exist among documents', () {
      final report = validate({
        'formatVersion': '1.0',
        'documents': [doc('here', EncyclopediaDomain.herbology, 'A').toJson()],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': true,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': <String, Object?>{},
        },
        'spoilerSanitization': {
          'mode': 'drop',
          'maskedRecordIds': <Object?>[],
          'droppedRecordIds': ['here'],
        },
      });
      expect(
        report.issuesOfKind(PortabilityValidationKind.sanitizationIntegrity),
        isNotEmpty,
      );
    });

    test('unsanitized media manifest is blocking', () {
      final report = validate({
        'formatVersion': '1.0',
        'documents': <Object?>[],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': false,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': <String, Object?>{},
        },
        'spoilerSanitization': {
          'mode': 'keep',
          'maskedRecordIds': <Object?>[],
          'droppedRecordIds': <Object?>[],
        },
      });
      expect(
        report.issuesOfKind(PortabilityValidationKind.mediaUnsanitized),
        isNotEmpty,
      );
    });

    test('license for unknown asset is a warning, not blocking', () {
      final report = validate({
        'formatVersion': '1.0',
        'documents': <Object?>[],
        'mediaManifest': {
          'assetIds': <Object?>[],
          'missingAssetIds': <Object?>[],
          'sanitizationApplied': true,
          'creditsByAsset': <String, Object?>{},
          'licensesByAsset': {
            'ghost': {
              'tag': 'cc0',
              'requiresAttribution': false,
              'allowCommercial': true,
              'notes': '',
            },
          },
        },
        'spoilerSanitization': {
          'mode': 'keep',
          'maskedRecordIds': <Object?>[],
          'droppedRecordIds': <Object?>[],
        },
      });
      expect(report.hasBlockingIssues, isFalse);
      expect(report.warnings, isNotEmpty);
      expect(
        report.warnings.first.kind,
        PortabilityValidationKind.mediaUnknownAsset,
      );
    });

    test('checksum mismatch is reported when checksum present', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r1', EncyclopediaDomain.herbology, 'A')],
        options: keepOptions,
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      expect(
        EncyclopediaPortabilityService.validateJsonText(text).hasBlockingIssues,
        isFalse,
      );
      final tampered = text.replaceAll('"A"', '"B"');
      final report = EncyclopediaPortabilityService.validateJsonText(tampered);
      expect(
        report.issuesOfKind(PortabilityValidationKind.checksumMismatch),
        isNotEmpty,
      );
    });

    test('not-json text is blocking malformedJson', () {
      final report = EncyclopediaPortabilityService.validateJsonText(
        '{not json',
      );
      expect(report.hasBlockingIssues, isTrue);
      expect(
        report.issuesOfKind(PortabilityValidationKind.malformedJson),
        isNotEmpty,
      );
    });

    test('issue ids are stable and describe() mentions kinds', () {
      final report = validate({'formatVersion': '1.0'});
      final again = validate({'formatVersion': '1.0'});
      expect(
        report.issues.map((i) => i.issueId).toList(),
        again.issues.map((i) => i.issueId).toList(),
      );
      expect(report.describe(), isNotEmpty);
      expect(report.describe(), isNot('No import issues.'));
    });
  });

  group('json_import', () {
    test('valid bundle imports into documents + registry', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc('r2', EncyclopediaDomain.idioms, 'Say', category: 'c2'),
          doc('r1', EncyclopediaDomain.herbology, 'Fern', category: 'c1'),
        ],
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      final result = EncyclopediaPortabilityService.importText(
        EncyclopediaPortabilityService.exportText(bundle),
      );
      expect(result.documents.map((d) => d.recordId), ['r1', 'r2']);
      expect(result.registry.totalRecords, 2);
      expect(result.registry.recordFor('r1')!.title, 'Fern');
      expect(result.report.hasBlockingIssues, isFalse);
    });

    test('imported document equality survives decode', () {
      final original = doc(
        'r1',
        EncyclopediaDomain.bestiary,
        'Cube Beast',
        aliases: const ['cube'],
        category: 'beasts',
      );
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [original],
        options: keepOptions,
      );
      final result = EncyclopediaPortabilityService.importText(
        EncyclopediaPortabilityService.exportText(bundle),
      );
      expect(result.documents.single, original);
    });

    test('blocking validation aborts import with StateError', () {
      expect(
        () => EncyclopediaPortabilityService.importText('{"format":"broken"}'),
        throwsStateError,
      );
    });

    test('warnings do not abort import', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: const [],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          includeMissingMedia: true,
        ),
        mediaLibrary: mediaLib(markOneMissing: true),
      );
      final result = EncyclopediaPortabilityService.importText(
        EncyclopediaPortabilityService.exportText(bundle),
      );
      expect(result.registry.totalRecords, 0);
      expect(result.bundle.mediaManifest.includedMissing, ['m2']);
    });

    test('import of masked bundle keeps masks without re-sanitizing', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc(
            'end',
            EncyclopediaDomain.artifacts,
            'The Ring',
            aliases: const ['precious'],
            spoiler: SpoilerLevel.ending,
          ),
        ],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
        ),
      );
      final result = EncyclopediaPortabilityService.importText(
        EncyclopediaPortabilityService.exportText(bundle),
      );
      expect(
        result.bundle.documentFor('end')!.title,
        kEncyclopediaSpoilerMaskTitle,
      );
      expect(result.bundle.spoilerSanitization.maskedRecordIds, ['end']);
      expect(
        result.registry.recordFor('end')!.title,
        kEncyclopediaSpoilerMaskTitle,
      );
    });
  });

  group('round_trip', () {
    test('export -> import -> export is byte-identical', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [
          doc(
            'a',
            EncyclopediaDomain.herbology,
            'Void Fern',
            aliases: const ['ghost fern'],
          ),
          doc(
            'b',
            EncyclopediaDomain.mythTheology,
            'Pole Myth',
            spoiler: SpoilerLevel.major,
          ),
        ],
        options: EncyclopediaExportOptions(
          explicitExport: true,
          spoilerMode: SpoilerSanitizationMode.mask,
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.mild),
        ),
        mediaLibrary: mediaLib(markOneMissing: true),
      );
      final text1 = EncyclopediaPortabilityService.exportText(bundle);
      final result = EncyclopediaPortabilityService.importText(text1);
      final text2 = EncyclopediaPortabilityService.exportText(result.bundle);
      expect(text2, text1);
    });

    test('round trip preserves document set exactly in keep mode', () {
      final docs = [
        doc('x', EncyclopediaDomain.names, 'Kael', aliases: const ['kael']),
        doc('y', EncyclopediaDomain.idioms, 'Iron Proverb'),
      ];
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: docs,
        options: keepOptions,
        mediaLibrary: mediaLib(),
      );
      final back = EncyclopediaPortabilityService.importText(
        EncyclopediaPortabilityService.exportText(bundle),
      );
      expect(back.documents, docs);
      expect(back.bundle.mediaManifest.assetIds, ['m1', 'm2']);
    });

    test('roundTripText helper equals double-pass text', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [doc('r', EncyclopediaDomain.artifacts, 'Cube')],
        options: keepOptions,
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      expect(EncyclopediaPortabilityService.roundTripText(text), text);
    });
  });
}
