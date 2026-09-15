// Sprint 111.39 — Import, Export & Portability.
//
// Domain-only contract untuk pertukaran data ensiklopedia Wave 3:
// json_export, json_import, schema_validation, media_manifest,
// spoiler_sanitization, round_trip.
//
// Konsumsi TANPA duplikasi tipe:
//  - EncyclopediaRecord / EncyclopediaDomain / CanonStatus /
//    SharedEncyclopediaSchema 111.6 (shared_encyclopedia_schema.dart)
//  - EncyclopediaMediaLibrary / MediaExportPlanner / SourceCredit /
//    MediaLicense / MediaCreditRole 111.7 (encyclopedia_media_rights.dart)
//  - SpoilerPolicy / SpoilerLevel 111.8
//    (encyclopedia_spoiler_accessibility.dart)
//  - EncyclopediaSearchDocument + toJson/fromJson 111.37
//    (encyclopedia_unified_search.dart)
//
// Tanpa persistence/UI/wall-clock/random/network; media manifest adalah
// kontrak domain (D-SCHEMA-01 tetap OPEN), tidak ada file IO nyata.
import 'dart:convert';

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

const int _mask64 = 0xFFFFFFFFFFFFFFFF;

/// Hash 64-bit FNV-1a atas UTF-8 — deterministik lintas proses (pola 111.31).
int _fnv1a64(String input) {
  var hash = 0xCBF29CE484222325;
  for (final unit in utf8.encode(input)) {
    hash = ((hash ^ unit) * 0x100000001B3) & _mask64;
  }
  return hash;
}

/// Enam belas digit hex stabil: dua paruh 32-bit (menghindari tanda minus
/// pada int 64-bit negatif di VM Dart).
String _hex16(int value) {
  final high = (value >> 32) & 0xFFFFFFFF;
  final low = value & 0xFFFFFFFF;
  return high.toRadixString(16).padLeft(8, '0') +
      low.toRadixString(16).padLeft(8, '0');
}

/// Judul pengganti untuk entri ter-mask; konstan agar round-trip stabil.
const String kEncyclopediaSpoilerMaskTitle = '[Spoiler terlindungi]';

String _requireTrimmed(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, field, '$field must be non-empty');
  }
  return trimmed;
}

List<String> _immutableIds(List<String> raw, String field) {
  final seen = <String>{};
  final cleaned = <String>[];
  for (final value in raw) {
    final trimmed = _requireTrimmed(value, field);
    if (!seen.add(trimmed)) {
      throw ArgumentError.value(trimmed, field, 'duplicate $field: $trimmed');
    }
    cleaned.add(trimmed);
  }
  return List.unmodifiable(cleaned);
}

/// Encode JSON kanonik: key map diurut rekursif, tanpa spasi tambahan.
/// Semua checksum dan perbandingan byte-identity memakai bentuk ini.
String _canonicalEncode(Object? value) {
  final buffer = StringBuffer();
  _writeCanonical(value, buffer);
  return buffer.toString();
}

void _writeCanonical(Object? value, StringBuffer buffer) {
  if (value == null) {
    buffer.write('null');
    return;
  }
  if (value is bool) {
    buffer.write(value ? 'true' : 'false');
    return;
  }
  if (value is num || value is String) {
    buffer.write(jsonEncode(value));
    return;
  }
  if (value is List) {
    buffer.write('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) buffer.write(',');
      _writeCanonical(value[i], buffer);
    }
    buffer.write(']');
    return;
  }
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    buffer.write('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(jsonEncode(keys[i]));
      buffer.write(':');
      _writeCanonical(value[keys[i]], buffer);
    }
    buffer.write('}');
    return;
  }
  buffer.write(jsonEncode(value.toString()));
}

/// Versi format bundel portabilitas. Kompatibilitas dinilai per major.
class EncyclopediaPortabilityFormat {
  const EncyclopediaPortabilityFormat._();

  static const String currentVersion = '1.0';
  static const List<String> supportedVersions = ['1.0'];
  static const int _currentMajor = 1;

  /// Major harus sama; minor lebih baru dianggap kompatibel selama major
  /// sama, versi tidak terparsing ditolak.
  static bool isVersionSupported(String value) {
    final dot = value.indexOf('.');
    if (dot <= 0) return false;
    final major = int.tryParse(value.substring(0, dot));
    if (major == null) return false;
    return major == _currentMajor;
  }
}

