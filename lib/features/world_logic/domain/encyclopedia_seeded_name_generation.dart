// Sprint 111.31 - Seeded Name Generation (domain-only).
//
// Menghasilkan nama dari [CulturalNameProfile] (111.30) + [PhonotacticsSpec]
// (111.29) secara deterministik dari seed EKSPISIT, dan tidak pernah
// menulis kanon tanpa penerimaan eksplisit pengguna.
//
// Enam acceptance canonical sprint_111.json dipetakan:
// - explicit_seed        -> SeededNameRequest.seed wajib (tanpa default),
//                           seed <= 0 ditolak (seedBlank)
// - batch_generation     -> SeededNameGenerator.generateBatch(count) dengan
//                           guard 1..maxBatchSize dan dedup intra-batch
// - reproducible_output  -> PRNG SplitMix64 lokal (bukan dart:math Random,
//                           bukan wall-clock): seed+input identik => output
//                           byte-identik lintas instance dan lintas waktu
// - regenerate           -> SeededNameBatch.regenerate() + nextSeed chain
//                           deterministik dari seed asal
// - accept_or_discard    -> GeneratedNameProposal + NameProposalStatus +
//                           batch.accept/discard immutable
// - no_auto_canon        -> generate tidak memutasi profil/spec/katalog
//                           input; accept hanya menandai SALINAN proposal —
//                           tidak ada jalur tulis persistence dari modul ini
//
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau dart:math Random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.

library;

import 'dart:convert';

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';

const int _mask64 = 0xFFFFFFFFFFFFFFFF;
const int _golden64 = 0x9E3779B97F4A7C15;

int _mix64(int z) {
  z = (z ^ (z >> 30)) & _mask64;
  z = (z * 0xBF58476D1CE4E5B9) & _mask64;
  z = (z ^ (z >> 27)) & _mask64;
  z = (z * 0x94D049BB133111EB) & _mask64;
  return (z ^ (z >> 31)) & _mask64;
}

/// PRNG 64-bit deterministik lokal (SplitMix64). Identik dengan polanya di
/// performance_scale_benchmark, tetapi dimiliki modul ini agar generator
/// nama tidak bergantung pada modul benchmark.
class _SplitMix64 {
  _SplitMix64(int seed) : _state = _mix64(seed);

  int _state;

  int nextInt() {
    _state = (_state + _golden64) & _mask64;
    return _mix64(_state);
  }

  int nextInRange(int bound) {
    assert(bound > 0);
    return nextInt().abs() % bound;
  }
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return trimmed;
}

/// Hash 64-bit FNV-1a atas UTF-8 — deterministik lintas proses (hashCode
/// Dart tidak stabil antar-run, jadi id proposal tidak boleh memakainya).
int _fnv1a64(String input) {
  var hash = 0xCBF29CE484222325;
  for (final unit in utf8.encode(input)) {
    hash = ((hash ^ unit) * 0x100000001B3) & _mask64;
  }
  return hash;
}

/// Status keputusan pengguna atas satu proposal nama.
enum NameProposalStatus {
  /// Masih menunggu keputusan pengguna — TIDAK ada efek kanon.
  proposed,

  /// Diterima eksplisit oleh pengguna. Penerimaan hanya menandai salinan
  /// batch ini; menulis ke kanon/persistence adalah langkah terpisah yang
  /// bukan tanggung jawab modul ini (no_auto_canon).
  accepted,

  /// Dibuang eksplisit oleh pengguna.
  discarded,
}

String _statusLabel(NameProposalStatus status) => switch (status) {
  NameProposalStatus.proposed => 'Diusulkan',
  NameProposalStatus.accepted => 'Diterima',
  NameProposalStatus.discarded => 'Dibuang',
};

/// Satu proposal nama hasil generator, immutable.
class GeneratedNameProposal {
  const GeneratedNameProposal._({
    required this.proposalId,
    required this.index,
    required this.text,
    required this.syllables,
    required this.patternIds,
    required this.status,
    required this.seed,
  });

