/// Kontrak Character Interview Workspace (Step 109.15).
///
/// Sesi wawancara orang pertama di Character Workspace sebagai sumber
/// profil karakter kanonis. Lima kemampuan kanonik sprint_109.json:
/// 1. **question_sets** — kumpulan pertanyaan tervalidasi (schema
///    deterministik: judul, prompt kosong, ID ganda);
/// 2. **first_person_answers** — jawaban verbatim orang-pertama per
///    pertanyaan, satu jawaban per pasangan sesi–pertanyaan;
/// 3. **session_history** — riwayat sesi per karakter terurut kronologis
///    dengan ID deterministik dari karakter + waktu mulai;
/// 4. **manual_edit** — penyuntingan jawaban manusia dengan riwayat revisi
///    yang dirawat, tanpa menimpa jejak jawaban asli;
/// 5. **source_provenance** — jejak sumber setiap atribut profil: sesi,
///    karakter, pertanyaan, waktu tangkap, waktu edit, jumlah revisi.
///
/// Modul ini domain murni: tanpa Drift dan tanpa UI. Persistensi ke
/// penyimpanan proyek dan penyambangan ke layar Character Workspace adalah
/// pekerjaan langkah integrasi tersendiri.
library;

/// Satu pertanyaan wawancara.
class InterviewQuestion {
  const InterviewQuestion({required this.id, required this.prompt});

  final String id;

  /// Teks pertanyaan orang-pertama, misal "Dari mana kamu berasal?".
  final String prompt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'prompt': prompt,
  };

  static InterviewQuestion fromJson(Map<String, Object?> json) =>
      InterviewQuestion(
        id: json['id']! as String,
        prompt: json['prompt']! as String,
      );
}

/// Kumpulan pertanyaan untuk satu skema wawancara.
class InterviewQuestionSet {
  const InterviewQuestionSet({
    required this.id,
    required this.title,
    required this.questions,
  });

  final String id;
  final String title;
  final List<InterviewQuestion> questions;

  /// Memvalidasi bentuk set; mengembalikan daftar masalah bernama
  /// (kosong berarti sah). Urutan pemeriksaan deterministik: judul,
  /// lalu tiap pertanyaan berurutan, lalu duplikasi ID.
  List<String> validateSchema() {
    final problems = <String>[];
    if (title.trim().isEmpty) problems.add('title must not be blank');
    final seen = <String>{};
    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      if (question.id.isEmpty) {
        problems.add('question[$i].id must not be blank');
      }
      if (question.prompt.trim().isEmpty) {
        problems.add('question[$i].prompt must not be blank');
      }
      if (question.id.isNotEmpty && !seen.add(question.id)) {
        problems.add('duplicate question id: ${question.id}');
      }
    }
    return problems;
  }

  InterviewQuestion? questionOf(String questionId) {
    for (final question in questions) {
      if (question.id == questionId) return question;
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'title': title,
    'questions': <Object?>[for (final q in questions) q.toJson()],
  };

  static InterviewQuestionSet fromJson(Map<String, Object?> json) =>
      InterviewQuestionSet(
        id: json['id']! as String,
        title: json['title']! as String,
        questions: (json['questions']! as List<Object?>)
            .whereType<Map<Object?, Object?>>()
            .map(
              (raw) => InterviewQuestion.fromJson(
                raw.map((k, v) => MapEntry(k.toString(), v)),
              ),
            )
            .toList(growable: false),
      );
}

/// Jawaban orang-pertama untuk satu pertanyaan dalam sebuah sesi.
class CharacterInterviewEntry {
  const CharacterInterviewEntry({
    required this.questionId,
    required this.questionPrompt,
    required this.answer,
    required this.answeredAt,
    this.editedAt,
    this.revisions = const <String>[],
  });

  final String questionId;
  final String questionPrompt;

  /// Jawaban terkini (verbatim hasil suntingan manual bila pernah diedit).
  final String answer;
  final DateTime answeredAt;

