// Sprint 111.41 — Performance & Scale Validation (Wave 3, domain-only).
//
// Objective kanonik sprint_111.json: menguji katalog besar, media banyak,
// graph padat, pencarian lintas domain, dan batch generator.
// Required outputs: datasets, budgets, results, index_strategy, bottlenecks,
// mitigations — dipetakan sebagai Wave3ScaleProfile (datasets),
// Wave3ScaleBudget (budgets), Wave3ScaleResult (results),
// Wave3IndexStrategy (index_strategy), Wave3ScaleBottleneck (bottlenecks),
// Wave3ScaleMitigation (mitigations).
//
// Konsumsi TANPA duplikasi:
//  - SplitMix64 dari wave 2 (performance_scale_benchmark.dart) sebagai
//    pembangun dataset deterministik.
//  - EncyclopediaSearchIndex / Query / Report (111.37) untuk pencarian
//    lintas domain skala besar.
//  - EncyclopediaGraph / EncyclopediaGraphEdge (111.38) untuk graph padat.
//  - SharedEncyclopediaSchema / EncyclopediaRecord (111.6) untuk katalog.
//  - EncyclopediaMediaLibrary / MediaExportManifest (111.7) untuk media.
//  - SeededNameGenerator + CulturalNameProfile + PhonotacticsSpec
//    (111.29-111.31) untuk batch generator.
//
// Determinisme: semua dataset dibangun dari seed SplitMix64 tetap; id dan
// isi tersortir kanonik; fingerprint dataset = FNV-1a 64 atas proyeksi isi
// NYATA hasil eksekusi builder (di-probe, bukan hash deklarasi). Dinding
// waktu hanya lewat Stopwatch terukur (pola wave 2) dengan ceiling keras
// longgar + budget turunan ber-headroom >= 4x sehingga variansi CI tidak
// membuat suite merah kecuali regresi nyata. Tanpa persistence, UI,
// network, locale, dart:math Random, atau wall-clock seed.

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_media_rights.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/performance_scale_benchmark.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_taxonomy.dart';

const int _mask64 = 0xFFFFFFFFFFFFFFFF;

/// FNV-1a 64-bit atas teks kanonik; bit tanda di-reserve dan LSB dipaksa 1
/// sehingga fingerprint selalu >= 1.
int wave3Fnv1a64(String text) {
  var hash = 0xCBF29CE484222325 & _mask64;
  for (final unit in text.codeUnits) {
    hash = (hash ^ unit) & _mask64;
    hash = (hash * 0x100000001B3) & _mask64;
  }
  return (hash & 0x7FFFFFFFFFFFFFFF) | 1;
}

/// Skenario kanonik objective 111.41. Urutan enum INI adalah urutan
/// pelaporan kanonik.
enum Wave3ScaleScenario {
  catalogLarge,
  mediaMany,
  graphDense,
  crossDomainSearch,
  generatorBatch,
}

extension Wave3ScaleScenarioContract on Wave3ScaleScenario {
  String get id {
    switch (this) {
      case Wave3ScaleScenario.catalogLarge:
        return 'catalog_large';
      case Wave3ScaleScenario.mediaMany:
        return 'media_many';
      case Wave3ScaleScenario.graphDense:
        return 'graph_dense';
      case Wave3ScaleScenario.crossDomainSearch:
        return 'cross_domain_search';
      case Wave3ScaleScenario.generatorBatch:
        return 'generator_batch';
    }
  }

  /// Profil unit skala validasi yang dikonsumsi [Wave3ScaleDatasetSpec].
  Map<String, int> get defaultUnits {
    switch (this) {
      case Wave3ScaleScenario.catalogLarge:
        return const {'records': 12000};
      case Wave3ScaleScenario.mediaMany:
        return const {'assets': 3000, 'missingEvery': 20};
      case Wave3ScaleScenario.graphDense:
        return const {'nodes': 1500};
      case Wave3ScaleScenario.crossDomainSearch:
        return const {'documents': 6000};
      case Wave3ScaleScenario.generatorBatch:
        return const {'batches': 8, 'batchSize': 256};
    }
  }
}

Wave3ScaleScenario _scenarioFromId(Object? raw) {
  final value = (raw ?? '').toString();
  for (final scenario in Wave3ScaleScenario.values) {
    if (scenario.id == value) return scenario;
  }
  throw ArgumentError.value(raw, 'scenario', 'unknown wave3 scale scenario');
}

Map<String, int> _unitMap(Object? raw, String field) {
  if (raw is! Map) {
    throw ArgumentError.value(raw, field, 'units must be an object');
  }
  final out = <String, int>{};
  raw.forEach((key, value) {
    if (key is! String || value is! int) {
      throw ArgumentError.value(raw, field, 'units must be string->int');
    }
    out[key] = value;
  });
  return out;
}

List<String> _stringList(Object? raw, String field) {
  if (raw == null) return const [];
  if (raw is! List) {
    throw ArgumentError.value(raw, field, 'must be a list');
  }
  return [
    for (final entry in raw)
      entry is String
          ? entry
          : (throw ArgumentError.value(
              entry,
              field,
              'entries must be strings',
            )),
  ];
}

// ---------------------------------------------------------------------------
// Datasets.
// ---------------------------------------------------------------------------

/// Satu deklarasi dataset per skenario kanonik. [fingerprint] adalah
/// proyeksi isi TERUKUR: dibangun dengan menjalankan builder dataset
/// deterministik nyata lalu meng-hash isi hasilnya — BUKAN hash deklarasi —
/// sehingga drift builder apa pun mengubah fingerprint.
class Wave3ScaleDatasetSpec {
  const Wave3ScaleDatasetSpec._({
    required this.scenario,
    required this.units,
    required this.seed,
    required this.fingerprint,
  });

  factory Wave3ScaleDatasetSpec.validated({
    required Wave3ScaleScenario scenario,
    required Map<String, int> units,
    required int seed,
  }) {
    if (units.isEmpty) {
      throw ArgumentError.value(units, 'units', 'units cannot be empty');
    }
    units.forEach((key, value) {
      if (key.trim().isEmpty) {
        throw ArgumentError.value(key, 'units', 'unit keys must be non-empty');
      }
      if (value <= 0) {
        throw ArgumentError.value(
          value,
          'units[$key]',
          'unit values must be positive',
        );
      }
    });
    if (seed <= 0) {
      throw ArgumentError.value(seed, 'seed', 'seed must be a positive int');
    }
    final sortedKeys = units.keys.toList()..sort();
    final frozen = Map<String, int>.unmodifiable(<String, int>{
      for (final key in sortedKeys) key: units[key]!,
    });
    return Wave3ScaleDatasetSpec._(
      scenario: scenario,
      units: frozen,
      seed: seed,
      fingerprint: Wave3ScaleDatasets.measureFingerprint(
        scenario,
        frozen,
        seed,
      ),
    );
  }

  final Wave3ScaleScenario scenario;
  final Map<String, int> units;
  final int seed;
  final int fingerprint;

  Map<String, Object?> toJson() => <String, Object?>{
    'scenario': scenario.id,
    'units': Map<String, int>.from(units),
    'seed': seed,
    'fingerprint': fingerprint,
  };

