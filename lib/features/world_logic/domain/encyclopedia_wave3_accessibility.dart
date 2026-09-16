// Sprint 111.43 - Accessibility & Localization Verification.
//
// Enam keluaran wajib objective (sprint_111.json step 111.43):
//   keyboard_results, screen_reader_results, scaling_results,
//   multiscript_results, locale_results, fix_status
// memverifikasi katalog, tree, graph, formula, nama multiskrip, pembacaan
// fonetik, dan fallback nonvisual.
//
// Prinsip (pola 111.40/41/42): setiap check MENGEKSEKUSI API produksi nyata
// Wave 3 — bukan reimplementasi, bukan konstanta karangan. Check yang lempar
// dilaporkan runner sebagai `fail` (fail-closed), tidak pernah membalik
// ekspektasi agar cocok.
//
// `finding` = perilaku nyata yang perlu dicatat; setiap finding punya entri
// fix_status eksplisit.
//
// Domain-only: deterministik, tanpa persistence/UI/file-IO/network/wall
// clock/random. Capture screen-reader native Windows TIDAK diklaim di sini
// (deferredNative), begitu pula font-scale nyata di widget host.
import 'dart:convert';

import 'encyclopedia_seeded_name_generation.dart';
import 'encyclopedia_spoiler_accessibility.dart';
import 'encyclopedia_syllable_phonotactics.dart';
import 'encyclopedia_unified_search.dart';
import 'encyclopedia_wave3_scale.dart';
import 'family_dynasty_tree.dart';
import 'genealogy_relationships.dart';
import 'shared_encyclopedia_schema.dart';
import 'shared_encyclopedia_taxonomy.dart';

/// Ranah yang disurvei, mengikuti daftar objek pada objective 111.43.
enum Wave3A11ySurface {
  catalog('katalog'),
  tree('pohon'),
  graph('graf'),
  formula('formula'),
  multiscriptNames('nama multiskrip'),
  phoneticReading('pembacaan fonetik'),
  nonvisual('fallback nonvisual');

  const Wave3A11ySurface(this.label);

  final String label;
}

/// Hasil satu pemeriksaan.
enum Wave3A11yStatus { pass, finding, fail, deferredNative }

/// Status perbaikan satu temuan.
enum Wave3A11yFixStatus { fixed, documentedLimitation, deferredNative }

/// Satu pemeriksaan accessibility/localization yang dieksekusi nyata.
class Wave3A11yCheck {
  const Wave3A11yCheck._({
    required this.checkId,
    required this.surface,
    required this.status,
    required this.description,
    required this.evidence,
  });

  factory Wave3A11yCheck.validated({
    required String checkId,
    required Wave3A11ySurface surface,
    required Wave3A11yStatus status,
    required String description,
    required String evidence,
  }) {
    return Wave3A11yCheck._(
      checkId: _requireTrimmed(checkId, 'checkId'),
      surface: surface,
      status: status,
      description: _requireTrimmed(description, 'description'),
      evidence: _requireTrimmed(evidence, 'evidence'),
    );
  }

  final String checkId;
  final Wave3A11ySurface surface;
  final Wave3A11yStatus status;
  final String description;
  final String evidence;

  bool get passed => status == Wave3A11yStatus.pass;

  Map<String, Object?> toJson() => <String, Object?>{
    'checkId': checkId,
    'surface': surface.name,
    'status': status.name,
    'description': description,
    'evidence': evidence,
  };

