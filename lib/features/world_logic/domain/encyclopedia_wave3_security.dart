// Sprint 111.42 — Security, Privacy & Content Safety Verification.
//
// Objective kanonik (sprint_111.json): menguji isolasi project, spoiler,
// metadata media, import berbahaya, export, dan hasil generator.
// Required outputs: threat_review, isolation_tests, import_tests,
// metadata_tests, spoiler_tests, fix_status.
//
// Desain: BUKAN re-implementasi — tiap check memanggil API produksi nyata
// (111.6 registry, 111.7 media rights, 111.8 spoiler, 111.31 generator,
// 111.37 search, 111.39 portability) atas fixture memori sementara dan
// membuktikan perilaku fail-closed. Deterministik penuh: tanpa wall-clock,
// random, network, persistence, file IO (D-SCHEMA-01 tetap OPEN). Threat
// hardware-bound dicatat DEFERRED tanpa klaim check lunak.
import 'dart:convert';

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_portability.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_scale.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

enum Wave3SecuritySurface {
  projectIsolation,
  spoilerLeak,
  mediaMetadata,
  dangerousImport,
  exportSafety,
  generatorSafety;

  static Wave3SecuritySurface fromName(Object? raw) {
    for (final surface in values) {
      if (surface.name == raw.toString()) return surface;
    }
    throw ArgumentError.value(raw, 'surface', 'unknown security surface');
  }
}

enum Wave3SecurityStatus {
  verifiedByChecks,
  fixedThisSlice,
  deferredHardware,
  unresolved;

  static Wave3SecurityStatus fromName(Object? raw) {
    for (final status in values) {
      if (status.name == raw.toString()) return status;
    }
    throw ArgumentError.value(raw, 'status', 'unknown security status');
  }
}

/// Satu ancaman threat review + check id yang membuktikannya (kosong =
/// hardware-bound, tidak pernah mengklaim check lunak).
class Wave3SecurityThreat {
  factory Wave3SecurityThreat({
    required String threatId,
    required Wave3SecuritySurface surface,
    required String description,
    List<String> controls = const <String>[],
  }) {
    return Wave3SecurityThreat._(
      threatId: _required(threatId, 'threatId'),
      surface: surface,
      description: _required(description, 'description'),
      controls: List.unmodifiable(controls),
    );
  }

  const Wave3SecurityThreat._({
    required this.threatId,
    required this.surface,
    required this.description,
    required this.controls,
  });

  factory Wave3SecurityThreat.fromJson(Map<String, Object?> json) {
    final rawControls = json['controls'];
    if (rawControls != null && rawControls is! List) {
      throw ArgumentError.value(rawControls, 'controls', 'must be a list');
    }
    return Wave3SecurityThreat(
      threatId: _required(json['threatId'], 'threatId'),
      surface: Wave3SecuritySurface.fromName(json['surface']),
      description: _required(json['description'], 'description'),
      controls: <String>[
        for (final raw in rawControls as List<Object?>? ?? const [])
          raw.toString(),
      ],
    );
  }

  final String threatId;
  final Wave3SecuritySurface surface;
  final String description;
  final List<String> controls;

  Map<String, Object?> toJson() => <String, Object?>{
    'controls': List<String>.from(controls),
    'description': description,
    'surface': surface.name,
    'threatId': threatId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wave3SecurityThreat &&
          other.threatId == threatId &&
          other.surface == surface &&
          other.description == description &&
          const ListEquality().equals(other.controls, controls));

  @override
  int get hashCode =>
      Object.hash(threatId, surface, description, Object.hashAll(controls));
}

/// Hasil satu check keamanan yang benar-benar dieksekusi harness.
class Wave3SecurityCheckOutcome {
  factory Wave3SecurityCheckOutcome({
    required String checkId,
    required bool passed,
    required String evidence,
  }) {
    final id = _required(checkId, 'checkId');
    final ev = _required(evidence, 'evidence');
    return passed
        ? Wave3SecurityCheckOutcome._pass(checkId: id, evidence: ev)
        : Wave3SecurityCheckOutcome._fail(checkId: id, evidence: ev);
  }

  const Wave3SecurityCheckOutcome._pass({
    required this.checkId,
    required this.evidence,
  }) : passed = true;

  const Wave3SecurityCheckOutcome._fail({
    required this.checkId,
    required this.evidence,
  }) : passed = false;

  const factory Wave3SecurityCheckOutcome.pass({
    required String checkId,
    required String evidence,
  }) = Wave3SecurityCheckOutcome._pass;

  const factory Wave3SecurityCheckOutcome.failed({
    required String checkId,
    required String evidence,
  }) = Wave3SecurityCheckOutcome._fail;

  factory Wave3SecurityCheckOutcome.fromJson(Map<String, Object?> json) {
    final passed = json['passed'];
    if (passed is! bool) {
      throw ArgumentError.value(passed, 'passed', 'must be a bool');
    }
    return Wave3SecurityCheckOutcome(
      checkId: _required(json['checkId'], 'checkId'),
      passed: passed,
      evidence: _required(json['evidence'], 'evidence'),
    );
  }

  final String checkId;
  final bool passed;
  final String evidence;

  Map<String, Object?> toJson() => <String, Object?>{
    'checkId': checkId,
    'evidence': evidence,
    'passed': passed,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wave3SecurityCheckOutcome &&
          other.checkId == checkId &&
          other.passed == passed &&
          other.evidence == evidence);

  @override
  int get hashCode => Object.hash(checkId, passed, evidence);
}