/// Mode sanitasi spoiler saat ekspor.
enum SpoilerSanitizationMode {
  keep,
  mask,
  drop;

  static SpoilerSanitizationMode fromName(Object? raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    for (final mode in SpoilerSanitizationMode.values) {
      if (mode.name == value) return mode;
    }
    throw ArgumentError.value(raw, 'mode', 'unknown spoiler sanitization mode');
  }
}

/// Opsi ekspor. Export tidak pernah implisit: [explicitExport] wajib true,
/// dan mode sanitasi spoiler wajib membawa [spoilerPolicy].
class EncyclopediaExportOptions {
  EncyclopediaExportOptions({
    required this.explicitExport,
    this.spoilerMode = SpoilerSanitizationMode.keep,
    this.spoilerPolicy,
    this.includeMissingMedia = false,
  }) {
    if (spoilerMode != SpoilerSanitizationMode.keep && spoilerPolicy == null) {
      throw ArgumentError.value(
        spoilerMode,
        'spoilerMode',
        'spoiler sanitization requires a spoilerPolicy',
      );
    }
  }

  final bool explicitExport;
  final SpoilerSanitizationMode spoilerMode;
  final SpoilerPolicy? spoilerPolicy;
  final bool includeMissingMedia;
}

/// Bagian laporan sanitasi yang ikut tersimpan dalam bundel.
class SpoilerSanitizationSection {
  SpoilerSanitizationSection._({
    required this.mode,
    required this.maskedRecordIds,
    required this.droppedRecordIds,
  });

  factory SpoilerSanitizationSection.validated({
    required SpoilerSanitizationMode mode,
    List<String> maskedRecordIds = const [],
    List<String> droppedRecordIds = const [],
  }) {
    final masked = _immutableIds(maskedRecordIds, 'maskedRecordId');
    final dropped = _immutableIds(droppedRecordIds, 'droppedRecordId');
    if (mode == SpoilerSanitizationMode.keep &&
        (masked.isNotEmpty || dropped.isNotEmpty)) {
      throw ArgumentError.value(
        mode,
        'mode',
        'keep mode must not report masked or dropped records',
      );
    }
    return SpoilerSanitizationSection._(
      mode: mode,
      maskedRecordIds: masked,
      droppedRecordIds: dropped,
    );
  }

  factory SpoilerSanitizationSection.fromJson(Map<String, Object?> json) {
    final mode = SpoilerSanitizationMode.fromName(json['mode']);
    return SpoilerSanitizationSection.validated(
      mode: mode,
      maskedRecordIds: _jsonStrings(json['maskedRecordIds']),
      droppedRecordIds: _jsonStrings(json['droppedRecordIds']),
    );
  }

  final SpoilerSanitizationMode mode;
  final List<String> maskedRecordIds;
  final List<String> droppedRecordIds;

  bool get applied => mode != SpoilerSanitizationMode.keep;

  Map<String, Object?> toJson() => <String, Object?>{
    'droppedRecordIds': List<String>.from(droppedRecordIds),
    'maskedRecordIds': List<String>.from(maskedRecordIds),
    'mode': mode.name,
  };
}

List<String> _jsonStrings(Object? raw, {String field = 'list'}) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw ArgumentError.value(raw, field, '$field must be a list');
  }
  return raw.map((e) {
    if (e is! String) {
      throw ArgumentError.value(e, field, 'entries must be strings');
    }
    return e;
  }).toList();
}

Map<String, Object?> _objectMap(Object? raw, String field) {
  if (raw is! Map) {
    throw ArgumentError.value(raw, field, '$field must be an object');
  }
  return <String, Object?>{
    for (final entry in raw.entries) entry.key.toString(): entry.value,
  };
}

/// Manifest media dalam bundel. Kontrak JSON dari planner 111.7 —
/// TANPA file IO nyata; sanitizationApplied wajib true.
class ExportMediaManifest {
  ExportMediaManifest._({
    required this.assetIds,
    required this.missingAssetIds,
    required this.sanitizationApplied,
    required this.includedMissing,
    required this.creditsByAsset,
    required this.licensesByAsset,
  });

