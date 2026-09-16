// Sprint 111.44 - Documentation & Worldbuilding Guidance.
//
// Enam keluaran wajib objective (sprint_111.json step 111.44):
//   feature_guides, taxonomy_guide, canon_guide, generator_guide,
//   portability_guide, known_limits
// diformalkan sebagai katalog entri panduan ter-audit di atas manifest modul
// Wave 3 NYATA (census `EncyclopediaWave3TestSuiteSources.wave3DomainModules()`
// dari 111.40) — bukan daftar karangan: setiap modul yang dirujuk grup
// kemampuan wajib ada di census, dan setiap modul census wajib terpetakan
// tepat satu kali.
//
// Isi panduan merangkum kontrak yang SUDAH diverifikasi ledger sprint 111
// (111.3-111.42); tidak ada acceptance baru yang diklaim. Batas jujur:
// ini dokumentasi domain; lapisan UI/persistence tetap di bawah
// D-SCHEMA-01 (OPEN) dan native GUI TIDAK diklaim.
//
// Domain-only: deterministik, tanpa persistence/UI/file-IO/network/wall
// clock/random.
import 'encyclopedia_wave3_test_matrix.dart';

/// Enam jenis panduan = enam keluaran wajib objective 111.44.
enum Wave3GuideKind {
  featureGuide('feat.', 'feature_guides'),
  taxonomyGuide('tax.', 'taxonomy_guide'),
  canonGuide('canon.', 'canon_guide'),
  generatorGuide('gen.', 'generator_guide'),
  portabilityGuide('port.', 'portability_guide'),
  knownLimit('lim.', 'known_limits');

  const Wave3GuideKind(this.idPrefix, this.outputLabel);

  /// Semua id entri WAJIB diawali prefix jenisnya sehingga jenis entri
  /// terbaca dari id tanpa ambiguity.
  final String idPrefix;

  /// Nama keluaran kanonik pada objective 111.44.
  final String outputLabel;

  static const List<Wave3GuideKind> canonicalKinds = <Wave3GuideKind>[
    Wave3GuideKind.featureGuide,
    Wave3GuideKind.taxonomyGuide,
    Wave3GuideKind.canonGuide,
    Wave3GuideKind.generatorGuide,
    Wave3GuideKind.portabilityGuide,
    Wave3GuideKind.knownLimit,
  ];
}

/// Sepuluh subjek wajib pada objective 111.44 ("Menjelaskan schema, canon,
/// provenance, spoiler, generator, validasi, import, export, backup, dan
/// recovery"). Katalog dianggap lengkap hanya bila setiap subjek dibahas
/// minimal satu entri.
class Wave3DocsRequiredTopics {
  const Wave3DocsRequiredTopics._();

  static const List<String> required = <String>[
    'schema',
    'canon',
    'provenance',
    'spoiler',
    'generator',
    'validasi',
    'import',
    'export',
    'backup',
    'recovery',
  ];
}

String _normalizeTopic(String raw) {
  final trimmed = raw.trim().toLowerCase();
  if (trimmed.isEmpty) {
    throw ArgumentError('topic tidak boleh kosong');
  }
  return trimmed;
}

List<String> _normalizeTopics(Iterable<String> raw) {
  final normalized = raw.map(_normalizeTopic).toList(growable: false);
  if (normalized.isEmpty) {
    throw ArgumentError('topics wajib berisi minimal satu subjek');
  }
  return List<String>.unmodifiable(normalized);
}

/// Satu entri panduan: id ber-prefix jenis, judul, ringkasan kontrak yang
/// sudah terverifikasi, daftar subjek yang dibahas, dan sumber langkah
/// sprint (bukti ledger), bukan klaim baru.
class Wave3GuideEntry {
  const Wave3GuideEntry._({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.topics,
    required this.sources,
  });