  static Wave3ScaleDatasetSpec fromJson(Map<String, Object?> json) {
    return Wave3ScaleDatasetSpec._(
      scenario: _scenarioFromId(json['scenario']),
      units: Map.unmodifiable(_unitMap(json['units'], 'units')),
      seed: _requireInt(json['seed'], 'seed'),
      fingerprint: _requireInt(json['fingerprint'], 'fingerprint'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wave3ScaleDatasetSpec &&
          other.scenario == scenario &&
          _intMapEq(other.units, units) &&
          other.seed == seed &&
          other.fingerprint == fingerprint);

  @override
  int get hashCode =>
      Object.hash(scenario, Object.hashAll(units.entries), seed, fingerprint);
}

bool _intMapEq(Map<String, int> a, Map<String, int> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

int _requireInt(Object? raw, String field) {
  if (raw is! int) {
    throw ArgumentError.value(raw, field, 'must be an int');
  }
  return raw;
}

/// Profil deklarasi dataset. [Wave3ScaleProfile.validation] mendaftarkan
/// tepat lima skenario kanonik pada skala validasi.
class Wave3ScaleProfile {
  Wave3ScaleProfile._({required List<Wave3ScaleDatasetSpec> datasets})
    : datasets = List.unmodifiable(datasets);

  factory Wave3ScaleProfile.validation() {
    const seeds = <Wave3ScaleScenario, int>{
      Wave3ScaleScenario.catalogLarge:
          EncyclopediaWave3ScaleHarness.catalogSeed,
      Wave3ScaleScenario.mediaMany: EncyclopediaWave3ScaleHarness.mediaSeed,
      Wave3ScaleScenario.graphDense: EncyclopediaWave3ScaleHarness.graphSeed,
      Wave3ScaleScenario.crossDomainSearch:
          EncyclopediaWave3ScaleHarness.searchSeed,
      Wave3ScaleScenario.generatorBatch:
          EncyclopediaWave3ScaleHarness.generatorSeed,
    };
    final specs = <Wave3ScaleDatasetSpec>[
      for (final scenario in Wave3ScaleScenario.values)
        Wave3ScaleDatasetSpec.validated(
          scenario: scenario,
          units: scenario.defaultUnits,
          seed: seeds[scenario]!,
        ),
    ];
    final seen = <Wave3ScaleScenario>{};
    for (final spec in specs) {
      if (!seen.add(spec.scenario)) {
        throw StateError('duplicate scenario: ${spec.scenario.id}');
      }
    }
    return Wave3ScaleProfile._(datasets: specs);
  }

  final List<Wave3ScaleDatasetSpec> datasets;

  List<Wave3ScaleScenario> get scenarios =>
      List.unmodifiable(datasets.map((d) => d.scenario));

  Wave3ScaleDatasetSpec? specFor(Wave3ScaleScenario scenario) {
    for (final spec in datasets) {
      if (spec.scenario == scenario) return spec;
    }
    return null;
  }

  List<Map<String, Object?>> toJson() =>
      datasets.map((d) => d.toJson()).toList();

  static Wave3ScaleProfile fromJson(List<Object?> raw) {
    final specs = <Wave3ScaleDatasetSpec>[];
    for (final entry in raw) {
      if (entry is! Map) {
        throw ArgumentError.value(entry, 'datasets', 'entries must be objects');
      }
      specs.add(Wave3ScaleDatasetSpec.fromJson(entry.cast<String, Object?>()));
    }
    return Wave3ScaleProfile._(datasets: specs);
  }
}

// ---------------------------------------------------------------------------
// Budgets / results / strategies / bottlenecks / mitigations.
// ---------------------------------------------------------------------------

/// Anggaran waktu dinding satu workload. [derive] memaksa headroom minimum
/// 4x di atas baseline terukur (lebih ketat dari floor wave 2) sehingga
/// variansi CI tidak membalikkan suite kecuali regresi nyata; ceiling keras
/// per skenario adalah gerbang terpisah yang terdokumentasi.
class Wave3ScaleBudget {
  const Wave3ScaleBudget({
    required this.budgetMs,
    required this.headroomMultiplier,
    this.workloadLabel = '',
    this.scenarioLabel = '',
  });

  factory Wave3ScaleBudget.derive({
    required int baselineMs,
    double headroomMultiplier = 4.0,
    String workloadLabel = '',
    String scenarioLabel = '',
  }) {
    final multiplier = headroomMultiplier < 4.0 ? 4.0 : headroomMultiplier;
    final budget = (baselineMs * multiplier).ceil();
    return Wave3ScaleBudget(
      budgetMs: budget < 1 ? 1 : budget,
      headroomMultiplier: multiplier,
      workloadLabel: workloadLabel,
      scenarioLabel: scenarioLabel,
    );
  }

  /// Ceiling keras per skenario kanonik — batas longgar yang dilewati
  /// mesin sehat selisih satu-dua orde magnitudo; melanggarnya ADALAH
  /// sinyal regresi, bukan noise.
  static int ceilingFor(Wave3ScaleScenario scenario) {
    switch (scenario) {
      case Wave3ScaleScenario.catalogLarge:
        return 60000;
      case Wave3ScaleScenario.mediaMany:
        return 60000;
      case Wave3ScaleScenario.graphDense:
        return 60000;
      case Wave3ScaleScenario.crossDomainSearch:
        return 60000;
      case Wave3ScaleScenario.generatorBatch:
        return 60000;
    }
  }

  static String rationaleFor(Wave3ScaleScenario scenario) {
    switch (scenario) {
      case Wave3ScaleScenario.catalogLarge:
        return 'registry build + census per domain atas 12k records; scan '
            'linear O(total) per domain harus tetap jauh di bawah satu '
            'detik per pass pada perangkat keras desktop.';
      case Wave3ScaleScenario.mediaMany:
        return 'registrasi pustaka O(n^2) lewat guard duplikasi path; 3k '
            'aset adalah skala validasi; ceiling menyerap mesin CI lambat '
            'tanpa menyembunyikan regresi kompleksitas.';
      case Wave3ScaleScenario.graphDense:
        return 'build 1500 simpul x 8 offset, BFS transitif, dan 2k probe '
            'pair index; baseline edgeBetween linear adalah biaya dominan '
            'terukur.';
      case Wave3ScaleScenario.crossDomainSearch:
        return 'index build + query sweep + agregasi facet atas 6k dokumen '
            'lintas domain; rescan penuh per query adalah bottleneck yang '
            'facet/term index mitigasi.';
      case Wave3ScaleScenario.generatorBatch:
        return '8 batch x 256 proposal lewat loop retry legal terbatas plus '
            'satu replay comparison; retry exhaustion akan melempar, jadi '
            'ceiling membatasi biaya jalur normal saja.';
    }
  }

  final int budgetMs;
  final double headroomMultiplier;
  final String workloadLabel;
  final String scenarioLabel;

  Map<String, Object?> toJson() => <String, Object?>{
    'budgetMs': budgetMs,
    'headroomMultiplier': headroomMultiplier,
    'workloadLabel': workloadLabel,
    'scenarioLabel': scenarioLabel,
  };

  static Wave3ScaleBudget fromJson(Map<String, Object?> json) {
    final multiplier = json['headroomMultiplier'];
    if (multiplier is! num) {
      throw ArgumentError.value(
        multiplier,
        'headroomMultiplier',
        'must be a number',
      );
    }
    return Wave3ScaleBudget(
      budgetMs: _requireInt(json['budgetMs'], 'budgetMs'),
      headroomMultiplier: multiplier.toDouble(),
      workloadLabel: json['workloadLabel'] is String
          ? json['workloadLabel']! as String
          : '',
      scenarioLabel: json['scenarioLabel'] is String
          ? json['scenarioLabel']! as String
          : '',
    );
  }
}

/// Satu workload terukur. [checksum] adalah agregat konten deterministik
/// (jumlah/fingerprint hasil nyata), bukan nilai waktu, sehingga replay
/// harness di build lain harus mereproduksinya persis.
class Wave3ScaleResult {
  const Wave3ScaleResult({
    required this.workloadLabel,
    required this.scenarioLabel,
    required this.units,
    required this.measuredMs,
    required this.ceilingMs,
    required this.budgetMs,
    required this.checksum,
  });

  final String workloadLabel;
  final String scenarioLabel;
  final Map<String, int> units;
  final int measuredMs;
  final int ceilingMs;
  final int budgetMs;
  final int checksum;

  bool get withinCeiling => measuredMs <= ceilingMs;

  Map<String, Object?> toJson() => <String, Object?>{
    'workloadLabel': workloadLabel,
    'scenarioLabel': scenarioLabel,
    'units': Map<String, int>.from(units),
    'measuredMs': measuredMs,
    'ceilingMs': ceilingMs,
    'budgetMs': budgetMs,
    'checksum': checksum,
  };

  static Wave3ScaleResult fromJson(Map<String, Object?> json) {
    final workloadLabel = json['workloadLabel'];
    if (workloadLabel is! String || workloadLabel.trim().isEmpty) {
      throw ArgumentError.value(
        workloadLabel,
        'workloadLabel',
        'must be a non-empty string',
      );
    }
    final scenarioLabel = json['scenarioLabel'];
    if (scenarioLabel is! String) {
      throw ArgumentError.value(
        scenarioLabel,
        'scenarioLabel',
        'must be a string',
      );
    }
    return Wave3ScaleResult(
      workloadLabel: workloadLabel,
      scenarioLabel: scenarioLabel,
      units: Map.unmodifiable(_unitMap(json['units'], 'units')),
      measuredMs: _requireInt(json['measuredMs'], 'measuredMs'),
      ceilingMs: _requireInt(json['ceilingMs'], 'ceilingMs'),
      budgetMs: _requireInt(json['budgetMs'], 'budgetMs'),
      checksum: _requireInt(json['checksum'], 'checksum'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wave3ScaleResult &&
          other.workloadLabel == workloadLabel &&
          other.scenarioLabel == scenarioLabel &&
          _intMapEq(other.units, units) &&
          other.measuredMs == measuredMs &&
          other.ceilingMs == ceilingMs &&
          other.budgetMs == budgetMs &&
          other.checksum == checksum);

  @override
  int get hashCode => Object.hash(
    workloadLabel,
    scenarioLabel,
    Object.hashAll(units.entries),
    measuredMs,
    ceilingMs,
    budgetMs,
    checksum,
  );
}

/// Strategi indeks terukur: masalah skala yang diaddress + mekanisme
/// penyelesai.
class Wave3IndexStrategy {
  const Wave3IndexStrategy({
    required this.label,
    required this.mechanism,
    required this.bottleneckLabels,
  });

  final String label;
  final String mechanism;
  final List<String> bottleneckLabels;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'mechanism': mechanism,
    'bottleneckLabels': List<String>.from(bottleneckLabels),
  };

  static Wave3IndexStrategy fromJson(Map<String, Object?> json) {
    final label = json['label'];
    if (label is! String || label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must be a non-empty string');
    }
    return Wave3IndexStrategy(
      label: label,
      mechanism: json['mechanism'] is String
          ? json['mechanism']! as String
          : '',
      bottleneckLabels: _stringList(
        json['bottleneckLabels'],
        'bottleneckLabels',
      ),
    );
  }
}

/// Bottleneck yang muncul pada skala validasi.
class Wave3ScaleBottleneck {
  const Wave3ScaleBottleneck({
    required this.label,
    required this.scenarioLabel,
    required this.reason,
    this.measuredMs = 0,
  });

  final String label;
  final String scenarioLabel;
  final String reason;
  final int measuredMs;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'scenarioLabel': scenarioLabel,
    'reason': reason,
    'measuredMs': measuredMs,
  };

  static Wave3ScaleBottleneck fromJson(Map<String, Object?> json) {
    final label = json['label'];
    if (label is! String || label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must be a non-empty string');
    }
    return Wave3ScaleBottleneck(
      label: label,
      scenarioLabel: json['scenarioLabel'] is String
          ? json['scenarioLabel']! as String
          : '',
      reason: json['reason'] is String ? json['reason']! as String : '',
      measuredMs: _requireInt(json['measuredMs'], 'measuredMs'),
    );
  }
}

/// Mitigasi yang terhubung ke satu atau lebih bottleneck lewat label exact.
class Wave3ScaleMitigation {
  const Wave3ScaleMitigation({
    required this.label,
    required this.bottleneckLabels,
    required this.action,
  });

  final String label;
  final List<String> bottleneckLabels;
  final String action;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'bottleneckLabels': List<String>.from(bottleneckLabels),
    'action': action,
  };

  static Wave3ScaleMitigation fromJson(Map<String, Object?> json) {
    final label = json['label'];
    if (label is! String || label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'must be a non-empty string');
    }
    return Wave3ScaleMitigation(
      label: label,
      bottleneckLabels: _stringList(
        json['bottleneckLabels'],
        'bottleneckLabels',
      ),
      action: json['action'] is String ? json['action']! as String : '',
    );
  }
}

// ---------------------------------------------------------------------------
// Index strategies with real implementations (equivalence-tested in suite).
// ---------------------------------------------------------------------------

/// Indeks per-domain di atas shared registry: mengubah scan O(total) per
/// domain dari [SharedEncyclopediaSchema.recordsFor] menjadi lookup O(1)
/// berbekal daftar id tersortir.
class Wave3CatalogIndex {
  Wave3CatalogIndex._(this._byDomain, this._total);

