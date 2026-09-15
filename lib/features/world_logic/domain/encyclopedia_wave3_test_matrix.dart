// Sprint 111.40 — Automated Test Matrix.
//
// Kontrak domain untuk matriks pengujian Wave 3 (Sprint 111). Step ini BUKAN
// fitur produk — ia memformalkan kesembilan required_suites kanonik
// (unit, property, integration, contract, migration, ui, generator_replay,
// end_to_end, regression) sebagai objek yang dapat diaudit: setiap suite
// punya verifier (sumber yang membuktikannya) dan catatan bukti, dan laporan
// agregatnya deterministik penuh (tanpa file IO, wall-clock, locale, random,
// atau jaringan).
//
// Batas jujur yang disengaja:
// - `migration` di Wave 3 = pemeriksaan kompatibilitas skema DOMAIN
//   (SchemaCompatibilityCheck 111.6). Migrasi Drift nyata TETAP di bawah
//   D-SCHEMA-01 (OPEN) dan tidak diklaim di sini.
// - `ui` di level domain = kontrak navigasi keyboard atas hasil pencarian
//   nyata (111.37); lapisan widget adalah step UI tersendiri.
// - Census modul (`wave3DomainModules`) adalah manifest statis hasil audit
//   16 Sep 2026: setiap modul yang terdaftar dipastikan punya minimal satu
//   berkas tes terpus yang mengimpornya.
import 'dart:convert';

/// Satu entri suite dalam matriks: nama, verifier, bukti, dan hitungan sumber.
/// Immutable; [sourceCount] nol berarti suite TIDAK memiliki verifier = gagal.
class EncyclopediaTestSuiteEntry {
  const EncyclopediaTestSuiteEntry._({
    required this.name,
    required this.verifier,
    required this.evidence,
    required this.sourceCount,
  });

  /// Konstruktor tervalidasi: ketiga teks wajib non-kosong setelah trim;
  /// [sourceCount] tidak boleh negatif.
  factory EncyclopediaTestSuiteEntry.validated({
    required String name,
    required String verifier,
    required String evidence,
    required int sourceCount,
  }) {
    return EncyclopediaTestSuiteEntry._(
      name: _requireTrimmed(name, 'name'),
      verifier: _requireTrimmed(verifier, 'verifier'),
      evidence: _requireTrimmed(evidence, 'evidence'),
      sourceCount: _requireNonNegative(sourceCount, 'sourceCount'),
    );
  }

  final String name;
  final String verifier;
  final String evidence;
  final int sourceCount;

  /// Suite dianggap terverifikasi bila ada minimal satu sumber pembukti.
  bool get passed => sourceCount > 0;

  /// Salinan dengan hitungan sumber berbeda (entri asal tak berubah).
  EncyclopediaTestSuiteEntry withSourceCount(int count) =>
      EncyclopediaTestSuiteEntry._(
        name: name,
        verifier: verifier,
        evidence: evidence,
        sourceCount: _requireNonNegative(count, 'sourceCount'),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'name': name,
    'verifier': verifier,
    'evidence': evidence,
    'sourceCount': sourceCount,
  };

  static EncyclopediaTestSuiteEntry fromJson(Map<String, Object?> json) {
    final sourceCount = json['sourceCount'];
    if (sourceCount is! int) {
      throw ArgumentError.value(sourceCount, 'sourceCount', 'must be an int');
    }
    return EncyclopediaTestSuiteEntry.validated(
      name: json['name']! as String,
      verifier: json['verifier']! as String,
      evidence: json['evidence']! as String,
      sourceCount: sourceCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaTestSuiteEntry &&
          other.name == name &&
          other.verifier == verifier &&
          other.evidence == evidence &&
          other.sourceCount == sourceCount);

  @override
  int get hashCode => Object.hash(name, verifier, evidence, sourceCount);
}

/// Deklarasi kanonik sembilan required_suites sprint_111.json langkah 111.40.
/// Sumber urutan: daftar nama terurut alfabetis — stabil untuk JSON.
class EncyclopediaWave3TestMatrix {
  const EncyclopediaWave3TestMatrix._();

  static const String _domainVerifier =
      'test/features/world_logic/sprint_111_40_test_matrix_test.dart';

