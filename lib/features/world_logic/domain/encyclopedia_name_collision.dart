// Sprint 111.32 - Name Collision & Cultural Consistency (domain-only).
//
// Mendeteksi kandidat nama yang duplikat, terlalu mirip, melanggar kaidah
// bunyi, atau tidak sesuai budaya — terhadap registri nama kanon dan profil
// budaya 111.30/111.29, serta menerima penerimaan manual eksplisit pengguna.
//
// Enam acceptance canonical sprint_111.json dipetakan:
// - exact_collision    -> NameCheckKind.exactCollision; teks ternormalisasi
//                         identik dengan record kanon / kandidat sebelumnya
// - similarity_warning -> NameCheckKind.similarityWarning; kesamaan
//                         Levenshtein ternormalisasi >= threshold (deterministik)
// - phonotactic_check  -> NameCheckKind.phonotacticViolation; simbol di luar
//                         inventory + ForbiddenSequence via violationsIn (111.29)
// - culture_check      -> NameCheckKind.cultureMismatch; cultureId/languageId
//                         vs CulturalNameProfile aktif + whitelist entityType,
//                         dan silang-budaya saat menabrak record beda budaya
// - reserved_names     -> NameCheckKind.reservedName; teks ternormalisasi
//                         masuk daftar cadangan CanonicalNameRegistry
// - manual_accept      -> NameManualAcceptance menekan pasangan
//                         (candidateId, kind) — pola ArtifactManualException 111.23
//
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau dart:math Random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.

library;

import 'dart:convert';

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';

const int _mask64 = 0xFFFFFFFFFFFFFFFF;

/// Hash 64-bit FNV-1a atas UTF-8 — deterministik lintas proses (pola 111.31).
int _fnv1a64(String input) {
  var hash = 0xCBF29CE484222325;
  for (final unit in utf8.encode(input)) {
    hash = ((hash ^ unit) * 0x100000001B3) & _mask64;
  }
  return hash;
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return trimmed;
}

/// Normalisasi perbandingan nama: trim, lowercase, whitespace dikolaps.
String _normalizedName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Jarak Levenshtein dua deret rune — deterministik, tanpa dependensi luar.
int _levenshtein(List<String> a, List<String> b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var best = previous[j] + 1;
      if (current[j - 1] + 1 < best) best = current[j - 1] + 1;
      if (previous[j - 1] + cost < best) best = previous[j - 1] + cost;
      current[j] = best;
    }
    previous = current;
  }
  return previous[b.length];
}

/// Kesamaan ternormalisasi 0..1: 1 - distance / max(len); dua string kosong
/// dinilai identik (1.0).
double _similarity(String a, String b) {
  if (a == b) return 1;
  final ra = a.runes.map(String.fromCharCode).toList();
  final rb = b.runes.map(String.fromCharCode).toList();
  final longest = ra.length > rb.length ? ra.length : rb.length;
  if (longest == 0) return 1;
  return 1 - _levenshtein(ra, rb) / longest;
}

/// Jenis masalah konsistensi nama yang dapat dilaporkan validator.
enum NameCheckKind {
  /// Nama sama persil (ternormalisasi) dengan nama kanon/kandidat lain.
  exactCollision('Exact collision'),

  /// Nama terlalu mirip dengan nama kanon — peringatan, bukan blokir.
  similarityWarning('Similarity warning'),

  /// Nama memakai simbol di luar inventory atau rangkaian terlarang.
  phonotacticViolation('Phonotactic violation'),

  /// Budaya/bahasa/tipe entitas tidak cocok dengan profil aktif atau kanon.
  cultureMismatch('Cultural mismatch'),

  /// Nama dicadangkan dan tidak boleh dipakai kandidat biasa.
  reservedName('Reserved name');

  const NameCheckKind(this.label);

  final String label;

  /// Hanya [similarityWarning] yang tidak memblokir penerimaan nama.
  bool get isBlocking => this != NameCheckKind.similarityWarning;
}

