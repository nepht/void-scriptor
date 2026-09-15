// Sprint 111.35 - Tone, Connotation & Dialogue Suggestions (domain-only).
//
// Menjelaskan nada (tone), konotasi, dan risiko penghinaan sebuah ungkapan,
// menyimpan contoh pemakaian, menilai kecocokan dengan suara karakter
// (character_fit), lalu menghasilkan saran dialog yang HANYA bisa diubah
// menjadi permintaan sisip eksplisit oleh pengguna (user_initiated_insert).
//
// Enam acceptance canonical sprint_111.json dipetakan:
// - tone             -> IdiomTone ladder berlabel + IdiomToneProfile.tone
// - connotation      -> IdiomConnotation (valence + isDoubleEdged)
// - offense_risk     -> OffenseRisk tangga 0..4 (weight, atLeast,
//                       blockingInSacred) pada profil dan toleransi karakter
// - examples         -> IdiomUsageExample (teks + terjemahan + konteks sosial)
// - character_fit    -> CharacterVoiceProfile + IdiomDialogueAdviser.fitFor
//                       -> CharacterFitAssessment (skor + alasan deterministik)
// - user_initiated_insert -> DialogueSuggestion.insertionRequest() menghasilkan
//                       ExplicitInsertionRequest ber-origin 'userInitiated'.
//                       Modul ini TIDAK punya jalur tulis ke editor/naskah/DB:
//                       request hanyalah data murni yang harus dieksekusi
//                       oleh lapisan di atasnya setelah aksi pengguna.
//
// Konsumsi lintas langkah: kunci idiomId merujuk [IdiomRecord] 111.33;
// konteks pemakaian (budaya memakai/menghindari, kelaziman konteks,
// keaktifan era) dibaca dari [IdiomUsageProfile] 111.34 dan [SocialContext]
// 111.30 — tipe tidak diduplikasi.
//
// Deterministik penuh: skor fit memakai bobot setengah-poin tetap lalu
// pembulatan menjauhi nol; urutan saran = verdict, idiomId, exampleId.
// Tanpa persistence, UI, locale, jaringan, wall-clock, atau random.
// D-SCHEMA-01 tetap OPEN; modul ini mirror domain untuk Drift mendatang.
library;

import 'package:void_scriptor/features/world_logic/domain/encyclopedia_idiom_usage.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart'
    show SocialContext;

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return trimmed;
}

