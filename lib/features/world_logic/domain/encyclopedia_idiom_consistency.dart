// Sprint 111.36 — Idiom Consistency & Anachronism Checks (domain-only).
//
// Acceptance canonical: culture_check, character_check, era_check,
// meaning_check, explain_warning, manual_exception.
//
// Design:
//  - `IdiomUsageLedger` mencatat KEJADIAN pemakaian ungkapan ( teks, marker,
//    karakter, budaya ) di atas `IdiomRegistry` 111.33.
//  - `IdiomConsistencyValidator` murni membaca — ia mengemas isu dari
//    predikat yang SUDAH ADA di `IdiomUsageProfile` 111.34 (usedByCulture,
//    avoidedByCulture, activeAtMarker) dan `CharacterVoiceProfile`/
//    `IdiomToneCatalog` 111.35. Tidak ada validasi yang menulis ulang kanon.
//  - `explain_warning`: tiap isu membawa pesan manusia-terbaca + laporan
//    punya `describe()`/`suggestionFor()`.
//  - `manual_exception`: pasangan (idiomId, kind) — opsional ter-scope satu
//    eventId — MENANAKAN flag suppressed pada salinan laporan; kanon dan
//    ledger tidak pernah dimutasi (pola NameManualAcceptance 111.32 /
//    ArtifactManualException 111.23).
//
// Deterministik: tanpa wall-clock, random, persistence, UI, network.
// D-SCHEMA-01 tetap OPEN.
import 'encyclopedia_idiom_registry.dart';
import 'encyclopedia_idiom_tone.dart';
import 'encyclopedia_idiom_usage.dart';

/// Hash 64-bit FNV-1a atas UTF-8 — deterministik lintas proses (pola 111.31).
int _fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  for (final unit in input.runes) {
    if (unit < 0x80) {
      hash = (hash ^ unit) * 0x100000001b3;
    } else {
      // Encode rune sebagai UTF-8 manual agar stabil lintas platform.
      for (final byte in _utf8Bytes(unit)) {
        hash = (hash ^ byte) * 0x100000001b3;
      }
    }
  }
  return hash;
}

List<int> _utf8Bytes(int rune) {
  if (rune < 0x80) return <int>[rune];
  if (rune < 0x800) {
    return <int>[0xC0 | (rune >> 6), 0x80 | (rune & 0x3F)];
  }
  if (rune < 0x10000) {
    return <int>[
      0xE0 | (rune >> 12),
      0x80 | ((rune >> 6) & 0x3F),
      0x80 | (rune & 0x3F),
    ];
  }
  return <int>[
    0xF0 | (rune >> 18),
    0x80 | ((rune >> 12) & 0x3F),
    0x80 | ((rune >> 6) & 0x3F),
    0x80 | (rune & 0x3F),
  ];
}

String _requireTrimmed(String value, String fieldName) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('$fieldName must be non-empty');
  }
  return trimmed;
}