  factory Wave3GuideEntry.validated({
    required String id,
    required Wave3GuideKind kind,
    required String title,
    required String summary,
    required Iterable<String> topics,
    required Iterable<String> sources,
  }) {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('id tidak boleh kosong');
    }
    if (!trimmedId.startsWith(kind.idPrefix)) {
      throw ArgumentError(
        'id "$trimmedId" wajib diawali prefix "${kind.idPrefix}"',
      );
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('title tidak boleh kosong');
    }
    final trimmedSummary = summary.trim();
    if (trimmedSummary.isEmpty) {
      throw ArgumentError('summary tidak boleh kosong');
    }
    final trimmedSources = sources
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (trimmedSources.isEmpty) {
      throw ArgumentError('sources wajib berisi minimal satu rujukan');
    }
    return Wave3GuideEntry._(
      id: trimmedId,
      kind: kind,
      title: trimmedTitle,
      summary: trimmedSummary,
      topics: _normalizeTopics(topics),
      sources: List<String>.unmodifiable(trimmedSources),
    );
  }

  final String id;
  final Wave3GuideKind kind;
  final String title;
  final String summary;
  final List<String> topics;
  final List<String> sources;

  bool coversTopic(String topic) => topics.contains(_normalizeTopic(topic));

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'title': title,
    'summary': summary,
    'topics': List<String>.from(topics),
    'sources': List<String>.from(sources),
  };

  static Wave3GuideEntry fromJson(Map<String, Object?> json) {
    final kindName = json['kind'];
    final kind = Wave3GuideKind.values
        .where((k) => k.name == kindName)
        .firstOrNull;
    if (kind == null) {
      throw ArgumentError('kind tidak dikenal: $kindName');
    }
    final topicsRaw = json['topics'];
    final sourcesRaw = json['sources'];
    if (topicsRaw is! List || sourcesRaw is! List) {
      throw ArgumentError('topics/sources wajib berupa list');
    }
    return Wave3GuideEntry.validated(
      id: json['id'] as String? ?? '',
      kind: kind,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      topics: topicsRaw.cast<String>(),
      sources: sourcesRaw.cast<String>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Wave3GuideEntry &&
      other.runtimeType == runtimeType &&
      const ListEquality().equals(
        other.toJson().values.toList(),
        toJson().values.toList(),
      );

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    summary,
    Object.hashAll(topics),
    Object.hashAll(sources),
  );

  @override
  String toString() => 'Wave3GuideEntry($id)';
}

/// Katalog panduan Wave 3: entri sorted by id, immutable, guard duplikat.
class Wave3DocsCatalog {
  const Wave3DocsCatalog._(this._entries);

  static final Wave3DocsCatalog canonical = Wave3DocsCatalog.withEntries(
    _buildCanonicalEntries(),
  );

  final List<Wave3GuideEntry> _entries;

  /// Entri ter-sort by id (deterministik) dan immutable.
  List<Wave3GuideEntry> get entries =>
      List<Wave3GuideEntry>.unmodifiable(_entries);

  /// Membangun katalog dari entri apa pun; guard duplikat id -> StateError.
  /// List input tidak pernah dipakai langsung (no-mutation contract).
  factory Wave3DocsCatalog.withEntries(Iterable<Wave3GuideEntry> input) {
    final snapshot = List<Wave3GuideEntry>.of(input);
    final ids = snapshot.map((e) => e.id).toSet();
    if (ids.length != snapshot.length) {
      throw StateError('id entri panduan duplikat terdeteksi');
    }
    final sorted = [...snapshot]..sort((a, b) => a.id.compareTo(b.id));
    return Wave3DocsCatalog._(List<Wave3GuideEntry>.unmodifiable(sorted));
  }

  Wave3GuideEntry? entryFor(String id) {
    final key = id.trim();
    for (final entry in _entries) {
      if (entry.id == key) {
        return entry;
      }
    }
    return null;
  }

  List<Wave3GuideEntry> entriesOfKind(Wave3GuideKind kind) =>
      List<Wave3GuideEntry>.unmodifiable(
        _entries.where((e) => e.kind == kind).toList(growable: false),
      );

  /// Subjek wajib objective 111.44 yang BELUM dibahas entri mana pun.
  List<String> missingRequiredTopics() => Wave3DocsRequiredTopics.required
      .where((topic) => !_entries.any((e) => e.coversTopic(topic)))
      .toList(growable: false);

  Map<String, Object?> toJson() => <String, Object?>{
    'entries': _entries.map((e) => e.toJson()).toList(),
  };

