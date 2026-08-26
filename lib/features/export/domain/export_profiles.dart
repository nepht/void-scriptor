/// Kontrak Manuscript Export Profiles (Step 109.38).
///
/// Profil ekspor naskah DOCX / plain text / web novel sebagai domain
/// murni (tanpa DB/UI; render di sini hanya bentuk teks profil).
/// Lima kemampuan kanonik sprint_109.json:
/// 1. **profile_settings** — pengaturan format per target ekspor;
/// 2. **chapter_rules** — aturan bab: penomoran, awalan judul,
///    halaman baru;
/// 3. **scene_break_rules** — aturan pemisah adegan: marker + baris
///    kosong;
/// 4. **front_matter** — halaman muka: judul + pengarang;
/// 5. **saved_presets** — preset profil tersimpan: simpan (timpa),
///    muat, hapus, daftar terurut.
library;

/// Target format ekspor.
enum ExportFormat { docx, plainText, webNovel }

/// Aturan penomoran bab.
class ChapterRules {
  const ChapterRules({
    required this.numberingStart,
    required this.titlePrefix,
    required this.pageBreakBefore,
  });

  /// Angka awal penomoran bab (0 atau 1 lazim).
  final int numberingStart;
  final String titlePrefix;

  /// Bab selalu mulai halaman baru (DOCX).
  final bool pageBreakBefore;

  /// Judul bab ke-[n] (n = nomor urut tampil, bukan offset).
  String title(int displayNumber) {
    final prefix = titlePrefix.isEmpty ? '' : '$titlePrefix ';
    return '$prefix$displayNumber';
  }
}

/// Aturan pemisah adegan.
class SceneBreakRules {
  const SceneBreakRules({required this.blankLinesAroundBreak});

  /// Banyaknya baris kosong di sekitar marker pemisah.
  final int blankLinesAroundBreak;
}

/// Halaman muka dokumen.
class FrontMatter {
  const FrontMatter({required this.title, required this.author});

  final String title;
  final String author;
}

/// Profil ekspor satu target format; mutable lewat setter terjaga.
class ExportProfile {
  ExportProfile({
    required this.format,
    required String sceneBreakMarker,
    this.chapterRules,
    this.sceneBreakRules,
    this.frontMatter,
  }) : sceneBreakMarker = _requireMarker(sceneBreakMarker);

  static String _requireMarker(String marker) {
    if (marker.isEmpty) {
      throw ArgumentError('scene break marker cannot be empty');
    }
    return marker;
  }

  /// Profil DOCX bawaan.
  factory ExportProfile.docx() =>
      ExportProfile(format: ExportFormat.docx, sceneBreakMarker: '* * *')
        ..setChapterRules(
          numberingStart: 1,
          titlePrefix: 'Bab',
          pageBreakBefore: true,
        );

  /// Profil plain text bawaan.
  factory ExportProfile.plainText() =>
      ExportProfile(format: ExportFormat.plainText, sceneBreakMarker: '---');

  /// Profil web novel bawaan.
  factory ExportProfile.webNovel() => ExportProfile(
    format: ExportFormat.webNovel,
    sceneBreakMarker: '<div style="text-align:center">* * *</div>',
  )..setSceneBreakRules(blankLinesBetween: 1);

  final ExportFormat format;

  /// Marker antaradegan; wajib tak kosong ([ArgumentError] via
  /// konstruktor).
  final String sceneBreakMarker;

  ChapterRules? chapterRules;
  SceneBreakRules? sceneBreakRules;
  FrontMatter? frontMatter;

  /// Menetapkan aturan bab.
  void setChapterRules({
    required int numberingStart,
    required String titlePrefix,
    required bool pageBreakBefore,
  }) {
    if (numberingStart < 0) {
      throw ArgumentError('numbering start cannot be negative');
    }
    chapterRules = ChapterRules(
      numberingStart: numberingStart,
      titlePrefix: titlePrefix,
      pageBreakBefore: pageBreakBefore,
    );
  }

  /// Menetapkan aturan pemisah adegan; negatif [ArgumentError].
  void setSceneBreakRules({required int blankLinesBetween}) {
    if (blankLinesBetween < 0) {
      throw ArgumentError('blank lines cannot be negative');
    }
    sceneBreakRules = SceneBreakRules(blankLinesAroundBreak: blankLinesBetween);
  }

  /// Menetapkan halaman muka.
  void setFrontMatter({required String title, required String author}) {
    frontMatter = FrontMatter(title: title, author: author);
  }

  /// Bentuk teks halaman muka untuk pratinjau profil.
  String renderFrontMatter() {
    final fm = frontMatter;
    if (fm == null) return '';
    return '${fm.title}\n${fm.author}\n';
  }
}

/// Buku preset profil milik proyek/pengguna.
class ExportPresetBook {
  final Map<String, ExportProfile> _presets = <String, ExportProfile>{};

  /// Menyimpan preset; nama sama menimpa (preset milik pengguna).
  void save({required String name, required ExportProfile profile}) {
    _presets[name] = profile;
  }

  /// Memuat preset; nama tak dikenal [StateError].
  ExportProfile load(String name) {
    final profile = _presets[name];
    if (profile == null) {
      throw StateError('unknown preset: $name');
    }
    return profile;
  }

  /// Menghapus preset; nama tak dikenal [StateError].
  void delete(String name) {
    if (!_presets.containsKey(name)) {
      throw StateError('unknown preset: $name');
    }
    _presets.remove(name);
  }

  /// Nama preset terurut alfabet untuk UI.
  List<String> names() {
    final list = List<String>.of(_presets.keys)..sort();
    return List.unmodifiable(list);
  }
}