String? _optionalTrimmed(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _normalizeKey(String value) => value.trim().toLowerCase();

/// True bila teks tidak mengandung huruf/angka — mis. `?`, `—`, `...`.
bool _isContentless(String value) => !value.runes.any(
  (r) =>
      (r >= 0x41 && r <= 0x5A) ||
      (r >= 0x61 && r <= 0x7A) ||
      (r >= 0x30 && r <= 0x39) ||
      r > 0x7F,
);

/// Empat jenis pemeriksaan konsistensi/anakronisme ungkapan
/// (acceptance canonical 111.36).
enum IdiomConsistencyKind {
  /// Budaya pemakai kejadian tidak tercatat memakai ungkapan (111.34).
  culture('Culture check'),

  /// Karakter pemakai tidak cocok dengan kepemilikan budaya/nada ungkapan.
  character('Character check'),

  /// Kejadian berada di luar rentang era ungkapan (anakronisme).
  era('Era check'),

  /// Arti tidak tercatat, meaning drift, atau tabrakan teks/makna.
  meaning('Meaning check');

  const IdiomConsistencyKind(this.label);

  /// Label manusiawi untuk UI (bukan kunci penyimpanan).
  final String label;

  static IdiomConsistencyKind fromName(String? name) =>
      values.firstWhere((k) => k.name == name);
}

/// Satu kejadian pemakaian ungkapan dalam naskah/kanon (input periksa).
class IdiomUsageEvent {
  const IdiomUsageEvent._({
    required this.eventId,
    required this.idiomId,
    required this.atMarker,
    required this.text,
    required this.characterId,
    required this.cultureId,
  });

  /// Membangun kejadian. [eventId] dan [idiomId] wajib; [atMarker] dan
  /// [text] opsional — bila diberikan harus non-kosong setelah dipangkas.
  factory IdiomUsageEvent.validated({
    required String eventId,
    required String idiomId,
    String? atMarker,
    String? text,
    String? characterId,
    String? cultureId,
  }) {
    final trimmedMarker = _optionalTrimmed(atMarker);
    final trimmedText = text == null ? '' : _requireTrimmed(text, 'text');
    return IdiomUsageEvent._(
      eventId: _requireTrimmed(eventId, 'eventId'),
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      atMarker: trimmedMarker ?? '',
      text: trimmedText,
      characterId: _optionalTrimmed(characterId),
      cultureId: _optionalTrimmed(cultureId),
    );
  }

  final String eventId;
  final String idiomId;

  /// Marker cerita kejadian (konvensi zero-pad 111.26/27); '' = tidak tercatat.
  final String atMarker;

  /// Teks sebagaimana dipakai; '' = kejadian posisi saja (tanpa occurrences).
  final String text;

  final String? characterId;
  final String? cultureId;

  bool get hasOccurrence => text.isNotEmpty;
  bool get hasMarker => atMarker.isNotEmpty;

  /// Id teks yang dicocokkan pada [record]: `'canonical'`, variantId,
  /// atau null bila tidak cocok sama sekali (toleran trim/kasus/whitespace).
  String? matchedTextId(IdiomRecord record) {
    if (!hasOccurrence) return null;
    if (record.normalizedText == normalizeIdiomText(text)) return 'canonical';
    return record.variantForText(text)?.variantId;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'eventId': eventId,
    'idiomId': idiomId,
    'atMarker': atMarker,
    'text': text,
    'characterId': characterId,
    'cultureId': cultureId,
  };

  static IdiomUsageEvent fromJson(Map<String, Object?> json) =>
      IdiomUsageEvent.validated(
        eventId: json['eventId']! as String,
        idiomId: json['idiomId']! as String,
        atMarker: json['atMarker'] as String?,
        text: (json['text'] as String?)?.isEmpty ?? true
            ? null
            : json['text']! as String,
        characterId: json['characterId'] as String?,
        cultureId: json['cultureId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomUsageEvent &&
          other.eventId == eventId &&
          other.idiomId == idiomId &&
          other.atMarker == atMarker &&
          other.text == text &&
          other.characterId == characterId &&
          other.cultureId == cultureId);

  @override
  int get hashCode =>
      Object.hash(eventId, idiomId, atMarker, text, characterId, cultureId);

  @override
  String toString() => 'IdiomUsageEvent($eventId, $idiomId)';
}

/// Kejadian pemakaian di atas registri ungkapan. Ledger boleh kosong —
/// seluruh checks struktural (meaning lintas registri) tetap berjalan.
class IdiomUsageLedger {
  const IdiomUsageLedger._(this._records, this._events);

  /// Ledger tanpa registri dan tanpa kejadian.
  factory IdiomUsageLedger.empty() =>
      IdiomUsageLedger._(IdiomRegistry.empty(), const <IdiomUsageEvent>[]);

  /// Membangun ledger; guard: [eventId] unik dan tiap kejadian merujuk
  /// idiom yang terdaftar di [records].
  factory IdiomUsageLedger.withRecords({
    required IdiomRegistry records,
    List<IdiomUsageEvent> events = const <IdiomUsageEvent>[],
  }) {
    final seenIds = <String>{};
    for (final e in events) {
      if (!seenIds.add(e.eventId)) {
        throw ArgumentError('duplicate eventId: ${e.eventId}');
      }
      if (records.recordFor(e.idiomId) == null) {
        throw ArgumentError('event references unknown idiomId: ${e.idiomId}');
      }
    }
    return IdiomUsageLedger._(
      records,
      List<IdiomUsageEvent>.unmodifiable(events),
    );
  }

  final IdiomRegistry _records;
  final List<IdiomUsageEvent> _events;

  IdiomRegistry get records => _records;

  List<IdiomUsageEvent> get events => _events;

  int get eventCount => _events.length;

  bool get hasOccurrences => _events.any((e) => e.hasOccurrence);

  /// Kejadian untuk satu idiom, terurut (marker, eventId); immutable.
  List<IdiomUsageEvent> eventsFor(String idiomId) {
    final needle = idiomId.trim();
    if (needle.isEmpty) return const <IdiomUsageEvent>[];
    final hits =
        _events.where((e) => e.idiomId == needle).toList(growable: false)
          ..sort((a, b) {
            final byMarker = a.atMarker.compareTo(b.atMarker);
            if (byMarker != 0) return byMarker;
            return a.eventId.compareTo(b.eventId);
          });
    return List<IdiomUsageEvent>.unmodifiable(hits);
  }

  bool hasEvent(String eventId) {
    final needle = eventId.trim();
    if (needle.isEmpty) return false;
    return _events.any((e) => e.eventId == needle);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'records': _records.toJson(),
    'events': _events.map((e) => e.toJson()).toList(),
  };

  static IdiomUsageLedger fromJson(Map<String, Object?> json) =>
      IdiomUsageLedger.withRecords(
        records: IdiomRegistry.fromJson(
          (json['records']! as Map<Object?, Object?>).cast<String, Object?>(),
        ),
        events: <IdiomUsageEvent>[
          for (final raw in (json['events']! as List<Object?>))
            IdiomUsageEvent.fromJson(
              (raw! as Map<Object?, Object?>).cast<String, Object?>(),
            ),
        ],
      );

  @override
  String toString() => 'IdiomUsageLedger($eventCount events)';
}

/// Satu isu konsistensi pada satu ungkapan. Immutable; [issueId] diturunkan
/// deterministik dari (idiomId, kind, relatedId, message) — bukan hashCode
/// Dart (pola NameCheckIssue 111.32).
class IdiomConsistencyIssue {
  const IdiomConsistencyIssue._({
    required this.issueId,
    required this.idiomId,
    required this.kind,
    required this.message,
    required this.relatedId,
    required this.suppressed,
  });

  /// Membangun issue tervalidasi dengan id stabil hasil hash field isi.
  factory IdiomConsistencyIssue.validated({
    required String idiomId,
    required IdiomConsistencyKind kind,
    required String message,
    String? relatedId,
  }) {
    final trimmedMessage = _requireTrimmed(message, 'message');
    final trimmedRelated = relatedId?.trim();
    final effectiveRelated = (trimmedRelated == null || trimmedRelated.isEmpty)
        ? null
        : trimmedRelated;
    final issueId =
        'ici-${_fnv1a64('${_requireTrimmed(idiomId, 'idiomId')}|'
        '${kind.name}|${effectiveRelated ?? '-'}|$trimmedMessage').toRadixString(16)}';
    return IdiomConsistencyIssue._(
      issueId: issueId,
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      kind: kind,
      message: trimmedMessage,
      relatedId: effectiveRelated,
      suppressed: false,
    );
  }

  final String issueId;
  final String idiomId;
  final IdiomConsistencyKind kind;

  /// Penjelasan manusia-terbaca (acceptance `explain_warning`).
  final String message;

  /// Id pihak terkait (eventId untuk isu berbasis kejadian; null untuk isu
  /// struktural registri).
  final String? relatedId;

  /// True bila ditekan oleh [IdiomManualException] pada SALINAN laporan.
  final bool suppressed;

  IdiomConsistencyIssue _copyWithSuppressed(bool value) =>
      IdiomConsistencyIssue._(
        issueId: issueId,
        idiomId: idiomId,
        kind: kind,
        message: message,
        relatedId: relatedId,
        suppressed: value,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'issueId': issueId,
    'idiomId': idiomId,
    'kind': kind.name,
    'message': message,
    'relatedId': relatedId,
    'suppressed': suppressed,
  };

  static IdiomConsistencyIssue fromJson(Map<String, Object?> json) {
    final issue = IdiomConsistencyIssue._(
      issueId: _requireTrimmed(json['issueId']! as String, 'issueId'),
      idiomId: _requireTrimmed(json['idiomId']! as String, 'idiomId'),
      kind: IdiomConsistencyKind.fromName(json['kind'] as String?),
      message: _requireTrimmed(json['message']! as String, 'message'),
      relatedId: _optionalTrimmed(json['relatedId'] as String?),
      suppressed: json['suppressed'] as bool? ?? false,
    );
    final derived =
        'ici-${_fnv1a64('${issue.idiomId}|${issue.kind.name}|'
        '${issue.relatedId ?? '-'}|${issue.message}').toRadixString(16)}';
    if (issue.issueId != derived) {
      throw ArgumentError(
        'issueId mismatch: stored ${issue.issueId} vs derived $derived',
      );
    }
    return issue;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomConsistencyIssue &&
          other.issueId == issueId &&
          other.idiomId == idiomId &&
          other.kind == kind &&
          other.message == message &&
          other.relatedId == relatedId &&
          other.suppressed == suppressed);

  @override
  int get hashCode =>
      Object.hash(issueId, idiomId, kind, message, relatedId, suppressed);

  @override
  String toString() => 'IdiomConsistencyIssue($issueId, ${kind.name})';
}