/// Satu kandidat nama yang akan diperiksa. Immutable.
class NameCandidate {
  const NameCandidate._({
    required this.candidateId,
    required this.text,
    required this.normalizedText,
    required this.cultureId,
    required this.languageId,
    required this.entityType,
  });

  /// Membangun kandidat tervalidasi: [candidateId]/[text]/[cultureId]/
  /// [languageId] non-kosong; [normalizedText] diturunkan dari [text].
  factory NameCandidate.validated({
    required String candidateId,
    required String text,
    required String cultureId,
    required String languageId,
    required NameEntityType entityType,
  }) {
    return NameCandidate._(
      candidateId: _requireTrimmed(candidateId, 'candidateId'),
      text: _requireTrimmed(text, 'text'),
      normalizedText: _normalizedName(text),
      cultureId: _requireTrimmed(cultureId, 'cultureId'),
      languageId: _requireTrimmed(languageId, 'languageId'),
      entityType: entityType,
    );
  }

  /// Kandidat dari proposal 111.31 — budaya/bahasa/tipe diambil dari
  /// permintaan asal (sumber kebenaran profil, bukan teks).
  factory NameCandidate.fromProposal(
    GeneratedNameProposal proposal,
    SeededNameRequest request,
  ) {
    return NameCandidate.validated(
      candidateId: proposal.proposalId,
      text: proposal.text,
      cultureId: request.profile.cultureId,
      languageId: request.profile.languageId,
      entityType: request.entityType,
    );
  }

  final String candidateId;
  final String text;

  /// Bentuk banding: trim, lowercase, whitespace dikolaps.
  final String normalizedText;

  final String cultureId;
  final String languageId;
  final NameEntityType entityType;

  Map<String, Object?> toJson() => <String, Object?>{
    'candidateId': candidateId,
    'text': text,
    'cultureId': cultureId,
    'languageId': languageId,
    'entityType': entityType.name,
  };

  static NameCandidate fromJson(Map<String, Object?> json) =>
      NameCandidate.validated(
        candidateId: json['candidateId']! as String,
        text: json['text']! as String,
        cultureId: json['cultureId']! as String,
        languageId: json['languageId']! as String,
        entityType: NameEntityType.values.firstWhere(
          (t) => t.name == json['entityType'],
        ),
      );
}

/// Satu nama yang sudah tercatat sebagai kanon. Immutable.
class CanonicalNameRecord {
  const CanonicalNameRecord._({
    required this.recordId,
    required this.text,
    required this.normalizedText,
    required this.cultureId,
    required this.languageId,
    required this.entityType,
  });

  /// Membangun record tervalidasi — field wajib non-kosong setelah dipangkas.
  factory CanonicalNameRecord.validated({
    required String recordId,
    required String text,
    required String cultureId,
    required String languageId,
    required NameEntityType entityType,
  }) {
    return CanonicalNameRecord._(
      recordId: _requireTrimmed(recordId, 'recordId'),
      text: _requireTrimmed(text, 'text'),
      normalizedText: _normalizedName(text),
      cultureId: _requireTrimmed(cultureId, 'cultureId'),
      languageId: _requireTrimmed(languageId, 'languageId'),
      entityType: entityType,
    );
  }

  final String recordId;
  final String text;
  final String normalizedText;
  final String cultureId;
  final String languageId;
  final NameEntityType entityType;

  Map<String, Object?> toJson() => <String, Object?>{
    'recordId': recordId,
    'text': text,
    'cultureId': cultureId,
    'languageId': languageId,
    'entityType': entityType.name,
  };

  static CanonicalNameRecord fromJson(Map<String, Object?> json) =>
      CanonicalNameRecord.validated(
        recordId: json['recordId']! as String,
        text: json['text']! as String,
        cultureId: json['cultureId']! as String,
        languageId: json['languageId']! as String,
        entityType: NameEntityType.values.firstWhere(
          (t) => t.name == json['entityType'],
        ),
      );
}