String? _optionalTrimmed(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Nada penyampaian sebuah ungkapannya (acceptance `tone`).
enum IdiomTone {
  /// Netral — tanpa warna emosional menonjol.
  neutral('Neutral'),

  /// Hangat, bersahabat.
  warm('Warm'),

  /// Main, ringan.
  playful('Playful'),

  /// Menyindir halus.
  ironic('Ironic'),

  /// Mengejek, lebih tajam dari ironi.
  mocking('Mocking'),

  /// Pahit, kecewa.
  bitter('Bitter'),

  /// Sindiran kasar/terbuka.
  sarcastic('Sarcastic'),

  /// Berduka, ratapan.
  mournful('Mournful'),

  /// Khidmat, layak untuk peristiwa resmi.
  solemn('Solemn'),

  /// Tegas, tanpa basa-basi.
  blunt('Blunt');

  const IdiomTone(this.label);

  /// Label manusiawi untuk UI (bukan kunci penyimpanan).
  final String label;

  static IdiomTone fromName(String? name) =>
      values.firstWhere((t) => t.name == name);
}

/// Muatan nilai sebuah ungkapan (acceptance `connotation`).
enum IdiomConnotation {
  /// Memuji atau memandang baik.
  positive('Positive', 1),

  /// Memandang buruk.
  negative('Negative', -1),

  /// Tanpa muatan nilai jelas.
  neutral('Neutral', 0),

  /// Bersisi ganda — bisa pujian sekaligus penghinaan tergantung pembacaan.
  ambivalent('Ambivalent', 0);

  const IdiomConnotation(this.label, this.valence);

  final String label;

  /// +1 memuji, -1 menghina, 0 netral/ambivalen.
  final int valence;

  /// Hanya [ambivalent] yang secara eksplisit bersisi ganda.
  bool get isDoubleEdged => this == IdiomConnotation.ambivalent;

  static IdiomConnotation fromName(String? name) =>
      values.firstWhere((c) => c.name == name);
}

/// Seberapa besar risiko ungkapan menyinggung (acceptance `offense_risk`).
/// Tangga [weight] naik strictly increasing sehingga perbandingan
/// `[atLeast]` selalu konsisten dengan urutan deklarasi.
enum OffenseRisk {
  /// Tidak menyinggung siapa pun.
  harmless('Harmless', 0),

  /// Bisa menyinggung sebagian kecil pendengar.
  mild('Mild', 1),

  /// Berisiko nyata di kebanyakan forum.
  moderate('Moderate', 2),

  /// Tinggi — tabu sosial kuat.
  high('High', 3),

  /// Parah — pantangan berat/terlarang.
  severe('Severe', 4);

  const OffenseRisk(this.label, this.weight);

  final String label;
  final int weight;

  /// Perbandingan tangga (refleksif).
  bool atLeast(OffenseRisk other) => weight >= other.weight;

  /// Tingkat high/severe memblokir pemakaian di konteks sakral.
  bool get blockingInSacred =>
      this == OffenseRisk.high || this == OffenseRisk.severe;

  static OffenseRisk fromName(String? name) =>
      values.firstWhere((r) => r.name == name);
}

/// Satu contoh pemakaian ungkapan (acceptance `examples`).
class IdiomUsageExample {
  const IdiomUsageExample._({
    required this.exampleId,
    required this.text,
    required this.translation,
    required this.context,
    required this.note,
  });

  /// Membuat contoh. [exampleId] dan [text] wajib non-kosong (dipangkas);
  /// [translation] dan [note] opsional (blank menjadi null/kosong).
  /// [context] null berarti contoh umum — cocok untuk konteks apa pun.
  factory IdiomUsageExample.validated({
    required String exampleId,
    required String text,
    String? translation,
    SocialContext? context,
    String note = '',
  }) {
    return IdiomUsageExample._(
      exampleId: _requireTrimmed(exampleId, 'exampleId'),
      text: _requireTrimmed(text, 'text'),
      translation: _optionalTrimmed(translation),
      context: context,
      note: note.trim(),
    );
  }

  final String exampleId;
  final String text;

  /// Terjemahan/parafrasa opsional per contoh.
  final String? translation;

  /// Konteks sosial pemakaian; null = contoh umum.
  final SocialContext? context;
  final String note;

  bool get hasTranslation => translation != null;

  /// Apakah contoh ini layak ditampilkan untuk [ctx] (null = semua).
  bool fitsContext(SocialContext? ctx) =>
      ctx == null || context == null || context == ctx;

  Map<String, Object?> toJson() => <String, Object?>{
    'exampleId': exampleId,
    'text': text,
    if (translation != null) 'translation': translation,
    if (context != null) 'context': context!.name,
    'note': note,
  };

  static IdiomUsageExample fromJson(Map<String, Object?> json) =>
      IdiomUsageExample.validated(
        exampleId: json['exampleId']! as String,
        text: json['text']! as String,
        translation: json['translation'] as String?,
        context: json['context'] == null
            ? null
            : SocialContext.values.firstWhere((c) => c.name == json['context']),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomUsageExample &&
          other.exampleId == exampleId &&
          other.text == text &&
          other.translation == translation &&
          other.context == context &&
          other.note == note);

  @override
  int get hashCode => Object.hash(exampleId, text, translation, context, note);

  @override
  String toString() => 'IdiomUsageExample($exampleId)';
}

/// Profil nada + konotasi + risiko + contoh untuk SATU ungkapan (kunci
/// [idiomId] merujuk [IdiomRecord] 111.33).
class IdiomToneProfile {
  const IdiomToneProfile._({
    required this.idiomId,
    required this.tone,
    required this.connotation,
    required this.offenseRisk,
    required this.examples,
    required this.registerHint,
    required this.note,
  });

  /// Membuat profil; [idiomId] wajib non-kosong. Guard: [exampleId] unik
  /// lintas contoh dalam profil. Koleksi contoh selalu immutable.
  factory IdiomToneProfile.validated({
    required String idiomId,
    required IdiomTone tone,
    required IdiomConnotation connotation,
    required OffenseRisk offenseRisk,
    List<IdiomUsageExample> examples = const <IdiomUsageExample>[],
    IdiomRegister? registerHint,
    String note = '',
  }) {
    final seen = <String>{};
    for (final e in examples) {
      if (!seen.add(e.exampleId)) {
        throw ArgumentError('duplicate exampleId: ${e.exampleId}');
      }
    }
    return IdiomToneProfile._(
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      tone: tone,
      connotation: connotation,
      offenseRisk: offenseRisk,
      examples: List<IdiomUsageExample>.unmodifiable(examples),
      registerHint: registerHint,
      note: note.trim(),
    );
  }

  final String idiomId;
  final IdiomTone tone;
  final IdiomConnotation connotation;

  /// Risiko penghinaan bawaan ungkapan (acceptance `offense_risk`).
  final OffenseRisk offenseRisk;
  final List<IdiomUsageExample> examples;

  /// Register 111.34 yang lazim; null = tanpa petunjuk register.
  final IdiomRegister? registerHint;
  final String note;

  int get exampleCount => examples.length;
  bool get hasExamples => examples.isNotEmpty;
  bool get hasRegisterHint => registerHint != null;

  /// Contoh yang layak untuk [context] (null = semua), terurut exampleId.
  List<IdiomUsageExample> exampleForContext(SocialContext? context) {
    final hits = examples.where((e) => e.fitsContext(context)).toList()
      ..sort((a, b) => a.exampleId.compareTo(b.exampleId));
    return List<IdiomUsageExample>.unmodifiable(hits);
  }

  /// Semua contoh terurut exampleId; immutable.
  List<IdiomUsageExample> get examplesForAll {
    final all = List<IdiomUsageExample>.of(examples)
      ..sort((a, b) => a.exampleId.compareTo(b.exampleId));
    return List<IdiomUsageExample>.unmodifiable(all);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'idiomId': idiomId,
    'tone': tone.name,
    'connotation': connotation.name,
    'offenseRisk': offenseRisk.name,
    'examples': examples.map((e) => e.toJson()).toList(),
    if (registerHint != null) 'registerHint': registerHint!.name,
    'note': note,
  };

  static IdiomToneProfile fromJson(Map<String, Object?> json) =>
      IdiomToneProfile.validated(
        idiomId: json['idiomId']! as String,
        tone: IdiomTone.fromName(json['tone'] as String?),
        connotation: IdiomConnotation.fromName(json['connotation'] as String?),
        offenseRisk: OffenseRisk.fromName(json['offenseRisk'] as String?),
        examples: (json['examples'] as List<Object?>? ?? const <Object?>[])
            .map(
              (e) => IdiomUsageExample.fromJson((e! as Map<String, Object?>)),
            )
            .toList(),
        registerHint: json['registerHint'] == null
            ? null
            : IdiomRegister.fromName(json['registerHint'] as String?),
        note: json['note'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomToneProfile &&
          other.idiomId == idiomId &&
          other.tone == tone &&
          other.connotation == connotation &&
          other.offenseRisk == offenseRisk &&
          other.registerHint == registerHint &&
          other.note == note &&
          other.examples.length == examples.length &&
          List.generate(
            examples.length,
            (i) => other.examples[i] == examples[i],
          ).every((ok) => ok));

  @override
  int get hashCode => Object.hash(
    idiomId,
    tone,
    connotation,
    offenseRisk,
    registerHint,
    note,
    examples.length,
  );

  @override
  String toString() => 'IdiomToneProfile($idiomId, ${tone.name})';
}

/// Katalog profil nada lintas ungkapan.
class IdiomToneCatalog {
  const IdiomToneCatalog._(this._profiles);

  /// Katalog kosong.
  factory IdiomToneCatalog.empty() =>
      const IdiomToneCatalog._(<IdiomToneProfile>[]);

  /// Membangun katalog; [IdiomToneProfile.idiomId] wajib unik lintas profil.
  /// Penyimpanan terurut idiomId sehingga hasil query deterministik.
  factory IdiomToneCatalog.withProfiles(List<IdiomToneProfile> profiles) {
    final seen = <String>{};
    for (final p in profiles) {
      if (!seen.add(p.idiomId)) {
        throw ArgumentError('duplicate idiomId: ${p.idiomId}');
      }
    }
    final sorted = List<IdiomToneProfile>.of(profiles)
      ..sort((a, b) => a.idiomId.compareTo(b.idiomId));
    return IdiomToneCatalog._(List<IdiomToneProfile>.unmodifiable(sorted));
  }

  final List<IdiomToneProfile> _profiles;

  List<IdiomToneProfile> get profiles => _profiles;
  int get profileCount => _profiles.length;

  List<String> get idiomIds =>
      List<String>.unmodifiable(_profiles.map((p) => p.idiomId));

  /// Lookup profil per idiomId, toleran whitespace; null saat tak ada.
  IdiomToneProfile? profileFor(String idiomId) {
    final needle = idiomId.trim();
    if (needle.isEmpty) return null;
    for (final p in _profiles) {
      if (p.idiomId == needle) return p;
    }
    return null;
  }

  /// Ungkapan dengan risiko penghinaan >= [risk], terurut idiomId.
  List<String> idiomIdsAtOrAboveOffense(OffenseRisk risk) {
    final hits = _profiles
        .where((p) => p.offenseRisk.atLeast(risk))
        .map((p) => p.idiomId)
        .toList();
    return List<String>.unmodifiable(hits);
  }

  /// Ungkapan paling berisiko; tie-break idiomId ascending; null saat kosong.
  String? mostOffensiveIdiomId() {
    IdiomToneProfile? best;
    for (final p in _profiles) {
      if (best == null || p.offenseRisk.weight > best.offenseRisk.weight) {
        best = p;
      }
    }
    return best?.idiomId;
  }

  int get totalExampleCount =>
      _profiles.fold(0, (sum, p) => sum + p.exampleCount);

  /// Nada yang benar-benar dipakai katalog, terurut index enum, dedup.
  List<IdiomTone> tonesInUse() {
    final out = <IdiomTone>{};
    for (final p in _profiles) {
      out.add(p.tone);
    }
    final list = out.toList()..sort((a, b) => a.index.compareTo(b.index));
    return List<IdiomTone>.unmodifiable(list);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'profiles': _profiles.map((p) => p.toJson()).toList(),
  };

  static IdiomToneCatalog fromJson(Map<String, Object?> json) =>
      IdiomToneCatalog.withProfiles(
        (json['profiles'] as List<Object?>? ?? const <Object?>[])
            .map((e) => IdiomToneProfile.fromJson((e! as Map<String, Object?>)))
            .toList(),
      );

  @override
  String toString() => 'IdiomToneCatalog($profileCount profiles)';
}

/// Suara sebuah karakter: nada yang disukai/dihindari dan ambang
/// toleransi penghinaan — masukan penilaian character_fit.
class CharacterVoiceProfile {
  const CharacterVoiceProfile._({
    required this.characterId,
    required this.displayName,
    required this.preferredTones,
    required this.avoidedTones,
    required this.offenseTolerance,
    required this.cultureId,
    required this.professionIds,
  });

  /// Membuat profil suara. Guard: [characterId] non-kosong; irisan
  /// preferred ∩ avoided harus kosong (satu nada tidak bisa disukai dan
  /// dihindari sekaligus); tiap [professionIds] non-kosong setelah dipangkas.
  factory CharacterVoiceProfile.validated({
    required String characterId,
    String? displayName,
    Set<IdiomTone> preferredTones = const <IdiomTone>{},
    Set<IdiomTone> avoidedTones = const <IdiomTone>{},
    OffenseRisk offenseTolerance = OffenseRisk.moderate,
    String? cultureId,
    List<String> professionIds = const <String>[],
  }) {
    final overlap = preferredTones.intersection(avoidedTones);
    if (overlap.isNotEmpty) {
      throw ArgumentError(
        'tone cannot be both preferred and avoided: '
        '${overlap.map((t) => t.name).join(', ')}',
      );
    }
    final trimmedProfessions =
        professionIds
            .map((p) {
              final t = p.trim();
              if (t.isEmpty) {
                throw ArgumentError('professionIds entries must be non-empty');
              }
              return t;
            })
            .toSet()
            .toList()
          ..sort();
    final preferred = preferredTones.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final avoided = avoidedTones.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return CharacterVoiceProfile._(
      characterId: _requireTrimmed(characterId, 'characterId'),
      displayName: _optionalTrimmed(displayName),
      preferredTones: List<IdiomTone>.unmodifiable(preferred),
      avoidedTones: List<IdiomTone>.unmodifiable(avoided),
      offenseTolerance: offenseTolerance,
      cultureId: _optionalTrimmed(cultureId),
      professionIds: List<String>.unmodifiable(trimmedProfessions),
    );
  }

  final String characterId;
  final String? displayName;

  /// Nada yang menjadi ciri suara karakter (menambah skor fit).
  final List<IdiomTone> preferredTones;

  /// Nada yang karakter tidak pernah pakai (mem-floor verdict).
  final List<IdiomTone> avoidedTones;

  /// Batas atas risiko penghinaan yang masih nyaman dipakai.
  final OffenseRisk offenseTolerance;

  /// Budaya karakter — dicocokkan dengan facet budaya usage 111.34.
  final String? cultureId;
  final List<String> professionIds;

  bool get hasCulture => cultureId != null;

  bool prefersTone(IdiomTone tone) => preferredTones.contains(tone);

  bool avoidsTone(IdiomTone tone) => avoidedTones.contains(tone);

  Map<String, Object?> toJson() => <String, Object?>{
    'characterId': characterId,
    if (displayName != null) 'displayName': displayName,
    'preferredTones': preferredTones.map((t) => t.name).toList(),
    'avoidedTones': avoidedTones.map((t) => t.name).toList(),
    'offenseTolerance': offenseTolerance.name,
    if (cultureId != null) 'cultureId': cultureId,
    'professionIds': professionIds,
  };

  static CharacterVoiceProfile fromJson(
    Map<String, Object?> json,
  ) => CharacterVoiceProfile.validated(
    characterId: json['characterId']! as String,
    displayName: json['displayName'] as String?,
    preferredTones:
        (json['preferredTones'] as List<Object?>? ?? const <Object?>[])
            .map((e) => IdiomTone.fromName((e! as String)))
            .toSet(),
    avoidedTones: (json['avoidedTones'] as List<Object?>? ?? const <Object?>[])
        .map((e) => IdiomTone.fromName((e! as String)))
        .toSet(),
    offenseTolerance: OffenseRisk.fromName(json['offenseTolerance'] as String?),
    cultureId: json['cultureId'] as String?,
    professionIds:
        (json['professionIds'] as List<Object?>? ?? const <Object?>[])
            .map((e) => e! as String)
            .toList(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterVoiceProfile &&
          other.characterId == characterId &&
          other.displayName == displayName &&
          other.offenseTolerance == offenseTolerance &&
          other.cultureId == cultureId &&
          _sameTones(other.preferredTones, preferredTones) &&
          _sameTones(other.avoidedTones, avoidedTones) &&
          _sameStrings(other.professionIds, professionIds));

  @override
  int get hashCode => Object.hash(
    characterId,
    displayName,
    offenseTolerance,
    cultureId,
    preferredTones.join(','),
    avoidedTones.join(','),
    professionIds.join(','),
  );

  @override
  String toString() => 'CharacterVoiceProfile($characterId)';
}

bool _sameTones(List<IdiomTone> a, List<IdiomTone> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _sameStrings(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Empat tingkat kecocokan ungkapan dengan karakter (acceptance
/// `character_fit`), terurut dari paling cocok.
enum CharacterFitVerdict {
  /// Cocok sempurna — nada disukai, risiko terkendali.
  ideal('Ideal'),

  /// Layak dipakai tanpa keraguan.
  comfortable('Comfortable'),

  /// Bisa dipakai dengan kesadaran penuh atas ganjalan yang tercatat.
  strained('Strained'),

  /// Tidak pantas — diblokir nada/ budaya yang menghindari, atau risiko
  /// melewati ambang.
  inappropriate('Inappropriate');

  const CharacterFitVerdict(this.label);

  final String label;

  /// 0 = paling cocok; makin besar makin buruk.
  int get rank => index;
}

/// Hasil penilaian fit: skor integer + alasan yang bisa dibaca.
class CharacterFitAssessment {
  const CharacterFitAssessment._({
    required this.idiomId,
    required this.characterId,
    required this.score,
    required this.reasons,
    required this.blockedByAvoidedTone,
    required this.blockedByAvoidedCulture,
  });

  /// Konstruktor rendah-level — [verdict] diturunkan dari [score] via
  /// ambang kanonik [IdiomDialogueAdviser.verdictForScore]. Dipakai untuk
  /// menyusun fixture dan hasil replika dari JSON.
  factory CharacterFitAssessment.of({
    required String idiomId,
    required String characterId,
    required int score,
    List<String> reasons = const <String>[],
    bool blockedByAvoidedTone = false,
    bool blockedByAvoidedCulture = false,
  }) {
    return CharacterFitAssessment._(
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      characterId: _requireTrimmed(characterId, 'characterId'),
      score: score,
      reasons: List<String>.unmodifiable(reasons),
      blockedByAvoidedTone: blockedByAvoidedTone,
      blockedByAvoidedCulture: blockedByAvoidedCulture,
    );
  }

  final String idiomId;
  final String characterId;

  /// Skor mentah (bisa negatif). Makin tinggi makin cocok.
  final int score;

  /// Alasan manusia-terbaca, urutan = urutan evaluasi advisers.
  final List<String> reasons;

  /// true saat nada karakter yang dihindari mem-floor hasil.
  final bool blockedByAvoidedTone;

  /// true saat budaya karakter (via usage 111.34) menghindari ungkapan.
  final bool blockedByAvoidedCulture;

  /// Alias baca untuk konsumen yang memakai awalan `is`.
  bool get isBlockedByAvoidedTone => blockedByAvoidedTone;

  bool get isBlockedByAvoidedCulture => blockedByAvoidedCulture;

  CharacterFitVerdict get verdict =>
      IdiomDialogueAdviser.verdictForScore(score);

  bool get isIdeal => verdict == CharacterFitVerdict.ideal;

  String describe() =>
      '$idiomId for $characterId: ${verdict.label} (skor $score)'
      '${reasons.isEmpty ? '' : ' — ${reasons.join('; ')}'}';

  Map<String, Object?> toJson() => <String, Object?>{
    'idiomId': idiomId,
    'characterId': characterId,
    'score': score,
    'reasons': reasons,
    'blockedByAvoidedTone': blockedByAvoidedTone,
    'blockedByAvoidedCulture': blockedByAvoidedCulture,
  };

  static CharacterFitAssessment fromJson(Map<String, Object?> json) =>
      CharacterFitAssessment.of(
        idiomId: json['idiomId']! as String,
        characterId: json['characterId']! as String,
        score: json['score']! as int,
        reasons: (json['reasons'] as List<Object?>? ?? const <Object?>[])
            .map((e) => e! as String)
            .toList(),
        blockedByAvoidedTone: json['blockedByAvoidedTone'] as bool? ?? false,
        blockedByAvoidedCulture:
            json['blockedByAvoidedCulture'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterFitAssessment &&
          other.idiomId == idiomId &&
          other.characterId == characterId &&
          other.score == score &&
          other.blockedByAvoidedTone == blockedByAvoidedTone &&
          other.blockedByAvoidedCulture == blockedByAvoidedCulture &&
          _sameStrings(other.reasons, reasons));

  @override
  int get hashCode => Object.hash(
    idiomId,
    characterId,
    score,
    blockedByAvoidedTone,
    blockedByAvoidedCulture,
    reasons.join('|'),
  );

  @override
  String toString() => 'CharacterFitAssessment($idiomId, ${verdict.name})';
}

/// Saran satu ungkapan (dengan satu contoh konkret) untuk karakter tertentu.
class DialogueSuggestion {
  const DialogueSuggestion._({
    required this.idiomId,
    required this.tone,
    required this.connotation,
    required this.offenseRisk,
    required this.exampleId,
    required this.text,
    required this.translation,
    required this.fit,
  });

  /// Menyusun saran. Guard: [profile] dan [fit] wajib merujuk idiomId yang
  /// sama; teks contoh tidak boleh kosong (divalidasi contoh itu sendiri).
  factory DialogueSuggestion.of({
    required IdiomToneProfile profile,
    required IdiomUsageExample example,
    required CharacterFitAssessment fit,
  }) {
    if (profile.idiomId != fit.idiomId) {
      throw ArgumentError(
        'fit.idiomId (${fit.idiomId}) must match profile.idiomId '
        '(${profile.idiomId})',
      );
    }
    return DialogueSuggestion._(
      idiomId: profile.idiomId,
      tone: profile.tone,
      connotation: profile.connotation,
      offenseRisk: profile.offenseRisk,
      exampleId: example.exampleId,
      text: example.text,
      translation: example.translation,
      fit: fit,
    );
  }

  final String idiomId;
  final IdiomTone tone;
  final IdiomConnotation connotation;
  final OffenseRisk offenseRisk;
  final String exampleId;

  /// Teks contoh — materi yang bisa dipertimbangkan penulis.
  final String text;
  final String? translation;

  /// Penilaian fit yang menyertai saran.
  final CharacterFitAssessment fit;

  CharacterFitVerdict get verdict => fit.verdict;

  /// Membangun PERMINTAAN sisip eksplisit (acceptance
  /// `user_initiated_insert`). Ini murni data — modul ini tidak menulis ke
  /// naskah/editor/database; lapisan UI hanya boleh memakainya setelah
  /// pengguna menekan aksi "sisipkan" secara sadar.
  ExplicitInsertionRequest insertionRequest() =>
      ExplicitInsertionRequest.userInitiated(
        idiomId: idiomId,
        exampleId: exampleId,
        text: text,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'idiomId': idiomId,
    'tone': tone.name,
    'connotation': connotation.name,
    'offenseRisk': offenseRisk.name,
    'exampleId': exampleId,
    'text': text,
    if (translation != null) 'translation': translation,
    'fit': fit.toJson(),
  };

  static DialogueSuggestion fromJson(Map<String, Object?> json) =>
      DialogueSuggestion.of(
        profile: IdiomToneProfile.validated(
          idiomId: json['idiomId']! as String,
          tone: IdiomTone.fromName(json['tone'] as String?),
          connotation: IdiomConnotation.fromName(
            json['connotation'] as String?,
          ),
          offenseRisk: OffenseRisk.fromName(json['offenseRisk'] as String?),
        ),
        example: IdiomUsageExample.validated(
          exampleId: json['exampleId']! as String,
          text: json['text']! as String,
          translation: json['translation'] as String?,
        ),
        fit: CharacterFitAssessment.fromJson(
          (json['fit']! as Map<String, Object?>),
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DialogueSuggestion &&
          other.idiomId == idiomId &&
          other.exampleId == exampleId &&
          other.text == text &&
          other.translation == translation &&
          other.fit == fit);

  @override
  int get hashCode => Object.hash(idiomId, exampleId, text, translation, fit);

  @override
  String toString() =>
      'DialogueSuggestion($idiomId/$exampleId, ${verdict.name})';
}

/// Permintaan sisip yang lahir dari aksi pengguna sadar. Bukan perintah
/// otomatis: [origin] selalu `userInitiated`, dan pemrosesnya WAJIB
/// memperlakukannya sebagai usulan yang dikonfirmasi, bukan penulisan senyap.
class ExplicitInsertionRequest {
  const ExplicitInsertionRequest._({
    required this.origin,
    required this.idiomId,
    required this.exampleId,
    required this.text,
  });

  /// Konstruktor ber-origin tetap `userInitiated`. Guard: seluruh field
  /// wajib non-kosong setelah dipangkas.
  factory ExplicitInsertionRequest.userInitiated({
    required String idiomId,
    required String exampleId,
    required String text,
  }) {
    return ExplicitInsertionRequest._(
      origin: 'userInitiated',
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      exampleId: _requireTrimmed(exampleId, 'exampleId'),
      text: _requireTrimmed(text, 'text'),
    );
  }

  /// Penanda asal permintaan — selalu konstan `userInitiated` pada slice ini.
  final String origin;
  final String idiomId;
  final String exampleId;
  final String text;

  bool get isUserInitiated => origin == 'userInitiated';

  Map<String, Object?> toJson() => <String, Object?>{
    'origin': origin,
    'idiomId': idiomId,
    'exampleId': exampleId,
    'text': text,
  };

  static ExplicitInsertionRequest fromJson(Map<String, Object?> json) {
    final origin = json['origin'] as String? ?? 'userInitiated';
    if (origin != 'userInitiated') {
      throw ArgumentError('unsupported insertion origin: $origin');
    }
    return ExplicitInsertionRequest.userInitiated(
      idiomId: json['idiomId']! as String,
      exampleId: json['exampleId']! as String,
      text: json['text']! as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExplicitInsertionRequest &&
          other.origin == origin &&
          other.idiomId == idiomId &&
          other.exampleId == exampleId &&
          other.text == text);

  @override
  int get hashCode => Object.hash(origin, idiomId, exampleId, text);

  @override
  String toString() => 'ExplicitInsertionRequest($idiomId/$exampleId)';
}

/// Penilai kecocokan dan generator saran dialog — murni fungsi deterministik
/// atas profil nada, profil suara, dan (opsional) konteks pemakaian 111.34.
class IdiomDialogueAdviser {
  const IdiomDialogueAdviser();

  // Bobot integer tetap — deterministik dan mudah diaudit.
  static const int _tonePreferred = 2;
  static const int _toneAvoided = -3;
  static const int _riskWithinTolerance = 1;
  static const int _riskAboveTolerance = -2;
  static const int _cultureUses = 1;
  static const int _contextUnfamiliar = -2;
  static const int _eraInactive = -2;
  static const int _sacredBlocked = -2;

  /// Skor lantai saat sebuah pemblokiran (nada/budaya) aktif.
  static const int _blockedFloorScore = -2;

  /// Ambang verdict kanonik (satu-satunya tempat angka ini hidup, supaya
  /// [CharacterFitAssessment.fromJson] tetap menurunkan verdict identik).
  static CharacterFitVerdict verdictForScore(int score) {
    if (score >= 3) return CharacterFitVerdict.ideal;
    if (score >= 1) return CharacterFitVerdict.comfortable;
    if (score >= -1) return CharacterFitVerdict.strained;
    return CharacterFitVerdict.inappropriate;
  }

  /// Penilaian character_fit satu ungkapan untuk satu karakter.
  ///
  /// [offense] mengoverride risiko bawaan profil (mis. untuk penilaian
  /// apa-adanya); [usage] (111.34) menambah facet budaya/konteks/era;
  /// [context] dan [atMarker] adalah kondisi pemakaiuan yang diminta.
  CharacterFitAssessment fitFor({
    required IdiomToneProfile profile,
    required CharacterVoiceProfile character,
    OffenseRisk? offense,
    IdiomUsageProfile? usage,
    SocialContext? context,
    String? atMarker,
  }) {
    if (usage != null && usage.idiomId != profile.idiomId) {
      throw ArgumentError(
        'usage.idiomId (${usage.idiomId}) must match profile.idiomId '
        '(${profile.idiomId})',
      );
    }
    var score = 0;
    final reasons = <String>[];
    var blockedTone = false;
    var blockedCulture = false;

    if (character.prefersTone(profile.tone)) {
      score += _tonePreferred;
      reasons.add(
        'nada ${profile.tone.label.toLowerCase()} disukai ${character.characterId}',
      );
    }
    if (character.avoidsTone(profile.tone)) {
      score += _toneAvoided;
      blockedTone = true;
      reasons.add(
        'nada ${profile.tone.label.toLowerCase()} dihindari ${character.characterId}',
      );
    }

    final risk = offense ?? profile.offenseRisk;
    if (risk.atLeast(character.offenseTolerance)) {
      if (risk != character.offenseTolerance) {
        score += _riskAboveTolerance;
        reasons.add(
          'risiko penghinaan ${risk.label.toLowerCase()} melewati ambang '
          '${character.offenseTolerance.label.toLowerCase()}',
        );
      }
      // Sama persis dengan ambang = tepat pada garis, tidak memberi bonus
      // maupun penalti.
    } else {
      score += _riskWithinTolerance;
      reasons.add(
        'risiko ${risk.label.toLowerCase()} masih dalam ambang '
        '${character.offenseTolerance.label.toLowerCase()}',
      );
    }

    final culture = character.cultureId;
    if (usage != null && culture != null) {
      if (usage.avoidedByCulture(culture)) {
        blockedCulture = true;
        reasons.add('budaya $culture menghindari ungkapan (usage 111.34)');
      } else if (usage.usedByCulture(culture)) {
        score += _cultureUses;
        reasons.add('budaya $culture lazim memakai ungkapan');
      }
    }

    if (usage != null && context != null && !usage.usableIn(context)) {
      score += _contextUnfamiliar;
      reasons.add('ungkapan lazim bukan untuk konteks ${context.name}');
    }

    if (usage != null && atMarker != null && !usage.activeAtMarker(atMarker)) {
      score += _eraInactive;
      reasons.add('ungkapan tidak aktif pada era $atMarker');
    }

    if (context == SocialContext.sacred && risk.blockingInSacred) {
      score += _sacredBlocked;
      reasons.add(
        'risiko ${risk.label.toLowerCase()} terblokir di konteks sakral',
      );
    }

    if ((blockedTone || blockedCulture) && score > _blockedFloorScore) {
      score = _blockedFloorScore;
    }

    return CharacterFitAssessment._(
      idiomId: profile.idiomId,
      characterId: character.characterId,
      score: score,
      reasons: List<String>.unmodifiable(reasons),
      blockedByAvoidedTone: blockedTone,
      blockedByAvoidedCulture: blockedCulture,
    );
  }

  /// Saran dialog terurut deterministik: verdict terbaik -> idiomId asc ->
  /// exampleId asc. Profil verdict `inappropriate` dikecualikan. Saat
  /// [context] diberikan, profil yang oleh usage 111.34 dinyatakan tidak
  /// lazim di konteks itu disingkirkan lebih dulu; sama hal untuk era via
  /// [atMarker]. Hasil selalu immutable dan TIDAK pernah menyentuh naskah.
  List<DialogueSuggestion> suggestionsFor({
    required IdiomToneCatalog catalog,
    required CharacterVoiceProfile character,
    SocialContext? context,
    String? atMarker,
    IdiomUsageCatalog? usageCatalog,
    int maxResults = 8,
  }) {
    if (maxResults < 1 || maxResults > 512) {
      throw ArgumentError('maxResults must be within 1..512');
    }
    final out = <DialogueSuggestion>[];
    for (final p in catalog.profiles) {
      final usage = usageCatalog?.profileFor(p.idiomId);
      if (usage != null) {
        if (context != null && !usage.usableIn(context)) continue;
        if (atMarker != null && !usage.activeAtMarker(atMarker)) continue;
      }
      final fit = fitFor(
        profile: p,
        character: character,
        usage: usage,
        context: context,
        atMarker: atMarker,
      );
      if (fit.verdict == CharacterFitVerdict.inappropriate) continue;
      for (final e in p.exampleForContext(context)) {
        out.add(DialogueSuggestion.of(profile: p, example: e, fit: fit));
      }
    }
    // Urutan dulu, baru pemangkasan — supaya kandidat bernada lebih cocok
    // yang lewat belakangan tidak terbuang sebelum sempat dibandingkan.
    out.sort((a, b) {
      final byVerdict = a.verdict.rank.compareTo(b.verdict.rank);
      if (byVerdict != 0) return byVerdict;
      final byIdiom = a.idiomId.compareTo(b.idiomId);
      if (byIdiom != 0) return byIdiom;
      return a.exampleId.compareTo(b.exampleId);
    });
    if (out.length > maxResults) {
      out.removeRange(maxResults, out.length);
    }
    return List<DialogueSuggestion>.unmodifiable(out);
  }
}