  factory ExportMediaManifest.validated({
    required List<String> assetIds,
    List<String> missingAssetIds = const [],
    bool sanitizationApplied = true,
    List<String> includedMissing = const [],
    Map<String, List<SourceCredit>> creditsByAsset = const {},
    Map<String, MediaLicense> licensesByAsset = const {},
  }) {
    final ids = _immutableIds(assetIds, 'assetId');
    final missing = _immutableIds(missingAssetIds, 'missingAssetId');
    final included = _immutableIds(includedMissing, 'includedMissingAssetId');
    if (!sanitizationApplied) {
      throw ArgumentError.value(
        sanitizationApplied,
        'sanitizationApplied',
        'media manifest requires metadata sanitization to be applied',
      );
    }
    return ExportMediaManifest._(
      assetIds: ids,
      missingAssetIds: missing,
      sanitizationApplied: true,
      includedMissing: included,
      creditsByAsset: _freezeCredits(creditsByAsset),
      licensesByAsset: Map.unmodifiable(licensesByAsset),
    );
  }

  /// Membungkus output planner 111.7; includedMissing = aset missing yang
  /// sengaja ikut diekspor (opsi includeMissingMedia).
  factory ExportMediaManifest.fromPlanner(
    MediaExportManifest plan, {
    required bool includeMissing,
  }) {
    final included = <String>[
      if (includeMissing)
        for (final id in plan.missingAssetIds)
          if (plan.assetIds.contains(id)) id,
    ];
    return ExportMediaManifest.validated(
      assetIds: plan.assetIds,
      missingAssetIds: plan.missingAssetIds,
      sanitizationApplied: plan.sanitizationApplied,
      includedMissing: included,
      creditsByAsset: plan.creditsByAsset,
      licensesByAsset: plan.licensesByAsset,
    );
  }

  factory ExportMediaManifest.fromJson(Map<String, Object?> json) {
    final credits = <String, List<SourceCredit>>{};
    final creditsRaw = json['creditsByAsset'];
    if (creditsRaw is Map) {
      for (final entry in creditsRaw.entries) {
        final list = entry.value;
        if (list is! List) {
          throw ArgumentError.value(
            list,
            'creditsByAsset',
            'credits must be a list',
          );
        }
        credits[entry.key.toString()] = list.map((e) {
          final map = _objectMap(e, 'credit');
          return SourceCredit.validated(
            creditId: (map['creditId'] ?? '').toString(),
            attributedTo: (map['attributedTo'] ?? '').toString(),
            role: _creditRoleFromName(map['role']),
            note: (map['note'] ?? '').toString(),
          );
        }).toList();
      }
    }
    final licenses = <String, MediaLicense>{};
    final licensesRaw = json['licensesByAsset'];
    if (licensesRaw is Map) {
      for (final entry in licensesRaw.entries) {
        final map = _objectMap(entry.value, 'licensesByAsset');
        licenses[entry.key.toString()] = MediaLicense.validated(
          tag: _licenseTagFromName(map['tag']),
          requiresAttribution: map['requiresAttribution'] as bool?,
          allowCommercial: map['allowCommercial'] as bool?,
          notes: (map['notes'] ?? '').toString(),
        );
      }
    }
    return ExportMediaManifest.validated(
      assetIds: _jsonStrings(json['assetIds'], field: 'assetIds'),
      missingAssetIds: _jsonStrings(
        json['missingAssetIds'],
        field: 'missingAssetIds',
      ),
      sanitizationApplied: json['sanitizationApplied'] == true,
      includedMissing: _jsonStrings(
        json['includedMissing'],
        field: 'includedMissing',
      ),
      creditsByAsset: credits,
      licensesByAsset: licenses,
    );
  }

  static Map<String, List<SourceCredit>> _freezeCredits(
    Map<String, List<SourceCredit>> source,
  ) {
    final frozen = <String, List<SourceCredit>>{};
    source.forEach((key, value) {
      frozen[key] = List.unmodifiable(value);
    });
    return Map.unmodifiable(frozen);
  }

  static MediaCreditRole _creditRoleFromName(Object? raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    for (final role in MediaCreditRole.values) {
      if (role.name.toLowerCase() == value) return role;
    }
    throw ArgumentError.value(raw, 'role', 'unknown media credit role');
  }

  static MediaLicenseTag _licenseTagFromName(Object? raw) {
    final value = (raw ?? '').toString().trim().toLowerCase();
    for (final tag in MediaLicenseTag.values) {
      if (tag.name.toLowerCase() == value) return tag;
    }
    throw ArgumentError.value(raw, 'tag', 'unknown media license tag');
  }