/// Pengecualian manual eksplisit atas satu jenis isu untuk satu ungkapan —
/// pola ArtifactManualException 111.23 / NameManualAcceptance 111.32.
/// Opsional ter-scope ke satu [eventScope] (eventId) agar hanya kejadian itu
/// yang ditekan.
class IdiomManualException {
  const IdiomManualException._({
    required this.exceptionId,
    required this.idiomId,
    required this.kind,
    required this.reason,
    required this.eventScope,
  });

  /// Membangun pengecualian; keempat teks wajib non-kosong setelah dipangkas
  /// ([eventScope] opsional).
  factory IdiomManualException.validated({
    required String exceptionId,
    required String idiomId,
    required IdiomConsistencyKind kind,
    required String reason,
    String? eventScope,
  }) {
    return IdiomManualException._(
      exceptionId: _requireTrimmed(exceptionId, 'exceptionId'),
      idiomId: _requireTrimmed(idiomId, 'idiomId'),
      kind: kind,
      reason: _requireTrimmed(reason, 'reason'),
      eventScope: _optionalTrimmed(eventScope),
    );
  }

  final String exceptionId;
  final String idiomId;
  final IdiomConsistencyKind kind;
  final String reason;

  /// Bila terisi, pengecualian hanya menekan isu pada kejadian ini.
  final String? eventScope;

