/// Kontrak Focus Writing Mode (Step 109.20).
///
/// Sesi menulis minim distraksi sebagai domain murni (tanpa DB/UI):
/// mesin keadaan chrome/kontrol, alasan keluar, status autosave
/// berlabel, dukungan tema, dan label semantik untuk screen reader.
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **distraction_free** — masuk mode menyembunyikan chrome; kontrol
///    inti tetap terdaftar dan dapat diakses;
/// 2. **keyboard_exit** — keluar bisa via keyboard; alasannya tercatat
///    (keyboard vs manual);
/// 3. **autosave_visible** — status tersimpan/belum selalu akurat pada
///    tiap transisi, dengan jam tersuntik;
/// 4. **theme_support** — tema fokus dapat diganti kapan pun termasuk
///    saat sesi aktif;
/// 5. **screen_reader_access** — setiap kontrol inti punya label
///    semantik; perubahan mode diumumkan.
library;

/// Alasan keluar dari mode fokus.
enum FocusExitReason {
  /// Keluar lewat pintasan keyboard.
  keyboard,

  /// Keluar lewat tombol/manual.
  manual,
}

/// Tema ruang fokus.
enum FocusTheme {
  /// Ikuti tema sistem.
  system,

  /// Terang seperti kertas.
  paper,

  /// Gelap rendah kontras.
  dark,
}

/// Satu pengumuman aksesibilitas.
class FocusAnnouncement {
  const FocusAnnouncement({required this.at, required this.message});

  final DateTime at;
  final String message;
}

/// Mesin keadaan sesi menulis fokus. Murni domain; UI memakai nilai-nilai
/// ini untuk merender chrome, label autosave, tema, dan semantik.
class FocusWritingSession {
  FocusWritingSession({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  bool _active = false;
  bool _chromeVisible = true;
  bool _dirty = false;
  DateTime? _lastSavedAt;
  FocusExitReason? _lastExitReason;
  FocusTheme _theme = FocusTheme.system;
  final List<FocusAnnouncement> _announcements = <FocusAnnouncement>[];

  /// Apakah sesi fokus sedang aktif.
  bool get isActive => _active;

  /// Chrome editor (panel/sidebars) terlihat atau tidak.
  bool get chromeVisible => _chromeVisible;

  /// Ada keadaan naskah yang belum tersimpan lewat jalur ini —
  /// termasuk sesi yang belum pernah menyimpan sama sekali.
  bool get isDirty => _dirty || _lastSavedAt == null;

  /// Waktu simpan terakhir; null bila belum pernah menyimpan.
  DateTime? get lastSavedAt => _lastSavedAt;

  /// Alasan keluar terakhir; hanya bermakna setelah keluar.
  FocusExitReason? get lastExitReason => _lastExitReason;

  /// Tema fokus aktif.
  FocusTheme get theme => _theme;

  /// Pengumuman aksesibilitas kronologis.
  List<FocusAnnouncement> get announcements =>
      List.unmodifiable(_announcements);

  /// Label autosave yang selalu akurat terhadap keadaan.
  String get autosaveLabel {
    if (_dirty || _lastSavedAt == null) return 'Belum tersimpan';
    final hh = _lastSavedAt!.hour.toString().padLeft(2, '0');
    final mm = _lastSavedAt!.minute.toString().padLeft(2, '0');
    return 'Tersimpan $hh:$mm';
  }

  /// Label semantik untuk kontrol inti — wajib ada walau chrome hilang.
  static const Map<String, String> controlLabels = <String, String>{
    'exit': 'Keluar dari mode fokus',
    'autosaveStatus': 'Status penyimpanan otomatis',
    'theme': 'Ganti tema fokus',
  };

  /// Memasuki mode fokus; [StateError] bila sudah aktif.
  void enter() {
    if (_active) {
      throw StateError('focus session already active');
    }
    _active = true;
    _chromeVisible = false;
    _announce('Mode fokus dimulai; tekan pintasan keluar untuk meninggalkan.');
  }

  /// Keluar dari mode fokus; [StateError] bila tidak sedang aktif.
  void exit({bool viaKeyboard = false}) {
    if (!_active) {
      throw StateError('no active focus session');
    }
    _active = false;
    _chromeVisible = true;
    _lastExitReason = viaKeyboard
        ? FocusExitReason.keyboard
        : FocusExitReason.manual;
    _announce('Keluar dari mode fokus.');
  }

  /// Menandai ada suntingan baru yang belum tersimpan.
  void edit() {
    if (!_active) {
      throw StateError('no active focus session');
    }
    _dirty = true;
  }

  /// Menandai autosave selesai pada jam tersuntik.
  void markSaved() {
    if (!_active) {
      throw StateError('no active focus session');
    }
    _dirty = false;
    _lastSavedAt = _clock();
  }

  /// Mengganti tema fokus kapan pun.
  void setTheme(FocusTheme next) => _theme = next;

  void _announce(String message) {
    _announcements.add(FocusAnnouncement(at: _clock(), message: message));
  }
}