  /// Membuat proposal tervalidasi: [proposalId] dan [text] non-kosong,
  /// [index] dan [seed] >= 0, koleksi dinormalisasi immutable.
  factory GeneratedNameProposal.validated({
    required String proposalId,
    required int index,
    required String text,
    required List<String> syllables,
    List<String> patternIds = const <String>[],
    NameProposalStatus status = NameProposalStatus.proposed,
    int seed = 0,
  }) {
    if (index < 0) {
      throw ArgumentError.value(index, 'index', 'index must be >= 0');
    }
    if (seed < 0) {
      throw ArgumentError.value(seed, 'seed', 'seed must be >= 0');
    }
    return GeneratedNameProposal._(
      proposalId: _requireTrimmed(proposalId, 'proposalId'),
      index: index,
      text: _requireTrimmed(text, 'text'),
      syllables: List.unmodifiable(syllables),
      patternIds: List.unmodifiable(patternIds),
      status: status,
      seed: seed,
    );
  }

  /// Id stabil dari (seed, index, text) — bukan hashCode Dart.
  final String proposalId;

  /// Posisi proposal dalam batch asalnya.
  final int index;

  /// Nama lengkap siap pakai (inti + afiks + gelar bila diminta).
  final String text;

  /// Suku kata pembentuk nama inti, urutan terjaga.
  final List<String> syllables;

  /// Id pola fonotaktik yang dipakai tiap suku kata (kosong bila tanpa spec).
  final List<String> patternIds;

  final NameProposalStatus status;

  /// Seed batch asal proposal ini.
  final int seed;

  String get statusLabel => _statusLabel(status);

  /// Salinan dengan status berbeda; asal tidak berubah.
  GeneratedNameProposal withStatus(NameProposalStatus newStatus) =>
      GeneratedNameProposal._(
        proposalId: proposalId,
        index: index,
        text: text,
        syllables: syllables,
        patternIds: patternIds,
        status: newStatus,
        seed: seed,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'proposalId': proposalId,
    'index': index,
    'text': text,
    'syllables': <Object?>[...syllables],
    'patternIds': <Object?>[...patternIds],
    'status': status.name,
    'seed': seed,
  };