  static Wave3DocsCatalog fromJson(Map<String, Object?> json) {
    final raw = json['entries'];
    if (raw is! List) {
      throw ArgumentError('entries wajib berupa list');
    }
    return Wave3DocsCatalog.withEntries(
      raw.map((e) => Wave3GuideEntry.fromJson(e as Map<String, Object?>)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Wave3DocsCatalog &&
      other.runtimeType == runtimeType &&
      other.toJson().toString() == toJson().toString();

  @override
  int get hashCode => toJson().toString().hashCode;
}

/// Grup pemetaan kemampuan kanonik (kontrak scope F23/F24/F26/F27/F28/F29,
/// alias F30 -> F24) + fondasi bersama -> daftar modul census 111.40.
class Wave3CapabilityGroup {
  const Wave3CapabilityGroup._({
    required this.id,
    required this.label,
    required this.stepRange,
    required this.modules,
  });

  factory Wave3CapabilityGroup.validated({
    required String id,
    required String label,
    required String stepRange,
    required Iterable<String> modules,
  }) {
    final trimmedId = id.trim();
    final trimmedLabel = label.trim();
    final trimmedRange = stepRange.trim();
    final moduleList = modules
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList(growable: false);
    if (trimmedId.isEmpty || trimmedLabel.isEmpty || trimmedRange.isEmpty) {
      throw ArgumentError('id/label/stepRange tidak boleh kosong');
    }
    if (moduleList.isEmpty) {
      throw ArgumentError('modules wajib berisi minimal satu modul census');
    }
    return Wave3CapabilityGroup._(
      id: trimmedId,
      label: trimmedLabel,
      stepRange: trimmedRange,
      modules: List<String>.unmodifiable(moduleList),
    );
  }

  final String id;
  final String label;
  final String stepRange;
  final List<String> modules;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'label': label,
    'stepRange': stepRange,
    'modules': List<String>.from(modules),
  };
}

/// Laporan cakupan panduan: kelengkapan 6 jenis keluaran + 10 subjek wajib
/// + audit pemetaan modul census (tepat sekali, tanpa modul tak dikenal).
class Wave3GuideCoverageReport {
  const Wave3GuideCoverageReport._({
    required this.kindsMissing,
    required this.topicsMissing,
    required this.modulesUncovered,
    required this.modulesMappedMoreThanOnce,
    required this.unknownModuleReferences,
  });

  factory Wave3GuideCoverageReport.of(Wave3DocsCatalog catalog) {
    final kindsMissing = Wave3GuideKind.canonicalKinds
        .where((kind) => catalog.entriesOfKind(kind).isEmpty)
        .toList(growable: false);

    final topicsMissing = catalog.missingRequiredTopics();

    // Audit modul census vs grup kemampuan kanonik.
    final census = EncyclopediaWave3TestSuiteSources.wave3DomainModules();
    final censusSet = census.toSet();
    final moduleCount = <String, int>{};
    for (final group in Wave3CapabilityGroups.canonical) {
      for (final module in group.modules) {
        moduleCount[module] = (moduleCount[module] ?? 0) + 1;
      }
    }
    final unknown = <String>[];
    final duplicated = <String>[];
    for (final entry in moduleCount.entries) {
      if (!censusSet.contains(entry.key)) {
        unknown.add(entry.key);
      }
      if (entry.value > 1) {
        duplicated.add(entry.key);
      }
    }
    final uncovered = census
        .where((module) => !moduleCount.containsKey(module))
        .toList(growable: false);

    return Wave3GuideCoverageReport._(
      kindsMissing: List<Wave3GuideKind>.unmodifiable(kindsMissing),
      topicsMissing: List<String>.unmodifiable(topicsMissing),
      modulesUncovered: List<String>.unmodifiable(uncovered..sort()),
      modulesMappedMoreThanOnce: List<String>.unmodifiable(duplicated..sort()),
      unknownModuleReferences: List<String>.unmodifiable(unknown..sort()),
    );
  }

  final List<Wave3GuideKind> kindsMissing;
  final List<String> topicsMissing;
  final List<String> modulesUncovered;
  final List<String> modulesMappedMoreThanOnce;
  final List<String> unknownModuleReferences;

  bool get isComplete =>
      kindsMissing.isEmpty &&
      topicsMissing.isEmpty &&
      modulesUncovered.isEmpty &&
      modulesMappedMoreThanOnce.isEmpty &&
      unknownModuleReferences.isEmpty;

  String describe() {
    final buffer = StringBuffer()
      ..writeln('Wave 3 documentation coverage:')
      ..writeln(
        '- output kinds missing: ${kindsMissing.map((k) => k.outputLabel).join(", ")}',
      )
      ..writeln('- required topics missing: ${topicsMissing.join(", ")}')
      ..writeln('- census modules uncovered: ${modulesUncovered.join(", ")}')
      ..writeln(
        '- modules mapped more than once: ${modulesMappedMoreThanOnce.join(", ")}',
      )
      ..writeln(
        '- unknown module references: ${unknownModuleReferences.join(", ")}',
      )
      ..write(isComplete ? 'coverage COMPLETE' : 'coverage INCOMPLETE');
    return buffer.toString();
  }
}

/// Tabel grup kemampuan kanonik dari docs/planning/v1.2/sprint_111_scope_contract.md
/// (F23/F24/F26/F27/F28/F29; alias F30 -> F24) + fondasi bersama lintas
/// kemampuan. Setiap modul census 111.40 muncul tepat satu kali di seluruh
/// grup (divalidasi oleh [Wave3GuideCoverageReport]).
class Wave3CapabilityGroups {
  const Wave3CapabilityGroups._();

  static final List<Wave3CapabilityGroup> canonical =
      List<Wave3CapabilityGroup>.unmodifiable(<Wave3CapabilityGroup>[
        Wave3CapabilityGroup.validated(
          id: 'F23',
          label: 'Herbology & Alchemy Database',
          stepRange: '111.9-111.13',
          modules: <String>[
            'encyclopedia_ingredient.dart',
            'encyclopedia_harvest.dart',
            'encyclopedia_effect.dart',
            'encyclopedia_alchemy.dart',
            'encyclopedia_alchemy_validation.dart',
          ],
        ),
        Wave3CapabilityGroup.validated(
          id: 'F24',
          label: 'Bestiary Journal (alias F30)',
          stepRange: '111.14-111.19',
          modules: <String>[
            'encyclopedia_creature.dart',
            'encyclopedia_anatomy.dart',
            'encyclopedia_ecology.dart',
            'encyclopedia_combat.dart',
            'encyclopedia_encounter.dart',
            'encyclopedia_harvestable_material.dart',
          ],
        ),
        Wave3CapabilityGroup.validated(
          id: 'F26',
          label: 'Artifacts & Ancient Relics',
          stepRange: '111.20-111.23',
          modules: <String>[
            'encyclopedia_artifact.dart',
            'encyclopedia_ownership_lineage.dart',
            'encyclopedia_activation_rules.dart',
            'encyclopedia_artifact_validation.dart',
          ],
        ),
        Wave3CapabilityGroup.validated(
          id: 'F27',
          label: 'Myth, Legend & Theology Archive',
          stepRange: '111.24-111.28',
          modules: <String>[
            'encyclopedia_myth.dart',
            'encyclopedia_belief_truth.dart',
            'encyclopedia_theology.dart',
            'encyclopedia_belief_distribution.dart',
            'encyclopedia_reveal_links.dart',
          ],
        ),
        Wave3CapabilityGroup.validated(
          id: 'F28',
          label: 'Syllable-Based Name Generator',
          stepRange: '111.29-111.32',
          modules: <String>[
            'encyclopedia_syllable_phonotactics.dart',
            'encyclopedia_name_profiles.dart',
            'encyclopedia_seeded_name_generation.dart',
            'encyclopedia_name_collision.dart',
          ],
        ),
        Wave3CapabilityGroup.validated(
          id: 'F29',
          label: 'Local Idiom & Proverb Bank',
          stepRange: '111.33-111.36',
          modules: <String>[
            'encyclopedia_idiom_registry.dart',
            'encyclopedia_idiom_usage.dart',
            'encyclopedia_idiom_tone.dart',
            'encyclopedia_idiom_consistency.dart',
          ],
        ),
        Wave3CapabilityGroup.validated(
          id: 'shared',
          label: 'Fondasi bersama lintas kemampuan',
          stepRange: '111.3-111.8, 111.37-111.43',
          modules: <String>[
            'shared_encyclopedia_taxonomy.dart',
            'encyclop_canon_provenance.dart',
            'encyclopedia_scope.dart',
            'shared_encyclopedia_schema.dart',
            'encyclopedia_media_rights.dart',
            'encyclopedia_spoiler_accessibility.dart',
            'encyclopedia_unified_search.dart',
            'encyclopedia_integration.dart',
            'encyclopedia_portability.dart',
          ],
        ),
      ]);
}

/// Modul harness verifikasi Wave 3 (111.40-111.43) di luar census 111.40:
/// mereka memverifikasi modul lain, bukan kemampuan worldbuilding sendiri,
/// sehingga tidak masuk tabel pemetaan modul; dokumentasinya wajib hadir di
/// entri feature guide fondasi (feat.f00-shared-foundation).
class Wave3HarnessModules {
  const Wave3HarnessModules._();

  static const List<String> documented = <String>[
    'encyclopedia_wave3_test_matrix.dart',
    'encyclopedia_wave3_scale.dart',
    'encyclopedia_wave3_security.dart',
    'encyclopedia_wave3_accessibility.dart',
  ];
}

/// Entri kanonik katalog panduan 111.44. Ringkasan hanya merangkum kontrak
/// yang sudah VERIFIED-LOCAL di ledger sprint 111; tidak ada acceptance baru.
List<Wave3GuideEntry> _buildCanonicalEntries() {
  return <Wave3GuideEntry>[
    // feature_guides (F23/F24/F26/F27/F28/F29 + fondasi).
    Wave3GuideEntry.validated(
      id: 'feat.f23-herbology-alchemy',
      kind: Wave3GuideKind.featureGuide,
      title: 'F23 Herbology & Alchemy Database',
      summary:
          'Katalog bahan (tipe, bagian terpakai, varian lokal, alias, media, sumber), habitat/kelangkaan/panen, efek/dosis/toksisitas/interaksi, resep alkimia terstruktur, dan validator konsistensi alkimia yang menjelaskan setiap isu (missing ingredient, substitusi tak sah, konflik efek, konflik preparasi) dengan manual exception per resep+kind. Semua domain-only dan deterministik.',
      topics: <String>['schema', 'canon', 'validasi', 'provenance'],
      sources: <String>['111.9', '111.10', '111.11', '111.12', '111.13'],
    ),
    Wave3GuideEntry.validated(
      id: 'feat.f24-bestiary',
      kind: Wave3GuideKind.featureGuide,
      title: 'F24 Bestiary Journal (mencakup alias F30)',
      summary:
          'Registri spesies (varian, tahap hidup, klasifikasi, nama lokal, status canon), profil anatomi/fisiologi, ekologi + tekanan predator, referensi pertarungan/kelemahan, jurnal pertemuan, dan bahan panen dengan konsekuensi ekologis. Alias F30 memakai flag F24 tanpa kontrak terpisah. Domain-only.',
      topics: <String>['canon', 'schema', 'provenance'],
      sources: <String>[
        '111.14',
        '111.15',
        '111.16',
        '111.17',
        '111.18',
        '111.19',
      ],
    ),
    Wave3GuideEntry.validated(
      id: 'feat.f26-artifacts',
      kind: Wave3GuideKind.featureGuide,
      title: 'F26 Artifacts & Ancient Relics',
      summary:
          'Registri artefak, garis kepemilikan (ownership lineage), aturan aktivasi/biaya/kutukan/keterbatasan, dan validasi pemakaian + keaslian (owner/activation/location/authenticity check, explain warning, manual exception). Semua pemeriksaan menjelaskan alasannya dan bisa di-override secara eksplisit.',
      topics: <String>['canon', 'provenance', 'validasi'],
      sources: <String>['111.20', '111.21', '111.22', '111.23'],
    ),
    Wave3GuideEntry.validated(
      id: 'feat.f27-myth-theology',
      kind: Wave3GuideKind.featureGuide,
      title: 'F27 Myth, Legend & Theology Archive',
      summary:
          'Registri mitos (varian, motif, tokoh, lokasi, kelompok pemberita), kepercayaan publik vs kebenaran historis ber-confidence, teologi/dewa/doktrin/skisma, distribusi kepercayaan + konversi/reformasi/persekusi/sinkretisme, dan tautan reveal/foreshadowing dengan spoiler preview ter-mask via SpoilerPolicy.',
      topics: <String>['canon', 'spoiler', 'provenance'],
      sources: <String>['111.24', '111.25', '111.26', '111.27', '111.28'],
    ),
    Wave3GuideEntry.validated(
      id: 'feat.f28-name-generator',
      kind: Wave3GuideKind.featureGuide,
      title: 'F28 Syllable-Based Name Generator',
      summary:
          'Kolompok suku kata + aturan fonotaktik (pola C/V, stress, urutan terlarang), profil nama budaya (era, konteks sosial, gelar, prefiks/sufiks), generasi ber-seed eksplisit yang reproducible, serta pemeriksaan tabrakan nama (exact + similarity) dan konsistensi budaya. Hasil tak pernah menulis kanon tanpa penerimaan eksplisit.',
      topics: <String>['generator', 'validasi'],
      sources: <String>['111.29', '111.30', '111.31', '111.32'],
    ),
    Wave3GuideEntry.validated(
      id: 'feat.f29-idiom-bank',
      kind: Wave3GuideKind.featureGuide,
      title: 'F29 Local Idiom & Proverb Bank',
      summary:
          'Registri idiom/peribahasa (teks asli, terjemahan literal, makna, varian, tautan bahasa), kepemilikan budaya + konteks pemakaian (register, profesi, era), nada/konotasi/saran dialog dengan insert yang selalu diinisiasi pengguna, dan pemeriksaan konsistensi/anakronisme dengan explain warning + manual exception.',
      topics: <String>['canon', 'validasi'],
      sources: <String>['111.33', '111.34', '111.35', '111.36'],
    ),
    Wave3GuideEntry.validated(
      id: 'feat.f00-shared-foundation',
      kind: Wave3GuideKind.featureGuide,
      title: 'Fondasi bersama ensiklopedia Wave 3',
      summary:
          'Taksonomi bersama (kategori, tag, alias, nama terlokalisasi, tautan lintas domain, versioning), model canon/provenance/confidence, cakupan temporal-regional-budaya, skema data bersama + rencana migrasi, media & hak sumber, spoiler/feature flag/accessibility, pencarian lintas domain, integrasi editor/graf/cerita, portability ekspor-impor, plus harness scale/security/accessibility/test-matrix Wave 3.',
      topics: <String>[
        'schema',
        'canon',
        'provenance',
        'spoiler',
        'import',
        'export',
        'backup',
        'recovery',
        'validasi',
      ],
      sources: <String>[
        '111.3',
        '111.4',
        '111.5',
        '111.6',
        '111.7',
        '111.8',
        '111.37',
        '111.38',
        '111.39',
        '111.40',
        '111.41',
        '111.42',
        '111.43',
      ],
    ),
    // taxonomy_guide.
    Wave3GuideEntry.validated(
      id: 'tax.taxonomy-registry',
      kind: Wave3GuideKind.taxonomyGuide,
      title: 'Taksonomi bersama: kategori, tag, alias, tautan',
      summary:
          'EncyclopediaTaxonomy menjaga kategori tervalidasi (id lowercase+trim), tag bebas ternormalisasi, alias per kategori, nama terlokalisasi (locale + originalScript untuk multiskrip), tautan lintas domain dengan kind terkontrol, dan versi skema semantic (bumpMinor/bumpMajor). Registry menolak referensi kategori/entri tak dikenal sehingga data rusak tertangkap di boundary, bukan di bacaan.',
      topics: <String>['schema', 'canon'],
      sources: <String>['111.3', '111.6'],
    ),
    Wave3GuideEntry.validated(
      id: 'tax.unified-search',
      kind: Wave3GuideKind.taxonomyGuide,
      title: 'Pencarian ensiklopedia lintas domain',
      summary:
          'Satu query menembus semua domain: skor judul/alias deterministik dengan tie-break stabil, filter AND (domain/kategori/budaya/region/status canon/tick), facet agregat, permission filter spoiler yang dijalankan TERAKHIR (denied tidak pernah bocor ke skor/facet), navigasi keyboard ter-clamp, dan saved search sebagai kontrak JSON in-memory (persistence menunggu D-SCHEMA-01).',
      topics: <String>['schema', 'spoiler', 'validasi'],
      sources: <String>['111.37'],
    ),
    // canon_guide.
    Wave3GuideEntry.validated(
      id: 'canon.canon-provenance-confidence',
      kind: Wave3GuideKind.canonGuide,
      title: 'Canon, provenance & confidence',
      summary:
          'Setiap klaim ensiklopedia membawa CanonStatus (canon/rumor/myth/hypothesis/generated), rujukan sumber, atribusi penulis/budaya, confidence [0,1], daftar asumsi eksplisit, dan riwayat revisi immutable: appendRevision merekam alasan + confidence baru tanpa menghapus sejarah. Confidence dan asumsi bukan pelengkap - ia kontrak pembacaan.',
      topics: <String>['canon', 'provenance'],
      sources: <String>['111.4', '111.5'],
    ),
    Wave3GuideEntry.validated(
      id: 'canon.spoiler-policy',
      kind: Wave3GuideKind.canonGuide,
      title: 'Spoiler policy & reveal points',
      summary:
          'SpoilerPolicy memakai level default safe dengan override per-record yang selalu menang; RevealPoint mencatat titik reveal per tick; registry menolak reveal duplikat. Semua jalur turunan (pencarian, ekspor, preview) menghormati policy yang sama sehingga konten tersembunyi tidak bocor lintas fitur.',
      topics: <String>['spoiler', 'canon'],
      sources: <String>['111.8', '111.28', '111.37'],
    ),
    // generator_guide.
    Wave3GuideEntry.validated(
      id: 'gen.phonotactics-and-profiles',
      kind: Wave3GuideKind.generatorGuide,
      title: 'Fonotaktik & profil nama budaya',
      summary:
          'PhonotacticsSpec mendefinisikan pola suku kata (onset-nucleus-coda), stress rule, dan urutan terlarang; isWordLegal memeriksa kata kandidat. CulturalNameProfile menyediakan era (marker + sequence rank), konteks sosial, gelar, dan aturan prefiks/sufiks yang boleh merujuk pola suku kata. Semua deterministik tanpa wall clock.',
      topics: <String>['generator', 'schema'],
      sources: <String>['111.29', '111.30'],
    ),
    Wave3GuideEntry.validated(
      id: 'gen.seeded-generation',
      kind: Wave3GuideKind.generatorGuide,
      title: 'Generasi nama ber-seed eksplisit',
      summary:
          'SeededNameGenerator mensyaratkan seed eksplisit (> 0; seed kosong ditolak), memakai PRNG lokal deterministik (SplitMix64 + FNV-1a64 untuk id proposal - hashCode Dart tidak stabil lintas proses), menghasilkan batch reproducible byte-identik per seed, mendukung regenerate dengan seed turunan, dan TIDAK PERNAH menulis kanon tanpa penerimaan eksplisit (no_auto_canon dibuktikan JSON-compare input sebelum/sesudah).',
      topics: <String>['generator', 'canon'],
      sources: <String>['111.31'],
    ),
    Wave3GuideEntry.validated(
      id: 'gen.collision-and-consistency',
      kind: Wave3GuideKind.generatorGuide,
      title: 'Tabrakan nama & konsistensi budaya',
      summary:
          'NameCheckReport membandingkan kandidat dengan inventaris: exact collision menang atas similarity (Levenshtein rune lokal), fonotaktik dinilai lewat PhonotacticsSpec (spec null = lulus tanpa klaim legalitas), whitelist budaya dinilai via profil 111.30, reserved names diblokir, dan manual acceptance bersifat presisi per (candidateId, kind). Semua issue punya issueId deterministik.',
      topics: <String>['generator', 'validasi'],
      sources: <String>['111.32'],
    ),
    // portability_guide.
    Wave3GuideEntry.validated(
      id: 'port.export-import-bundle',
      kind: Wave3GuideKind.portabilityGuide,
      title: 'Ekspor & impor bundel ensiklopedia',
      summary:
          'Ekspor butuh opt-in eksplisit (explicitExport), menghasilkan JSON kanonik (key sorted) berisi documents + media manifest + laporan sanitization spoiler + checksum. Impor fail-closed: isu blocking (format tak didukung, dokumen rusak, record duplikat, manifest tak tersanitasi, checksum mismatch/checksum hilang) membuat importText melempar; warning tidak membatalkan impor. Round trip export-import-export byte-identik.',
      topics: <String>['import', 'export', 'schema', 'validasi'],
      sources: <String>['111.39', '111.42'],
    ),
    Wave3GuideEntry.validated(
      id: 'port.media-rights',
      kind: Wave3GuideKind.portabilityGuide,
      title: 'Media, hak cipta & keamanan sumber',
      summary:
          'Media hanya lewat path relatif proyek (path absolut dan traversal ditolak), kredit dan lisensi terekam per aset, sanitization metadata membuang kunci GPS/identitas secara case-insensitive dan order-stable, dan rencana ekspor mengecualikan file hilang secara default (includeMissing harus eksplisit). Manifest ekspor wajib menyatakan sanitizationApplied.',
      topics: <String>['export', 'provenance'],
      sources: <String>['111.7', '111.39'],
    ),
    Wave3GuideEntry.validated(
      id: 'port.backup-rollback',
      kind: Wave3GuideKind.portabilityGuide,
      title: 'Backup, rollback & recovery skema',
      summary:
          'SharedEncyclopediaSchema mendefinisikan rencana migrasi deterministik per domain: backup (dengan checksum + byte size), schema check, transfer, compatibility check (missing/duplicate category), rollback drill, dan repair path (flag + de-dup kategori). Kontrak ini domain-level; persistence dan backup file nyata masih menunggu D-SCHEMA-01 (OPEN).',
      topics: <String>['backup', 'recovery', 'schema'],
      sources: <String>['111.6'],
    ),
    // known_limits.
    Wave3GuideEntry.validated(
      id: 'lim.d-schema-01-persistence-open',
      kind: Wave3GuideKind.knownLimit,
      title: 'D-SCHEMA-01: persistence belum didaratkan',
      summary:
          'Seluruh modul Wave 3 adalah domain-only: belum ada tabel Drift, UI, atau file IO nyata. Saved search, bundel, dan backup bersifat kontrak JSON in-memory; migrasi yang diuji adalah SchemaCompatibilityCheck domain. D-SCHEMA-01 tetap OPEN sampai keputusan skema dan slice persistence tersendiri - jangan mengangkat klaim GUI/persistence dari dokumentasi ini.',
      topics: <String>['schema', 'backup', 'recovery', 'import', 'export'],
      sources: <String>[
        '111.6',
        '111.37',
        '111.39',
        'sprint_111_scope_contract.md',
      ],
    ),
    Wave3GuideEntry.validated(
      id: 'lim.native-ui-deferred',
      kind: Wave3GuideKind.knownLimit,
      title: 'Native GUI & screen reader belum diverifikasi',
      summary:
          'Capture screen-reader native Windows dan pengujian font-scale di widget host tidak diklaim oleh harness 111.43 (status deferredNative); hasil a11y yang terdokumentasi adalah kontrak domain (keyboard map, screen reader labels, fallback nonvisual). Journey native adalah slice tersendiri di luar 111.44.',
      topics: <String>['generator', 'validasi', 'spoiler'],
      sources: <String>['111.43'],
    ),
    Wave3GuideEntry.validated(
      id: 'lim.hardware-bound-verification',
      kind: Wave3GuideKind.knownLimit,
      title: 'Verifikasi hardware-bound (power loss)',
      summary:
          'Integritas power-loss nyata tidak dapat diverifikasi dari domain (dart:io flush bukan fsync); threat th-power-loss-integrity di harness 111.42 berstatus deferredHardware dan tidak pernah diklaim lunak. Preseden: 145.30 diterima PARTIAL hardware-bound oleh keputusan pengguna.',
      topics: <String>['backup', 'recovery'],
      sources: <String>['111.42', '145.30'],
    ),
    Wave3GuideEntry.validated(
      id: 'lim.scale-numbers-device-local',
      kind: Wave3GuideKind.knownLimit,
      title: 'Angka skala = baseline perangkat ini',
      summary:
          'Durasi dan ceiling pada laporan scale 111.41 adalah baseline perangkat pengembangan (fingerprints dataset dan golden generator replay dibekukan dari probe terukur), bukan budget produksi lintas hardware. Strategi indeks (catalog/edge-pair/facet) terbukti setara naive scan, bukan hasil profiling runtime UI.',
      topics: <String>['generator', 'validasi', 'schema'],
      sources: <String>['111.41'],
    ),
  ];
}

/// firstOrNull untuk List tanpa dependensi package:collection.
extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

/// Equality list kecil untuk operator== entri (hindari dependensi eksternal).
class ListEquality {
  const ListEquality();

  bool equals(List<Object?> a, List<Object?> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