  factory Wave3CatalogIndex.from(SharedEncyclopediaSchema schema) {
    final byDomain = <EncyclopediaDomain, List<String>>{};
    for (final domain in EncyclopediaDomain.values) {
      byDomain[domain] = [
        for (final record in schema.recordsFor(domain)) record.recordId,
      ]..sort();
    }
    var total = 0;
    for (final ids in byDomain.values) {
      total += ids.length;
    }
    return Wave3CatalogIndex._(
      Map.unmodifiable(<EncyclopediaDomain, List<String>>{
        for (final entry in byDomain.entries)
          entry.key: List.unmodifiable(entry.value),
      }),
      total,
    );
  }

  final Map<EncyclopediaDomain, List<String>> _byDomain;
  final int _total;

  int get totalIndexed => _total;

  List<String> recordIdsFor(EncyclopediaDomain domain) =>
      _byDomain[domain] ?? const [];

  int countFor(EncyclopediaDomain domain) => recordIdsFor(domain).length;
}

/// Lookup edge arah-bebas di atas [EncyclopediaGraph]: menjawab
/// [edgeBetween] dengan pemenang PERSIS sama dengan scan linear (edgeId
/// terkecil, karena edges graph sudah tersortir edgeId) dalam O(1).
class Wave3EdgePairIndex {
  Wave3EdgePairIndex._(this._byPair, this._edgeCount);

  factory Wave3EdgePairIndex.from(EncyclopediaGraph graph) {
    final byPair = <String, List<EncyclopediaGraphEdge>>{};
    for (final edge in graph.edges) {
      byPair
          .putIfAbsent(
            _pairKey(edge.fromId, edge.toId),
            () => <EncyclopediaGraphEdge>[],
          )
          .add(edge);
      byPair
          .putIfAbsent(
            _pairKey(edge.toId, edge.fromId),
            () => <EncyclopediaGraphEdge>[],
          )
          .add(edge);
    }
    for (final list in byPair.values) {
      list.sort((a, b) => a.edgeId.compareTo(b.edgeId));
    }
    return Wave3EdgePairIndex._(
      Map.unmodifiable(<String, List<EncyclopediaGraphEdge>>{
        for (final entry in byPair.entries)
          entry.key: List.unmodifiable(entry.value),
      }),
      graph.edgeCount,
    );
  }

  static String _pairKey(String a, String b) => '$a\u0000$b';

  final Map<String, List<EncyclopediaGraphEdge>> _byPair;
  final int _edgeCount;

  int get edgeCount => _edgeCount;