/// Laporan ter-audit: threats sorted-by-id, outcomes sorted-by-id,
/// fix_status per threat (output `fix_status`). Guard fail-closed.
class EncyclopediaWave3SecurityReport {
  EncyclopediaWave3SecurityReport._({
    required this.threats,
    required this.outcomes,
    required this.fixStatus,
  });

  factory EncyclopediaWave3SecurityReport.of({
    required List<Wave3SecurityThreat> threats,
    required List<Wave3SecurityCheckOutcome> outcomes,
    Set<String> fixedThisSliceIds = const <String>{},
  }) {
    final sortedThreats = List<Wave3SecurityThreat>.from(threats)
      ..sort((a, b) => a.threatId.compareTo(b.threatId));
    final sortedOutcomes = List<Wave3SecurityCheckOutcome>.from(outcomes)
      ..sort((a, b) => a.checkId.compareTo(b.checkId));
    final outcomeIds = <String>{};
    for (final outcome in sortedOutcomes) {
      if (!outcomeIds.add(outcome.checkId)) {
        throw StateError('duplicate checkId: ${outcome.checkId}');
      }
    }
    final threatIds = <String>{};
    final referenced = <String>{};
    for (final threat in sortedThreats) {
      if (!threatIds.add(threat.threatId)) {
        throw StateError('duplicate threatId: ${threat.threatId}');
      }
      for (final control in threat.controls) {
        if (!outcomeIds.contains(control)) {
          throw ArgumentError.value(
            control,
            'controls',
            'threat ${threat.threatId} references unknown check "$control"',
          );
        }
        referenced.add(control);
      }
    }
    for (final outcome in sortedOutcomes) {
      if (!referenced.contains(outcome.checkId)) {
        throw ArgumentError.value(
          outcome.checkId,
          'outcomes',
          'check "${outcome.checkId}" is not referenced by any threat',
        );
      }
    }
    final byId = <String, Wave3SecurityCheckOutcome>{
      for (final outcome in sortedOutcomes) outcome.checkId: outcome,
    };
    final fixStatus = <String, String>{};
    for (final threat in sortedThreats) {
      final Wave3SecurityStatus status;
      if (threat.controls.isEmpty) {
        status = Wave3SecurityStatus.deferredHardware;
      } else if (fixedThisSliceIds.contains(threat.threatId)) {
        status = Wave3SecurityStatus.fixedThisSlice;
      } else {
        final allPass = threat.controls.every((id) => byId[id]!.passed);
        status = allPass
            ? Wave3SecurityStatus.verifiedByChecks
            : Wave3SecurityStatus.unresolved;
      }
      fixStatus[threat.threatId] = status.name;
    }
    return EncyclopediaWave3SecurityReport._(
      threats: List.unmodifiable(sortedThreats),
      outcomes: List.unmodifiable(sortedOutcomes),
      fixStatus: Map.unmodifiable(fixStatus),
    );
  }

  factory EncyclopediaWave3SecurityReport.fromJson(Map<String, Object?> json) {
    final rawThreats = json['threats'];
    final rawOutcomes = json['outcomes'];
    if (rawThreats is! List || rawOutcomes is! List) {
      throw ArgumentError.value(
        json,
        'json',
        'threats and outcomes must be lists',
      );
    }
    return EncyclopediaWave3SecurityReport.of(
      threats: [
        for (final e in rawThreats)
          Wave3SecurityThreat.fromJson(_asMap(e, 'threats')),
      ],
      outcomes: [
        for (final e in rawOutcomes)
          Wave3SecurityCheckOutcome.fromJson(_asMap(e, 'outcomes')),
      ],
      fixedThisSliceIds: _fixedIdsFrom(json['fixStatus']),
    );
  }

  final List<Wave3SecurityThreat> threats;
  final List<Wave3SecurityCheckOutcome> outcomes;
  final Map<String, String> fixStatus;

  /// Output kanonik `threat_review`: seluruh ancaman ter-audit, sorted.
  List<Wave3SecurityThreat> get threatReview => threats;

  bool get passing => outcomes.every((o) => o.passed);

  List<String> get failedCheckIds =>
      outcomes.where((o) => !o.passed).map((o) => o.checkId).toList();

  List<String> get deferredThreatIds => fixStatus.entries
      .where((e) => e.value == Wave3SecurityStatus.deferredHardware.name)
      .map((e) => e.key)
      .toList();

  List<Wave3SecurityCheckOutcome> checksFor(Wave3SecuritySurface surface) {
    final ids = <String>{
      for (final threat in threats)
        if (threat.surface == surface) ...threat.controls,
    };
    return List.unmodifiable(
      outcomes.where((o) => ids.contains(o.checkId)).toList(),
    );
  }

