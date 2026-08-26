/// Clean Export Transformation (Step 109.39).
///
/// Menghapus penanda internal dan catatan privat tanpa menormalisasi teks,
/// whitespace, line ending, atau struktur naskah di sekeliling penanda.
library;

/// Hasil immutable dari satu transformasi ekspor bersih.
class CleanExportResult {
  const CleanExportResult({
    required this.sourceText,
    required this.text,
    required this.removedInternalLinks,
    required this.removedPrivateNotes,
    required this.fingerprint,
  });

  /// Sumber asli, dipertahankan verbatim untuk audit tanpa mutasi.
  final String sourceText;

  /// Teks hasil transformasi.
  final String text;
  final int removedInternalLinks;
  final int removedPrivateNotes;

  /// Fingerprint FNV-1a 64-bit atas [text], stabil lintas proses.
  final String fingerprint;

  bool get wasChanged => sourceText != text;

  @override
  bool operator ==(Object other) =>
      other is CleanExportResult &&
      other.sourceText == sourceText &&
      other.text == text &&
      other.removedInternalLinks == removedInternalLinks &&
      other.removedPrivateNotes == removedPrivateNotes &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode => Object.hash(
    sourceText,
    text,
    removedInternalLinks,
    removedPrivateNotes,
    fingerprint,
  );
}

/// Transformer domain murni untuk menyiapkan naskah publik.
class CleanExportTransformer {
  const CleanExportTransformer();

  static final RegExp _privateNote = RegExp(
    r'\[\[PRIVATE:[\s\S]*?\]\]',
    caseSensitive: false,
  );
  static final RegExp _sceneMarkdownLink = RegExp(
    r'\[([^\]]+)\]\(scene:[^)]+\)',
    caseSensitive: false,
  );
  static final RegExp _loreLink = RegExp(r'\[\[([^\]\r\n]+)\]\]');
  static final RegExp _bareSceneLink = RegExp(
    r'scene:[a-zA-Z0-9_-]+',
    caseSensitive: false,
  );

  /// Membersihkan [source] dalam urutan yang tetap. Penggantian hanya
  /// menyentuh token yang dikenali; karakter lain dipertahankan byte-for-byte.
  CleanExportResult transform(String source) {
    var text = source;
    var removedPrivateNotes = 0;
    var removedInternalLinks = 0;

    text = text.replaceAllMapped(_privateNote, (_) {
      removedPrivateNotes++;
      return '';
    });
    text = text.replaceAllMapped(_sceneMarkdownLink, (match) {
      removedInternalLinks++;
      return match.group(1)!;
    });
    text = text.replaceAllMapped(_loreLink, (match) {
      removedInternalLinks++;
      return match.group(1)!;
    });
    text = text.replaceAllMapped(_bareSceneLink, (_) {
      removedInternalLinks++;
      return '';
    });

    return CleanExportResult(
      sourceText: source,
      text: text,
      removedInternalLinks: removedInternalLinks,
      removedPrivateNotes: removedPrivateNotes,
      fingerprint: _fnv1a64(text),
    );
  }

  static String _fnv1a64(String text) {
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    const mask = 0xffffffffffffffff;
    for (final byte in text.codeUnits) {
      hash ^= byte;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