  EncyclopediaGraphEdge? edgeBetween(String a, String b) {
    final matches = _byPair[_pairKey(a, b)];
    if (matches == null || matches.isEmpty) return null;
    return matches.first;
  }
}

/// Indeks facet pra-bucket atas [EncyclopediaSearchIndex]: keanggotaan
/// culture, region, dan category menjadi lookup peta, bukan scan dokumen
/// per query.
class Wave3FacetIndex {
  Wave3FacetIndex._({
    required Map<String, List<String>> byCulture,
    required Map<String, List<String>> byRegion,
    required Map<String, List<String>> byCategory,
    required this.totalDocuments,
  }) : _byCulture = Map.unmodifiable(_frozen(byCulture)),
       _byRegion = Map.unmodifiable(_frozen(byRegion)),
       _byCategory = Map.unmodifiable(_frozen(byCategory));

  static Map<String, List<String>> _frozen(Map<String, List<String>> source) {
    return <String, List<String>>{
      for (final entry in source.entries)
        entry.key: List.unmodifiable(entry.value),
    };
  }

  factory Wave3FacetIndex.from(EncyclopediaSearchIndex index) {
    final byCulture = <String, List<String>>{};
    final byRegion = <String, List<String>>{};
    final byCategory = <String, List<String>>{};
    for (final document in index.documents) {
      for (final culture in document.cultureIds) {
        byCulture.putIfAbsent(culture, () => <String>[]).add(document.recordId);
      }
      for (final region in document.regionIds) {
        byRegion.putIfAbsent(region, () => <String>[]).add(document.recordId);
      }
      final category = document.taxonomyCategoryId ?? kUncategorizedFacetKey;
      byCategory.putIfAbsent(category, () => <String>[]).add(document.recordId);
    }
    for (final map in <Map<String, List<String>>>[
      byCulture,
      byRegion,
      byCategory,
    ]) {
      for (final list in map.values) {
        list.sort();
      }
    }
    return Wave3FacetIndex._(
      byCulture: byCulture,
      byRegion: byRegion,
      byCategory: byCategory,
      totalDocuments: index.count,
    );
  }

  final Map<String, List<String>> _byCulture;
  final Map<String, List<String>> _byRegion;
  final Map<String, List<String>> _byCategory;
  final int totalDocuments;

  int get cultureCount => _byCulture.length;

  List<String> cultureMatches(String cultureId) =>
      _byCulture[cultureId] ?? const [];

  List<String> regionMatches(String regionId) =>
      _byRegion[regionId] ?? const [];

  List<String> categoryMatches(String categoryId) =>
      _byCategory[categoryId] ?? const [];
}

// ---------------------------------------------------------------------------
// Deterministic dataset builders + measured fingerprinting.
// ---------------------------------------------------------------------------

/// Builder lima dataset skala kanonik plus workload yang diukur harness.
/// Setiap builder fungsi murni deterministik dari argumennya — seed sama,
/// konten sama persis.
class Wave3ScaleDatasets {
  const Wave3ScaleDatasets._();

  static const List<int> defaultOffsets = [1, 2, 3, 7, 11, 17, 23, 41];
  static const int cultureCount = 12;
  static const int regionCount = 6;
  static const int categoryCount = 40;

  static final Map<String, int> _fingerprintCache = <String, int>{};

  static String nodeId(int index) => 'gn-${index.toString().padLeft(5, '0')}';
  static String _edgeId(int index) => 'ge-${index.toString().padLeft(6, '0')}';

  /// Katalog besar: domain dan category round-robin di atas shared registry
  /// (111.6).
  static SharedEncyclopediaSchema buildCatalog({
    required int recordCount,
    required int seed,
  }) {
    if (recordCount <= 0) {
      throw ArgumentError.value(recordCount, 'recordCount', 'must be positive');
    }
    const domains = EncyclopediaDomain.values;
    final schema = SharedEncyclopediaSchema();
    final rng = SplitMix64(seed);
    for (var i = 0; i < recordCount; i++) {
      final id = 'wr-${i.toString().padLeft(6, '0')}';
      schema.register(
        EncyclopediaRecord.validated(
          recordId: id,
          domain: domains[i % domains.length],
          title: _catalogTitle(i, rng),
          taxonomyCategoryId:
              'cat-${(i % categoryCount).toString().padLeft(3, '0')}',
          canonStatus: _canonForIndex(i),
          scopeLocations: <String>[
            'reg-${(i % regionCount).toString().padLeft(2, '0')}',
          ],
        ),
      );
    }
    return schema;
  }

  static String _catalogTitle(int index, SplitMix64 rng) {
    final suffix = rng.nextInRange(4096);
    final head = index % 3 == 0 ? 'Void' : 'Qorn';
    return '$head Talis-$suffix';
  }

  static CanonStatus _canonForIndex(int index) {
    const statuses = CanonStatus.values;
    return statuses[index % statuses.length];
  }

  /// Pustaka media banyak: id/path unik, setiap kelipatan [missingEvery]
  /// ditandai missing secara eksplisit (111.7).
  static EncyclopediaMediaLibrary buildMediaLibrary({
    required int assetCount,
    required int missingEvery,
  }) {
    if (assetCount <= 0 || missingEvery <= 0) {
      throw ArgumentError('assetCount and missingEvery must be positive');
    }
    final library = EncyclopediaMediaLibrary();
    for (var i = 0; i < assetCount; i++) {
      final id = 'med-${i.toString().padLeft(4, '0')}';
      library.register(
        EncyclopediaMediaAsset.validated(
          assetId: id,
          kind: MediaKind.image,
          relativePath: 'media/scale/$id.png',
        ),
      );
    }
    for (var i = 0; i < assetCount; i++) {
      if (i % missingEvery == 0) {
        library.markMissing('med-${i.toString().padLeft(4, '0')}');
      }
    }
    return library;
  }

  /// Graph berarah padat: setiap simpul mendapat satu edge per offset,
  /// modulo jumlah simpul. Offset 1 menjamin satu komponen strongly
  /// connected; offset berbeda menjamin pasangan (from, to) unik.
  static EncyclopediaGraph buildDenseGraph({
    required int nodeCount,
    required List<int> offsets,
  }) {
    if (nodeCount < 2) {
      throw ArgumentError.value(nodeCount, 'nodeCount', 'must be >= 2');
    }
    if (offsets.isEmpty) {
      throw ArgumentError.value(offsets, 'offsets', 'must not be empty');
    }
    for (final offset in offsets) {
      if (offset < 1 || offset >= nodeCount) {
        throw ArgumentError.value(
          offset,
          'offsets',
          'offsets must be within 1..nodeCount-1',
        );
      }
    }
    const kinds = CrossDomainLinkKind.values;
    final edges = <EncyclopediaGraphEdge>[];
    var edgeIndex = 0;
    for (var i = 0; i < nodeCount; i++) {
      for (var k = 0; k < offsets.length; k++) {
        final to = (i + offsets[k]) % nodeCount;
        edges.add(
          EncyclopediaGraphEdge.validated(
            edgeId: _edgeId(edgeIndex++),
            fromId: nodeId(i),
            toId: nodeId(to),
            kind: kinds[k % kinds.length],
          ),
        );
      }
    }
    return EncyclopediaGraph.build(edges: edges);
  }

  /// Korpus pencarian lintas domain (dokumen 111.37 atas record 111.6).
  static EncyclopediaSearchIndex buildSearchIndex({
    required int recordCount,
    required int seed,
  }) {
    if (recordCount <= 0) {
      throw ArgumentError.value(recordCount, 'recordCount', 'must be positive');
    }
    const domains = EncyclopediaDomain.values;
    final rng = SplitMix64(seed);
    final documents = <EncyclopediaSearchDocument>[];
    for (var i = 0; i < recordCount; i++) {
      final id = 'ws-${i.toString().padLeft(5, '0')}';
      documents.add(
        EncyclopediaSearchDocument.validated(
          record: EncyclopediaRecord.validated(
            recordId: id,
            domain: domains[i % domains.length],
            title: _catalogTitle(i, rng),
            taxonomyCategoryId:
                'cat-${(i % categoryCount).toString().padLeft(3, '0')}',
            canonStatus: _canonForIndex(i),
            scopeLocations: <String>[
              'reg-${(i % regionCount).toString().padLeft(2, '0')}',
            ],
          ),
          aliases: <String>['alias-$id'],
          cultureIds: <String>[
            'cult-${(i % cultureCount).toString().padLeft(2, '0')}',
            'cult-${((i * 5 + 3) % cultureCount).toString().padLeft(2, '0')}',
          ],
        ),
      );
    }
    return EncyclopediaSearchIndex.withDocuments(documents);
  }