  Wave3SecurityThreat threatNamed(String threatId) {
    for (final threat in threats) {
      if (threat.threatId == threatId.trim()) return threat;
    }
    throw ArgumentError.value(threatId, 'threatId', 'unknown threat');
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'fixStatus': <String, String>{
      for (final entry
          in fixStatus.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        entry.key: entry.value,
    },
    'outcomes': outcomes.map((o) => o.toJson()).toList(),
    'threats': threats.map((t) => t.toJson()).toList(),
  };

  String describe() {
    final buffer = StringBuffer()
      ..writeln('Wave 3 security verification report')
      ..writeln('checks: ${outcomes.length}, passing: $passing');
    for (final outcome in outcomes) {
      buffer.writeln(
        '  ${outcome.passed ? 'PASS' : 'FAIL'} ${outcome.checkId}'
        ' — ${outcome.evidence}',
      );
    }
    for (final threat in threats) {
      final status = fixStatus[threat.threatId]!;
      final verdict =
          status == Wave3SecurityStatus.deferredHardware.name &&
              threat.controls.isEmpty
          ? 'UNVERIFIABLE (hardware-bound)'
          : status;
      buffer.writeln('  ${threat.threatId}: $verdict');
    }
    if (!passing) {
      buffer.writeln('HASIL: GAGAL — ada check yang tidak lulus.');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaWave3SecurityReport &&
          jsonEncode(other.toJson()) == jsonEncode(toJson()));

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

String _required(Object? raw, String field) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw ArgumentError.value(raw, field, '$field must be non-empty');
  }
  return value;
}

Map<String, Object?> _asMap(Object? raw, String field) {
  if (raw is! Map) {
    throw ArgumentError.value(raw, field, 'entries must be objects');
  }
  return <String, Object?>{
    for (final entry in raw.entries) entry.key.toString(): entry.value,
  };
}

Set<String> _fixedIdsFrom(Object? raw) {
  if (raw is! Map) return const <String>{};
  return <String>{
    for (final entry in raw.entries)
      if (entry.value.toString() == Wave3SecurityStatus.fixedThisSlice.name)
        entry.key.toString(),
  };
}

/// Equality list string ringan tanpa dependensi luar.
class ListEquality {
  const ListEquality();

  bool equals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Harness: menjalankan satu check nyata per mitigasi di atas API produksi
/// dan membekukannya menjadi laporan ter-audit. Deterministik byte-stabil.
class EncyclopediaWave3SecurityHarness {
  const EncyclopediaWave3SecurityHarness._();

  /// Judul rahasia yang tidak boleh bocor lewat jalur ter-gate.
  static const String secretTitle = 'Qowner Is The Void Cube Bearer';

  static EncyclopediaWave3SecurityReport run() {
    return EncyclopediaWave3SecurityReport.of(
      threats: _threatReview(),
      outcomes: <Wave3SecurityCheckOutcome>[
        _checkIsolationRegistryNamespace(),
        _checkIsolationSearchVisibility(),
        _checkIsolationExportLeak(),
        _checkMetadataSensitiveStripped(),
        _checkMetadataPathContainment(),
        _checkMetadataSanitizationGate(),
        _checkSpoilerExportMask(),
        _checkSpoilerExportDrop(),
        _checkSpoilerSearchHiddenIdsOnly(),
        _checkSpoilerOverrideBeatsDefault(),
        _checkImportMalformedJson(),
        _checkImportNonMapPayload(),
        _checkImportTamperedChecksum(),
        _checkImportMissingChecksum(),
        _checkImportUnsanitizedManifest(),
        _checkExportExplicitOptIn(),
        _checkExportMissingMediaExcluded(),
        _checkExportRoundTripIntegrity(),
        _checkGeneratorExplicitSeed(),
        _checkGeneratorReplayDeterminism(),
        _checkGeneratorBatchBounds(),
        _checkGeneratorNoAutoCanon(),
      ],
      fixedThisSliceIds: const <String>{'th-import-checksum-bypass'},
    );
  }