/// Registri nama kanon + daftar nama cadangan untuk satu ruang kerja.
class CanonicalNameRegistry {
  const CanonicalNameRegistry._({
    required this._records,
    required this._reservedNames,
  });

  /// Membangun registri tervalidasi: [recordId] unik; [reservedNames]
  /// dinormalisasi saat masuk dan tidak boleh kosong setelah normalisasi.
  factory CanonicalNameRegistry.validated({
    required List<CanonicalNameRecord> records,
    Set<String> reservedNames = const <String>{},
  }) {
    final seen = <String>{};
    for (final r in records) {
      if (!seen.add(r.recordId)) {
        throw ArgumentError('duplicate record id: ${r.recordId}');
      }
    }
    final normalizedReserved = <String>{};
    for (final raw in reservedNames) {
      final n = _normalizedName(raw);
      if (n.isEmpty) {
        throw ArgumentError('reserved name cannot be empty');
      }
      normalizedReserved.add(n);
    }
    final sorted = List<CanonicalNameRecord>.of(records)
      ..sort((a, b) => a.recordId.compareTo(b.recordId));
    return CanonicalNameRegistry._(
      records: List.unmodifiable(sorted),
      reservedNames: Set.unmodifiable(normalizedReserved),
    );
  }

  final List<CanonicalNameRecord> _records;
  final Set<String> _reservedNames;

  /// Record terurut recordId, immutable.
  List<CanonicalNameRecord> get records => _records;

  /// Daftar cadangan dalam bentuk ternormalisasi.
  Set<String> get reservedNames => _reservedNames;

  bool isReserved(String normalizedText) =>
      _reservedNames.contains(normalizedText);

  int get recordCount => _records.length;

  Map<String, Object?> toJson() => <String, Object?>{
    'records': <Object?>[for (final r in _records) r.toJson()],
    'reservedNames': <Object?>[..._reservedNames]..sort(),
  };

  static CanonicalNameRegistry fromJson(Map<String, Object?> json) =>
      CanonicalNameRegistry.validated(
        records: <CanonicalNameRecord>[
          for (final raw in (json['records']! as List<Object?>))
            CanonicalNameRecord.fromJson(
              (raw! as Map<Object?, Object?>).cast<String, Object?>(),
            ),
        ],
        reservedNames: (json['reservedNames']! as List<Object?>)
            .cast<String>()
            .toSet(),
      );
}

/// Penerimaan manual eksplisit atas satu jenis masalah untuk satu kandidat —
/// pola konsisten dengan ArtifactManualException (111.23): pasangan
/// (candidateId, kind) yang cocok menekan issue-nya.
class NameManualAcceptance {
  const NameManualAcceptance._({
    required this.acceptanceId,
    required this.candidateId,
    required this.kind,
    required this.reason,
  });

  /// Membangun penerimaan tervalidasi: ketiga teks wajib non-kosong.
  factory NameManualAcceptance.validated({
    required String acceptanceId,
    required String candidateId,
    required NameCheckKind kind,
    required String reason,
  }) {
    return NameManualAcceptance._(
      acceptanceId: _requireTrimmed(acceptanceId, 'acceptanceId'),
      candidateId: _requireTrimmed(candidateId, 'candidateId'),
      kind: kind,
      reason: _requireTrimmed(reason, 'reason'),
    );
  }

  final String acceptanceId;
  final String candidateId;
  final NameCheckKind kind;
  final String reason;

  /// Hanya tepat pasangan (candidateId, kind) — tanpa pencocokan longgar.
  bool matches(String candidateId, NameCheckKind kind) =>
      this.candidateId == candidateId && this.kind == kind;

  Map<String, Object?> toJson() => <String, Object?>{
    'acceptanceId': acceptanceId,
    'candidateId': candidateId,
    'kind': kind.name,
    'reason': reason,
  };