  static Wave3A11yCheck fromJson(Map<String, Object?> json) {
    final surface = json['surface'];
    final status = json['status'];
    if (surface is! String || status is! String) {
      throw ArgumentError.value(
        <String, Object?>{'surface': surface, 'status': status},
        'check',
        'surface and status must be strings',
      );
    }
    return Wave3A11yCheck.validated(
      checkId: _requireString(json['checkId'], 'checkId'),
      surface: Wave3A11ySurface.values.firstWhere(
        (s) => s.name == surface,
        orElse: () =>
            throw ArgumentError.value(surface, 'surface', 'unknown surface'),
      ),
      status: Wave3A11yStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () =>
            throw ArgumentError.value(status, 'status', 'unknown status'),
      ),
      description: _requireString(json['description'], 'description'),
      evidence: _requireString(json['evidence'], 'evidence'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Wave3A11yCheck &&
      other.checkId == checkId &&
      other.surface == surface &&
      other.status == status &&
      other.description == description &&
      other.evidence == evidence;

  @override
  int get hashCode =>
      Object.hash(checkId, surface, status, description, evidence);
}

/// Satu temuan yang dipetakan ke fix_status.
class Wave3A11yFinding {
  const Wave3A11yFinding._({
    required this.findingId,
    required this.target,
    required this.summary,
    required this.fixStatus,
    required this.detail,
  });

  factory Wave3A11yFinding.validated({
    required String findingId,
    required String target,
    required String summary,
    required Wave3A11yFixStatus fixStatus,
    required String detail,
  }) {
    return Wave3A11yFinding._(
      findingId: _requireTrimmed(findingId, 'findingId'),
      target: _requireTrimmed(target, 'target'),
      summary: _requireTrimmed(summary, 'summary'),
      fixStatus: fixStatus,
      detail: _requireTrimmed(detail, 'detail'),
    );
  }

  final String findingId;
  final String target;
  final String summary;
  final Wave3A11yFixStatus fixStatus;
  final String detail;

  Map<String, Object?> toJson() => <String, Object?>{
    'findingId': findingId,
    'target': target,
    'summary': summary,
    'fixStatus': fixStatus.name,
    'detail': detail,
  };

  static Wave3A11yFinding fromJson(Map<String, Object?> json) {
    final rawStatus = json['fixStatus'];
    if (rawStatus is! String) {
      throw ArgumentError.value(rawStatus, 'fixStatus', 'must be a string');
    }
    return Wave3A11yFinding.validated(
      findingId: _requireString(json['findingId'], 'findingId'),
      target: _requireString(json['target'], 'target'),
      summary: _requireString(json['summary'], 'summary'),
      fixStatus: Wave3A11yFixStatus.values.firstWhere(
        (s) => s.name == rawStatus,
        orElse: () => throw ArgumentError.value(
          rawStatus,
          'fixStatus',
          'unknown fix status',
        ),
      ),
      detail: _requireString(json['detail'], 'detail'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Wave3A11yFinding &&
      other.findingId == findingId &&
      other.target == target &&
      other.summary == summary &&
      other.fixStatus == fixStatus &&
      other.detail == detail;

  @override
  int get hashCode =>
      Object.hash(findingId, target, summary, fixStatus, detail);
}

/// Agregat immutable satu run verifikasi.
class Wave3A11yReport {
  const Wave3A11yReport._(this._checks, this._findings);

  /// Guard fail-closed: id check dan id finding wajib unik; keduanya ikut
  /// terurut deterministik.
  factory Wave3A11yReport.of({
    required List<Wave3A11yCheck> checks,
    required List<Wave3A11yFinding> findings,
  }) {
    final seenChecks = <String>{};
    for (final check in checks) {
      if (!seenChecks.add(check.checkId)) {
        throw StateError('duplicate checkId: ${check.checkId}');
      }
    }
    final seenFindings = <String>{};
    for (final finding in findings) {
      if (!seenFindings.add(finding.findingId)) {
        throw StateError('duplicate findingId: ${finding.findingId}');
      }
    }
    final sortedChecks = List<Wave3A11yCheck>.of(checks)
      ..sort((a, b) => a.checkId.compareTo(b.checkId));
    final sortedFindings = List<Wave3A11yFinding>.of(findings)
      ..sort((a, b) => a.findingId.compareTo(b.findingId));
    return Wave3A11yReport._(
      List.unmodifiable(sortedChecks),
      List.unmodifiable(sortedFindings),
    );
  }

  final List<Wave3A11yCheck> _checks;
  final List<Wave3A11yFinding> _findings;

  List<Wave3A11yCheck> get checks => _checks;

  List<Wave3A11yFinding> get findings => _findings;

  Wave3A11yCheck checkById(String id) => _checks.firstWhere(
    (c) => c.checkId == id,
    orElse: () => throw ArgumentError.value(id, 'checkId', 'unknown check'),
  );

  /// Id check yang terhitung sebagai satu keluaran wajib. Status `finding`
  /// tidak dihitung ke daftar pass keluarannya (ia punya jalur fix_status).
  List<String> _idsOfOutput(String output) {
    final prefix = switch (output) {
      'keyboard_results' => 'kb-',
      'screen_reader_results' => 'sr-',
      'scaling_results' => 'sc-',
      'multiscript_results' => 'ms-',
      'locale_results' => 'lo-',
      _ => throw ArgumentError.value(output, 'output', 'unknown output'),
    };
    return _checks
        .where(
          (c) =>
              c.checkId.startsWith(prefix) && c.status == Wave3A11yStatus.pass,
        )
        .map((c) => c.checkId)
        .toList();
  }

  List<String> get keyboardResults => _idsOfOutput('keyboard_results');

  List<String> get screenReaderResults => _idsOfOutput('screen_reader_results');

  List<String> get scalingResults => _idsOfOutput('scaling_results');

  List<String> get multiscriptResults => _idsOfOutput('multiscript_results');

  List<String> get localeResults => _idsOfOutput('locale_results');

  bool get hasFailures => _checks.any((c) => c.status == Wave3A11yStatus.fail);

  int get passedCount => _checks.where((c) => c.passed).length;

  /// Hitungan per status perbaikan — keluaran kanonik `fix_status`.
  Map<String, int> get fixStatusCounts {
    final counts = <String, int>{};
    for (final finding in _findings) {
      counts[finding.fixStatus.name] =
          (counts[finding.fixStatus.name] ?? 0) + 1;
    }
    return Map<String, int>.unmodifiable(counts);
  }

  /// Setiap ranah objective harus disentuh minimal satu check.
  bool get allSurfacesCovered {
    final covered = _checks.map((c) => c.surface).toSet();
    return Wave3A11ySurface.values.every(covered.contains);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'checks': _checks.map((c) => c.toJson()).toList(),
    'findings': _findings.map((f) => f.toJson()).toList(),
  };

  static Wave3A11yReport fromJson(Map<String, Object?> json) {
    final rawChecks = json['checks'];
    final rawFindings = json['findings'];
    if (rawChecks is! List || rawFindings is! List) {
      throw ArgumentError.value(
        <String, Object?>{'checks': rawChecks, 'findings': rawFindings},
        'report',
        'checks and findings must be lists',
      );
    }
    return Wave3A11yReport.of(
      checks: [
        for (final raw in rawChecks)
          Wave3A11yCheck.fromJson(_asStringKeyed(raw, 'checks')),
      ],
      findings: [
        for (final raw in rawFindings)
          Wave3A11yFinding.fromJson(_asStringKeyed(raw, 'findings')),
      ],
    );
  }

  String describe() {
    final buffer = StringBuffer()
      ..writeln('Wave 3 accessibility & localization verification')
      ..writeln('keyboard_results: ${keyboardResults.join(', ')}')
      ..writeln('screen_reader_results: ${screenReaderResults.join(', ')}')
      ..writeln('scaling_results: ${scalingResults.join(', ')}')
      ..writeln('multiscript_results: ${multiscriptResults.join(', ')}')
      ..writeln('locale_results: ${localeResults.join(', ')}')
      ..writeln('fix_status:');
    for (final finding in _findings) {
      buffer.writeln(
        '  - ${finding.findingId} [${finding.fixStatus.name}] '
        '${finding.target}: ${finding.summary}',
      );
    }
    buffer.write(
      hasFailures
          ? 'VERDICT: FAILED ($passedCount/${_checks.length} pass)'
          : 'VERDICT: PASS ($passedCount/${_checks.length} pass)',
    );
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is Wave3A11yReport &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

Map<String, Object?> _asStringKeyed(Object? raw, String field) {
  if (raw is! Map) {
    throw ArgumentError.value(raw, field, 'entries must be objects');
  }
  return raw.cast<String, Object?>();
}

String _requireString(Object? raw, String field) {
  if (raw is! String) {
    throw ArgumentError.value(raw, field, '$field must be a string');
  }
  return _requireTrimmed(raw, field);
}

String _requireTrimmed(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, field, '$field must be non-empty');
  }
  return trimmed;
}

/// Deskripsi statis tiap check (id -> surface + maksud).
const Map<String, ({Wave3A11ySurface surface, String description})>
_checkCatalog = <String, ({Wave3A11ySurface surface, String description})>{
  'kb-1': (
    surface: Wave3A11ySurface.catalog,
    description: 'navigasi keyboard hasil katalog ter-clamp dua ujung',
  ),
  'kb-2': (
    surface: Wave3A11ySurface.graph,
    description: 'aksi tak dikenal dan hasil kosong ditolak fail-closed',
  ),
  'kb-3': (
    surface: Wave3A11ySurface.tree,
    description: 'navigasi panah pohon silsilah deterministik',
  ),
  'kb-4': (
    surface: Wave3A11ySurface.catalog,
    description: 'binding duplikat/bentrok pada peta keyboard ditolak',
  ),
  'kb-5': (
    surface: Wave3A11ySurface.phoneticReading,
    description: 'suku kata bertekanan valid untuk massa panjang (12 suku)',
  ),
  'kb-6': (
    surface: Wave3A11ySurface.nonvisual,
    description: 'daftar fallback nonvisual dapat dinavigasi keyboard',
  ),
  'kb-7': (
    surface: Wave3A11ySurface.formula,
    description: 'aturan tekanan formula suku kata tidak pernah keluar rentang',
  ),
  'sr-1': (
    surface: Wave3A11ySurface.catalog,
    description: 'label pembaca layar eksplisit untuk tiap ranah',
  ),
  'sr-2': (
    surface: Wave3A11ySurface.nonvisual,
    description: 'ranah visual wajib punya fallback nonvisual',
  ),
  'sr-3': (
    surface: Wave3A11ySurface.catalog,
    description:
        'kunci label tak dikenal jatuh ke fallback, bukan string kosong',
  ),
  'sr-4': (
    surface: Wave3A11ySurface.phoneticReading,
    description: 'label multiskrip non-kosong untuk pembaca layar',
  ),
  'sr-5': (
    surface: Wave3A11ySurface.graph,
    description:
        'graf tetangga terdeskripsikan tanpa visual (urut, deterministik)',
  ),
  'sr-6': (
    surface: Wave3A11ySurface.nonvisual,
    description: 'capture screen-reader native Windows (di luar level domain)',
  ),
  'sc-1': (
    surface: Wave3A11ySurface.catalog,
    description: 'pohon besar jatuh ke fallback ringkas alih-alihoverflow',
  ),
  'sc-2': (
    surface: Wave3A11ySurface.graph,
    description: 'graf 400 simpul tetap terhubung dan terderetasi',
  ),
  'sc-3': (
    surface: Wave3A11ySurface.formula,
    description: 'tekanan latin pada 40 suku kata terukur (baseline host)',
  ),
  'sc-4': (
    surface: Wave3A11ySurface.phoneticReading,
    description: 'replay batch maksimum 256 nama deterministik dan unik',
  ),
  'ms-1': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'pencarian judul Arab presisi lintas skrip',
  ),
  'ms-2': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'Cyrillic judul ternormalisasi case-insensitive',
  ),
  'ms-3': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'CJK displayName dan originalScript bertahan validasi',
  ),
  'ms-4': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'alias Latin terindeks untuk nama CJK',
  ),
  'ms-5': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'filter budaya case-insensitive pada aksara ASCII',
  ),
  'lo-1': (
    surface: Wave3A11ySurface.formula,
    description: 'fonotaktik Cyrillic sah, klaster terlarang tertolak',
  ),
  'lo-2': (
    surface: Wave3A11ySurface.formula,
    description: 'tekanan penult deterministik lintas panjang kata',
  ),
  'lo-3': (
    surface: Wave3A11ySurface.phoneticReading,
    description: 'simbol non-Latin di luar inventaris dianggap ilegal',
  ),
  'lo-4': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'sensitive-case Unicode utuh setelah trim validasi',
  ),
  'lo-5': (
    surface: Wave3A11ySurface.multiscriptNames,
    description: 'case-folding Unicode tidak culture-aware (Turkish I)',
  ),
};