  final List<String> assetIds;
  final List<String> missingAssetIds;
  final bool sanitizationApplied;
  final List<String> includedMissing;
  final Map<String, List<SourceCredit>> creditsByAsset;
  final Map<String, MediaLicense> licensesByAsset;

  /// Aset dengan lisensi wajib-atribusi tetapi tanpa credit = peringatan
  /// atribusi (bukan blokir; user bisa melengkapi setelah impor).
  List<String> get attributionWarnings {
    final warnings = <String>[];
    licensesByAsset.forEach((assetId, license) {
      if (!license.requiresAttribution) return;
      final credits = creditsByAsset[assetId] ?? const [];
      if (credits.isEmpty) warnings.add(assetId);
    });
    return List.unmodifiable(warnings..sort());
  }

  Map<String, Object?> toJson() {
    final creditsJson = <String, Object?>{};
    final sortedCreditKeys = creditsByAsset.keys.toList()..sort();
    for (final key in sortedCreditKeys) {
      creditsJson[key] = creditsByAsset[key]!.map((credit) {
        return <String, Object?>{
          'attributedTo': credit.attributedTo,
          'creditId': credit.creditId,
          'note': credit.note,
          'role': credit.role.name,
        };
      }).toList();
    }
    final licensesJson = <String, Object?>{};
    final sortedLicenseKeys = licensesByAsset.keys.toList()..sort();
    for (final key in sortedLicenseKeys) {
      final license = licensesByAsset[key]!;
      licensesJson[key] = <String, Object?>{
        'allowCommercial': license.allowCommercial,
        'notes': license.notes,
        'requiresAttribution': license.requiresAttribution,
        'tag': license.tag.name,
      };
    }
    return <String, Object?>{
      'assetIds': List<String>.from(assetIds),
      'creditsByAsset': creditsJson,
      'includedMissing': List<String>.from(includedMissing),
      'licensesByAsset': licensesJson,
      'missingAssetIds': List<String>.from(missingAssetIds),
      'sanitizationApplied': sanitizationApplied,
    };
  }
}

/// Kategori temuan validasi skema saat impor.
enum PortabilityValidationKind {
  malformedJson,
  missingSection,
  unsupportedFormat,
  malformedDocument,
  duplicateRecord,
  mediaUnsanitized,
  mediaUnknownAsset,
  sanitizationIntegrity,
  checksumMismatch;

  String get label {
    switch (this) {
      case PortabilityValidationKind.malformedJson:
        return 'payload bukan JSON objek yang sah';
      case PortabilityValidationKind.missingSection:
        return 'bagian wajib tidak ada';
      case PortabilityValidationKind.unsupportedFormat:
        return 'versi format tidak didukung';
      case PortabilityValidationKind.malformedDocument:
        return 'dokumen tidak sah';
      case PortabilityValidationKind.duplicateRecord:
        return 'recordId duplikat';
      case PortabilityValidationKind.mediaUnsanitized:
        return 'manifest media belum disanitasi';
      case PortabilityValidationKind.mediaUnknownAsset:
        return 'kredit/lisensi menunjuk aset tidak dikenal';
      case PortabilityValidationKind.sanitizationIntegrity:
        return 'laporan sanitasi tidak konsisten dengan dokumen';
      case PortabilityValidationKind.checksumMismatch:
        return 'checksum tidak cocok dengan payload';
    }
  }

  PortabilitySeverity get severity {
    if (this == PortabilityValidationKind.mediaUnknownAsset) {
      return PortabilitySeverity.warning;
    }
    return PortabilitySeverity.blocking;
  }
}

enum PortabilitySeverity { blocking, warning }

/// Satu temuan validasi; issueId deterministik (pola 111.32/111.36).
class PortabilityValidationIssue {
  PortabilityValidationIssue._({
    required this.issueId,
    required this.kind,
    required this.path,
    required this.message,
  });

  factory PortabilityValidationIssue.validated({
    required PortabilityValidationKind kind,
    required String path,
    required String message,
  }) {
    final p = _requireTrimmed(path, 'path');
    final m = _requireTrimmed(message, 'message');
    final id = 'epv-${_hex16(_fnv1a64('${kind.name}|$p|$m'))}';
    return PortabilityValidationIssue._(
      issueId: id,
      kind: kind,
      path: p,
      message: m,
    );
  }