  static NameManualAcceptance fromJson(Map<String, Object?> json) =>
      NameManualAcceptance.validated(
        acceptanceId: json['acceptanceId']! as String,
        candidateId: json['candidateId']! as String,
        kind: NameCheckKind.values.firstWhere((k) => k.name == json['kind']),
        reason: json['reason']! as String,
      );
}

/// Satu masalah konsistensi pada satu kandidat. Immutable.
class NameCheckIssue {
  const NameCheckIssue._({
    required this.issueId,
    required this.candidateId,
    required this.kind,
    required this.message,
    this.relatedId,
  });

  /// Membangun issue tervalidasi dengan id stabil dari
  /// (candidateId, kind, relatedId, message) — bukan hashCode Dart.
  factory NameCheckIssue.validated({
    required String candidateId,
    required NameCheckKind kind,
    required String message,
    String? relatedId,
  }) {
    final trimmedMessage = _requireTrimmed(message, 'message');
    final trimmedRelated = relatedId?.trim();
    final effectiveRelated = (trimmedRelated == null || trimmedRelated.isEmpty)
        ? null
        : trimmedRelated;
    final issueId =
        'nc-${_fnv1a64('$candidateId|${kind.name}|'
        '${effectiveRelated ?? '-'}|$trimmedMessage').toRadixString(16)}';
    return NameCheckIssue._(
      issueId: issueId,
      candidateId: _requireTrimmed(candidateId, 'candidateId'),
      kind: kind,
      message: trimmedMessage,
      relatedId: effectiveRelated,
    );
  }

  final String issueId;
  final String candidateId;
  final NameCheckKind kind;
  final String message;

  /// Id pihak yang ditabrak (record kanon / kandidat lain / profil / spec).
  final String? relatedId;

  /// Klasifikasi turunan dari [kind].
  bool get blocking => kind.isBlocking;

  Map<String, Object?> toJson() => <String, Object?>{
    'issueId': issueId,
    'candidateId': candidateId,
    'kind': kind.name,
    'message': message,
    'relatedId': relatedId,
    'blocking': blocking,
  };

  static NameCheckIssue fromJson(Map<String, Object?> json) {
    final issue = NameCheckIssue.validated(
      candidateId: json['candidateId']! as String,
      kind: NameCheckKind.values.firstWhere((k) => k.name == json['kind']),
      message: json['message']! as String,
      relatedId: json['relatedId'] as String?,
    );
    if (json['issueId'] != null && json['issueId'] != issue.issueId) {
      throw ArgumentError(
        'issueId mismatch: stored ${json['issueId']} vs derived '
        '${issue.issueId}',
      );
    }
    return issue;
  }
}

/// Laporan immutable hasil validasi satu batch kandidat.
class NameCheckReport {
  const NameCheckReport._(this._issues);

  /// Membangun laporan dari [issues]: issueId harus unik; disimpan terurut
  /// issueId agar deterministik.
  factory NameCheckReport.of(List<NameCheckIssue> issues) {
    final seen = <String>{};
    for (final i in issues) {
      if (!seen.add(i.issueId)) {
        throw ArgumentError('duplicate issueId: ${i.issueId}');
      }
    }
    final sorted = List<NameCheckIssue>.of(issues)
      ..sort((a, b) => a.issueId.compareTo(b.issueId));
    return NameCheckReport._(List.unmodifiable(sorted));
  }

  final List<NameCheckIssue> _issues;

  List<NameCheckIssue> get issues => _issues;

  bool get hasIssues => _issues.isNotEmpty;

  int get issueCount => _issues.length;

  bool get hasBlockingIssues => _issues.any((i) => i.blocking);

  List<NameCheckIssue> issuesOf(NameCheckKind kind) =>
      List.unmodifiable(_issues.where((i) => i.kind == kind));