  bool get isEventScoped => eventScope != null;

  /// Kecocokan toleran kasus/whitespace pada pasangan (idiomId, kind).
  bool matches(String idiomId, IdiomConsistencyKind kind) =>
      _normalizeKey(this.idiomId) == _normalizeKey(idiomId) &&
      this.kind == kind;

  /// True bila isu [kind] pada kejadian [eventId] tercakup pengecualian ini.
  bool suppresses(String eventId, IdiomConsistencyKind kind) {
    if (this.kind != kind) return false;
    final scope = eventScope;
    if (scope != null && scope != eventId.trim()) return false;
    return true;
  }

  /// True bila [issue] ditekan oleh pengecualian ini.
  bool suppressesForIssue(IdiomConsistencyIssue issue) {
    if (!matches(issue.idiomId, issue.kind)) return false;
    final scope = eventScope;
    if (scope == null) return true;
    return issue.relatedId != null && scope == issue.relatedId;
  }

  /// Salinan ter-scope ke satu eventId (asli tidak berubah).
  IdiomManualException forEvent(String eventId) =>
      IdiomManualException.validated(
        exceptionId: exceptionId,
        idiomId: idiomId,
        kind: kind,
        reason: reason,
        eventScope: eventId,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'exceptionId': exceptionId,
    'idiomId': idiomId,
    'kind': kind.name,
    'reason': reason,
    'eventScope': eventScope,
  };

  static IdiomManualException fromJson(Map<String, Object?> json) =>
      IdiomManualException.validated(
        exceptionId: json['exceptionId']! as String,
        idiomId: json['idiomId']! as String,
        kind: IdiomConsistencyKind.fromName(json['kind'] as String?),
        reason: json['reason']! as String,
        eventScope: json['eventScope'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdiomManualException &&
          other.exceptionId == exceptionId &&
          other.idiomId == idiomId &&
          other.kind == kind &&
          other.reason == reason &&
          other.eventScope == eventScope);

  @override
  int get hashCode =>
      Object.hash(exceptionId, idiomId, kind, reason, eventScope);

  @override
  String toString() => 'IdiomManualException($exceptionId, $idiomId)';
}

/// Laporan hasil validasi satu ledger. Immutable — [validate] membangun
/// salinan isu dengan flag suppressed; sumber (registry/usage/tone/ledger)
/// tidak pernah dimutasi.
class IdiomConsistencyReport {
  const IdiomConsistencyReport._(this._issues, this._eventScope);