  final String issueId;
  final PortabilityValidationKind kind;
  final String path;
  final String message;

  PortabilitySeverity get severity => kind.severity;

  bool get isBlocking => severity == PortabilitySeverity.blocking;

  Map<String, Object?> toJson() => <String, Object?>{
    'issueId': issueId,
    'kind': kind.name,
    'message': message,
    'path': path,
  };
}

/// Hasil validasi skema payload impor.
class PortabilityValidationReport {
  PortabilityValidationReport._({required this.issues});

  static PortabilityValidationReport empty() =>
      PortabilityValidationReport._(issues: const []);

  static PortabilityValidationReport of(List<PortabilityValidationIssue> raw) {
    final issues = List<PortabilityValidationIssue>.from(raw)
      ..sort((a, b) => a.issueId.compareTo(b.issueId));
    final seen = <String>{};
    for (final issue in issues) {
      if (!seen.add(issue.issueId)) {
        throw ArgumentError.value(
          issue.issueId,
          'issueId',
          'duplicate issueId: ${issue.issueId}',
        );
      }
    }
    return PortabilityValidationReport._(issues: List.unmodifiable(issues));
  }

  final List<PortabilityValidationIssue> issues;

  bool get hasBlockingIssues => issues.any((i) => i.isBlocking);

  bool get isClean => issues.isEmpty;

  List<PortabilityValidationIssue> get warnings =>
      List.unmodifiable(issues.where((i) => !i.isBlocking));

  List<PortabilityValidationIssue> issuesOfKind(
    PortabilityValidationKind kind,
  ) => List.unmodifiable(issues.where((i) => i.kind == kind));

  String describe() {
    if (issues.isEmpty) return 'No import issues.';
    final lines = issues
        .map((i) => '${i.kind.label} @ ${i.path}: ${i.message}')
        .toList();
    return lines.join('\n');
  }
}

/// Bundel portabilitas siap-ekspor: dokumen terurut + manifest + laporan
/// sanitasi + checksum atas payload kanonik.
class EncyclopediaPortabilityBundle {
  EncyclopediaPortabilityBundle._({
    required this.formatVersion,
    required this.documents,
    required this.mediaManifest,
    required this.spoilerSanitization,
    required this.checksum,
  });

  factory EncyclopediaPortabilityBundle.validated({
    required List<EncyclopediaSearchDocument> documents,
    required ExportMediaManifest mediaManifest,
    required SpoilerSanitizationSection spoilerSanitization,
    String formatVersion = EncyclopediaPortabilityFormat.currentVersion,
  }) {
    if (!EncyclopediaPortabilityFormat.isVersionSupported(formatVersion)) {
      throw ArgumentError.value(
        formatVersion,
        'formatVersion',
        'unsupported portability format version',
      );
    }
    final sorted = List<EncyclopediaSearchDocument>.from(documents)
      ..sort((a, b) => a.recordId.compareTo(b.recordId));
    final ids = <String>[];
    for (final document in sorted) {
      if (ids.contains(document.recordId)) {
        throw StateError('duplicate recordId: ${document.recordId}');
      }
      ids.add(document.recordId);
    }
    final payload = _payloadMap(
      formatVersion: formatVersion,
      documents: sorted,
      mediaManifest: mediaManifest,
      spoilerSanitization: spoilerSanitization,
    );
    return EncyclopediaPortabilityBundle._(
      formatVersion: formatVersion,
      documents: List.unmodifiable(sorted),
      mediaManifest: mediaManifest,
      spoilerSanitization: spoilerSanitization,
      checksum: _hex16(_fnv1a64(_canonicalEncode(payload))),
    );
  }

  static Map<String, Object?> _payloadMap({
    required String formatVersion,
    required List<EncyclopediaSearchDocument> documents,
    required ExportMediaManifest mediaManifest,
    required SpoilerSanitizationSection spoilerSanitization,
  }) {
    return <String, Object?>{
      'documents': documents.map((d) => d.toJson()).toList(),
      'formatVersion': formatVersion,
      'mediaManifest': mediaManifest.toJson(),
      'spoilerSanitization': spoilerSanitization.toJson(),
    };
  }

  final String formatVersion;
  final List<EncyclopediaSearchDocument> documents;
  final ExportMediaManifest mediaManifest;
  final SpoilerSanitizationSection spoilerSanitization;
  final String checksum;