  /// Penjelasan manusia-terbaca atas seluruh issue aktif.
  String describe() {
    if (_issues.isEmpty) return 'No name issues.';
    final buffer = StringBuffer('Name consistency issues:');
    for (final i in _issues) {
      buffer.write(' [${i.kind.label}] ${i.message}');
    }
    return buffer.toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'issues': <Object?>[for (final i in _issues) i.toJson()],
    'hasBlockingIssues': hasBlockingIssues,
  };

  static NameCheckReport fromJson(Map<String, Object?> json) =>
      NameCheckReport.of(<NameCheckIssue>[
        for (final raw in (json['issues']! as List<Object?>))
          NameCheckIssue.fromJson(
            (raw! as Map<Object?, Object?>).cast<String, Object?>(),
          ),
      ]);
}

/// Validator deterministik konsistensi nama. Murni statis — tidak ada state
/// global dan tidak ada jalur tulis persistence (manual_accept hanya menekan
/// issue pada SALINAN laporan; kanon tidak pernah ditulis dari modul ini).
class NameConsistencyValidator {
  const NameConsistencyValidator();

  /// Ambang default peringatan kemiripan (1 - jarak/maxPanjang).
  static const double defaultSimilarityThreshold = 0.75;

  /// Periksa [candidates] terhadap [registry] dan (opsional) profil aktif
  /// [profile] + spec fonotaktik [spec].
  ///
  /// - [similarityThreshold] wajib di rentang (0, 1].
  /// - [acceptances] menekan pasangan (candidateId, kind) yang cocok
  ///   (manual_accept); acceptanceId harus unik.
  /// - [profile] null berarti culture-check kandidat-vs-profil dilewati.
  /// - [spec] null berarti phonotactic-check dilewati — validator TIDAK
  ///   boleh mengklaim legalitas tanpa bukti kaidah.
  NameCheckReport validate({
    required List<NameCandidate> candidates,
    required CanonicalNameRegistry registry,
    CulturalNameProfile? profile,
    PhonotacticsSpec? spec,
    double similarityThreshold = defaultSimilarityThreshold,
    List<NameManualAcceptance> acceptances = const <NameManualAcceptance>[],
  }) {
    if (candidates.isEmpty) {
      throw ArgumentError.value(candidates, 'candidates', 'cannot be empty');
    }
    if (similarityThreshold <= 0 || similarityThreshold > 1) {
      throw ArgumentError.value(
        similarityThreshold,
        'similarityThreshold',
        'must be within (0, 1]',
      );
    }
    final seenCandidateIds = <String>{};
    for (final c in candidates) {
      if (!seenCandidateIds.add(c.candidateId)) {
        throw ArgumentError('duplicate candidateId: ${c.candidateId}');
      }
    }
    final seenAcceptanceIds = <String>{};
    for (final a in acceptances) {
      if (!seenAcceptanceIds.add(a.acceptanceId)) {
        throw ArgumentError('duplicate acceptanceId: ${a.acceptanceId}');
      }
    }

    final inventory = spec == null
        ? const <String>{}
        : Set.unmodifiable(<String>{
            for (final part in spec.inventory) part.symbol.toLowerCase(),
          });

    final issues = <NameCheckIssue>[];
    final seenNormalized = <String, String>{}; // normalized -> candidateId

    for (final c in candidates) {
      // --- reserved_names -------------------------------------------------
      if (registry.isReserved(c.normalizedText)) {
        issues.add(
          NameCheckIssue.validated(
            candidateId: c.candidateId,
            kind: NameCheckKind.reservedName,
            message:
                '"${c.text}" is reserved and cannot be proposed as a '
                'regular name.',
            relatedId: 'reserved',
          ),
        );
      }

      // --- exact_collision vs kandidat sebelumnya --------------------------
      final priorId = seenNormalized[c.normalizedText];
      var exactHit = false;
      if (priorId != null) {
        exactHit = true;
        issues.add(
          NameCheckIssue.validated(
            candidateId: c.candidateId,
            kind: NameCheckKind.exactCollision,
            message:
                '"${c.text}" is identical to previously proposed candidate '
                '$priorId.',
            relatedId: priorId,
          ),
        );
      }
      seenNormalized[c.normalizedText] = c.candidateId;

      // --- pemeriksaan terhadap seluruh record kanon -----------------------
      for (final r in registry.records) {
        if (r.recordId == c.candidateId) continue; // idem = entitas yang sama
        if (r.normalizedText == c.normalizedText) {
          exactHit = true;
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.exactCollision,
              message:
                  '"${c.text}" exactly collides with canonical name '
                  '${r.recordId} ("${r.text}").',
              relatedId: r.recordId,
            ),
          );
          // Silang budaya: nama yang diakui budaya X sudah tercatat sebagai
          // milik budaya Y (atau bahasa Y) pada kanon.
          if (r.cultureId != c.cultureId || r.languageId != c.languageId) {
            issues.add(
              NameCheckIssue.validated(
                candidateId: c.candidateId,
                kind: NameCheckKind.cultureMismatch,
                message:
                    '"${c.text}" claims culture ${c.cultureId}/'
                    '${c.languageId} but canonical ${r.recordId} is '
                    '${r.cultureId}/${r.languageId}.',
                relatedId: r.recordId,
              ),
            );
          }
        } else if (!exactHit &&
            _similarity(r.normalizedText, c.normalizedText) >=
                similarityThreshold) {
          // --- similarity_warning (per record, hanya bila belum exact) ----
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.similarityWarning,
              message:
                  '"${c.text}" is too similar to canonical ${r.recordId} '
                  '("${r.text}").',
              relatedId: r.recordId,
            ),
          );
        }
      }

      // --- phonotactic_check ----------------------------------------------
      if (spec != null) {
        final symbols = c.normalizedText.split('');
        final unknown = <String>{
          for (final s in symbols)
            if (s != ' ' && !inventory.contains(s)) s,
        }.toList()..sort();
        if (unknown.isNotEmpty) {
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.phonotacticViolation,
              message:
                  '"${c.text}" uses symbols outside the '
                  '${spec.languageId} '
                  'inventory: ${unknown.join(', ')}.',
              relatedId: spec.id,
            ),
          );
        }
        for (final violation in spec.violationsIn(symbols)) {
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.phonotacticViolation,
              message: '"${c.text}" contains forbidden sequence $violation.',
              relatedId: violation,
            ),
          );
        }
      }

      // --- culture_check vs profil aktif ----------------------------------
      if (profile != null) {
        if (c.cultureId != profile.cultureId) {
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.cultureMismatch,
              message:
                  '"${c.text}" claims culture ${c.cultureId} but the active '
                  'profile ${profile.profileId} belongs to ${profile.cultureId}.',
              relatedId: profile.profileId,
            ),
          );
        }
        if (c.languageId != profile.languageId) {
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.cultureMismatch,
              message:
                  '"${c.text}" claims language ${c.languageId} but the '
                  'active profile ${profile.profileId} is rooted in '
                  '${profile.languageId}.',
              relatedId: profile.profileId,
            ),
          );
        }
        if (!profile.supportsEntityType(c.entityType)) {
          issues.add(
            NameCheckIssue.validated(
              candidateId: c.candidateId,
              kind: NameCheckKind.cultureMismatch,
              message:
                  'entity type ${c.entityType.name} is outside the '
                  'whitelist of profile ${profile.profileId}.',
              relatedId: profile.profileId,
            ),
          );
        }
      }
    }

    // --- manual_accept: suppressed (candidateId, kind) dihapus -------------
    final active = List<NameCheckIssue>.unmodifiable(
      issues.where(
        (i) => !acceptances.any((a) => a.matches(i.candidateId, i.kind)),
      ),
    );
    return NameCheckReport.of(active);
  }
}