  /// Kesembilan suite wajib, sumber-nol sampai [|fromSources] memetakannya.
  static const List<EncyclopediaTestSuiteEntry>
  suites = <EncyclopediaTestSuiteEntry>[
    EncyclopediaTestSuiteEntry._(
      name: 'contract',
      verifier: _domainVerifier,
      evidence:
          'JSON byte-stability lintas modul (proposal batch, laporan tabrakan, '
          'bundel portability) + tolak payload rusak lewat laporan.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'end_to_end',
      verifier: _domainVerifier,
      evidence:
          'Rantai penuh generate -> accept -> canonicalize -> index -> search '
          '-> export -> import -> re-search di atas modul 111.29..111.39.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'generator_replay',
      verifier: _domainVerifier,
      evidence:
          'Vektor golden seed->teks/proposalId beku (probe terukur, bukan '
          'karangan) direplikasi byte-exact + rantai nextSeed beku.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'integration',
      verifier: _domainVerifier,
      evidence:
          'Rantai lintas modul: generator->validator tabrakan, '
          'generator->indeks pencarian, portability round-trip.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'migration',
      verifier: _domainVerifier,
      evidence:
          'SchemaCompatibilityCheck 111.6 pada registri kosong, sampel bersih, '
          'dan kasus missing-category (check tidak vacuous). Migrasi Drift '
          'tetap di bawah D-SCHEMA-01 (OPEN) — tidak diklaim.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'property',
      verifier: _domainVerifier,
      evidence:
          'Invarian generator atas seed tersampel: determinisme, unisitas, '
          'invarian inventory, regenerasi seed-turunan berbeda.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'regression',
      verifier: _domainVerifier,
      evidence:
          'Sensus modul Wave 3 (manifest audit) + idempotensi agregat matriks; '
          'regresi penuh test/features/world_logic dijalankan sebagai gate.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'ui',
      verifier: _domainVerifier,
      evidence:
          'Kontrak navigasi keyboard 111.37 mengemudi seleksi atas hasil '
          'pencarian nyata (clamp tanpa wrap). Lapisan widget = step UI '
          'tersendiri.',
      sourceCount: 0,
    ),
    EncyclopediaTestSuiteEntry._(
      name: 'unit',
      verifier: 'test/features/world_logic/domain/*_test.dart (sensus)',
      evidence:
          'Setiap modul domain Wave 3 punya minimal satu berkas tes terpus '
          'yang mengimpornya — census diverifikasi audit 16 Sep 2026.',
      sourceCount: 0,
    ),
  ];

  /// Nama suite terurut alfabetis (stabil untuk JSON dan perbandingan).
  static List<String> get suiteNames =>
      List<String>.unmodifiable(suites.map((s) => s.name));

  static EncyclopediaTestSuiteEntry? suiteNamed(String name) {
    for (final suite in suites) {
      if (suite.name == name) return suite;
    }
    return null;
  }
}

/// Agregat deterministik atas kesembilan entri dengan hitungan sumber.
class EncyclopediaWave3TestMatrixReport {
  EncyclopediaWave3TestMatrixReport._({
    required List<EncyclopediaTestSuiteEntry> entries,
  }) : entries = List<EncyclopediaTestSuiteEntry>.unmodifiable(
         List<EncyclopediaTestSuiteEntry>.of(entries)
           ..sort((a, b) => a.name.compareTo(b.name)),
       );

  /// Bangun dari entri eksplisit: nama harus bagian dari matrix kanonik dan
  /// unik (duplikat = [StateError]).
  factory EncyclopediaWave3TestMatrixReport.of(
    List<EncyclopediaTestSuiteEntry> entries,
  ) {
    final seen = <String>{};
    for (final entry in entries) {
      if (EncyclopediaWave3TestMatrix.suiteNamed(entry.name) == null) {
        throw ArgumentError.value(
          entry.name,
          'entries',
          'unknown suite name: ${entry.name}',
        );
      }
      if (!seen.add(entry.name)) {
        throw StateError('duplicate suite entry: ${entry.name}');
      }
    }
    return EncyclopediaWave3TestMatrixReport._(entries: entries);
  }

  /// Peta nama -> jumlah sumber verifier. Nama tak dikenal ditolak
  /// (fail-closed — baris karangan tidak pernah sah); nama kanonik yang
  /// tidak ada di peta dihitung nol = suite gagal.
  factory EncyclopediaWave3TestMatrixReport.fromSources(
    Map<String, int> sources,
  ) {
    for (final name in sources.keys) {
      if (EncyclopediaWave3TestMatrix.suiteNamed(name) == null) {
        throw ArgumentError.value(name, 'sources', 'unknown suite name: $name');
      }
    }
    return EncyclopediaWave3TestMatrixReport._(
      entries: <EncyclopediaTestSuiteEntry>[
        for (final suite in EncyclopediaWave3TestMatrix.suites)
          suite.withSourceCount(sources[suite.name] ?? 0),
      ],
    );
  }