  List<String> get recordIds =>
      List.unmodifiable(documents.map((d) => d.recordId));

  EncyclopediaSearchDocument? documentFor(String recordId) {
    for (final document in documents) {
      if (document.recordId == recordId) return document;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    ..._payloadMap(
      formatVersion: formatVersion,
      documents: documents,
      mediaManifest: mediaManifest,
      spoilerSanitization: spoilerSanitization,
    ),
    'checksum': checksum,
  };
}

/// Hasil impor: bundel tervalidasi + registry 111.6 terisi + laporan.
class EncyclopediaImportResult {
  EncyclopediaImportResult._({
    required this.bundle,
    required this.documents,
    required this.registry,
    required this.report,
  });

  final EncyclopediaPortabilityBundle bundle;
  final List<EncyclopediaSearchDocument> documents;
  final SharedEncyclopediaSchema registry;
  final PortabilityValidationReport report;
}

/// Layanan portabilitas: bangun bundel, ekspor teks kanonik, validasi
/// skema, dan impor dengan verifikasi checksum. Deterministik penuh.
class EncyclopediaPortabilityService {
  const EncyclopediaPortabilityService._();

  static EncyclopediaPortabilityBundle buildBundle({
    required List<EncyclopediaSearchDocument> documents,
    required EncyclopediaExportOptions options,
    EncyclopediaMediaLibrary? mediaLibrary,
  }) {
    if (!options.explicitExport) {
      throw ArgumentError.value(
        options,
        'options',
        'encyclopedia export requires explicit opt-in (explicitExport: true)',
      );
    }
    final sorted = List<EncyclopediaSearchDocument>.from(documents)
      ..sort((a, b) => a.recordId.compareTo(b.recordId));
    final seen = <String>{};
    for (final document in sorted) {
      if (!seen.add(document.recordId)) {
        throw StateError('duplicate recordId: ${document.recordId}');
      }
    }
    final sanitized = _sanitizeDocuments(sorted, options);
    final manifest = _planManifest(mediaLibrary, options);
    return EncyclopediaPortabilityBundle.validated(
      documents: sanitized.documents,
      mediaManifest: manifest,
      spoilerSanitization: sanitized.section,
    );
  }

  static _SanitizationOutcome _sanitizeDocuments(
    List<EncyclopediaSearchDocument> sorted,
    EncyclopediaExportOptions options,
  ) {
    if (options.spoilerMode == SpoilerSanitizationMode.keep) {
      return _SanitizationOutcome(
        documents: sorted,
        section: SpoilerSanitizationSection.validated(
          mode: SpoilerSanitizationMode.keep,
        ),
      );
    }
    final policy = options.spoilerPolicy!;
    final output = <EncyclopediaSearchDocument>[];
    final masked = <String>[];
    final dropped = <String>[];
    for (final document in sorted) {
      final allowed = policy.allows(
        document.spoilerLevel,
        recordKey: document.recordId,
      );
      if (allowed) {
        output.add(document);
        continue;
      }
      if (options.spoilerMode == SpoilerSanitizationMode.drop) {
        dropped.add(document.recordId);
        continue;
      }
      masked.add(document.recordId);
      output.add(_maskedCopy(document));
    }
    return _SanitizationOutcome(
      documents: output,
      section: SpoilerSanitizationSection.validated(
        mode: options.spoilerMode,
        maskedRecordIds: masked,
        droppedRecordIds: dropped,
      ),
    );
  }

  static EncyclopediaSearchDocument _maskedCopy(
    EncyclopediaSearchDocument document,
  ) {
    final record = EncyclopediaRecord.validated(
      recordId: document.record.recordId,
      domain: document.record.domain,
      title: kEncyclopediaSpoilerMaskTitle,
      taxonomyCategoryId: document.record.taxonomyCategoryId,
      canonStatus: document.record.canonStatus,
      scopeLocations: document.record.scopeLocationIds,
    );
    return EncyclopediaSearchDocument.validated(
      record: record,
      aliases: const [],
      cultureIds: const [],
      validity: document.validity,
      spoilerLevel: SpoilerLevel.safe,
    );
  }

  static ExportMediaManifest _planManifest(
    EncyclopediaMediaLibrary? library,
    EncyclopediaExportOptions options,
  ) {
    if (library == null) {
      return ExportMediaManifest.validated(assetIds: const []);
    }
    final plan = library.planExport(
      explicitExport: true,
      includeMissing: options.includeMissingMedia,
    );
    return ExportMediaManifest.fromPlanner(
      plan,
      includeMissing: options.includeMissingMedia,
    );
  }