  /// Waktu suntingan terakhir; null bila belum pernah diedit.
  final DateTime? editedAt;

  /// Jawaban-jawaban sebelumnya, urut kronologis (paling awal dulu).
  final List<String> revisions;

  bool get isEdited => editedAt != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'questionId': questionId,
    'questionPrompt': questionPrompt,
    'answer': answer,
    'answeredAt': answeredAt.toIso8601String(),
    'editedAt': editedAt?.toIso8601String(),
    'revisions': <Object?>[for (final r in revisions) r],
  };

  static CharacterInterviewEntry fromJson(Map<String, Object?> json) =>
      CharacterInterviewEntry(
        questionId: json['questionId']! as String,
        questionPrompt: json['questionPrompt']! as String,
        answer: json['answer']! as String,
        answeredAt: DateTime.parse(json['answeredAt']! as String),
        editedAt: json['editedAt'] == null
            ? null
            : DateTime.parse(json['editedAt']! as String),
        revisions: <String>[
          for (final r
              in json['revisions'] as List<Object?>? ?? const <Object?>[])
            r! as String,
        ],
      );
}

/// Jejak sumber kanonis satu atribut profil karakter.
class CharacterInterviewProvenance {
  const CharacterInterviewProvenance({
    required this.sessionId,
    required this.characterId,
    required this.questionId,
    required this.capturedAt,
    required this.revisionCount,
    this.editedAt,
  });

  /// Provenance kosong untuk pertanyaan yang belum terjawab/tak dikenal.
  CharacterInterviewProvenance.blank()
    : sessionId = '',
      characterId = '',
      questionId = '',
      capturedAt = DateTime.utc(1970),
      editedAt = null,
      revisionCount = 0;

  final String sessionId;
  final String characterId;
  final String questionId;
  final DateTime capturedAt;
  final DateTime? editedAt;
  final int revisionCount;
}

/// Satu sesi wawancara orang-pertama dengan satu karakter.
class CharacterInterviewSession {
  CharacterInterviewSession._(
    this.id,
    this.characterId,
    this.questionSet,
    this.startedAt,
    this._clock,
  );

  /// Membuka sesi baru. ID deterministik dari karakter + waktu buka agar
  /// riwayat antar-rebuild tetap konsisten.
  ///
  /// [openedAt] adalah waktu buka eksplisit dan TIDAK mengonsumsi tick
  /// [clock]; jam suntikan hanya dipakai untuk cap aksi (jawaban/suntingan).
  factory CharacterInterviewSession.start({
    required String characterId,
    required InterviewQuestionSet questionSet,
    DateTime? openedAt,
    DateTime Function()? clock,
  }) {
    final effectiveClock = clock ?? DateTime.now;
    final startedAt = openedAt ?? effectiveClock();
    return CharacterInterviewSession._(
      '$characterId::${startedAt.toIso8601String()}',
      characterId,
      questionSet,
      startedAt,
      effectiveClock,
    );
  }

  final String id;
  final String characterId;
  final InterviewQuestionSet questionSet;
  final DateTime startedAt;
  final DateTime Function() _clock;
  final Map<String, CharacterInterviewEntry> _entries =
      <String, CharacterInterviewEntry>{};

  /// Entri jawaban dalam urutan perekaman.
  List<CharacterInterviewEntry> get entries =>
      List.unmodifiable(_entries.values);

  CharacterInterviewEntry? entryFor(String questionId) => _entries[questionId];

