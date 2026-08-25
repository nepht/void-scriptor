/// Kesehatan tautan lore inline (Step 109.11).
///
/// Klasifikasi murni atas hasil [InlineLoreLinkParser] tanpa menyentuh
/// database: teks polos dan escape literal tidak pernah dihitung sebagai
/// kemunculan link, sehingga laporan integritas hanya melihat tautan nyata.
library;

import 'inline_lore_links.dart';
import 'lore_link_suggester.dart';

/// Status kesehatan satu target tautan lore.
enum LoreLinkHealth {
  /// Target ditemukan tepat satu kali di katalog.
  resolved,

  /// Target tidak ada di katalog mana pun.
  broken,

  /// Normalisasi target cocok dengan lebih dari satu entitas katalog,
  /// sehingga lookup tidak bisa memilih secara deterministik.
  ambiguous,
}

/// Satu temuan integritas untuk pasangan (sumber, target) unik.
class LoreLinkFinding {
  const LoreLinkFinding({
    required this.sourceId,
    required this.sourceTitle,
    required this.target,
    this.health = LoreLinkHealth.resolved,
    this.occurrences = 1,
    this.candidates = const <LoreEntityRef>[],
  });

  /// ID sumber teks (misal scene id atau `<sceneId>_draft`).
  final String sourceId;

  /// Judul manusiawi sumber untuk ditampilkan di laporan.
  final String sourceTitle;

  /// Display name target tautan (isi kurung setelah trim).
  final String target;

  final LoreLinkHealth health;

  /// Jumlah kemunculan target yang sama dalam satu sumber.
  final int occurrences;

  /// Kandidat katalog saat [LoreLinkHealth.ambiguous]; kosong selain itu.
  final List<LoreEntityRef> candidates;
}

/// Hasil pemindaian integritas tautan lore atas semua teks proyek.
class LoreLinkIntegrityReport {
  const LoreLinkIntegrityReport(this.findings);

  final List<LoreLinkFinding> findings;

  /// Temuan dengan [LoreLinkHealth.broken].
  List<LoreLinkFinding> get brokenLinks =>
      findings.where((f) => f.health == LoreLinkHealth.broken).toList();

  /// Temuan dengan [LoreLinkHealth.ambiguous].
  List<LoreLinkFinding> get ambiguousLinks =>
      findings.where((f) => f.health == LoreLinkHealth.ambiguous).toList();

  /// True bila tidak ada temuan broken maupun ambigu.
  bool get isClean => brokenLinks.isEmpty && ambiguousLinks.isEmpty;
}

/// Pengklasifikasi murni tautan lore terhadap katalog entitas.
class LoreLinkClassifier {
  const LoreLinkClassifier();

  /// Normalisasi nama: trim + lowercase + pipihkan spasi beruntun.
  ///
  /// Dipakai bersama oleh klasifikasi ambiguitas dan lookup backlink agar
  /// `[[  api  ]]`, `[[Api]]`, dan `[[a p i]]` dianggap target sama.
  static String normalize(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Mengklasifikasikan daftar target mentah per sumber terhadap
  /// [catalog]. Kemunculan target identik dalam satu sumber digabung ke
  /// satu temuan beserta hitungan [LoreLinkFinding.occurrences].
  List<LoreLinkFinding> classify(
    Map<String, ({String title, List<String> targets})> sources, {
    required List<LoreEntityRef> catalog,
  }) {
    final normalizedCatalog = <String, List<LoreEntityRef>>{};
    for (final entity in catalog) {
      normalizedCatalog
          .putIfAbsent(normalize(entity.name), () => [])
          .add(entity);
    }

    final findings = <LoreLinkFinding>[];
    for (final entry in sources.entries) {
      final counts = <String, int>{};
      final displayNames = <String, String>{};
      for (final rawTarget in entry.value.targets) {
        final key = normalize(rawTarget);
        if (key.isEmpty) continue;
        counts[key] = (counts[key] ?? 0) + 1;
        displayNames.putIfAbsent(key, () => rawTarget.trim());
      }

      for (final counted in counts.entries) {
        final candidates = normalizedCatalog[counted.key] ?? const [];
        final health = switch (candidates.length) {
          0 => LoreLinkHealth.broken,
          1 => LoreLinkHealth.resolved,
          _ => LoreLinkHealth.ambiguous,
        };
        findings.add(
          LoreLinkFinding(
            sourceId: entry.key,
            sourceTitle: entry.value.title,
            target: displayNames[counted.key] ?? counted.key,
            health: health,
            occurrences: counted.value,
            candidates: candidates,
          ),
        );
      }
    }
    return findings;
  }
}

/// Editor teks tingkat proyek yang hanya menyentuh segmen tautan.
class ProjectLoreLinkEditor {
  const ProjectLoreLinkEditor();

  /// Mengganti display name semua tautan [from] menjadi [to].
  ///
  /// Teks polos dan escape literal `\[[from]]` dengan nama sama tidak
  /// tersentuh. Bila [from] sama dengan [to], atau tidak ada segmen yang
  /// cocok, [content] dikembalikan apa adanya (identik, tanpa realokasi).
  String retarget(String content, {required String from, required String to}) {
    if (from.trim() == to.trim()) return content;
    return const InlineLoreLinkEditor().renameTarget(
      content,
      from: from,
      to: to,
    );
  }
}