  /// Membangun laporan: issueId harus unik; disimpan terurut issueId.
  factory IdiomConsistencyReport.of(
    List<IdiomConsistencyIssue> issues, {
    List<String> eventScope = const <String>[],
  }) {
    final seen = <String>{};
    for (final i in issues) {
      if (!seen.add(i.issueId)) {
        throw ArgumentError('duplicate issueId: ${i.issueId}');
      }
    }
    final sorted = List<IdiomConsistencyIssue>.of(issues)
      ..sort((a, b) => a.issueId.compareTo(b.issueId));
    final sortedScope = List<String>.of(eventScope)..sort();
    return IdiomConsistencyReport._(
      List<IdiomConsistencyIssue>.unmodifiable(sorted),
      List<String>.unmodifiable(sortedScope),
    );
  }

  final List<IdiomConsistencyIssue> _issues;
  final List<String> _eventScope;

  /// Seluruh isu (aktif + tertekan), terurut issueId.
  List<IdiomConsistencyIssue> get issues => _issues;

  /// Kejadian yang ikut diperiksa (terurut eventId).
  List<String> get eventScope => _eventScope;

  List<IdiomConsistencyIssue> get activeIssues =>
      List<IdiomConsistencyIssue>.unmodifiable(
        _issues.where((i) => !i.suppressed),
      );

  List<IdiomConsistencyIssue> get suppressedIssues =>
      List<IdiomConsistencyIssue>.unmodifiable(
        _issues.where((i) => i.suppressed),
      );

  bool get hasIssues => activeIssues.isNotEmpty;

  int get issueCount => activeIssues.length;

  int get totalIssueCount => _issues.length;

  List<IdiomConsistencyIssue> issuesOf(IdiomConsistencyKind kind) =>
      List<IdiomConsistencyIssue>.unmodifiable(
        _issues.where((i) => i.kind == kind && !i.suppressed),
      );

  bool hasViolations(IdiomConsistencyKind kind) => issuesOf(kind).isNotEmpty;

  int suppressedCount(IdiomConsistencyKind kind) =>
      suppressedIssues.where((i) => i.kind == kind).length;

  /// Penjelasan untuk satu ungkapan (acceptance `explain_warning`).
  List<String> suggestionFor(String idiomId) {
    final needle = idiomId.trim();
    if (needle.isEmpty) return const <String>[];
    return List<String>.unmodifiable(
      activeIssues.where((i) => i.idiomId == needle).map((i) => i.message),
    );
  }

  /// Narasi laporan manusia-terbaca, deterministik.
  String describe() {
    final active = activeIssues;
    if (active.isEmpty) {
      if (suppressedIssues.isNotEmpty) {
        return 'Tanpa isu konsistensi aktif '
            '(${suppressedIssues.length} ditekan pengecualian manual).';
      }
      return 'Tanpa isu konsistensi ungkapan aktif.';
    }
    final buffer = StringBuffer('Isu konsistensi ungkapan:');
    for (final i in active) {
      buffer.write(' [${i.kind.label}] ${i.message}');
    }
    if (suppressedIssues.isNotEmpty) {
      buffer.write(
        ' (${suppressedIssues.length} ditekan pengecualian manual).',
      );
    }
    return buffer.toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'issues': _issues.map((i) => i.toJson()).toList(),
    'eventScope': _eventScope,
  };

  static IdiomConsistencyReport fromJson(Map<String, Object?> json) =>
      IdiomConsistencyReport.of(<IdiomConsistencyIssue>[
        for (final raw in (json['issues']! as List<Object?>))
          IdiomConsistencyIssue.fromJson(
            (raw! as Map<Object?, Object?>).cast<String, Object?>(),
          ),
      ], eventScope: (json['eventScope']! as List<Object?>).cast<String>());

  @override
  String toString() =>
      'IdiomConsistencyReport(${activeIssues.length} active, '
      '${suppressedIssues.length} suppressed)';
}

/// Validator deterministik konsistensi + anakronisme ungkapan. Murni statis:
/// tidak ada state global, tidak ada jalur tulis persistence —
/// `manual_exception` hanya menandai isu pada SALINAN laporan.
class IdiomConsistencyValidator {
  const IdiomConsistencyValidator();