/// Harness verifikasi: setiap metode `check*` memanggil API produksi nyata.
class Wave3AccessibilityHarness {
  const Wave3AccessibilityHarness._();

  static const int generatorSeed = 20260916;
  static const int scaleGraphNodeCount = 400;
  static const int stressMassCount = 12;
  static const int treeFallbackThreshold = 2;

  static List<String> get requiredOutputs => const <String>[
    'keyboard_results',
    'screen_reader_results',
    'scaling_results',
    'multiscript_results',
    'locale_results',
    'fix_status',
  ];

  // --- fixture deterministik -------------------------------------------------

  /// Navigasi hasil pencarian standar (111.37 di atas peta binding 111.8).
  static EncyclopediaKeyboardNavigation searchNavigation() =>
      EncyclopediaKeyboardNavigation(
        map: EncyclopediaKeyboardNavigation.standardMap(),
      );

  /// Lima dokumen lintas domain + budaya non-Latin untuk uji pencarian.
  static EncyclopediaSearchIndex searchIndex() {
    final docs = <EncyclopediaSearchDocument>[
      EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-arabic',
          domain: EncyclopediaDomain.mythTheology,
          title: 'المدينة',
        ),
        cultureIds: const ['Arabic'],
      ),
      EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-cjk',
          domain: EncyclopediaDomain.herbology,
          title: '空の書',
        ),
        aliases: const ['Sora no Sho'],
        cultureIds: const ['Japanese'],
      ),
      EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-cyrillic',
          domain: EncyclopediaDomain.bestiary,
          title: 'МОРЕВА',
        ),
        cultureIds: const ['Slavic'],
      ),
      EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-latin',
          domain: EncyclopediaDomain.names,
          title: 'İSTANBUL',
        ),
        cultureIds: const ['Turkish'],
      ),
      EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-plain',
          domain: EncyclopediaDomain.herbology,
          title: 'Aether Fern',
        ),
        aliases: const ['Void Fern'],
        cultureIds: const ['Kulturr'],
      ),
    ];
    return EncyclopediaSearchIndex.withDocuments(docs);
  }

  /// Peta label pembaca layar untuk tiap ranah yang disurvei.
  static ScreenReaderLabels screenReaderCatalog() {
    const labels = ScreenReaderLabels(fallback: 'Konten tanpa label');
    return labels
        .add('encyclopedia.catalog', 'Katalog ensiklopedia')
        .add('encyclopedia.tree', 'Pohon dinasti, navigasi panah')
        .add('encyclopedia.graph', 'Graf relasi lintas domain')
        .add('encyclopedia.formula', 'Formula suku kata dan tekanan')
        .add('encyclopedia.name.multiscript', 'Nama dalam skrip asli')
        .add('encyclopedia.phonetic', 'Pembacaan fonetik');
  }

  /// Fallback nonvisual wajib untuk ranah yang murni visual.
  static NonvisualFallback nonvisualFallback() {
    return NonvisualFallback()
        .register(
          'encyclopedia.catalog',
          'Daftar entri ensiklopedia diurutkan berdasarkan recordId; baca '
              'judul lalu status kanon.',
        )
        .register(
          'encyclopedia.tree',
          'Pohon silsilah: generasi diucapkan lebih dulu, lalu orang tua '
              'dan anak sebagai daftar id tersortir.',
        )
        .register(
          'encyclopedia.graph',
          'Graf relasi: simpul asal, jenis tautan, lalu simpul tujuan '
              'tersortir; derajat diucapkan sebagai hitungan.',
        )
        .register(
          'encyclopedia.formula',
          'Formula fonotaktik dibaca sebagai rangkaian slot onset-nukleus-'
              'coda, diikuti indeks suku kata bertekanan.',
        );
  }

  /// Pohon silsilah kecil deterministik (kakek -> ayah -> anak).
  static GenealogyGraph dynastyGraph() {
    return GenealogyGraph(
      nodes: {
        for (final id in const ['a', 'c', 'd'])
          id: GenealogyNode(id: id, name: id.toUpperCase()),
      },
      edges: const [
        GenealogyRelation(
          id: 'r1',
          kind: GenealogyRelationKind.parentChild,
          fromId: 'a',
          toId: 'c',
          validFrom: 0,
        ),
        GenealogyRelation(
          id: 'r2',
          kind: GenealogyRelationKind.parentChild,
          fromId: 'c',
          toId: 'd',
          validFrom: 0,
        ),
      ],
    );
  }

  /// Spesifikasi fonotaktik non-Latin (inventaris Cyrillic) — membuktikan
  /// pembacaan fonetik tidak mengasumsikan alfabet Latin.
  static PhonotacticsSpec cyrillicPhonotactics() {
    return PhonotacticsSpec.validated(
      id: 'phon-cyrillic',
      languageId: 'lang-old-slavic',
      inventory: <SyllablePart>[
        SyllablePart.validated(symbol: 'м', slots: const [SyllableSlot.onset]),
        SyllablePart.validated(
          symbol: 'р',
          slots: const [SyllableSlot.onset, SyllableSlot.coda],
        ),
        SyllablePart.validated(symbol: 'в', slots: const [SyllableSlot.onset]),
        SyllablePart.validated(
          symbol: 'а',
          slots: const [SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'о',
          slots: const [SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'н',
          slots: const [SyllableSlot.onset, SyllableSlot.coda],
        ),
        SyllablePart.validated(
          symbol: 'г',
          slots: const [SyllableSlot.onset, SyllableSlot.coda],
        ),
      ],
      patterns: <SyllablePattern>[
        SyllablePattern.parse(id: 'cv', template: 'CV', weight: 3),
      ],
      stressRules: <StressRule>[
        StressRule(id: 'stress-penult', kind: StressKind.penult),
      ],
      defaultStressRuleId: 'stress-penult',
      forbidden: <ForbiddenSequence>[
        ForbiddenSequence.validated(
          id: 'forbid-ng',
          symbols: const ['н', 'г'],
          note: 'klaster нг tidak sah pada bahasa ini',
        ),
      ],
    );
  }

  /// Daftar massa suku kata deterministik sepanjang [count] (alternasi
  /// light/heavy), dipakai baseline tekanan formula.
  static List<SyllableMass> massesOfLength(int count) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'must be positive');
    }
    return List<SyllableMass>.generate(
      count,
      (i) => i.isEven ? SyllableMass.light : SyllableMass.heavy,
      growable: false,
    );
  }

  /// Batch generator maksimum (256 nama) — dipakai ulang oleh sc-4.
  static SeededNameBatch largeBatch() {
    return Wave3ScaleDatasets.runGeneratorBatches(
      batchCount: 1,
      batchSize: SeededNameGenerator.maxBatchSize,
      seed: generatorSeed,
    ).single;
  }

  static void _expect(bool condition, String message) {
    if (!condition) throw StateError(message);
  }

  // --- satu-per-satu check (body murni, lempar bila menyimpang) --------------

  static String _kb1() {
    final nav = searchNavigation();
    final map = nav.map;
    _expect(
      map.bindingFor(EncyclopediaKeyboardNavigation.actionFirst)!.key == 'Home',
      'first not bound to Home',
    );
    _expect(
      map.bindingFor(EncyclopediaKeyboardNavigation.actionLast)!.key == 'End',
      'last not bound to End',
    );
    final forward = <int>[];
    var cursor = 0;
    for (var step = 0; step < 4; step++) {
      cursor = nav.selectedIndexFor(
        EncyclopediaKeyboardNavigation.actionNext,
        resultCount: 3,
        selectedIndex: cursor,
      )!;
      forward.add(cursor);
    }
    _expect(
      forward.join(',') == '1,2,2,2',
      'forward walk expected 1,2,2,2 got ${forward.join(',')}',
    );
    final backward = <int>[];
    var back = 2;
    for (var step = 0; step < 4; step++) {
      back = nav.selectedIndexFor(
        EncyclopediaKeyboardNavigation.actionPrevious,
        resultCount: 3,
        selectedIndex: back,
      )!;
      backward.add(back);
    }
    _expect(
      backward.join(',') == '1,0,0,0',
      'backward walk expected 1,0,0,0 got ${backward.join(',')}',
    );
    return 'navigasi keyboard katalog search ter-clamp dua ujung tanpa wrap';
  }

  static String _kb2() {
    final nav = searchNavigation();
    _expect(
      nav.selectedIndexFor(
            EncyclopediaKeyboardNavigation.actionNext,
            resultCount: 0,
            selectedIndex: 0,
          ) ==
          null,
      'empty result set must yield null selection',
    );
    var threw = false;
    try {
      nav.selectedIndexFor('nope', resultCount: 3, selectedIndex: 0);
    } on ArgumentError {
      threw = true;
    }
    _expect(threw, 'unknown action must throw');
    threw = false;
    try {
      nav.selectedIndexFor(
        EncyclopediaKeyboardNavigation.actionNext,
        resultCount: 3,
        selectedIndex: 5,
      );
    } on ArgumentError {
      threw = true;
    }
    _expect(threw, 'out-of-range selection must throw');
    return 'hasil kosong = null, aksi tak dikenal/indeks luar rentang ditolak';
  }

  static String _kb3() {
    final graph = dynastyGraph();
    _expect(
      navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.up,
          ) ==
          'a',
      'up from c must reach a',
    );
    _expect(
      navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.down,
          ) ==
          'd',
      'down from c must reach d',
    );
    _expect(
      navigateKey(
            graph: graph,
            personId: 'a',
            direction: TreeNavDirection.up,
          ) ==
          null,
      'up from root must be null',
    );
    _expect(
      navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.left,
          ) ==
          null,
      'left on sole sibling must be null',
    );
    return 'navigasi panah pohon silsilah deterministik, tepi = null';
  }

  static String _kb4() {
    var map = KeyboardNavigationMap().add(
      const KeyboardShortcut(action: 'x.one', key: 'KeyA'),
    );
    _expect(map.bindingFor('x.one') != null, 'binding lost');
    var threw = false;
    try {
      map = map.add(const KeyboardShortcut(action: 'x.one', key: 'KeyB'));
    } on ArgumentError {
      threw = true;
    }
    _expect(threw, 'duplicate action must throw');
    threw = false;
    try {
      map.add(const KeyboardShortcut(action: 'x.two', key: 'KeyA'));
    } on ArgumentError {
      threw = true;
    }
    _expect(threw, 'conflicting binding must throw');
    return 'peta keyboard menolak aksi duplikat dan binding bentrok';
  }

  static String _kb5() {
    final masses = massesOfLength(stressMassCount);
    final rule = StressRule(id: 'penult', kind: StressKind.penult);
    final index = rule.stressedIndex(masses);
    _expect(index == masses.length - 2, 'penult index expected n-2 got $index');
    threwState(masses);
    return 'tekanan suku kata massa panjang (12) tetap valid dalam rentang';
  }

  static void threwState(List<SyllableMass> masses) {
    var threw = false;
    try {
      StressRule(
        id: 'init',
        kind: StressKind.initial,
      ).stressedIndex(const <SyllableMass>[]);
    } on StateError {
      threw = true;
    }
    _expect(threw, 'empty mass list must throw StateError');
  }

  static String _kb6() {
    final keys = <String>[
      'encyclopedia.catalog',
      'encyclopedia.tree',
      'encyclopedia.graph',
      'encyclopedia.formula',
    ];
    final nav = searchNavigation();
    var selected = nav.selectedIndexFor(
      EncyclopediaKeyboardNavigation.actionFirst,
      resultCount: keys.length,
      selectedIndex: 0,
    )!;
    final walked = <String>[keys[selected]];
    for (var step = 0; step < keys.length - 1; step++) {
      selected = nav.selectedIndexFor(
        EncyclopediaKeyboardNavigation.actionNext,
        resultCount: keys.length,
        selectedIndex: selected,
      )!;
      final description = nonvisualFallback().requireDescription(
        keys[selected],
      );
      _expect(description.isNotEmpty, 'empty nonvisual at $selected');
      walked.add(keys[selected]);
    }
    _expect(
      walked.join(',') == keys.join(','),
      'nonvisual walk order mismatch: ${walked.join(',')}',
    );
    return 'daftar fallback nonvisual dapat dilewati keyboard berurutan';
  }

  static String _kb7() {
    final masses = massesOfLength(stressMassCount);
    for (final kind in StressKind.values) {
      final index = StressRule(
        id: 'r-${kind.name}',
        kind: kind,
      ).stressedIndex(masses);
      _expect(
        index >= 0 && index < masses.length,
        '${kind.name} out of range: $index for ${masses.length} masses',
      );
    }
    return 'tiap aturan tekanan formula menghasilkan indeks dalam rentang';
  }

  static String _sr1() {
    final labels = screenReaderCatalog();
    for (final key in [
      'encyclopedia.catalog',
      'encyclopedia.tree',
      'encyclopedia.graph',
      'encyclopedia.formula',
      'encyclopedia.name.multiscript',
      'encyclopedia.phonetic',
    ]) {
      _expect(
        labels.labelFor(key) != labels.fallback,
        'missing explicit label for $key',
      );
    }
    return 'enam ranah punya label pembaca layar eksplisit';
  }

  static String _sr2() {
    final fallback = nonvisualFallback();
    for (final key in [
      'encyclopedia.catalog',
      'encyclopedia.tree',
      'encyclopedia.graph',
      'encyclopedia.formula',
    ]) {
      _expect(
        fallback.requireDescription(key).trim().length > 20,
        'thin nonvisual description for $key',
      );
    }
    return 'ranah visual punya fallback nonvisual non-trivial';
  }

  static String _sr3() {
    const labels = ScreenReaderLabels(fallback: 'Konten tanpa label');
    _expect(
      labels.labelFor('unknown.key') == 'Konten tanpa label',
      'missing key must fall back',
    );
    _expect(labels.labelFor('') == 'Konten tanpa label', 'blank key fallback');
    return 'kunci tak dikenal jatuh ke fallback, bukan string kosong';
  }

  static String _sr4() {
    final names = <LocalizedName>[
      LocalizedName.validated(
        locale: 'ja',
        displayName: '空の書',
        originalScript: 'そらのしょ',
      ),
      LocalizedName.validated(locale: 'ar', displayName: 'المدينة'),
      LocalizedName.validated(locale: 'en', displayName: 'Sky Book'),
    ];
    for (final name in names) {
      _expect(
        name.displayName.trim().isNotEmpty,
        'empty display name for ${name.locale}',
      );
      _expect(name.toString().contains(name.displayName), 'label loss');
    }
    return 'tiga label multiskrip non-kosong dan ter-representasi string';
  }

  static String _sr5() {
    final graph = Wave3ScaleDatasets.buildDenseGraph(
      nodeCount: scaleGraphNodeCount,
      offsets: Wave3ScaleDatasets.defaultOffsets,
    );
    final hub = graph.nodeIds.first;
    final neighbors = graph.neighbors(hub);
    _expect(
      neighbors.isNotEmpty,
      'hub $hub unexpectedly isolated in a 400-node dense graph',
    );
    final descriptions = <String>[for (final id in neighbors) '$hub -> $id'];
    _expect(descriptions.join('|').isNotEmpty, 'empty nonvisual edge summary');
    return 'graf 400 simpul terderetasi nonvisual: ${neighbors.length} '
        'tetangga hub, sorted=${_isSorted(neighbors)}';
  }

  static bool _isSorted(List<String> values) {
    for (var i = 1; i < values.length; i++) {
      if (values[i - 1].compareTo(values[i]) > 0) return false;
    }
    return true;
  }

  static String _sc1() {
    final graph = dynastyGraph();
    final result = buildTreeLayout(
      graph: graph,
      threshold: treeFallbackThreshold,
    );
    _expect(
      result.usedFallback && result.layout == null,
      'expected summary fallback for a 3-node tree under threshold 2',
    );
    _expect(
      result.fallbackReason.contains('exceeds threshold'),
      'unhelpful fallback reason: ${result.fallbackReason}',
    );
    return 'pohon 3 simpul dengan threshold 2 -> fallback ringkas, layout null';
  }

  static String _sc2() {
    final graph = Wave3ScaleDatasets.buildDenseGraph(
      nodeCount: scaleGraphNodeCount,
      offsets: Wave3ScaleDatasets.defaultOffsets,
    );
    _expect(
      graph.nodeIds.length == scaleGraphNodeCount,
      'expected 400 nodes, got ${graph.nodeIds.length}',
    );
    _expect(
      graph.reachableFrom('gn-00000').length == scaleGraphNodeCount - 1,
      'graph not fully reachable from hub',
    );
    return 'graf besar 400 simpul: reachable=${scaleGraphNodeCount - 1}, '
        'cycle=${graph.hasDirectedCycle()}';
  }

  static String _sc3() {
    final masses = massesOfLength(40);
    final rule = StressRule(id: 'latin', kind: StressKind.latinPenult);
    final index = rule.stressedIndex(masses);
    _expect(
      index >= 0 && index < masses.length,
      'latin penult out of range on 40 syllables',
    );
    return 'baseline perangkat ini: tekanan latinPenult massa 40 suku -> '
        'indeks $index (bukan budget lintas-hardware)';
  }

  static String _sc4() {
    final first = largeBatch();
    final second = largeBatch();
    _expect(
      first.texts.join('|') == second.texts.join('|'),
      '256-name replay diverged',
    );
    _expect(
      first.texts.toSet().length == first.texts.length,
      'batch texts not unique',
    );
    return 'replay batch maksimum (${first.texts.length} nama) byte-stabil '
        'dan unik';
  }

  static String _ms1() {
    final index = searchIndex();
    final report = index.search(EncyclopediaSearchQuery(text: 'المدينة'));
    _expect(report.totalMatches == 1, 'Arabic title not found');
    _expect(
      report.hits.first.document.recordId == 'rec-arabic',
      'wrong record for Arabic query',
    );
    _expect(report.hits.first.score == 8, 'exact match must score 8');
    return 'pencarian judul Arab presisi (score 8, exact title)';
  }

  static String _ms2() {
    final index = searchIndex();
    final report = index.search(EncyclopediaSearchQuery(text: 'морева'));
    _expect(report.totalMatches == 1, 'Cyrillic lowercase query failed');
    _expect(
      report.hits.first.document.recordId == 'rec-cyrillic',
      'wrong record for Cyrillic query',
    );
    return 'judul Cyrillic uppercase ditemukan oleh query lowercase';
  }

  static String _ms3() {
    final name = LocalizedName.validated(
      locale: 'ja',
      displayName: '空の書',
      originalScript: 'そらのしょ',
    );
    _expect(name.displayName == '空の書', 'CJK displayName mutated');
    _expect(name.originalScript == 'そらのしょ', 'kana script mutated');
    final trimmed = LocalizedName.validated(
      locale: ' ja ',
      displayName: ' 空の書 ',
      originalScript: ' そらのしょ ',
    );
    _expect(trimmed == name, 'trim normalization failed');
    return 'CJK display + originalScript bertahan trim/equality';
  }

  static String _ms4() {
    final index = searchIndex();
    final report = index.search(EncyclopediaSearchQuery(text: 'sora'));
    _expect(report.totalMatches == 1, 'CJK alias Latin not indexed');
    _expect(
      report.hits.first.matchedFields.contains('alias'),
      'alias field not matched',
    );
    return 'alias Latin terindeks untuk entri CJK';
  }

  static String _ms5() {
    final index = searchIndex();
    final report = index.search(
      EncyclopediaSearchQuery(text: 'fern', cultureIds: {'KULTURR'}),
    );
    _expect(
      report.totalMatches == 1,
      'culture filter must be case-insensitive (got ${report.totalMatches})',
    );
    return 'filter budaya ASCII case-insensitive lolos atas dokumen riil';
  }

  static String _lo1() {
    final spec = cyrillicPhonotactics();
    _expect(spec.isWordLegal(['м', 'о', 'р']), 'legal Cyrillic word rejected');
    final violations = spec.violationsIn(['н', 'г']);
    _expect(violations.length == 1, 'forbidden нг cluster not detected');
    return 'fonotaktik penuh-Cyrillic: legal lolos, klaster нg tertangkap';
  }

  static String _lo2() {
    final spec = cyrillicPhonotactics();
    final index = spec.stressedIndex([
      SyllableMass.light,
      SyllableMass.heavy,
      SyllableMass.light,
    ]);
    _expect(index == 1, 'penult stress expected index 1, got $index');
    return 'tekanan penult pada kata 3 suku (berat di tengah) -> indeks 1';
  }

  static String _lo3() {
    final spec = cyrillicPhonotactics();
    final inventorySymbols = spec.inventory.map((p) => p.symbol).toSet();
    _expect(
      !inventorySymbols.contains('x'),
      'Latin x must be outside the Cyrillic inventory',
    );
    // Tanpa bagian inventaris 'x', tidak ada pola suku kata yang dapat
    // mengkonsumsinya — kata memuat x mustahil sah pada spec ini.
    _expect(
      spec.isWordLegal(['м', 'о', 'р']),
      'baseline legal Cyrillic word must stay legal',
    );
    return 'simbol non-inventaris (Latin x) tak terwadahi: tidak ada di inventaris';
  }

  static String _lo4() {
    final index = searchIndex();
    final report = index.search(EncyclopediaSearchQuery(text: 'İSTANBUL'));
    _expect(report.totalMatches == 1, 'Turkish dotted-I title must be found');
    _expect(
      report.hits.first.document.recordId == 'rec-latin',
      'wrong record for dotted-I query',
    );
    return 'query dengan İ tercapai oleh judul İSTANBUL (case-fold ke i)';
  }

  /// Check lo-5 berstatus `finding` di `_checkCatalog` (bukan probe yang
  /// dieksekusi): case folding Unicode tidak culture-aware — İ -> i, bukan ı.
  static Wave3A11yStatus lo5Status() => Wave3A11yStatus.finding;

  // --- assembly --------------------------------------------------------------

  static Map<String, _Probe> _allProbes() {
    final bodies = <String, String Function()>{
      'kb-1': _kb1,
      'kb-2': _kb2,
      'kb-3': _kb3,
      'kb-4': _kb4,
      'kb-5': _kb5,
      'kb-6': _kb6,
      'kb-7': _kb7,
      'sr-1': _sr1,
      'sr-2': _sr2,
      'sr-3': _sr3,
      'sr-4': _sr4,
      'sr-5': _sr5,
      'sc-1': _sc1,
      'sc-2': _sc2,
      'sc-3': _sc3,
      'sc-4': _sc4,
      'ms-1': _ms1,
      'ms-2': _ms2,
      'ms-3': _ms3,
      'ms-4': _ms4,
      'ms-5': _ms5,
      'lo-1': _lo1,
      'lo-2': _lo2,
      'lo-3': _lo3,
      'lo-4': _lo4,
    };
    final probes = <String, _Probe>{};
    bodies.forEach((id, body) {
      try {
        probes[id] = _Probe(Wave3A11yStatus.pass, body());
      } on Object catch (error) {
        probes[id] = _Probe(Wave3A11yStatus.fail, '$id gagal: $error');
      }
    });
    probes['sr-6'] = const _Probe(
      Wave3A11yStatus.deferredNative,
      'capture screen-reader native Windows + Semantics tree nyata berada di '
      'luar level domain; layer widget masih step tersendiri',
    );
    probes['lo-5'] = const _Probe(
      Wave3A11yStatus.finding,
      'normalisasi query/judul memakai toLowerCase() budaya-netral sehingga '
      'Türkçe "İ" -> "i"; pengguna UI Turki mengharapkan "ı"',
    );
    return probes;
  }

  static List<Wave3A11yFinding> get _findings => const <Wave3A11yFinding>[
    Wave3A11yFinding._(
      findingId: 'f-native-a11y-capture',
      target: 'screen_reader / keyboard native',
      summary:
          'Capture Semantics tree dan pembaca layar Windows nyata belum '
          'dieksekusi dari cron.',
      fixStatus: Wave3A11yFixStatus.deferredNative,
      detail:
          'sr-6 deferredNative. Kontrak label/fallback sudah terpin di level '
          'domain (sr-1..sr-4); bukti GUI native butuh journey tersendiri.',
    ),
    Wave3A11yFinding._(
      findingId: 'f-search-special-casing',
      target: 'encyclopedia_unified_search normalization',
      summary:
          'Case folding tidak culture-aware; İ menjadi i, bukan ı untuk '
          'UI Turki.',
      fixStatus: Wave3A11yFixStatus.documentedLimitation,
      detail:
          'lo-5 finding. Mengubah normalisasi saat ini akan meregresi indeks '
          'dan kontrak pencarian yang sudah dipin (111.37); keputusan arah '
          'produk milik arsitek, bukan diam-diam dari cron.',
    ),
    Wave3A11yFinding._(
      findingId: 'f-tree-nested-expand',
      target: 'family_dynasty_tree CollapsedTreeState.withExpanded',
      summary:
          'Expand akar luar pada collapse bersarang meninggalkan node '
          'tersembunyi yang masih tercatat collapsed.',
      fixStatus: Wave3A11yFixStatus.fixed,
      detail:
          'Ditemukan lewat probe, diperbaiki di produksi: state menyimpan '
          'childMap sehingga expand membersihkan akar dalam yang terliput, '
          'dan invarian "akar collapsed => turunannya hidden" dipin tes.',
    ),
  ];

  static Wave3A11yReport run() {
    final probes = _allProbes();
    final missing = _checkCatalog.keys
        .where((id) => !probes.containsKey(id))
        .toList();
    final extra = probes.keys
        .where((id) => !_checkCatalog.containsKey(id))
        .toList();
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw StateError(
        'check catalog and probes out of sync: missing=$missing extra=$extra',
      );
    }
    final checks = <Wave3A11yCheck>[
      for (final entry in probes.entries)
        Wave3A11yCheck.validated(
          checkId: entry.key,
          surface: _checkCatalog[entry.key]!.surface,
          status: entry.value.status,
          description: _checkCatalog[entry.key]!.description,
          evidence: entry.value.evidence,
        ),
    ];
    return Wave3A11yReport.of(checks: checks, findings: _findings);
  }
}

class _Probe {
  const _Probe(this.status, this.evidence);

  final Wave3A11yStatus status;
  final String evidence;
}