  /// Merekam jawaban orang-pertama verbatim. Pertanyaan tak dikenal atau
  /// teks kosong ditolak [ArgumentError]; jawaban ganda ditolak
  /// [StateError] (gunakan [editAnswer]).
  CharacterInterviewEntry answer(String questionId, {required String text}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be blank');
    }
    final question = questionSet.questionOf(questionId);
    if (question == null) {
      throw ArgumentError.value(questionId, 'questionId', 'unknown question');
    }
    if (_entries.containsKey(questionId)) {
      throw StateError('question $questionId already answered');
    }
    final entry = CharacterInterviewEntry(
      questionId: questionId,
      questionPrompt: question.prompt,
      answer: trimmed,
      answeredAt: _clock(),
    );
    _entries[questionId] = entry;
    return entry;
  }

  /// Menyunting jawaban secara manual; jawaban lama masuk riwayat revisi.
  /// Pertanyaan belum terjawab ditolak [StateError], teks kosong ditolak
  /// [ArgumentError].
  CharacterInterviewEntry editAnswer(
    String questionId, {
    required String newText,
  }) {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(newText, 'newText', 'must not be blank');
    }
    final entry = _entries[questionId];
    if (entry == null) {
      throw StateError('question $questionId has no answer to edit');
    }
    final updated = CharacterInterviewEntry(
      questionId: entry.questionId,
      questionPrompt: entry.questionPrompt,
      answer: trimmed,
      answeredAt: entry.answeredAt,
      editedAt: _clock(),
      revisions: <String>[...entry.revisions, entry.answer],
    );
    _entries[questionId] = updated;
    return updated;
  }

  /// Jejak sumber kanonis jawaban suatu pertanyaan; [blank] bila belum
  /// terjawab atau pertanyaan tidak dikenal.
  CharacterInterviewProvenance provenanceFor(String questionId) {
    final entry = _entries[questionId];
    if (entry == null) return CharacterInterviewProvenance.blank();
    return CharacterInterviewProvenance(
      sessionId: id,
      characterId: characterId,
      questionId: questionId,
      capturedAt: entry.answeredAt,
      editedAt: entry.editedAt,
      revisionCount: entry.revisions.length,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'characterId': characterId,
    'questionSet': questionSet.toJson(),
    'startedAt': startedAt.toIso8601String(),
    'entries': <Object?>[for (final e in _entries.values) e.toJson()],
  };

  static CharacterInterviewSession fromJson(Map<String, Object?> json) {
    final session = CharacterInterviewSession._(
      json['id']! as String,
      json['characterId']! as String,
      InterviewQuestionSet.fromJson(
        (json['questionSet']! as Map<Object?, Object?>).map(
          (k, v) => MapEntry(k.toString(), v),
        ),
      ),
      DateTime.parse(json['startedAt']! as String),
      DateTime.now, // tak dipakai ulang pada sesi hasil restorasi
    );
    final entries = json['entries'];
    if (entries is List<Object?>) {
      for (final raw in entries.whereType<Map<Object?, Object?>>()) {
        final entry = CharacterInterviewEntry.fromJson(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
        session._entries[entry.questionId] = entry;
      }
    }
    return session;
  }
}

/// Riwayat sesi wawancara lintas karakter.
class CharacterInterviewLog {
  final List<CharacterInterviewSession> _sessions =
      <CharacterInterviewSession>[];

  /// Semua sesi dalam urutan pendaftaran.
  List<CharacterInterviewSession> get all => List.unmodifiable(_sessions);

  void add(CharacterInterviewSession session) => _sessions.add(session);

  /// Sesi milik satu karakter, terurut kronologis dari waktu mulai.
  List<CharacterInterviewSession> sessionsFor(String characterId) {
    final filtered = <CharacterInterviewSession>[
      for (final s in _sessions)
        if (s.characterId == characterId) s,
    ]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return filtered;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'sessions': <Object?>[for (final s in _sessions) s.toJson()],
  };

  static CharacterInterviewLog fromJson(Map<String, Object?> json) {
    final log = CharacterInterviewLog();
    final sessions = json['sessions'];
    if (sessions is List<Object?>) {
      for (final raw in sessions.whereType<Map<Object?, Object?>>()) {
        log.add(
          CharacterInterviewSession.fromJson(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          ),
        );
      }
    }
    return log;
  }
}