  /// Teks ekspor kanonik: key terurut rekursif, memuat checksum payload.
  static String exportText(EncyclopediaPortabilityBundle bundle) =>
      _canonicalEncode(bundle.toJson());

  /// Verifikasi checksum atas teks ekspor. False untuk teks tak sah.
  static bool verifyChecksum(String text) {
    final parsed = _tryDecodeObject(text);
    if (parsed == null) return false;
    final recorded = parsed['checksum'];
    if (recorded is! String) return false;
    final payload = <String, Object?>{...parsed}..remove('checksum');
    return _hex16(_fnv1a64(_canonicalEncode(payload))) == recorded;
  }

  /// Validasi skema payload (String JSON). Tidak melempar untuk payload
  /// rusak — temuan dilaporkan lewat [PortabilityValidationReport].
  static PortabilityValidationReport validateJson(String jsonText) {
    final issues = <PortabilityValidationIssue>[];
    final parsed = _tryDecodeObject(jsonText);
    if (parsed == null) {
      return PortabilityValidationReport.of([
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.malformedJson,
          path: r'$',
          message: 'payload is not a decodable JSON object',
        ),
      ]);
    }

    final version = parsed['formatVersion'];
    if (version is! String ||
        !EncyclopediaPortabilityFormat.isVersionSupported(version)) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.unsupportedFormat,
          path: 'formatVersion',
          message: 'unsupported format version: $version',
        ),
      );
    }

    final documents = _validateDocuments(parsed['documents'], issues);

    _validateMediaManifest(parsed['mediaManifest'], issues);

    _validateSanitization(parsed['spoilerSanitization'], documents, issues);

    final checksumRaw = parsed['checksum'];
    if (checksumRaw != null) {
      if (checksumRaw is! String || !verifyChecksum(jsonText)) {
        issues.add(
          PortabilityValidationIssue.validated(
            kind: PortabilityValidationKind.checksumMismatch,
            path: 'checksum',
            message: 'checksum does not match the canonical payload',
          ),
        );
      }
    }

    return PortabilityValidationReport.of(issues);
  }

  static PortabilityValidationReport validateJsonText(String jsonText) =>
      validateJson(jsonText);

  static List<Map<String, Object?>> _validateDocuments(
    Object? raw,
    List<PortabilityValidationIssue> issues,
  ) {
    if (raw == null) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.missingSection,
          path: 'documents',
          message: 'required section documents is missing',
        ),
      );
      return const [];
    }
    if (raw is! List) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.malformedDocument,
          path: 'documents',
          message: 'documents must be a list',
        ),
      );
      return const [];
    }
    final entries = <Map<String, Object?>>[];
    final ids = <String>{};
    for (var i = 0; i < raw.length; i++) {
      final path = 'documents[$i]';
      try {
        final map = _objectMap(raw[i], path);
        final document = EncyclopediaSearchDocument.fromJson(map);
        entries.add(document.toJson());
        if (!ids.add(document.recordId)) {
          issues.add(
            PortabilityValidationIssue.validated(
              kind: PortabilityValidationKind.duplicateRecord,
              path: path,
              message: 'duplicate recordId: ${document.recordId}',
            ),
          );
        }
      } on Object catch (error) {
        issues.add(
          PortabilityValidationIssue.validated(
            kind: PortabilityValidationKind.malformedDocument,
            path: path,
            message: 'invalid document entry: $error',
          ),
        );
      }
    }
    return entries;
  }

  static void _validateMediaManifest(
    Object? raw,
    List<PortabilityValidationIssue> issues,
  ) {
    if (raw == null) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.missingSection,
          path: 'mediaManifest',
          message: 'required section mediaManifest is missing',
        ),
      );
      return;
    }
    final manifestMap = _objectMap(raw, 'mediaManifest');
    if (manifestMap['sanitizationApplied'] != true) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.mediaUnsanitized,
          path: 'mediaManifest.sanitizationApplied',
          message: 'media manifest must record sanitization as applied',
        ),
      );
    }
    Set<String> known;
    try {
      known = ExportMediaManifest.fromJson(manifestMap).assetIds.toSet();
    } on Object catch (error) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.malformedDocument,
          path: 'mediaManifest',
          message: 'invalid media manifest: $error',
        ),
      );
      return;
    }
    final missing = _stringKeys(manifestMap, 'missingAssetIds');
    known.addAll(missing);
    for (final section in const ['creditsByAsset', 'licensesByAsset']) {
      final value = manifestMap[section];
      if (value is! Map) continue;
      for (final key in value.keys.map((k) => k.toString())) {
        if (!known.contains(key)) {
          issues.add(
            PortabilityValidationIssue.validated(
              kind: PortabilityValidationKind.mediaUnknownAsset,
              path: 'mediaManifest.$section.$key',
              message: 'entry refers to unknown asset $key',
            ),
          );
        }
      }
    }
  }

  static Set<String> _stringKeys(Object? raw, String field) {
    if (raw is! Map) return <String>{};
    final value = raw[field];
    if (value is! List) return <String>{};
    return value.map((e) => e.toString()).toSet();
  }

  static void _validateSanitization(
    Object? raw,
    List<Map<String, Object?>> documents,
    List<PortabilityValidationIssue> issues,
  ) {
    if (raw == null) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.missingSection,
          path: 'spoilerSanitization',
          message: 'required section spoilerSanitization is missing',
        ),
      );
      return;
    }
    SpoilerSanitizationSection section;
    try {
      section = SpoilerSanitizationSection.fromJson(
        _objectMap(raw, 'spoilerSanitization'),
      );
    } on Object catch (error) {
      issues.add(
        PortabilityValidationIssue.validated(
          kind: PortabilityValidationKind.malformedDocument,
          path: 'spoilerSanitization',
          message: 'invalid sanitization section: $error',
        ),
      );
      return;
    }
    final present = documents
        .map((d) => (d['recordId'] ?? '').toString())
        .toSet();
    for (final id in section.maskedRecordIds) {
      if (!present.contains(id)) {
        issues.add(
          PortabilityValidationIssue.validated(
            kind: PortabilityValidationKind.sanitizationIntegrity,
            path: 'spoilerSanitization.maskedRecordIds',
            message: 'masked record $id is not present in documents',
          ),
        );
      }
    }
    for (final id in section.droppedRecordIds) {
      if (present.contains(id)) {
        issues.add(
          PortabilityValidationIssue.validated(
            kind: PortabilityValidationKind.sanitizationIntegrity,
            path: 'spoilerSanitization.droppedRecordIds',
            message: 'dropped record $id must not appear in documents',
          ),
        );
      }
    }
  }

  static Map<String, Object?>? _tryDecodeObject(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return null;
      return <String, Object?>{
        for (final entry in decoded.entries) entry.key.toString(): entry.value,
      };
    } on FormatException {
      return null;
    }
  }

  /// Impor payload. Validasi blocking -> StateError (fail-closed).
  static EncyclopediaImportResult importText(String jsonText) {
    final report = validateJson(jsonText);
    if (report.hasBlockingIssues) {
      throw StateError(
        'encyclopedia import blocked by validation:\n${report.describe()}',
      );
    }
    final parsed = _tryDecodeObject(jsonText)!;
    final documents = (parsed['documents'] as List)
        .map(
          (e) =>
              EncyclopediaSearchDocument.fromJson(_objectMap(e, 'documents')),
        )
        .toList();
    final manifest = ExportMediaManifest.fromJson(
      _objectMap(parsed['mediaManifest'], 'mediaManifest'),
    );
    final section = SpoilerSanitizationSection.fromJson(
      _objectMap(parsed['spoilerSanitization'], 'spoilerSanitization'),
    );
    final bundle = EncyclopediaPortabilityBundle.validated(
      documents: documents,
      mediaManifest: manifest,
      spoilerSanitization: section,
    );
    final registry = SharedEncyclopediaSchema();
    for (final document in bundle.documents) {
      registry.register(document.record);
    }
    return EncyclopediaImportResult._(
      bundle: bundle,
      documents: bundle.documents,
      registry: registry,
      report: report,
    );
  }

  /// Impor lalu ekspor ulang; untuk payload sah hasilnya byte-identik.
  static String roundTripText(String jsonText) =>
      exportText(importText(jsonText).bundle);
}

class _SanitizationOutcome {
  const _SanitizationOutcome({required this.documents, required this.section});

  final List<EncyclopediaSearchDocument> documents;
  final SpoilerSanitizationSection section;
}