  static EncyclopediaWave3TestMatrixReport fromJson(Map<String, Object?> json) {
    final raw = json['entries'];
    if (raw is! List) {
      throw ArgumentError.value(raw, 'entries', 'must be a list');
    }
    return EncyclopediaWave3TestMatrixReport.of(<EncyclopediaTestSuiteEntry>[
      for (final entry in raw)
        EncyclopediaTestSuiteEntry.fromJson(
          (entry! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
    ]);
  }

  final List<EncyclopediaTestSuiteEntry> entries;

  int get totalCount => entries.length;

  int get passedCount => entries.where((e) => e.passed).length;

  /// Nama suite gagal, terurut alfabetis, immutable.
  List<String> get failedSuiteNames => List<String>.unmodifiable(
    entries.where((e) => !e.passed).map((e) => e.name),
  );

  /// Rasio lulus [0,1]; nol bila laporan kosong.
  double get coverage => entries.isEmpty ? 0 : passedCount / entries.length;

  bool get isComplete =>
      entries.length == EncyclopediaWave3TestMatrix.suites.length &&
      passedCount == entries.length;

  EncyclopediaTestSuiteEntry? entryFor(String name) {
    for (final entry in entries) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'entries': <Object?>[for (final entry in entries) entry.toJson()],
    'totalCount': totalCount,
    'passedCount': passedCount,
  };

  /// Ringkasan teks deterministik untuk log gate.
  String describe() {
    final buffer = StringBuffer()
      ..writeln('Wave 3 test matrix: $passedCount/$totalCount suites PASS');
    for (final entry in entries) {
      buffer.writeln(
        '- ${entry.name}: ${entry.passed ? 'PASS' : 'FAIL'} '
        '(${entry.sourceCount} sources, verifier=${entry.verifier})',
      );
    }
    if (!isComplete) {
      buffer.write(
        'matrix INCOMPLETE — missing: ${failedSuiteNames.join(', ')}',
      );
    } else {
      buffer.write('matrix COMPLETE');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaWave3TestMatrixReport &&
          jsonEncode(other.toJson()) == jsonEncode(toJson()));

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// Satu vektor golden generator: seed eksplisit -> teks + proposalId beku.
/// Nilai beku hasil probe terukur di toolchain Windows (bukan karangan).
class EncyclopediaGoldenSeedVector {
  const EncyclopediaGoldenSeedVector._({
    required this.seed,
    required this.texts,
    required this.proposalIds,
  });

  factory EncyclopediaGoldenSeedVector.validated({
    required int seed,
    required List<String> texts,
    required List<String> proposalIds,
  }) {
    if (seed <= 0) {
      throw ArgumentError.value(seed, 'seed', 'seed must be > 0');
    }
    if (texts.isEmpty || texts.length != proposalIds.length) {
      throw ArgumentError.value(
        texts.length,
        'texts',
        'texts and proposalIds must be non-empty and equal length',
      );
    }
    for (final text in texts) {
      if (text.trim().isEmpty) {
        throw ArgumentError.value(text, 'texts', 'text must be non-empty');
      }
    }
    return EncyclopediaGoldenSeedVector._(
      seed: seed,
      texts: List<String>.unmodifiable(texts),
      proposalIds: List<String>.unmodifiable(proposalIds),
    );
  }

  static EncyclopediaGoldenSeedVector fromJson(Map<String, Object?> json) {
    final seed = json['seed'];
    if (seed is! int) {
      throw ArgumentError.value(seed, 'seed', 'must be an int');
    }
    return EncyclopediaGoldenSeedVector.validated(
      seed: seed,
      texts: (json['texts']! as List<Object?>).cast<String>(),
      proposalIds: (json['proposalIds']! as List<Object?>).cast<String>(),
    );
  }

  final int seed;
  final List<String> texts;
  final List<String> proposalIds;

  int get count => texts.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'seed': seed,
    'texts': List<String>.from(texts),
    'proposalIds': List<String>.from(proposalIds),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EncyclopediaGoldenSeedVector &&
          other.seed == seed &&
          _sameStrings(other.texts, texts) &&
          _sameStrings(other.proposalIds, proposalIds));

  @override
  int get hashCode =>
      Object.hash(seed, Object.hashAll(texts), Object.hashAll(proposalIds));
}

/// Vektor golden beku untuk suite generator_replay.
class EncyclopediaWave3GoldenVectors {
  const EncyclopediaWave3GoldenVectors._();

  /// Konfigurasi replay: profil+spec di fixture matriks (elv-a, 3 suku
  /// kata, tanpa afiks) — perubahan generator sekecil apa pun akan
  /// memecahkan replay ini = regresi tertangkap.
  static const List<EncyclopediaGoldenSeedVector> seedVectors =
      <EncyclopediaGoldenSeedVector>[
        EncyclopediaGoldenSeedVector._(
          seed: 20260916,
          texts: <String>[
            'Karakmak',
            'Sesilnil',
            'Takmaklik',
            'Lakise',
            'Nilsalrel',
            'Kilkini',
            'Kirekta',
            'Lekneri',
          ],
          proposalIds: <String>[
            'np-6127f436582a1984',
            'np-1949cc71065c94b3',
            'np-5f45fd02ec149388',
            'np--5b041cb29798e647',
            'np--29ea2cdbff6dffcd',
            'np--24677d8cc7c96373',
            'np--76451066216b04cc',
            'np--10f19409ac35fea2',
          ],
        ),
        EncyclopediaGoldenSeedVector._(
          seed: 1,
          texts: <String>['Laknaklak', 'Minikil', 'Leniti', 'Limaksik'],
          proposalIds: <String>[
            'np-6ebb7d8dd5bf03da',
            'np--2e2889805f6765e2',
            'np--4ed9c502fc8bf665',
            'np--5041ccb729148de8',
          ],
        ),
        EncyclopediaGoldenSeedVector._(
          seed: 987654321,
          texts: <String>['Namelsa', 'Silkilmak', 'Larene', 'Sakita'],
          proposalIds: <String>[
            'np--1aacc37df140e813',
            'np--64bd894c4a3a428c',
            'np--6df016102cdea413',
            'np-2448b1bc6f30aa40',
          ],
        ),
      ];

  /// Rantai seed turunan (nextSeed) beku dari start 20260916 sepanjang 8.
  static const int seedChainStart = 20260916;
  static const int seedChainLength = 8;
  static const List<int> seedChain = <int>[
    20260916,
    536485690083857610,
    581575079265485054,
    1469159760392966205,
    8129802667767773830,
    2551917999901379389,
    815037790930304375,
    2939009994093364313,
  ];
}

/// Manifest sumber verifikasi Wave 3 hasil audit 16 Sep 2026.
class EncyclopediaWave3TestSuiteSources {
  const EncyclopediaWave3TestSuiteSources._();

  /// 37 modul domain Wave 3 di lib/features/world_logic/domain — setiap nama
  /// dipastikan punya minimal satu berkas tes terpus yang mengimpornya
  /// (audit scan tree test/, 16 Sep 2026).
  static const List<String> _wave3DomainModules = <String>[
    'encyclop_canon_provenance.dart',
    'encyclopedia_activation_rules.dart',
    'encyclopedia_alchemy.dart',
    'encyclopedia_alchemy_validation.dart',
    'encyclopedia_anatomy.dart',
    'encyclopedia_artifact.dart',
    'encyclopedia_artifact_validation.dart',
    'encyclopedia_belief_distribution.dart',
    'encyclopedia_belief_truth.dart',
    'encyclopedia_combat.dart',
    'encyclopedia_creature.dart',
    'encyclopedia_ecology.dart',
    'encyclopedia_effect.dart',
    'encyclopedia_encounter.dart',
    'encyclopedia_harvest.dart',
    'encyclopedia_harvestable_material.dart',
    'encyclopedia_idiom_consistency.dart',
    'encyclopedia_idiom_registry.dart',
    'encyclopedia_idiom_tone.dart',
    'encyclopedia_idiom_usage.dart',
    'encyclopedia_ingredient.dart',
    'encyclopedia_integration.dart',
    'encyclopedia_media_rights.dart',
    'encyclopedia_myth.dart',
    'encyclopedia_name_collision.dart',
    'encyclopedia_name_profiles.dart',
    'encyclopedia_ownership_lineage.dart',
    'encyclopedia_portability.dart',
    'encyclopedia_reveal_links.dart',
    'encyclopedia_scope.dart',
    'encyclopedia_seeded_name_generation.dart',
    'encyclopedia_spoiler_accessibility.dart',
    'encyclopedia_syllable_phonotactics.dart',
    'encyclopedia_theology.dart',
    'encyclopedia_unified_search.dart',
    'shared_encyclopedia_schema.dart',
    'shared_encyclopedia_taxonomy.dart',
  ];

  static List<String> wave3DomainModules() =>
      List<String>.unmodifiable(_wave3DomainModules);

  /// Jumlah sumber verifier per suite — hasil audit 16 Sep 2026 (lihat
  /// catatan evidence tiap suite). Semua positif = matriks Wave 3 lengkap
  /// pada level domain.
  static Map<String, int> wave3MatrixCounts() {
    return <String, int>{
      'unit': _wave3DomainModules.length,
      'property': 5,
      'integration': 3,
      'contract': 2,
      'migration': 3,
      'ui': 1,
      'generator_replay': 3,
      'end_to_end': 1,
      'regression': 3,
    };
  }
}

String _requireTrimmed(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, field, '$field must be non-empty');
  }
  return trimmed;
}

int _requireNonNegative(int value, String field) {
  if (value < 0) {
    throw ArgumentError.value(value, field, '$field must be >= 0');
  }
  return value;
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
