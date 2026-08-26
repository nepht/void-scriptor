/// Kontrak Scene POV Lock (Step 109.33).
///
/// Kunci POV, tense, dan mode narasi per adegan/bagian sebagai domain
/// murni (tanpa DB/UI). Lima kemampuan kanonik sprint_109.json:
/// 1. **scene_pov** — POV terkunci per adegan; kunci ulang berbeda
///    ditolak;
/// 2. **section_override** — bagian mewarisi kunci adegan kecuali
///    di-override eksplisit;
/// 3. **tense** — tense narasi terekam per adegan;
/// 4. **narration_mode** — mode narasi wajib eksplisit (tanpa default
///    diam-diam);
/// 5. **visible_status** — status kunci terlihat per adegan.
library;

/// Mode sudut pandang narasi.
enum PovMode { firstPerson, thirdLimited, thirdOmniscient }

/// Tense narasi.
enum NarrativeTense { past, present }

/// Status kunci POV sebuah adegan.
enum PovStatus {
  /// Belum pernah dikunci.
  unset,

  /// Terkunci (atau ter-override lewat bagian).
  locked,

  /// Sengaja dibuka setelah sebelumnya terkunci.
  unlocked,
}

/// Kunci POV satu adegan (nilai immutable).
class ScenePovLock {
  const ScenePovLock({
    required this.povCharacterId,
    required this.mode,
    required this.tense,
    this.fromSection,
  });

  final String povCharacterId;
  final PovMode mode;
  final NarrativeTense tense;

  /// Id bagian bila nilai ini datang dari override bagian.
  final String? fromSection;
}

/// Ledger kunci POV lintas adegan dan bagian; murni domain.
class PovLedger {
  final Map<String, ScenePovLock> _sceneLocks = <String, ScenePovLock>{};

  /// Adegan yang sengaja dibuka setelah terkunci.
  final Set<String> _unlockedScenes = <String>{};

  final Map<String, List<String>> _sections = <String, List<String>>{};

  /// Mengunci POV satu adegan; [mode] wajib disebut ([ArgumentError]
  /// bila tidak). Kunci ulang saat masih terkunci ditolak
  /// [StateError]; adegan berstatus unlocked boleh dikunci lagi dan
  /// kembali `locked`.
  void lockScene({
    required String sceneId,
    required String povCharacterId,
    PovMode? mode,
    NarrativeTense tense = NarrativeTense.past,
  }) {
    if (mode == null) {
      throw ArgumentError('narration mode must be explicit');
    }
    if (_sceneLocks.containsKey(sceneId) &&
        !_unlockedScenes.contains(sceneId)) {
      throw StateError('scene already locked: $sceneId');
    }
    _sceneLocks[sceneId] = ScenePovLock(
      povCharacterId: povCharacterId,
      mode: mode,
      tense: tense,
    );
    _unlockedScenes.remove(sceneId);
  }

  /// Membuka kunci satu adegan; hanya sah dari status locked
  /// ([StateError] bila belum ada kunci).
  void markUnlocked(String sceneId) {
    if (!_sceneLocks.containsKey(sceneId)) {
      throw StateError('scene has no lock to unlock: $sceneId');
    }
    _unlockedScenes.add(sceneId);
  }

  /// Mendefinisikan bagian berisi daftar adegan; anggota mewarisi
  /// kunci adegannya sendiri hingga di-override.
  void defineSection({
    required String sectionId,
    required List<String> sceneIds,
  }) {
    _sections[sectionId] = List.of(sceneIds);
  }

  /// Meng-override seluruh adegan anggota satu bagian sekaligus;
  /// nilai hasil override selalu berstatus locked.
  void overrideSection({
    required String sectionId,
    required String povCharacterId,
    required PovMode mode,
    NarrativeTense tense = NarrativeTense.past,
  }) {
    final members = _sections[sectionId];
    if (members == null) {
      throw StateError('unknown section: $sectionId');
    }
    for (final sceneId in members) {
      _sceneLocks[sceneId] = ScenePovLock(
        povCharacterId: povCharacterId,
        mode: mode,
        tense: tense,
        fromSection: sectionId,
      );
      _unlockedScenes.remove(sceneId);
    }
  }

  /// Kunci langsung milik adegan (tanpa warisan bagian).
  ScenePovLock? povOf(String sceneId) => _sceneLocks[sceneId];

  /// POV efektif: sama dengan [povOf]; struktur siap untuk aturan
  /// warisan lanjutan.
  ScenePovLock? effectivePovOf(String sceneId) => _sceneLocks[sceneId];

  /// Status kunci satu adegan; adegan tak dikenal `unset`.
  PovStatus statusOf(String sceneId) {
    if (!_sceneLocks.containsKey(sceneId)) return PovStatus.unset;
    return _unlockedScenes.contains(sceneId)
        ? PovStatus.unlocked
        : PovStatus.locked;
  }

  /// Status seluruh adegan yang dikenal ledger.
  Map<String, PovStatus> allStatuses() => <String, PovStatus>{
    for (final entry in _sceneLocks.entries) entry.key: statusOf(entry.key),
  };
}