  static List<Wave3SecurityThreat> _threatReview() {
    return <Wave3SecurityThreat>[
      Wave3SecurityThreat(
        threatId: 'th-export-implicit-missing-media',
        surface: Wave3SecuritySurface.exportSafety,
        description:
            'Export diam-diam ikut membawa referensi media hilang/rusak '
            'tanpa opt-in eksplisit.',
        controls: <String>[
          'chk-export-explicit-opt-in',
          'chk-export-missing-media-excluded',
        ],
      ),
      Wave3SecurityThreat(
        threatId: 'th-export-integrity-regression',
        surface: Wave3SecuritySurface.exportSafety,
        description:
            'Round trip export->import->export berubah byte sehingga '
            'verifikasi integritas pasca-impor tidak lagi sah.',
        controls: <String>['chk-export-round-trip-integrity'],
      ),
      Wave3SecurityThreat(
        threatId: 'th-generator-nondeterminism-or-autocanon',
        surface: Wave3SecuritySurface.generatorSafety,
        description:
            'Generator nama memakai seed implisit/dinding-waktu, batch tak '
            'terbatas, atau menulis hasil langsung ke kanon tanpa keputusan '
            'pengguna.',
        controls: <String>[
          'chk-generator-explicit-seed',
          'chk-generator-replay-determinism',
          'chk-generator-batch-bounds',
          'chk-generator-no-auto-canon',
        ],
      ),
      Wave3SecurityThreat(
        threatId: 'th-import-checksum-bypass',
        surface: Wave3SecuritySurface.dangerousImport,
        description:
            'BUG NYATA ditutup slice ini: validateJson hanya memverifikasi '
            'checksum bila ADA (if != null), sehingga payload yang membuang '
            'field "checksum" lolos validasi dan dapat diimpor tanpa bukti '
            'integritas.',
        controls: <String>['chk-import-missing-checksum'],
      ),
      Wave3SecurityThreat(
        threatId: 'th-import-malformed-payload',
        surface: Wave3SecuritySurface.dangerousImport,
        description:
            'Payload rusak/non-object membuat importer melempar tanpa '
            'laporan, atau lebih buruk: sebagian terparse diam-diam.',
        controls: <String>[
          'chk-import-malformed-json',
          'chk-import-non-map-payload',
        ],
      ),
      Wave3SecurityThreat(
        threatId: 'th-import-payload-tampering',
        surface: Wave3SecuritySurface.dangerousImport,
        description:
            'Payload pihak ketiga diedit (titel diganti) tanpa terdeteksi '
            'oleh import.',
        controls: <String>['chk-import-tampered-checksum'],
      ),
      Wave3SecurityThreat(
        threatId: 'th-media-exif-location-leak',
        surface: Wave3SecuritySurface.mediaMetadata,
        description:
            'Metadata EXIF/identitas (GPS, pemilik kamera, telepon) '
            'terekspos ke UI/ekspor dan membocorkan lokasi dunia nyata.',
        controls: <String>[
          'chk-metadata-sensitive-stripped',
          'chk-metadata-sanitization-gate',
        ],
      ),
      Wave3SecurityThreat(
        threatId: 'th-media-path-traversal',
        surface: Wave3SecuritySurface.mediaMetadata,
        description:
            'Path media absolut/drive/parent-traversal menunjuk di luar '
            'paket proyek.',
        controls: <String>['chk-metadata-path-containment'],
      ),
      Wave3SecurityThreat(
        threatId: 'th-power-loss-integrity',
        surface: Wave3SecuritySurface.projectIsolation,
        description:
            'Kerusakan paket proyek akibat cabut daya nyata saat tulis '
            'DB/manifest. TIDAK terverifikasi dari cron — butuh hands-on '
            'perangkat keras (preseden 145.30/145.42).',
      ),
      Wave3SecurityThreat(
        threatId: 'th-project-data-crossover',
        surface: Wave3SecuritySurface.projectIsolation,
        description:
            'Entri satu proyek terlihat lewat registry, pencarian, atau '
            'bundel ekspor proyek lain.',
        controls: <String>[
          'chk-isolation-registry-namespace',
          'chk-isolation-search-visibility',
          'chk-isolation-export-leak',
        ],
      ),
      Wave3SecurityThreat(
        threatId: 'th-spoiler-leak-export-search',
        surface: Wave3SecuritySurface.spoilerLeak,
        description:
            'Judul/alias spoiler bocor lewat bundel tanpa sanitasi atau '
            'laporan pencarian membocorkan konten record tersembunyi.',
        controls: <String>[
          'chk-spoiler-export-mask',
          'chk-spoiler-export-drop',
          'chk-spoiler-search-hidden-ids-only',
        ],
      ),
      Wave3SecurityThreat(
        threatId: 'th-spoiler-override-bypass',
        surface: Wave3SecuritySurface.spoilerLeak,
        description:
            'Override per-record diabaikan sehingga policy ketat '
            'membocorkan ending atau policy longgar menyembunyikan yang '
            'diizinkan.',
        controls: <String>['chk-spoiler-override-beats-default'],
      ),
      Wave3SecurityThreat(
        threatId: 'th-unsanitized-media-manifest-import',
        surface: Wave3SecuritySurface.dangerousImport,
        description:
            'Bundle dengan manifest media tak tersanitasi dapat diimpor '
            'dan menyuntik metadata mentah ke proyek tujuan.',
        controls: <String>['chk-import-unsanitized-manifest'],
      ),
    ];
  }

  // --- isolasi project ------------------------------------------------------

  static Wave3SecurityCheckOutcome _checkIsolationRegistryNamespace() {
    final a = SharedEncyclopediaSchema();
    final b = SharedEncyclopediaSchema();
    a.register(
      EncyclopediaRecord.validated(
        recordId: 'alpha-only',
        domain: EncyclopediaDomain.herbology,
        title: 'Alpha',
      ),
    );
    b.register(
      EncyclopediaRecord.validated(
        recordId: 'beta-only',
        domain: EncyclopediaDomain.bestiary,
        title: 'Beta',
      ),
    );
    final isolated =
        a.recordFor('beta-only') == null && b.recordFor('alpha-only') == null;
    var dupBlocked = false;
    try {
      a.register(
        EncyclopediaRecord.validated(
          recordId: 'alpha-only',
          domain: EncyclopediaDomain.herbology,
          title: 'Alpha again',
        ),
      );
    } on ArgumentError {
      dupBlocked = true;
    }
    if (isolated && dupBlocked) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-isolation-registry-namespace',
        evidence:
            'dua SharedEncyclopediaSchema terpisah; id proyek lain tak terlihat; '
            'duplikat id dalam satu registry ditolak ArgumentError',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-isolation-registry-namespace',
      evidence: 'namespace registry bocor lintas proyek',
    );
  }

  static Wave3SecurityCheckOutcome _checkIsolationSearchVisibility() {
    final projectA =
        EncyclopediaSearchIndex.withDocuments(<EncyclopediaSearchDocument>[
          _doc('a-secret', EncyclopediaDomain.mythTheology, secretTitle),
          _doc('a-open', EncyclopediaDomain.herbology, 'Void Fern'),
        ]);
    final projectB = EncyclopediaSearchIndex.withDocuments(
      <EncyclopediaSearchDocument>[
        _doc('b-only', EncyclopediaDomain.artifacts, 'Ember Lantern'),
      ],
    );
    final leakedB = projectB.search(EncyclopediaSearchQuery(text: 'void fern'));
    final leakedA = projectA.search(
      EncyclopediaSearchQuery(text: 'ember lantern'),
    );
    if (leakedB.hits.isEmpty &&
        leakedB.totalMatches == 0 &&
        leakedA.hits.isEmpty) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-isolation-search-visibility',
        evidence: 'query dokumen proyek A nol hasil di indeks B dua arah',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-isolation-search-visibility',
      evidence: 'hasil pencarian bocor antar indeks proyek',
    );
  }