  /// Periksa seluruh kejadian dalam [events] terhadap profil [usage] dan
  /// [tone] opsional (nada untuk character_check); [characters] dipakai
  /// untuk character_check;
  /// [eventScope] membatasi pemeriksaan kejadian ke eventId terpilih;
  /// [exceptions] menekan isu yang diterima manual.
  ///
  /// Guard: [usage] wajib berisi profil, setiap profil usage dan setiap
  /// exception harus merujuk idiom terdaftar di ledger; setiap eventId di
  /// [eventScope] harus ada di ledger.
  static IdiomConsistencyReport validate({
    required IdiomUsageCatalog usage,
    IdiomToneCatalog? tone,
    required List<CharacterVoiceProfile> characters,
    required IdiomUsageLedger events,
    Set<String>? eventScope,
    List<IdiomManualException> exceptions = const <IdiomManualException>[],
  }) {
    if (usage.profileCount == 0) {
      throw ArgumentError('usage catalog must contain at least one profile');
    }
    final registry = events.records;
    for (final p in usage.profiles) {
      if (registry.recordFor(p.idiomId) == null) {
        throw ArgumentError(
          'usage profile references unknown idiomId: ${p.idiomId}',
        );
      }
    }
    for (final x in exceptions) {
      if (registry.recordFor(x.idiomId) == null) {
        throw ArgumentError(
          'manual exception references unknown idiomId: ${x.idiomId}',
        );
      }
    }
    final scopeIds = <String>[];
    if (eventScope == null) {
      scopeIds.addAll(events.events.map((e) => e.eventId));
    } else {
      for (final id in eventScope) {
        final trimmed = _requireTrimmed(id, 'eventScope entry');
        if (!events.hasEvent(trimmed)) {
          throw ArgumentError(
            'eventScope references unknown eventId: $trimmed',
          );
        }
        scopeIds.add(trimmed);
      }
    }

    final raw = <IdiomConsistencyIssue>[
      ..._structuralIssues(registry),
      ..._eventIssues(
        usage: usage,
        tone: tone,
        characters: characters,
        events: events,
        scopeIds: scopeIds,
      ),
    ];

    final flagged = raw
        .map((i) {
          final suppressed = exceptions.any((x) => x.suppressesForIssue(i));
          return suppressed ? i._copyWithSuppressed(true) : i;
        })
        .toList(growable: false);

    return IdiomConsistencyReport.of(flagged, eventScope: scopeIds);
  }

  // --- checks struktural registri (tanpa kejadian) -------------------------

  static List<IdiomConsistencyIssue> _structuralIssues(IdiomRegistry registry) {
    final issues = <IdiomConsistencyIssue>[];
    final meaningGroups = <String, List<IdiomRecord>>{};
    final textGroups = <String, List<IdiomRecord>>{};
    for (final r in registry.records) {
      final meaningKey = normalizeIdiomText(r.meaning);
      if (_isContentless(r.meaning)) {
        issues.add(
          IdiomConsistencyIssue.validated(
            idiomId: r.idiomId,
            kind: IdiomConsistencyKind.meaning,
            message: 'Arti tidak tercatat untuk ungkapan ini.',
          ),
        );
      } else {
        (meaningGroups[meaningKey] ??= <IdiomRecord>[]).add(r);
      }
      (textGroups[r.normalizedText] ??= <IdiomRecord>[]).add(r);
    }
    for (final group in meaningGroups.values) {
      if (group.length < 2) continue;
      for (final r in group) {
        final others =
            group
                .where((o) => o.idiomId != r.idiomId)
                .map((o) => o.idiomId)
                .toList()
              ..sort();
        issues.add(
          IdiomConsistencyIssue.validated(
            idiomId: r.idiomId,
            kind: IdiomConsistencyKind.meaning,
            message:
                'Arti identik dengan ungkapan lain — terkait: '
                '${others.join(', ')}.',
          ),
        );
      }
    }
    for (final group in textGroups.values) {
      if (group.length < 2) continue;
      for (final r in group) {
        issues.add(
          IdiomConsistencyIssue.validated(
            idiomId: r.idiomId,
            kind: IdiomConsistencyKind.meaning,
            message: 'Teks identical dengan ungkapan lain dalam registri.',
          ),
        );
      }
    }
    return issues;
  }

