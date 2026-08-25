/// Inline lore linking untuk teks naskah Void Scriptor.
///
/// Sintaks `[[Entity]]` menandai satu segmen sebagai tautan lore ke entitas
/// worldbuilding tanpa pernah mengubah isi teks lainnya: teks polos,
/// spasi ganda, baris baru, dan emoji dipertahankan apa adanya, sehingga
/// hasil parse selalu bisa dirender ulang identik (round trip).
library;

/// Satu potongan hasil parse teks naskah.
sealed class InlineLoreSegment {
  const InlineLoreSegment();
}

/// Teks biasa yang harus tetap verbatim.
class LoreTextSegment extends InlineLoreSegment {
  const LoreTextSegment(this.text);

  final String text;

  @override
  String toString() => 'LoreTextSegment($text)';
}

/// Tautan lore `[[Entity]]`; [target] adalah isi mentah di dalam kurung.
class LoreLinkSegment extends InlineLoreSegment {
  const LoreLinkSegment(this.target);

  final String target;

  /// Nama entitas untuk lookup: isi kurung setelah trim.
  String get displayName => target.trim();

  @override
  String toString() => 'LoreLinkSegment($target)';
}

/// Memecah teks naskah menjadi segmen teks dan segmen tautan lore.
class InlineLoreLinkParser {
  const InlineLoreLinkParser();

  /// Aturan sintaks:
  /// - `[[Entity]]` menjadi [LoreLinkSegment]; isi kurung di-trim saat lookup.
  /// - `\[[teks]]` adalah literal: backslash meniadakan pembuka link.
  /// - Kurung tanpa penutup, kosong/berisi spasi saja, atau memuat baris baru
  ///   dibiarkan sebagai teks biasa.
  List<InlineLoreSegment> parse(String source) {
    if (source.isEmpty) return <InlineLoreSegment>[const LoreTextSegment('')];

    final segments = <InlineLoreSegment>[];
    final pendingText = StringBuffer();
    var index = 0;

    void flushText() {
      if (pendingText.isEmpty) return;
      segments.add(LoreTextSegment(pendingText.toString()));
      pendingText.clear();
    }

    while (index < source.length) {
      final isEscapedOpening =
          source[index] == r'\' &&
          index + 2 < source.length &&
          source[index + 1] == '[' &&
          source[index + 2] == '[';

      if (isEscapedOpening) {
        pendingText
          ..write(r'\')
          ..write('[[');
        index += 3;
        continue;
      }

      final isOpening =
          source[index] == '[' &&
          index + 1 < source.length &&
          source[index + 1] == '[';

      if (!isOpening) {
        pendingText.write(source[index]);
        index += 1;
        continue;
      }

      final closing = source.indexOf(']]', index + 2);
      if (closing == -1) {
        pendingText.write('[[');
        index += 2;
        continue;
      }

      final body = source.substring(index + 2, closing);
      if (body.trim().isEmpty || _containsLineBreak(body)) {
        pendingText.write('[[');
        index += 2;
        continue;
      }

      flushText();
      segments.add(LoreLinkSegment(body));
      index = closing + 2;
    }

    flushText();
    return segments;
  }

  static bool _containsLineBreak(String value) =>
      value.contains('\n') || value.contains('\r');
}

/// Merender segmen hasil parse kembali menjadi teks naskah.
///
/// Kontrak round trip: `render(parse(source)) == source` untuk input apa pun,
/// termasuk tautan ber-spasi di dalam kurung dan escape literal.
class InlineLoreLinkRenderer {
  const InlineLoreLinkRenderer();

  String render(List<InlineLoreSegment> segments) {
    final buffer = StringBuffer();
    for (final segment in segments) {
      if (segment is LoreTextSegment) {
        buffer.write(segment.text);
      } else if (segment is LoreLinkSegment) {
        buffer
          ..write('[[')
          ..write(segment.target)
          ..write(']]');
      }
    }
    return buffer.toString();
  }
}

/// Operasi sunting pada teks yang hanya menyentuh segmen tautan.
class InlineLoreLinkEditor {
  const InlineLoreLinkEditor();

  /// Mengganti nama target semua tautan yang cocok dengan [from].
  ///
  /// Kecocokan memakai display name (isi kurung setelah trim), bersifat case
  /// sensitive, dan tidak pernah menyentuh kemunculan teks biasa maupun
  /// escape literal dengan nama sama. Bila tidak ada yang cocok, [source]
  /// dikembalikan apa adanya (identik, tanpa realokasi).
  String renameTarget(
    String source, {
    required String from,
    required String to,
  }) {
    final segments = const InlineLoreLinkParser().parse(source);
    final normalizedFrom = from.trim();
    var touched = false;

    final renamed = <InlineLoreSegment>[];
    for (final segment in segments) {
      if (segment is LoreLinkSegment && segment.displayName == normalizedFrom) {
        touched = true;
        renamed.add(LoreLinkSegment(to));
      } else {
        renamed.add(segment);
      }
    }

    if (!touched) return source;
    return const InlineLoreLinkRenderer().render(renamed);
  }
}