  static Wave3SecurityCheckOutcome _checkIsolationExportLeak() {
    final bundleA = EncyclopediaPortabilityService.buildBundle(
      documents: <EncyclopediaSearchDocument>[
        _doc('a-secret', EncyclopediaDomain.mythTheology, secretTitle),
      ],
      options: EncyclopediaExportOptions(explicitExport: true),
    );
    final textA = EncyclopediaPortabilityService.exportText(bundleA);
    final bundleB = EncyclopediaPortabilityService.buildBundle(
      documents: const <EncyclopediaSearchDocument>[],
      options: EncyclopediaExportOptions(explicitExport: true),
    );
    final textB = EncyclopediaPortabilityService.exportText(bundleB);
    if (!textB.contains(secretTitle) &&
        !textB.contains('a-secret') &&
        textA.contains(secretTitle)) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-isolation-export-leak',
        evidence: 'bundel ekspor B tidak memuat judul/record proyek A',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-isolation-export-leak',
      evidence: 'bundel ekspor memuat data proyek lain',
    );
  }

  // --- metadata media --------------------------------------------------------

  static Wave3SecurityCheckOutcome _checkMetadataSensitiveStripped() {
    final result = MediaMetadataSanitizer.sanitize(<String, String>{
      'GPSLatitude': '-6.200000',
      'GPSLongitude': '106.816666',
      'CameraOwnerName': 'Choi DS',
      'PhoneNumber': '0812-0000-0000',
      'description': 'peta void cube',
      'title': 'Void Cube sketch',
    });
    final leaked = result.cleaned.keys
        .where(
          (k) => const {
            'gpslatitude',
            'gpslongitude',
            'cameraownername',
            'phonenumber',
          }.contains(k.trim().toLowerCase()),
        )
        .toList();
    if (leaked.isEmpty &&
        result.removedKeys.length == 4 &&
        result.cleaned.containsKey('description') &&
        result.cleaned.containsKey('title')) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-metadata-sensitive-stripped',
        evidence:
            '4 kunci sensitif dibuang (case-insensitive), kunci aman bertahan',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-metadata-sensitive-stripped',
      evidence: 'metadata sensitif masih terbawa',
    );
  }

  static Wave3SecurityCheckOutcome _checkMetadataPathContainment() {
    final hostile = <String>[
      r'C:\Users\victim\.ssh\id_rsa',
      '/etc/passwd',
      '../../outside.png',
      r'assets\..\..\escape.png',
    ];
    var allRejected = true;
    for (final path in hostile) {
      try {
        EncyclopediaMediaAsset.validated(
          assetId: 'x',
          kind: MediaKind.image,
          relativePath: path,
        );
        allRejected = false;
        break;
      } on ArgumentError {
        continue;
      }
    }
    var positiveOk = false;
    try {
      final ok = EncyclopediaMediaAsset.validated(
        assetId: 'ok',
        kind: MediaKind.image,
        relativePath: r'assets\references\m1.png',
      );
      positiveOk = ok.relativePath == 'assets/references/m1.png';
    } on ArgumentError {
      positiveOk = false;
    }
    if (allRejected && positiveOk) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-metadata-path-containment',
        evidence:
            '4 path hostil (drive, POSIX absolute, ../, backslash traversal) '
            'ditolak; backslash non-traversal dinormalisasi',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-metadata-path-containment',
      evidence: 'path traversal/absolut lolos validasi aset media',
    );
  }

  static Wave3SecurityCheckOutcome _checkMetadataSanitizationGate() {
    var uncleanRejected = false;
    try {
      ExportMediaManifest.validated(
        assetIds: const <String>['m1'],
        sanitizationApplied: false,
      );
    } on ArgumentError {
      uncleanRejected = true;
    }
    var honestOk = false;
    try {
      ExportMediaManifest.validated(assetIds: const <String>['m1']);
      honestOk = true;
    } on ArgumentError {
      honestOk = false;
    }
    if (uncleanRejected && honestOk) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-metadata-sanitization-gate',
        evidence:
            'manifest tanpa sanitasi ditolak saat dibangun; manifest sanitized '
            'tetap sah',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-metadata-sanitization-gate',
      evidence: 'gerbang sanitasi metadata tidak fail-closed',
    );
  }

  // --- spoiler -----------------------------------------------------------------

  static Wave3SecurityCheckOutcome _checkSpoilerExportMask() {
    final bundle = EncyclopediaPortabilityService.buildBundle(
      documents: <EncyclopediaSearchDocument>[
        _doc(
          'sp-mask',
          EncyclopediaDomain.mythTheology,
          secretTitle,
          aliases: const ['final secret'],
          spoiler: SpoilerLevel.ending,
        ),
      ],
      options: EncyclopediaExportOptions(
        explicitExport: true,
        spoilerMode: SpoilerSanitizationMode.mask,
        spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
      ),
    );
    final text = EncyclopediaPortabilityService.exportText(bundle);
    final maskedDoc = bundle.documentFor('sp-mask')!;
    if (!text.contains(secretTitle) &&
        !text.contains('final secret') &&
        maskedDoc.record.title == kEncyclopediaSpoilerMaskTitle &&
        maskedDoc.aliases.isEmpty) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-spoiler-export-mask',
        evidence:
            'mask mengganti judul + mengosongkan alias; teks bundel bebas '
            'rahasia ending',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-spoiler-export-mask',
      evidence: 'ekspor mask membocorkan judul/alias spoiler',
    );
  }

  static Wave3SecurityCheckOutcome _checkSpoilerExportDrop() {
    final bundle = EncyclopediaPortabilityService.buildBundle(
      documents: <EncyclopediaSearchDocument>[
        _doc(
          'sp-drop',
          EncyclopediaDomain.artifacts,
          secretTitle,
          spoiler: SpoilerLevel.ending,
        ),
        _doc('sp-keep', EncyclopediaDomain.herbology, 'Void Fern'),
      ],
      options: EncyclopediaExportOptions(
        explicitExport: true,
        spoilerMode: SpoilerSanitizationMode.drop,
        spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
      ),
    );
    final text = EncyclopediaPortabilityService.exportText(bundle);
    if (!text.contains(secretTitle) &&
        bundle.documentFor('sp-drop') == null &&
        bundle.spoilerSanitization.droppedRecordIds.length == 1 &&
        bundle.spoilerSanitization.droppedRecordIds.single == 'sp-drop' &&
        text.contains('Void Fern')) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-spoiler-export-drop',
        evidence:
            'drop menghapus record ending dari bundel; laporan mencatat id '
            'ter-drop; record aman bertahan',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-spoiler-export-drop',
      evidence: 'ekspor drop tidak menghapus konten spoiler',
    );
  }

  static Wave3SecurityCheckOutcome _checkSpoilerSearchHiddenIdsOnly() {
    final index =
        EncyclopediaSearchIndex.withDocuments(<EncyclopediaSearchDocument>[
          _doc(
            'hidden-1',
            EncyclopediaDomain.mythTheology,
            secretTitle,
            spoiler: SpoilerLevel.ending,
          ),
          _doc('shown-1', EncyclopediaDomain.herbology, 'Void Fern'),
        ]);
    final report = index.search(
      EncyclopediaSearchQuery(text: ''),
      permission: EncyclopediaPermissionFilter(
        spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
      ),
    );
    final serialized = jsonEncode(report.toJson());
    if (report.hits.length == 1 &&
        report.hits.single.recordId == 'shown-1' &&
        report.hiddenRecordIds.length == 1 &&
        report.hiddenRecordIds.single == 'hidden-1' &&
        !serialized.contains(secretTitle)) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-spoiler-search-hidden-ids-only',
        evidence:
            'hidden hanya id; judul rahasia tak muncul di hits/facet/JSON',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-spoiler-search-hidden-ids-only',
      evidence: 'laporan pencarian membocorkan record tersembunyi',
    );
  }

  static Wave3SecurityCheckOutcome _checkSpoilerOverrideBeatsDefault() {
    const secret = SpoilerLevel.ending;
    final strictButUnlocked = SpoilerPolicy(
      defaultLevel: SpoilerLevel.safe,
      overrides: <String, SpoilerLevel>{'trusted': SpoilerLevel.ending},
    );
    final looseButLocked = SpoilerPolicy(
      defaultLevel: SpoilerLevel.ending,
      overrides: <String, SpoilerLevel>{'censored': SpoilerLevel.safe},
    );
    final unlocked = strictButUnlocked.allows(secret, recordKey: 'trusted');
    final lockedOut = looseButLocked.allows(secret, recordKey: 'censored');
    final defaultApplies = strictButUnlocked.allows(secret, recordKey: 'x');
    if (unlocked && !lockedOut && !defaultApplies) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-spoiler-override-beats-default',
        evidence:
            'override menang dua arah (longgarkan & ketatkan); record lain '
            'memakai default',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-spoiler-override-beats-default',
      evidence: 'override spoiler per-record tidak menang atas default',
    );
  }

  // --- import berbahaya ------------------------------------------------------

  static Wave3SecurityCheckOutcome _checkImportMalformedJson() {
    final report = EncyclopediaPortabilityService.validateJson('{not json');
    var importBlocked = false;
    try {
      EncyclopediaPortabilityService.importText('{not json');
    } on StateError {
      importBlocked = true;
    }
    if (report.hasBlockingIssues &&
        report
            .issuesOfKind(PortabilityValidationKind.malformedJson)
            .isNotEmpty &&
        importBlocked) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-import-malformed-json',
        evidence: 'JSON rusak -> blocking malformedJson -> importText melempar',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-import-malformed-json',
      evidence: 'payload malformed tidak ditolak fail-closed',
    );
  }

  static Wave3SecurityCheckOutcome _checkImportNonMapPayload() {
    var blocked = false;
    try {
      EncyclopediaPortabilityService.importText('[1,2,3]');
    } on StateError {
      blocked = true;
    }
    final report = EncyclopediaPortabilityService.validateJson('[1,2,3]');
    if (blocked &&
        report.hasBlockingIssues &&
        report
            .issuesOfKind(PortabilityValidationKind.malformedJson)
            .isNotEmpty) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-import-non-map-payload',
        evidence:
            'payload array non-object -> malformedJson blocking sebelum cast',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-import-non-map-payload',
      evidence: 'payload non-map tidak menghasilkan laporan blocking',
    );
  }

  static Wave3SecurityCheckOutcome _checkImportTamperedChecksum() {
    final bundle = EncyclopediaPortabilityService.buildBundle(
      documents: <EncyclopediaSearchDocument>[
        _doc('t1', EncyclopediaDomain.herbology, 'Void Fern'),
      ],
      options: EncyclopediaExportOptions(explicitExport: true),
    );
    final text = EncyclopediaPortabilityService.exportText(bundle);
    final tampered = text.replaceAll('Void Fern', 'Hacked Fern');
    var blocked = false;
    try {
      EncyclopediaPortabilityService.importText(tampered);
    } on StateError {
      blocked = true;
    }
    final report = EncyclopediaPortabilityService.validateJson(tampered);
    if (blocked &&
        report
            .issuesOfKind(PortabilityValidationKind.checksumMismatch)
            .isNotEmpty) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-import-tampered-checksum',
        evidence:
            'edit isi -> checksumMismatch blocking -> StateError; suntikan tak '
            'pernah masuk registry',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-import-tampered-checksum',
      evidence: 'payload tamper lolos verifikasi checksum',
    );
  }

  static Wave3SecurityCheckOutcome _checkImportMissingChecksum() {
    final bundle = EncyclopediaPortabilityService.buildBundle(
      documents: <EncyclopediaSearchDocument>[
        _doc('mc1', EncyclopediaDomain.herbology, 'Void Fern'),
      ],
      options: EncyclopediaExportOptions(explicitExport: true),
    );
    final decoded =
        jsonDecode(EncyclopediaPortabilityService.exportText(bundle))
            as Map<String, Object?>;
    final text = jsonEncode(<String, Object?>{...decoded}..remove('checksum'));
    final report = EncyclopediaPortabilityService.validateJson(text);
    var blocked = false;
    try {
      EncyclopediaPortabilityService.importText(text);
    } on StateError {
      blocked = true;
    }
    if (blocked &&
        report
            .issuesOfKind(PortabilityValidationKind.checksumMissing)
            .isNotEmpty) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-import-missing-checksum',
        evidence:
            'FIX 111.42: tanpa checksum -> blocking checksumMissing -> '
            'importText melempar (sebelumnya fail-open)',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-import-missing-checksum',
      evidence: 'payload tanpa checksum masih dapat diimpor',
    );
  }

  static Wave3SecurityCheckOutcome _checkImportUnsanitizedManifest() {
    final payload = <String, Object?>{
      'formatVersion': EncyclopediaPortabilityFormat.currentVersion,
      'documents': <Object?>[],
      'mediaManifest': <String, Object?>{
        'assetIds': <Object?>[],
        'missingAssetIds': <Object?>[],
        'sanitizationApplied': false,
        'creditsByAsset': <String, Object?>{},
        'licensesByAsset': <String, Object?>{},
      },
      'spoilerSanitization': <String, Object?>{
        'mode': 'keep',
        'maskedRecordIds': <Object?>[],
        'droppedRecordIds': <Object?>[],
      },
    };
    final report = EncyclopediaPortabilityService.validateJson(
      jsonEncode(payload),
    );
    if (report.hasBlockingIssues &&
        report
            .issuesOfKind(PortabilityValidationKind.mediaUnsanitized)
            .isNotEmpty) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-import-unsanitized-manifest',
        evidence: 'sanitizationApplied:false -> mediaUnsanitized blocking',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-import-unsanitized-manifest',
      evidence: 'manifest tak tersanitasi lolos validasi',
    );
  }

  // --- export safety ------------------------------------------------------------

  static Wave3SecurityCheckOutcome _checkExportExplicitOptIn() {
    var implicitRejected = false;
    try {
      EncyclopediaPortabilityService.buildBundle(
        documents: const <EncyclopediaSearchDocument>[],
        options: EncyclopediaExportOptions(explicitExport: false),
      );
    } on ArgumentError {
      implicitRejected = true;
    }
    if (implicitRejected) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-export-explicit-opt-in',
        evidence:
            'explicitExport:false melempar ArgumentError sebelum satu byte '
            'pun terbentuk',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-export-explicit-opt-in',
      evidence: 'ekspor implisit tanpa opt-in tidak ditolak',
    );
  }

  static Wave3SecurityCheckOutcome _checkExportMissingMediaExcluded() {
    final library = EncyclopediaMediaLibrary()
      ..register(
        EncyclopediaMediaAsset.validated(
          assetId: 'ok',
          kind: MediaKind.image,
          relativePath: 'assets/references/ok.png',
        ),
      )
      ..register(
        EncyclopediaMediaAsset.validated(
          assetId: 'gone',
          kind: MediaKind.image,
          relativePath: 'assets/references/gone.png',
        ),
      )
      ..markMissing('gone');
    final bundle = EncyclopediaPortabilityService.buildBundle(
      documents: const <EncyclopediaSearchDocument>[],
      options: EncyclopediaExportOptions(explicitExport: true),
      mediaLibrary: library,
    );
    if (!bundle.mediaManifest.assetIds.contains('gone') &&
        bundle.mediaManifest.missingAssetIds.contains('gone')) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-export-missing-media-excluded',
        evidence:
            'aset missing dikecualikan dari assetIds, dicatat di '
            'missingAssetIds',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-export-missing-media-excluded',
      evidence: 'media hilang ikut diekspor tanpa opt-in eksplisit',
    );
  }

  static Wave3SecurityCheckOutcome _checkExportRoundTripIntegrity() {
    final docs = <EncyclopediaSearchDocument>[
      _doc(
        'rt1',
        EncyclopediaDomain.herbology,
        'Void Fern',
        aliases: const ['ghost fern'],
      ),
      _doc('rt2', EncyclopediaDomain.bestiary, 'Cube Beast'),
    ];
    final bundle = EncyclopediaPortabilityService.buildBundle(
      documents: docs,
      options: EncyclopediaExportOptions(explicitExport: true),
    );
    final text = EncyclopediaPortabilityService.exportText(bundle);
    final imported = EncyclopediaPortabilityService.importText(text);
    final reExported = EncyclopediaPortabilityService.exportText(
      imported.bundle,
    );
    final registryClean =
        imported.registry.totalRecords == docs.length &&
        imported.registry.recordFor('rt1')?.title == 'Void Fern';
    if (EncyclopediaPortabilityService.verifyChecksum(text) &&
        reExported == text &&
        registryClean) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-export-round-trip-integrity',
        evidence:
            'export->import->export byte-identik; checksum terverifikasi; '
            'registry import tepat 2 record',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-export-round-trip-integrity',
      evidence: 'round trip mengubah payload atau checksum tidak cocok',
    );
  }

  // --- generator safety ------------------------------------------------------------

  static CulturalNameProfile _profile() {
    return CulturalNameProfile.validated(
      profileId: 'sec-prof',
      cultureId: 'c-sec',
      languageId: 'elv-s',
      entityTypes: const <NameEntityType>{NameEntityType.person},
    );
  }

  static SeededNameRequest _request(int seed) {
    return SeededNameRequest.validated(
      profile: _profile(),
      entityType: NameEntityType.person,
      seed: seed,
    );
  }

  static Wave3SecurityCheckOutcome _checkGeneratorExplicitSeed() {
    var zeroRejected = false;
    var negativeRejected = false;
    try {
      _request(0);
    } on ArgumentError {
      zeroRejected = true;
    }
    try {
      _request(-1);
    } on ArgumentError {
      negativeRejected = true;
    }
    if (zeroRejected && negativeRejected) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-generator-explicit-seed',
        evidence:
            'seed 0 dan negatif ditolak seedBlank — mustahil generasi ber-seed '
            'tersembunyi',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-generator-explicit-seed',
      evidence: 'seed implisit (0/negatif) diterima generator',
    );
  }

  static Wave3SecurityCheckOutcome _checkGeneratorReplayDeterminism() {
    final first = Wave3ScaleDatasets.runGeneratorBatches(
      batchCount: 2,
      batchSize: 8,
      seed: 20260916,
    );
    final replay = Wave3ScaleDatasets.runGeneratorBatches(
      batchCount: 2,
      batchSize: 8,
      seed: 20260916,
    );
    final other = Wave3ScaleDatasets.runGeneratorBatches(
      batchCount: 2,
      batchSize: 8,
      seed: 987654321,
    );
    final stable =
        first.first.texts.join('|') == replay.first.texts.join('|') &&
        first.last.texts.join('|') == replay.last.texts.join('|');
    final diverges = first.first.texts.join('|') != other.first.texts.join('|');
    if (stable && diverges) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-generator-replay-determinism',
        evidence:
            'replay seed sama byte-identik lintas proses dua pemanggilan; seed '
            'berbeda menghasilkan teks berbeda',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-generator-replay-determinism',
      evidence: 'generator tidak deterministik terhadap seed eksplisit',
    );
  }

  static Wave3SecurityCheckOutcome _checkGeneratorBatchBounds() {
    var zeroRejected = false;
    var overflowRejected = false;
    try {
      SeededNameGenerator.generateBatch(request: _request(7), count: 0);
    } on ArgumentError {
      zeroRejected = true;
    }
    try {
      SeededNameGenerator.generateBatch(
        request: _request(7),
        count: SeededNameGenerator.maxBatchSize + 1,
      );
    } on ArgumentError {
      overflowRejected = true;
    }
    if (zeroRejected && overflowRejected) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-generator-batch-bounds',
        evidence:
            'count 0 dan maxBatchSize+1 ditolak ArgumentError — batch tak '
            'terbatas mustahil',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-generator-batch-bounds',
      evidence: 'batas ukuran batch tidak ditegakkan',
    );
  }

  static Wave3SecurityCheckOutcome _checkGeneratorNoAutoCanon() {
    final batch = SeededNameGenerator.generateBatch(
      request: _request(424242),
      count: 3,
    );
    final before = jsonEncode(batch.toJson());
    final accepted = batch.accept(batch.proposals.first.proposalId);
    final after = jsonEncode(batch.toJson());
    if (before == after &&
        batch.acceptedCount == 0 &&
        accepted.acceptedCount == 1 &&
        accepted.count == batch.count) {
      return const Wave3SecurityCheckOutcome.pass(
        checkId: 'chk-generator-no-auto-canon',
        evidence:
            'accept hanya menandai salinan batch; batch asal byte-identik dan '
            'tidak ada jalur tulis kanon dari modul',
      );
    }
    return const Wave3SecurityCheckOutcome.failed(
      checkId: 'chk-generator-no-auto-canon',
      evidence: 'accept memutasi batch asal atau menulis kanon otomatis',
    );
  }

  static EncyclopediaSearchDocument _doc(
    String id,
    EncyclopediaDomain domain,
    String title, {
    List<String> aliases = const [],
    SpoilerLevel spoiler = SpoilerLevel.safe,
  }) {
    return EncyclopediaSearchDocument.validated(
      record: EncyclopediaRecord.validated(
        recordId: id,
        domain: domain,
        title: title,
      ),
      aliases: aliases,
      spoilerLevel: spoiler,
    );
  }
}