  // --- checks berbasis kejadian (culture/era/character/text) ---------------

  static List<IdiomConsistencyIssue> _eventIssues({
    required IdiomUsageCatalog usage,
    required IdiomToneCatalog? tone,
    required List<CharacterVoiceProfile> characters,
    required IdiomUsageLedger events,
    required List<String> scopeIds,
  }) {
    final issues = <IdiomConsistencyIssue>[];
    final charactersById = <String, CharacterVoiceProfile>{
      for (final c in characters) c.characterId: c,
    };
    final selected = scopeIds.toSet();
    for (final e in events.events) {
      if (!selected.contains(e.eventId)) continue;
      final record = events.records.recordFor(e.idiomId)!;
      final profile = usage.profileFor(e.idiomId);

      // culture_check — budaya kejadian vs facet budaya profil (predikat 111.34).
      final eventCulture = e.cultureId;
      if (profile != null && eventCulture != null) {
        if (profile.avoidedByCulture(eventCulture)) {
          issues.add(
            IdiomConsistencyIssue.validated(
              idiomId: e.idiomId,
              kind: IdiomConsistencyKind.culture,
              message: 'Budaya $eventCulture menghindari ungkapan ini.',
              relatedId: e.eventId,
            ),
          );
        } else if (!profile.usedByCulture(eventCulture)) {
          final listed = profile.cultures.map((c) => c.cultureId).toList()
            ..sort();
          issues.add(
            IdiomConsistencyIssue.validated(
              idiomId: e.idiomId,
              kind: IdiomConsistencyKind.culture,
              message:
                  'Budaya $eventCulture tidak tercatat memakai ungkapan '
                  'ini (budaya terdaftar: ${listed.join(', ')}).',
              relatedId: e.eventId,
            ),
          );
        }
      }

      // era_check — pemakaian di luar rentang era yang dicatat (anakronisme).
      if (profile != null &&
          e.hasMarker &&
          !profile.activeAtMarker(e.atMarker)) {
        final labels = profile.eras.map((x) => x.label).toList()..sort();
        issues.add(
          IdiomConsistencyIssue.validated(
            idiomId: e.idiomId,
            kind: IdiomConsistencyKind.era,
            message:
                'Pemakaian pada marker ${e.atMarker} berada di luar '
                'rentang era terdaftar: ${labels.join(', ')}.',
            relatedId: e.eventId,
          ),
        );
      }

      // character_check — profil suara karakter vs kepemilikan budaya + nada.
      final charId = e.characterId;
      if (charId != null) {
        final character = charactersById[charId];
        if (character != null) {
          final charCulture = character.cultureId;
          if (profile != null &&
              charCulture != null &&
              profile.cultures.isNotEmpty &&
              !profile.usedByCulture(charCulture)) {
            issues.add(
              IdiomConsistencyIssue.validated(
                idiomId: e.idiomId,
                kind: IdiomConsistencyKind.character,
                message:
                    'Karakter $charId (budaya $charCulture) memakai '
                    'ungkapan dari budaya yang tidak tercatat.',
                relatedId: charId,
              ),
            );
          }
          if (tone != null) {
            final toneProfile = tone.profileFor(e.idiomId);
            if (toneProfile != null && character.avoidsTone(toneProfile.tone)) {
              issues.add(
                IdiomConsistencyIssue.validated(
                  idiomId: e.idiomId,
                  kind: IdiomConsistencyKind.character,
                  message:
                      'Karakter $charId menghindari nada '
                      '${toneProfile.tone.label} yang melekat pada ungkapan '
                      'ini.',
                  relatedId: charId,
                ),
              );
            }
          }
        }
      }

      // meaning_check (permukaan) — teks kejadian tidak cocok kanon/varian.
      if (e.hasOccurrence && e.matchedTextId(record) == null) {
        issues.add(
          IdiomConsistencyIssue.validated(
            idiomId: e.idiomId,
            kind: IdiomConsistencyKind.meaning,
            message:
                'Teks kejadian "${e.text}" tidak cocok dengan kanon '
                'maupun varian terdaftar.',
            relatedId: e.eventId,
          ),
        );
      }
    }
    return issues;
  }
}
