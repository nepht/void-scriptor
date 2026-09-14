/// Kontrak Word Targets & Session Progress (Step 109.21).
///
/// Pelacak target kata dan kemajuan sesian sebagai domain murni
/// (tanpa DB/UI). Lima kemampuan kanonik sprint_109.json:
/// 1. **target_levels** — target per sesi, adegan, bab, dan project
///    ditetapkan terpisah;
/// 2. **live_progress** — kemajuan hidup (tertulis/sisa/fraksi) akurat
///    saat menulis bertahap;
/// 3. **session_reset** — reset menyentuh lingkup sesian saja; progres
///    adegan/bab/project utuh;
/// 4. **history** — setiap mutasi tercatat kronologis dengan jam
///    tersuntik;
/// 5. **timezone_safe** — kunci hari lokal diturunkan dari instan UTC +
///    offset menit eksplisit, bukan zona jam host.
library;

/// Tingkat lingkup target kata.
enum WordTargetLevel {
  /// Sesi menulis harian.
  session,

  /// Adegan tunggal.
  scene,

  /// Bab penuh.
  chapter,

  /// Keseluruhan proyek.
  project,
}

/// Kunci hari kalender lokal yang deterministik lintas mesin.
class WordTargetDayStamp {
  const WordTargetDayStamp({required this.dayKey});

  /// Bentuk 'yyyy-MM-dd'.
  final String dayKey;

  /// Menurunkan kunci hari dari instan UTC plus offset menit eksplisit
  /// zona penulis; tidak pernah membaca zona jam host.
  ///
  /// [utcInstant] wajib berstatus UTC ([ArgumentError] bila non-UTC):
  /// `DateTime` lokal sudah membawa offset host sehingga hasil pergeseran
  /// menjadi salah basis (vs-hunt-20260914-story STORY-08).
  static WordTargetDayStamp fromUtcInstant(
    DateTime utcInstant, {
    required int offsetMinutes,
  }) {
    if (!utcInstant.isUtc) {
      throw ArgumentError.value(
        utcInstant,
        'utcInstant',
        'must be UTC; use DateTime.utc or toUtc()',
      );
    }
    final shifted = utcInstant.add(Duration(minutes: offsetMinutes));
    final y = shifted.year.toString().padLeft(4, '0');
    final m = shifted.month.toString().padLeft(2, '0');
    final d = shifted.day.toString().padLeft(2, '0');
    return WordTargetDayStamp(dayKey: '$y-$m-$d');
  }

  Map<String, Object?> toJson() => <String, Object?>{'dayKey': dayKey};
}

/// Kemajuan sebuah lingkup target.
class WordTargetProgress {
  const WordTargetProgress({required this.target, required this.written});

  final int target;
  final int written;

  /// Kata yang masih dibutuhkan untuk mencapai target.
  int get remaining => target > written ? target - written : 0;

  /// Fraksi kemajuan dalam [0..1]; 0 bila target belum ditetapkan.
  double get fraction => target <= 0 ? 0 : (written / target).clamp(0.0, 1.0);
}

/// Satu kejadian riwayat pelacak.
class WordTargetEvent {
  const WordTargetEvent({required this.at, required this.summary});

  final DateTime at;
  final String summary;
}

class _ScopeState {
  int target = 0;
  int written = 0;
}

/// Pelacak target kata multi-tingkat; murni domain, serialisasi UI/DB
/// menyusul di lapisan integrasi.
class WordTargetTracker {
  WordTargetTracker({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final Map<WordTargetLevel, Map<String, _ScopeState>> _states =
      <WordTargetLevel, Map<String, _ScopeState>>{
        WordTargetLevel.session: <String, _ScopeState>{},
        WordTargetLevel.scene: <String, _ScopeState>{},
        WordTargetLevel.chapter: <String, _ScopeState>{},
        WordTargetLevel.project: <String, _ScopeState>{},
      };
  final List<WordTargetEvent> _events = <WordTargetEvent>[];

  /// Riwayat mutasi kronologis.
  List<WordTargetEvent> get history => List.unmodifiable(_events);

  /// Menetapkan/mengganti target pada satu lingkup; [ArgumentError]
  /// bila scopeKey kosong atau words bukan bilangan positif.
  void setTarget({
    required WordTargetLevel level,
    required String scopeKey,
    required int words,
  }) {
    if (scopeKey.trim().isEmpty) {
      throw ArgumentError('scopeKey must not be blank');
    }
    if (words <= 0) {
      throw ArgumentError('words must be positive');
    }
    final state = _stateFor(level, scopeKey);
    state.target = words;
    _events.add(
      WordTargetEvent(
        at: _clock(),
        summary: 'target: ${level.name}:$scopeKey=$words',
      ),
    );
  }

  /// Menambah hitungan kata tertulis pada satu lingkup; [ArgumentError]
  /// bila scopeKey kosong/blank (setidaknya satu non-spasi) atau count
  /// bukan bilangan positif — guard yang sama dengan [setTarget].
  void recordWords({
    required WordTargetLevel level,
    required String scopeKey,
    required int count,
  }) {
    if (scopeKey.trim().isEmpty) {
      throw ArgumentError('scopeKey must not be blank');
    }
    if (count <= 0) {
      throw ArgumentError('count must be positive');
    }
    final state = _stateFor(level, scopeKey);
    state.written += count;
    _events.add(
      WordTargetEvent(
        at: _clock(),
        summary: 'write: ${level.name}:$scopeKey+$count',
      ),
    );
  }

  /// Mengosongkan kemajuan seluruh lingkup sesi; target sesi dipertahankan
  /// dan progres tingkat lain tak tersentuh.
  void resetSession() {
    for (final state in _states[WordTargetLevel.session]!.values) {
      state.written = 0;
    }
    _events.add(WordTargetEvent(at: _clock(), summary: 'reset: session'));
  }

  /// Kemajuan saat ini untuk satu lingkup; target 0 bila belum ada.
  WordTargetProgress progressFor({
    required WordTargetLevel level,
    required String scopeKey,
  }) {
    final state = _states[level]?[scopeKey] ?? (_ScopeState()..target = 0);
    return WordTargetProgress(target: state.target, written: state.written);
  }

  _ScopeState _stateFor(WordTargetLevel level, String scopeKey) =>
      _states[level]!.putIfAbsent(scopeKey, _ScopeState.new);
}