  static PhonotacticsSpec _scaleSpec() {
    return PhonotacticsSpec.validated(
      id: 'scale-spec',
      languageId: 'elv-s',
      inventory: <SyllablePart>[
        SyllablePart.validated(
          symbol: 'a',
          slots: <SyllableSlot>[SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'e',
          slots: <SyllableSlot>[SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'i',
          slots: <SyllableSlot>[SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'o',
          slots: <SyllableSlot>[SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'u',
          slots: <SyllableSlot>[SyllableSlot.nucleus],
        ),
        SyllablePart.validated(
          symbol: 'k',
          slots: <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda],
        ),
        SyllablePart.validated(
          symbol: 'l',
          slots: <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda],
        ),
        SyllablePart.validated(
          symbol: 'm',
          slots: <SyllableSlot>[SyllableSlot.onset],
        ),
        SyllablePart.validated(
          symbol: 'n',
          slots: <SyllableSlot>[SyllableSlot.onset],
        ),
        SyllablePart.validated(
          symbol: 'r',
          slots: <SyllableSlot>[SyllableSlot.onset],
        ),
        SyllablePart.validated(
          symbol: 's',
          slots: <SyllableSlot>[SyllableSlot.onset],
        ),
        SyllablePart.validated(
          symbol: 't',
          slots: <SyllableSlot>[SyllableSlot.onset],
        ),
      ],
      patterns: <SyllablePattern>[
        SyllablePattern.parse(id: 'cv', template: 'CV', weight: 3),
        SyllablePattern.parse(id: 'cvc', template: 'CVC', weight: 2),
        SyllablePattern.parse(id: 'cvd', template: 'CV(C)', weight: 1),
      ],
    );
  }

  static CulturalNameProfile _scaleProfile() {
    return CulturalNameProfile.validated(
      profileId: 'prof-scale',
      cultureId: 'c-scale',
      languageId: 'elv-s',
      entityTypes: <NameEntityType>{
        NameEntityType.person,
        NameEntityType.place,
      },
    );
  }

  /// Workload batch generator (111.31): [batchCount] batch independen
  /// berukuran [batchSize], masing-masing ber-seed deterministik dari
  /// [seed]. Unisitas teks DIJAMIN hanya dalam satu batch (kontrak
  /// generator), bukan lintas batch.
  static List<SeededNameBatch> runGeneratorBatches({
    required int batchCount,
    required int batchSize,
    required int seed,
  }) {
    if (batchCount <= 0) {
      throw ArgumentError.value(batchCount, 'batchCount', 'must be positive');
    }
    if (batchSize < 1 || batchSize > SeededNameGenerator.maxBatchSize) {
      throw ArgumentError.value(
        batchSize,
        'batchSize',
        'must be within 1..${SeededNameGenerator.maxBatchSize}',
      );
    }
    final profile = _scaleProfile();
    final spec = _scaleSpec();
    final batches = <SeededNameBatch>[];
    for (var b = 0; b < batchCount; b++) {
      batches.add(
        SeededNameGenerator.generateBatch(
          request: SeededNameRequest.validated(
            profile: profile,
            spec: spec,
            entityType: NameEntityType.person,
            seed: seed + b * 100003,
          ),
          count: batchSize,
        ),
      );
    }
    return List.unmodifiable(batches);
  }

  /// Menjalankan builder NYATA untuk [scenario] pada skala deklarasinya dan
  /// mem-fingerprint konten yang dihasilkan (id, path, atau teks). Bagian
  /// terukur dari [Wave3ScaleDatasetSpec.validated].
  static int measureFingerprint(
    Wave3ScaleScenario scenario,
    Map<String, int> units,
    int seed,
  ) {
    final parts = <String>[
      for (final entry
          in units.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        '${entry.key}=${entry.value}',
    ];
    final key = '${scenario.id}|${parts.join(',')}|$seed';
    final cached = _fingerprintCache[key];
    if (cached != null) return cached;
    final measured = switch (scenario) {
      Wave3ScaleScenario.catalogLarge => wave3Fnv1a64(
        buildCatalog(
          recordCount: units['records']!,
          seed: seed,
        ).recordIds.join(';'),
      ),
      Wave3ScaleScenario.mediaMany => () {
        final plan = buildMediaLibrary(
          assetCount: units['assets']!,
          missingEvery: units['missingEvery'] ?? 20,
        ).planExport(explicitExport: true);
        final buffer = StringBuffer('present:')
          ..writeAll(plan.assetIds, ',')
          ..write('|missing:')
          ..writeAll(plan.missingAssetIds, ',');
        return wave3Fnv1a64(buffer.toString());
      }(),
      Wave3ScaleScenario.graphDense => wave3Fnv1a64(
        buildDenseGraph(
          nodeCount: units['nodes']!,
          offsets: defaultOffsets,
        ).edges.map((e) => '${e.edgeId}:${e.fromId}>${e.toId}').join(';'),
      ),
      Wave3ScaleScenario.crossDomainSearch => wave3Fnv1a64(
        buildSearchIndex(
          recordCount: units['documents']!,
          seed: seed,
        ).recordIds.join(';'),
      ),
      Wave3ScaleScenario.generatorBatch => wave3Fnv1a64(
        runGeneratorBatches(
          batchCount: units['batches']!,
          batchSize: units['batchSize']!,
          seed: seed,
        ).map((b) => b.texts.join(',')).join(';'),
      ),
    };
    _fingerprintCache[key] = measured;
    return measured;
  }
}

// ---------------------------------------------------------------------------
// Aggregate report.
// ---------------------------------------------------------------------------

/// Agregat immutable satu run validasi. [Wave3ScaleReport.of] gagal-tertutup
/// pada label workload duplikat, bottleneck tanpa mitigasi, dan seksi kosong
/// — mengikuti disiplin matriks 111.40.
class Wave3ScaleReport {
  Wave3ScaleReport._({
    required this.datasets,
    required this.budgets,
    required this.results,
    required this.indexStrategies,
    required this.bottlenecks,
    required this.mitigations,
  });

  factory Wave3ScaleReport.of({
    required List<Wave3ScaleDatasetSpec> datasets,
    required List<Wave3ScaleBudget> budgets,
    required List<Wave3ScaleResult> results,
    required List<Wave3IndexStrategy> indexStrategies,
    required List<Wave3ScaleBottleneck> bottlenecks,
    required List<Wave3ScaleMitigation> mitigations,
  }) {
    if (datasets.isEmpty ||
        budgets.isEmpty ||
        results.isEmpty ||
        indexStrategies.isEmpty ||
        bottlenecks.isEmpty ||
        mitigations.isEmpty) {
      throw StateError('a scale report cannot have empty sections');
    }
    final labels = <String>{};
    for (final result in results) {
      if (!labels.add(result.workloadLabel)) {
        throw StateError('duplicate workload label: ${result.workloadLabel}');
      }
    }
    final bottleneckLabels = <String>{};
    for (final bottleneck in bottlenecks) {
      if (!bottleneckLabels.add(bottleneck.label)) {
        throw StateError('duplicate bottleneck label: ${bottleneck.label}');
      }
    }
    final sortedBottlenecks = List<Wave3ScaleBottleneck>.from(bottlenecks)
      ..sort((a, b) => a.label.compareTo(b.label));
    final sortedMitigations = List<Wave3ScaleMitigation>.from(mitigations)
      ..sort((a, b) => a.label.compareTo(b.label));
    final covered = <String>{
      for (final mitigation in sortedMitigations)
        ...mitigation.bottleneckLabels,
    };
    for (final label in bottleneckLabels) {
      if (!covered.contains(label)) {
        throw StateError('bottleneck without mitigation: $label');
      }
    }
    return Wave3ScaleReport._(
      datasets: List.unmodifiable(datasets),
      budgets: List.unmodifiable(budgets),
      results: List.unmodifiable(results),
      indexStrategies: List.unmodifiable(indexStrategies),
      bottlenecks: List.unmodifiable(sortedBottlenecks),
      mitigations: List.unmodifiable(sortedMitigations),
    );
  }

  final List<Wave3ScaleDatasetSpec> datasets;
  final List<Wave3ScaleBudget> budgets;
  final List<Wave3ScaleResult> results;
  final List<Wave3IndexStrategy> indexStrategies;
  final List<Wave3ScaleBottleneck> bottlenecks;
  final List<Wave3ScaleMitigation> mitigations;

  List<Wave3ScaleResult> resultsFor(Wave3ScaleScenario scenario) =>
      List.unmodifiable(results.where((r) => r.scenarioLabel == scenario.id));

  Map<Wave3ScaleScenario, int> get scenarioCoverage {
    final out = <Wave3ScaleScenario, int>{};
    for (final scenario in Wave3ScaleScenario.values) {
      final count = resultsFor(scenario).length;
      if (count > 0) out[scenario] = count;
    }
    return Map.unmodifiable(out);
  }

  List<String> get missingScenarioNames => List.unmodifiable([
    for (final scenario in Wave3ScaleScenario.values)
      if (resultsFor(scenario).isEmpty) scenario.id,
  ]);

  bool get isComplete => missingScenarioNames.isEmpty;

  List<String> get ceilingViolations => List.unmodifiable(
    [
      for (final result in results)
        if (!result.withinCeiling) result.workloadLabel,
    ]..sort(),
  );

  bool get allWithinCeiling => ceilingViolations.isEmpty;

  List<String> get unmitigatedBottlenecks {
    final covered = <String>{
      for (final mitigation in mitigations) ...mitigation.bottleneckLabels,
    };
    return List.unmodifiable(
      bottlenecks
          .map((b) => b.label)
          .where((label) => !covered.contains(label))
          .toList(),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'datasets': datasets.map((d) => d.toJson()).toList(),
    'budgets': budgets.map((b) => b.toJson()).toList(),
    'results': results.map((r) => r.toJson()).toList(),
    'indexStrategies': indexStrategies.map((s) => s.toJson()).toList(),
    'bottlenecks': bottlenecks.map((b) => b.toJson()).toList(),
    'mitigations': mitigations.map((m) => m.toJson()).toList(),
  };

  static Wave3ScaleReport fromJson(Map<String, Object?> json) {
    List<Map<String, Object?>> section(Object? raw, String field) {
      if (raw is! List) {
        throw ArgumentError.value(raw, field, 'must be a list');
      }
      return [
        for (final entry in raw)
          entry is Map
              ? entry.cast<String, Object?>()
              : (throw ArgumentError.value(
                  entry,
                  field,
                  'entries must be objects',
                )),
      ];
    }

    return Wave3ScaleReport._(
      datasets: section(
        json['datasets'],
        'datasets',
      ).map(Wave3ScaleDatasetSpec.fromJson).toList(),
      budgets: section(
        json['budgets'],
        'budgets',
      ).map(Wave3ScaleBudget.fromJson).toList(),
      results: section(
        json['results'],
        'results',
      ).map(Wave3ScaleResult.fromJson).toList(),
      indexStrategies: section(
        json['indexStrategies'],
        'indexStrategies',
      ).map(Wave3IndexStrategy.fromJson).toList(),
      bottlenecks: section(
        json['bottlenecks'],
        'bottlenecks',
      ).map(Wave3ScaleBottleneck.fromJson).toList(),
      mitigations: section(
        json['mitigations'],
        'mitigations',
      ).map(Wave3ScaleMitigation.fromJson).toList(),
    );
  }

  String describe() {
    final buffer = StringBuffer(
      'Wave3 scale report (${results.length} workloads)',
    );
    for (final scenario in Wave3ScaleScenario.values) {
      final scenarioResults = resultsFor(scenario);
      var worst = 0;
      for (final result in scenarioResults) {
        if (result.measuredMs > worst) worst = result.measuredMs;
      }
      buffer.writeln(
        ' - ${scenario.id}: ${scenarioResults.length} workloads, '
        'max ${worst}ms / ceiling ${Wave3ScaleBudget.ceilingFor(scenario)}ms',
      );
    }
    buffer.write(
      allWithinCeiling
          ? 'ALL CEILINGS MET'
          : 'CEILING VIOLATIONS: ${ceilingViolations.join(',')}',
    );
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wave3ScaleReport &&
          _canonicalEncode(other.toJson()) == _canonicalEncode(toJson()));

  @override
  int get hashCode => _canonicalEncode(toJson()).hashCode;
}

/// Encoding kanonik kunci-terurut rekursif agar kesamaan JSON tidak pernah
/// bergantung urutan insertion map.
String _canonicalEncode(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    final buffer = StringBuffer('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) buffer.write(',');
      buffer
        ..write(_encodeScalarKey(keys[i]))
        ..write(':')
        ..write(_canonicalEncode(value[keys[i]]));
    }
    return '${buffer.toString()}}';
  }
  if (value is List) {
    return '[${value.map(_canonicalEncode).join(',')}]';
  }
  return _encodeScalarKey(value);
}

String _encodeScalarKey(Object? value) {
  if (value is String) {
    return '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }
  if (value == null) return 'null';
  return '$value';
}

// ---------------------------------------------------------------------------
// Harness.
// ---------------------------------------------------------------------------

/// Menjalankan seluruh skenario skala kanonik Wave 3 end-to-end terhadap
/// API domain nyata dan menghasilkan [Wave3ScaleReport]. Mengulang bentuk
/// wave 2 `PerformanceScaleBenchmark.runAll` (build -> baseline -> cached),
/// tetapi mengkonsumsi permukaan search/graph/media/generator wave 3.
class EncyclopediaWave3ScaleHarness {
  EncyclopediaWave3ScaleHarness();

  static const int catalogSeed = 2026091601;
  static const int mediaSeed = 2026091602;
  static const int graphSeed = 2026091603;
  static const int searchSeed = 2026091604;
  static const int generatorSeed = 2026091605;

  /// Fingerprint dibekukan dari PROBE terukur pada toolchain Windows
  /// (lihat catatan ledger 111.41). Perubahan builder membuat tes golden
  /// gagal alih-alih angka bergeser diam-diam.
  static Map<String, int> goldenFingerprints() => const <String, int>{
    'catalog_large': 790069949095368701,
    'media_many': 7677818809525770991,
    'graph_dense': 6515078107335204461,
    'cross_domain_search': 3939955306960818557,
    'generator_batch': 5576845544389638749,
  };

  static const String bottleneckCatalog =
      'catalog_large:per_domain_scan_is_linear';
  static const String bottleneckGraphPair =
      'graph_dense:edge_between_is_linear';
  static const String bottleneckGraphReach =
      'graph_dense:reachability_recomputed_per_call';
  static const String bottleneckSearchQuery =
      'cross_domain_search:queries_rescan_and_retokens_all_documents';
  static const String bottleneckMediaPlan =
      'media_many:export_plans_rebuild_lists_every_call';
  static const String bottleneckGeneratorRetry =
      'generator_batch:legal_retry_loop_bounds_batch_cost';

  static const String bottleneckLibraryRegistration =
      'media_many:library_registration_is_quadratic';

  Wave3ScaleReport runAll() {
    final profile = Wave3ScaleProfile.validation();
    final results = <Wave3ScaleResult>[];
    final budgets = <Wave3ScaleBudget>[];

    Wave3ScaleResult measure({
      required String workloadLabel,
      required Wave3ScaleScenario scenario,
      required Map<String, int> units,
      required int Function() workload,
      Map<String, int> extraUnits = const {},
    }) {
      final stopwatch = Stopwatch()..start();
      final checksum = workload();
      stopwatch.stop();
      final measured = stopwatch.elapsedMilliseconds < 1
          ? 1
          : stopwatch.elapsedMilliseconds;
      final budget = Wave3ScaleBudget.derive(
        baselineMs: measured,
        workloadLabel: workloadLabel,
        scenarioLabel: scenario.id,
      );
      final result = Wave3ScaleResult(
        workloadLabel: workloadLabel,
        scenarioLabel: scenario.id,
        units: Map.unmodifiable(<String, int>{...units, ...extraUnits}),
        measuredMs: measured,
        ceilingMs: Wave3ScaleBudget.ceilingFor(scenario),
        budgetMs: budget.budgetMs,
        checksum: checksum,
      );
      results.add(result);
      budgets.add(budget);
      return result;
    }

    // --- catalog_large ------------------------------------------------------
    final catalogUnits = Wave3ScaleScenario.catalogLarge.defaultUnits;
    final recordCount = catalogUnits['records']!;
    measure(
      workloadLabel: 'catalog_large:register_all',
      scenario: Wave3ScaleScenario.catalogLarge,
      units: catalogUnits,
      workload: () => Wave3ScaleDatasets.buildCatalog(
        recordCount: recordCount,
        seed: catalogSeed,
      ).totalRecords,
    );
    final domainCounts = measure(
      workloadLabel: 'catalog_large:domain_counts',
      scenario: Wave3ScaleScenario.catalogLarge,
      units: catalogUnits,
      workload: () {
        final schema = Wave3ScaleDatasets.buildCatalog(
          recordCount: recordCount,
          seed: catalogSeed,
        );
        int total = 0;
        for (final domain in EncyclopediaDomain.values) {
          total += schema.countFor(domain);
        }
        return total;
      },
    );
    measure(
      workloadLabel: 'catalog_large:indexed_census',
      scenario: Wave3ScaleScenario.catalogLarge,
      units: catalogUnits,
      workload: () {
        final schema = Wave3ScaleDatasets.buildCatalog(
          recordCount: recordCount,
          seed: catalogSeed,
        );
        final index = Wave3CatalogIndex.from(schema);
        var total = 0;
        for (final domain in EncyclopediaDomain.values) {
          final ids = index.recordIdsFor(domain);
          if (ids.length != schema.countFor(domain)) {
            throw StateError('catalog index disagrees for ${domain.id}');
          }
          total += ids.length;
        }
        return total;
      },
    );

    // --- media_many ----------------------------------------------------------
    final mediaUnits = Wave3ScaleScenario.mediaMany.defaultUnits;
    final assetCount = mediaUnits['assets']!;
    final missingEvery = mediaUnits['missingEvery']!;
    measure(
      workloadLabel: 'media_many:library_build',
      scenario: Wave3ScaleScenario.mediaMany,
      units: mediaUnits,
      workload: () => Wave3ScaleDatasets.buildMediaLibrary(
        assetCount: assetCount,
        missingEvery: missingEvery,
      ).planExport(explicitExport: true).assetIds.length,
    );
    final mediaLibrary = Wave3ScaleDatasets.buildMediaLibrary(
      assetCount: assetCount,
      missingEvery: missingEvery,
    );
    measure(
      workloadLabel: 'media_many:export_plan',
      scenario: Wave3ScaleScenario.mediaMany,
      units: mediaUnits,
      workload: () {
        var total = 0;
        for (var pass = 0; pass < 100; pass++) {
          final plan = mediaLibrary.planExport(explicitExport: true);
          total += plan.assetIds.length + plan.missingAssetIds.length;
        }
        return total ~/ 100;
      },
    );

    // --- graph_dense ----------------------------------------------------------
    final graphUnits = Wave3ScaleScenario.graphDense.defaultUnits;
    final nodeCount = graphUnits['nodes']!;
    measure(
      workloadLabel: 'graph_dense:build',
      scenario: Wave3ScaleScenario.graphDense,
      units: graphUnits,
      workload: () => Wave3ScaleDatasets.buildDenseGraph(
        nodeCount: nodeCount,
        offsets: Wave3ScaleDatasets.defaultOffsets,
      ).edgeCount,
    );
    final graph = Wave3ScaleDatasets.buildDenseGraph(
      nodeCount: nodeCount,
      offsets: Wave3ScaleDatasets.defaultOffsets,
    );
    measure(
      workloadLabel: 'graph_dense:reachability',
      scenario: Wave3ScaleScenario.graphDense,
      units: graphUnits,
      workload: () => graph.reachableFrom(Wave3ScaleDatasets.nodeId(0)).length,
    );
    final pairIndex = Wave3EdgePairIndex.from(graph);
    measure(
      workloadLabel: 'graph_dense:pair_queries',
      scenario: Wave3ScaleScenario.graphDense,
      units: graphUnits,
      workload: () {
        final nodes = graph.nodeIds;
        var found = 0;
        for (var i = 0; i < 2000; i++) {
          final a = nodes[i % nodes.length];
          final b = nodes[(i * 3 + 1) % nodes.length];
          final indexed = pairIndex.edgeBetween(a, b);
          final linear = graph.edgeBetween(a, b);
          if ((indexed == null) != (linear == null) ||
              indexed?.edgeId != linear?.edgeId) {
            throw StateError('pair index diverges from linear scan: $a->$b');
          }
          if (indexed != null) found++;
        }
        return found;
      },
    );

    // --- cross_domain_search ---------------------------------------------------
    final searchUnits = Wave3ScaleScenario.crossDomainSearch.defaultUnits;
    final documentCount = searchUnits['documents']!;
    measure(
      workloadLabel: 'cross_domain_search:index_build',
      scenario: Wave3ScaleScenario.crossDomainSearch,
      units: searchUnits,
      workload: () => Wave3ScaleDatasets.buildSearchIndex(
        recordCount: documentCount,
        seed: searchSeed,
      ).count,
    );
    final searchIndex = Wave3ScaleDatasets.buildSearchIndex(
      recordCount: documentCount,
      seed: searchSeed,
    );
    measure(
      workloadLabel: 'cross_domain_search:query_sweep',
      scenario: Wave3ScaleScenario.crossDomainSearch,
      units: searchUnits,
      extraUnits: const {'probeCount': 6},
      workload: () {
        final queries = <EncyclopediaSearchQuery>[
          EncyclopediaSearchQuery(text: 'void'),
          EncyclopediaSearchQuery(text: 'talis qorn'),
          EncyclopediaSearchQuery(
            domains: {
              EncyclopediaDomain.bestiary,
              EncyclopediaDomain.herbology,
            },
          ),
          EncyclopediaSearchQuery(categoryIds: {'cat-005'}),
          EncyclopediaSearchQuery(regionIds: {'reg-02'}),
          EncyclopediaSearchQuery(text: 'void talis', requireAllTerms: true),
        ];
        var total = 0;
        for (final query in queries) {
          total += searchIndex.search(query).totalMatches;
        }
        return total;
      },
    );
    measure(
      workloadLabel: 'cross_domain_search:facet_count',
      scenario: Wave3ScaleScenario.crossDomainSearch,
      units: searchUnits,
      workload: () => Wave3FacetIndex.from(searchIndex).cultureCount,
    );

    // --- generator_batch ---------------------------------------------------------
    final generatorUnits = Wave3ScaleScenario.generatorBatch.defaultUnits;
    final batchCount = generatorUnits['batches']!;
    final batchSize = generatorUnits['batchSize']!;
    measure(
      workloadLabel: 'generator_batch:${batchCount}x$batchSize',
      scenario: Wave3ScaleScenario.generatorBatch,
      units: <String, int>{
        ...generatorUnits,
        'names': batchCount * batchSize,
        'uniqueBatches': batchCount,
      },
      workload: () {
        final batches = Wave3ScaleDatasets.runGeneratorBatches(
          batchCount: batchCount,
          batchSize: batchSize,
          seed: generatorSeed,
        );
        for (final batch in batches) {
          if (batch.texts.toSet().length != batch.count) {
            throw StateError('batch ${batch.seed} produced duplicate texts');
          }
        }
        return wave3Fnv1a64(batches.map((b) => b.texts.join(',')).join(';'));
      },
    );
    measure(
      workloadLabel: 'generator_batch:replay',
      scenario: Wave3ScaleScenario.generatorBatch,
      units: const {'batchSize': 256},
      workload: () {
        final a = Wave3ScaleDatasets.runGeneratorBatches(
          batchCount: 1,
          batchSize: batchSize,
          seed: generatorSeed,
        ).single;
        final b = Wave3ScaleDatasets.runGeneratorBatches(
          batchCount: 1,
          batchSize: batchSize,
          seed: generatorSeed,
        ).single;
        if (a.texts.join('|') != b.texts.join('|')) {
          throw StateError('generator replay diverged');
        }
        return a.count;
      },
    );

    // --- qualitative sections --------------------------------------------------
    int msOf(String label) =>
        results.firstWhere((r) => r.workloadLabel == label).measuredMs;

    final bottlenecks = List<Wave3ScaleBottleneck>.from([
      Wave3ScaleBottleneck(
        label: bottleneckCatalog,
        scenarioLabel: Wave3ScaleScenario.catalogLarge.id,
        reason:
            'countFor/recordsFor memindai setiap record ter-registrasi per '
            'domain sehingga census penuh O(records x domains) — terukur '
            '${domainCounts.measuredMs}ms untuk $recordCount records.',
        measuredMs: domainCounts.measuredMs,
      ),
      Wave3ScaleBottleneck(
        label: bottleneckGraphPair,
        scenarioLabel: Wave3ScaleScenario.graphDense.id,
        reason:
            'EncyclopediaGraph.edgeBetween memindai linear seluruh edge; '
            '2k probe atas ${graph.edgeCount} edge didominasi biaya ini.',
        measuredMs: msOf('graph_dense:pair_queries'),
      ),
      Wave3ScaleBottleneck(
        label: bottleneckGraphReach,
        scenarioLabel: Wave3ScaleScenario.graphDense.id,
        reason:
            'reachableFrom menjalankan BFS baru per panggilan tanpa memo; '
            'pada graph padat setiap panggilan O(V+E).',
        measuredMs: msOf('graph_dense:reachability'),
      ),
      Wave3ScaleBottleneck(
        label: bottleneckSearchQuery,
        scenarioLabel: Wave3ScaleScenario.crossDomainSearch.id,
        reason:
            'setiap query mengiterasi seluruh dokumen dan membangun ulang '
            'peta token; biaya tumbuh linear terhadap ukuran korpus per '
            'query.',
        measuredMs: msOf('cross_domain_search:query_sweep'),
      ),
      Wave3ScaleBottleneck(
        label: bottleneckMediaPlan,
        scenarioLabel: Wave3ScaleScenario.mediaMany.id,
        reason:
            'planExport membangun ulang daftar include/missing di setiap '
            'panggilan.',
        measuredMs: msOf('media_many:export_plan'),
      ),
      Wave3ScaleBottleneck(
        label: bottleneckLibraryRegistration,
        scenarioLabel: Wave3ScaleScenario.mediaMany.id,
        reason:
            'EncyclopediaMediaLibrary.register memindai seluruh path yang ada '
            'demi guard duplikasi — O(n^2) terhadap jumlah aset.',
        measuredMs: msOf('media_many:library_build'),
      ),
      Wave3ScaleBottleneck(
        label: bottleneckGeneratorRetry,
        scenarioLabel: Wave3ScaleScenario.generatorBatch.id,
        reason:
            'satu proposal dapat mencoba ulang hingga 64 legal + 200 '
            'duplikat sebelum mendarat, sehingga biaya terburuk batch tidak '
            'dibatasi jumlah saja.',
        measuredMs: msOf('generator_batch:${batchCount}x$batchSize'),
      ),
    ])..sort((a, b) => a.label.compareTo(b.label));

    const mitigations = <Wave3ScaleMitigation>[
      Wave3ScaleMitigation(
        label: 'catalog:per_domain_index',
        bottleneckLabels: [bottleneckCatalog],
        action:
            'registrasi record ke daftar id tersortir per domain sekali '
            'saja (Wave3CatalogIndex) sehingga census dan baca per domain '
            'menjadi lookup O(1), bukan scan ulang seluruh registry.',
      ),
      Wave3ScaleMitigation(
        label: 'generator:bounded_retry_budget_and_batch_cache',
        bottleneckLabels: [bottleneckGeneratorRetry],
        action:
            'pertahankan budget retry keras yang sudah ada (64 legal / 200 '
            'duplikat) dan cache batch selesai dengan kunci seed+size; '
            'regenerasi hanya memasuki loop ulang lewat rantai nextSeed '
            'eksplisit.',
      ),
      Wave3ScaleMitigation(
        label: 'graph:edge_pair_index_and_reachability_memo',
        bottleneckLabels: [bottleneckGraphPair, bottleneckGraphReach],
        action:
            'bangun peta (from,to)->edge pertama-by-id dua arah '
            '(Wave3EdgePairIndex) untuk query pasangan dan memoize '
            'reachability per revisi graph sehingga lintasan BFS berulang '
            'teramortisasi.',
      ),
      Wave3ScaleMitigation(
        label: 'media:path_index_and_memoized_plan',
        bottleneckLabels: [bottleneckLibraryRegistration, bottleneckMediaPlan],
        action:
            'index relativePath->assetId untuk guard duplikasi O(1) dan '
            'simpan hasil planExport sekali per revisi pustaka sehingga '
            'sweep ekspor tidak rebuild daftar berulang.',
      ),
      Wave3ScaleMitigation(
        label: 'search:facet_index_and_query_lru',
        bottleneckLabels: [bottleneckSearchQuery],
        action:
            'pra-bucket postings culture/region/category sekali '
            '(Wave3FacetIndex) dan cache laporan query selesai dengan LRU '
            'terbatas berkunci JSON kanonik query, sehingga sweep berulang '
            'memakai ulang hasil.',
      ),
    ];

    const strategies = <Wave3IndexStrategy>[
      Wave3IndexStrategy(
        label: 'catalog:per_domain_index',
        mechanism:
            'Map<EncyclopediaDomain, List<String>> id tersortir dibangun '
            'sekali per revisi registry; totalIndexed sama dengan naive '
            'scan (dibuktikan tes ekivalensi).',
        bottleneckLabels: [bottleneckCatalog],
      ),
      Wave3IndexStrategy(
        label: 'graph:edge_pair_index',
        mechanism:
            r'Map<"<from>\u0000<to>", List<edge sorted by edgeId>> dua '
            'arah; edgeBetween menghasilkan pemenang sama dengan scan '
            'linear dalam O(1) (dibuktikan probe 2k pasangan).',
        bottleneckLabels: [bottleneckGraphPair],
      ),
      Wave3IndexStrategy(
        label: 'search:facet_index',
        mechanism:
            'postings recordId tersortir culture/region/category dibangun '
            'sekali dari indeks 111.37; query keanggotaan tidak lagi '
            'memindai dokumen (dibuktikan ekivalensi naif-vs-index).',
        bottleneckLabels: [bottleneckSearchQuery],
      ),
    ];

    return Wave3ScaleReport.of(
      datasets: profile.datasets,
      budgets: budgets,
      results: results,
      indexStrategies: strategies,
      bottlenecks: bottlenecks,
      mitigations: mitigations,
    );
  }
}