  static GeneratedNameProposal fromJson(Map<String, Object?> json) =>
      GeneratedNameProposal.validated(
        proposalId: json['proposalId']! as String,
        index: json['index']! as int,
        text: json['text']! as String,
        syllables: (json['syllables']! as List<Object?>).cast<String>(),
        patternIds:
            ((json['patternIds'] as List<Object?>?) ?? const <Object?>[])
                .cast<String>(),
        status: NameProposalStatus.values.firstWhere(
          (s) => s.name == json['status'],
        ),
        seed: (json['seed'] as int?) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedNameProposal &&
          other.proposalId == proposalId &&
          other.index == index &&
          other.text == text &&
          other.status == status &&
          other.seed == seed &&
          _sameStrings(other.syllables, syllables) &&
          _sameStrings(other.patternIds, patternIds);

  @override
  int get hashCode => Object.hash(
    proposalId,
    index,
    text,
    status,
    seed,
    Object.hashAll(syllables),
    Object.hashAll(patternIds),
  );
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Permintaan generasi: profil budaya + (opsional) spec fonotaktik bahasa
/// yang sama, tipe entitas, konteks sosial, jumlah suku kata, pilihan gelar
/// dan afiks, serta seed EKSPISIT.
class SeededNameRequest {
  const SeededNameRequest._({
    required this.profile,
    required this.spec,
    required this.entityType,
    required this.context,
    required this.syllableCount,
    required this.addTitle,
    required this.addAffixes,
    required this.seed,
  });

  /// Membangun permintaan tervalidasi. [seed] wajib ada tanpa default dan
  /// harus > 0 (seed 0/blank ditolak — explicit_seed). [entityType] wajib
  /// masuk whitelist [profile]. Bila [spec] diberikan, languageId-nya wajib
  /// sama dengan bahasa profil. [syllableCount] dibatasi 1..8.
  factory SeededNameRequest.validated({
    required CulturalNameProfile profile,
    PhonotacticsSpec? spec,
    required NameEntityType entityType,
    SocialContext? context,
    int syllableCount = 2,
    bool addTitle = false,
    bool addAffixes = true,
    required int seed,
  }) {
    if (seed <= 0) {
      throw ArgumentError.value(
        seed,
        'seed',
        'seedBlank: seed must be an explicit positive integer',
      );
    }
    if (syllableCount < 1 || syllableCount > 8) {
      throw ArgumentError.value(
        syllableCount,
        'syllableCount',
        'syllableCount must be within 1..8',
      );
    }
    if (!profile.supportsEntityType(entityType)) {
      throw ArgumentError.value(
        entityType.name,
        'entityType',
        'entity type $entityType is outside the profile whitelist',
      );
    }
    if (spec != null && spec.languageId != profile.languageId) {
      throw ArgumentError.value(
        spec.languageId,
        'spec',
        'spec language "${spec.languageId}" does not match profile '
            'language "${profile.languageId}"',
      );
    }
    return SeededNameRequest._(
      profile: profile,
      spec: spec,
      entityType: entityType,
      context: context ?? profile.defaultContext,
      syllableCount: syllableCount,
      addTitle: addTitle,
      addAffixes: addAffixes,
      seed: seed,
    );
  }

  final CulturalNameProfile profile;

  /// Spec fonotaktik bahasa; null berarti generasi bebas-pola (nama inti
  /// dibentuk dari suku kata nucleus/onset default pool jika ada, atau
  /// tetap sah secara struktur namun tanpa validasi larangan).
  final PhonotacticsSpec? spec;

  final NameEntityType entityType;

  /// Konteks sosial ter-resolve (default profil bila pemanggil memberi null).
  final SocialContext context;

  final int syllableCount;
  final bool addTitle;
  final bool addAffixes;

  /// Seed eksplisit batch.
  final int seed;

  /// Salinan dengan field berbeda; asal tidak berubah.
  SeededNameRequest copyWith({int? seed, int? syllableCount, bool? addTitle}) {
    return SeededNameRequest.validated(
      profile: profile,
      spec: spec,
      entityType: entityType,
      context: context,
      syllableCount: syllableCount ?? this.syllableCount,
      addTitle: addTitle ?? this.addTitle,
      addAffixes: addAffixes,
      seed: seed ?? this.seed,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'profile': profile.toJson(),
    'spec': spec?.toJson(),
    'entityType': entityType.name,
    'context': context.name,
    'syllableCount': syllableCount,
    'addTitle': addTitle,
    'addAffixes': addAffixes,
    'seed': seed,
  };

  static SeededNameRequest fromJson(Map<String, Object?> json) {
    final specJson = json['spec'] as Map<Object?, Object?>?;
    return SeededNameRequest.validated(
      profile: CulturalNameProfile.fromJson(
        (json['profile']! as Map<Object?, Object?>).cast<String, Object?>(),
      ),
      spec: specJson == null
          ? null
          : PhonotacticsSpec.fromJson(specJson.cast<String, Object?>()),
      entityType: NameEntityType.values.firstWhere(
        (t) => t.name == json['entityType'],
      ),
      context: SocialContext.values.firstWhere(
        (c) => c.name == json['context'],
      ),
      syllableCount: json['syllableCount']! as int,
      addTitle: json['addTitle'] as bool? ?? false,
      addAffixes: json['addAffixes'] as bool? ?? true,
      seed: json['seed']! as int,
    );
  }
}

/// Hasil satu batch generasi: daftar proposal immutable + keputusan
/// accept/discard di level batch.
class SeededNameBatch {
  const SeededNameBatch._({
    required this.request,
    required this.seed,
    required this.proposals,
  });

  /// Membangun batch tervalidasi: [proposals] non-kosong dengan index
  /// 0..n-1 berurutan dan proposalId unik; [seed] harus > 0.
  factory SeededNameBatch.validated({
    required SeededNameRequest request,
    required int seed,
    required List<GeneratedNameProposal> proposals,
  }) {
    if (proposals.isEmpty) {
      throw ArgumentError.value(
        proposals,
        'proposals',
        'batch cannot be empty',
      );
    }
    final seenIds = <String>{};
    for (var i = 0; i < proposals.length; i++) {
      final p = proposals[i];
      if (p.index != i) {
        throw ArgumentError.value(
          p.index,
          'proposals',
          'proposal index ${p.index} out of order at position $i',
        );
      }
      if (!seenIds.add(p.proposalId)) {
        throw ArgumentError.value(
          p.proposalId,
          'proposals',
          'duplicate proposal id: ${p.proposalId}',
        );
      }
    }
    return SeededNameBatch._(
      request: request,
      seed: seed,
      proposals: List.unmodifiable(proposals),
    );
  }

  final SeededNameRequest request;

  /// Seed batch ini (mungkin seed turunan dari regenerate).
  final int seed;

  /// Proposal dalam urutan index.
  final List<GeneratedNameProposal> proposals;

  int get count => proposals.length;

  /// Teks seluruh proposal, urutan batch.
  List<String> get texts => List.unmodifiable(proposals.map((p) => p.text));

  int get acceptedCount =>
      proposals.where((p) => p.status == NameProposalStatus.accepted).length;

  int get discardedCount =>
      proposals.where((p) => p.status == NameProposalStatus.discarded).length;

  int get proposedCount =>
      proposals.where((p) => p.status == NameProposalStatus.proposed).length;

  SeededNameBatch _replace(String proposalId, NameProposalStatus status) {
    final idx = proposals.indexWhere((p) => p.proposalId == proposalId);
    if (idx < 0) {
      throw StateError('unknown proposal id: $proposalId');
    }
    final target = proposals[idx];
    if (target.status != NameProposalStatus.proposed) {
      throw StateError(
        'proposal $proposalId already decided (${target.status.name})',
      );
    }
    return SeededNameBatch._(
      request: request,
      seed: seed,
      proposals: List.unmodifiable(<GeneratedNameProposal>[
        for (var i = 0; i < proposals.length; i++)
          if (i == idx) target.withStatus(status) else proposals[i],
      ]),
    );
  }

  /// Terima satu proposal secara eksplisit (accept_or_discard). Menghasilkan
  /// batch baru; batch asal tidak berubah. TIDAK menulis kanon (no_auto_canon).
  SeededNameBatch accept(String proposalId) =>
      _replace(proposalId, NameProposalStatus.accepted);

  /// Buang satu proposal secara eksplisit. Immutable seperti [accept].
  SeededNameBatch discard(String proposalId) =>
      _replace(proposalId, NameProposalStatus.discarded);

  /// Batch baru dengan seed turunan deterministik — regenerate seluruh
  /// proposal tanpa mengubah permintaan.
  SeededNameBatch regenerate() => SeededNameGenerator.generateBatch(
    request: request.copyWith(seed: SeededNameGenerator.nextSeed(seed)),
    count: count,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'request': request.toJson(),
    'seed': seed,
    'proposals': <Object?>[for (final p in proposals) p.toJson()],
  };

  static SeededNameBatch fromJson(Map<String, Object?> json) =>
      SeededNameBatch.validated(
        request: SeededNameRequest.fromJson(
          (json['request']! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
        seed: json['seed']! as int,
        proposals: <GeneratedNameProposal>[
          for (final raw in (json['proposals']! as List<Object?>))
            GeneratedNameProposal.validated(
              proposalId: _proposalField(raw, 'proposalId')! as String,
              index: _proposalField(raw, 'index')! as int,
              text: _proposalField(raw, 'text')! as String,
              syllables: (_proposalField(raw, 'syllables')! as List<Object?>)
                  .cast<String>(),
              patternIds:
                  ((_proposalField(raw, 'patternIds') as List<Object?>?) ??
                          const <Object?>[])
                      .cast<String>(),
              status: NameProposalStatus.values.firstWhere(
                (s) => s.name == _proposalField(raw, 'status'),
              ),
              seed: (_proposalField(raw, 'seed') as int?) ?? 0,
            ),
        ],
      );
}

Object? _proposalField(Object? raw, String key) =>
    (raw! as Map<Object?, Object?>)[key];

/// Generator nama seeded deterministik. Murni statis — tidak ada state
/// global, tidak ada tulis apa pun.
class SeededNameGenerator {
  /// Batas praktis satu batch (guard sumber daya, bukan semantics).
  static const int maxBatchSize = 256;

  static const int _maxLegalRetries = 64;
  static const int _maxDuplicateRetries = 200;

  static Never _fail(String reason) =>
      throw StateError('name generation exhausted: $reason');

  /// Seed turunan deterministik untuk regenerate (SplitMix atas seed saat
  /// ini); hasil selalu > 0 sehingga sah sebagai explicit seed.
  static int nextSeed(int seed) {
    var s = _mix64(seed & _mask64);
    if (s <= 0) s = _mix64(s ^ _golden64);
    return s;
  }

  static GeneratedNameProposal generateOne({
    required SeededNameRequest request,
  }) {
    return generateBatch(request: request, count: 1).proposals.single;
  }

  /// Bangkitkan [count] proposal deterministik dari [request].
  static SeededNameBatch generateBatch({
    required SeededNameRequest request,
    required int count,
  }) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'count must be >= 1');
    }
    if (count > maxBatchSize) {
      throw ArgumentError.value(
        count,
        'count',
        'count exceeds maxBatchSize ($maxBatchSize)',
      );
    }
    final seed = request.seed;
    final patterns = _effectivePatterns(request.spec);
    final seenTexts = <String>{};
    final proposals = <GeneratedNameProposal>[];
    for (var index = 0; index < count; index++) {
      final rng = _SplitMix64(_mix64(seed ^ _mix64(index * _golden64)));
      var attempts = 0;
      GeneratedNameProposal? proposal;
      while (true) {
        final core = _generateCore(request, rng, patterns);
        final text = _decorate(request, core, rng);
        if (seenTexts.add(text)) {
          proposal = GeneratedNameProposal.validated(
            proposalId: _proposalId(seed, index, text),
            index: index,
            text: text,
            syllables: core.$1,
            patternIds: core.$2,
            seed: seed,
          );
          break;
        }
        attempts++;
        if (attempts > _maxDuplicateRetries) {
          _fail('duplicate space exhausted for seed $seed index $index');
        }
      }
      proposals.add(proposal);
    }
    return SeededNameBatch.validated(
      request: request,
      seed: seed,
      proposals: proposals,
    );
  }

  static String _proposalId(int seed, int index, String text) =>
      'np-${_fnv1a64('$seed|$index|$text').toRadixString(16)}';

  /// Pola efektif; untuk request tanpa spec, sintetisasi pola 'CV' murni
  /// (deterministik, tanpa dependensi id spec).
  static List<SyllablePattern> _effectivePatterns(PhonotacticsSpec? spec) {
    if (spec != null) return spec.patterns;
    return <SyllablePattern>[
      SyllablePattern.parse(id: 'default-cv', template: 'CV'),
    ];
  }

  static (List<String>, List<String>) _generateCore(
    SeededNameRequest request,
    _SplitMix64 rng,
    List<SyllablePattern> patterns,
  ) {
    final weights = patterns.map((p) => p.weight < 0 ? 0 : p.weight).toList();
    final totalWeight = weights.fold<int>(0, (a, b) => a + b);
    for (var attempt = 0; attempt <= _maxLegalRetries; attempt++) {
      final syllables = <String>[];
      final usedPatterns = <String>[];
      for (var s = 0; s < request.syllableCount; s++) {
        final pattern = _pickPattern(patterns, weights, totalWeight, rng);
        final slots = <String>[];
        final slotLog = <SyllableSlot>[];
        for (final position in pattern.positions) {
          final candidates = _candidatesFor(request.spec, position.slot);
          if (candidates.isEmpty) {
            _fail('slot ${position.slot.name} has no inventory member');
          }
          final include = !position.optional || rng.nextInRange(3) != 0;
          if (!include) continue;
          slots.add(candidates[rng.nextInRange(candidates.length)]);
          slotLog.add(position.slot);
        }
        if (slots.isEmpty) {
          _fail('pattern ${pattern.id} produced an empty syllable');
        }
        syllables.add(slots.join());
        usedPatterns.add(pattern.id);
        if (request.spec != null &&
            !request.spec!.isWordLegal(
              syllables.expand((x) => x.split('')).toList(),
            )) {
          break;
        }
        if (s == request.syllableCount - 1) {
          return (syllables, usedPatterns);
        }
      }
      // Retry legalitas: kata menegah melanggar larangan — tarik ulang utuh.
      continue;
    }
    _fail('legality retries exhausted for seed ${request.seed}');
  }

  static SyllablePattern _pickPattern(
    List<SyllablePattern> patterns,
    List<int> weights,
    int totalWeight,
    _SplitMix64 rng,
  ) {
    if (totalWeight <= 0) {
      return patterns[rng.nextInRange(patterns.length)];
    }
    var pick = rng.nextInRange(totalWeight);
    for (var i = 0; i < patterns.length; i++) {
      pick -= weights[i];
      if (pick < 0) return patterns[i];
    }
    return patterns.last;
  }

  static List<String> _candidatesFor(
    PhonotacticsSpec? spec,
    SyllableSlot slot,
  ) {
    final source = spec?.inventory;
    if (source == null) {
      return switch (slot) {
        SyllableSlot.onset => const <String>['k', 'l', 'm', 'n', 'r', 's', 't'],
        SyllableSlot.nucleus => const <String>['a', 'e', 'i'],
        SyllableSlot.coda => const <String>['k', 'l', 'n', 'r', 's'],
      };
    }
    return <String>[
      for (final part in source)
        if (part.canOccurIn(slot)) part.symbol,
    ];
  }

  static String _capitalizeFirst(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _decorate(
    SeededNameRequest request,
    (List<String>, List<String>) core,
    _SplitMix64 rng,
  ) {
    // Core generation already uppercased; join lowercase syllable list.
    var text = _capitalizeFirst(core.$1.join());
    if (request.addAffixes) {
      final applicable = request.profile
          .affixesApplyingTo(request.entityType, request.context)
          .where((r) => !r.optional || rng.nextInRange(2) == 0)
          .toList();
      final lower = text.toLowerCase();
      var core = lower;
      for (final rule in applicable.where(
        (r) => r.kind == NameAffixKind.prefix,
      )) {
        core = rule.attachTo(core);
      }
      for (final rule in applicable.where(
        (r) => r.kind == NameAffixKind.suffix,
      )) {
        core = rule.attachTo(core);
      }
      text = _capitalizeFirst(core);
    }
    if (request.addTitle) {
      final applying = request.profile.titlesApplyingTo(
        request.entityType,
        request.context,
      );
      if (applying.isNotEmpty) {
        final title = applying[rng.nextInRange(applying.length)];
        text = title.applyTo(text);
      }
    }
    return text;
  }
}
