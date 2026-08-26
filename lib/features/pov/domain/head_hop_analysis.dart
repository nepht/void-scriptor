/// Kontrak Head-Hopping Analysis & Report (Step 109.35).
///
/// Deteksi perpindahan akses batin (head-hop) dan kebocoran informasi
/// di luar batas pengetahuan POV sebagai domain murni, mengikat
/// PovLedger 109.33 dan KnowledgeLedger 109.34. Lima kemampuan
/// kanonik sprint_109.json:
/// 1. **narration_analysis** — beat narasi dianalisis terhadap kunci
///    POV adegannya;
/// 2. **knowledge_violation** — fakta yang di-reveal di luar batas
///    pengetahuan POV dilaporkan;
/// 3. **jump_to_text** — tiap temuan membawa id+teks blok sumber;
/// 4. **false_positive_control** — temuan bisa diabaikan beralasan;
/// 5. **chapter_report** — laporan bab merangkum jumlah dan status.
library;

import 'package:void_scriptor/features/pov/domain/knowledge_boundary.dart';
import 'package:void_scriptor/features/pov/domain/pov_lock.dart';

/// Satu potongan narasi yang dianalisis.
class NarrationBeat {
  const NarrationBeat({
    required this.id,
    required this.text,
    this.innerAccessCharacterIds = const <String>[],
    this.revealedFactIds = const <String>[],
  });

  final String id;
  final String text;

  /// Karakter yang mendapat akses batin pada beat ini.
  final List<String> innerAccessCharacterIds;

  /// Fakta yang di-reveal narasi pada beat ini.
  final List<String> revealedFactIds;
}

/// Jenis temuan analisis.
enum FindingKind { headHop, knowledgeViolation }

/// Satu temuan; membawa blok sumber untuk lompatan editor.
class AnalysisFinding {
  const AnalysisFinding({
    required this.kind,
    required this.beatId,
    required this.beatText,
    required this.explanation,
  });

  final FindingKind kind;
  final String beatId;

  /// Cuplikan teks sumber agar editor bisa melompat langsung.
  final String beatText;

  /// Penjelasan deterministik dalam bahasa manusia.
  final String explanation;

  @override
  bool operator ==(Object other) =>
      other is AnalysisFinding &&
      other.kind == kind &&
      other.beatId == beatId &&
      other.explanation == explanation;

  @override
  int get hashCode => Object.hash(kind, beatId, explanation);
}

/// Hasil analisis satu adegan.
class SceneAnalysis {
  SceneAnalysis({
    required this.sceneId,
    required List<AnalysisFinding> rawFindings,
    required this.dismissedCount,
    required this.isVisible,
  }) : findings = List.unmodifiable(rawFindings);

  final String sceneId;

  /// Semua temuan mentah analisis (termasuk yang sudah diabaikan).
  final List<AnalysisFinding> findings;
  final int dismissedCount;

  /// Filter hidup: konsultasi set pengabaian analyzer saat dibaca,
  /// sehingga dismiss memengaruhi hasil yang sudah ada juga.
  final bool Function(AnalysisFinding) isVisible;

  /// Temuan aktif; yang diabaikan hilang dari daftar ini.
  List<AnalysisFinding> get activeFindings =>
      List.unmodifiable(findings.where(isVisible));
}

/// Laporan satu bab.
class ChapterReport {
  const ChapterReport({
    required this.chapterId,
    required this.sceneCount,
    required this.headHopCount,
    required this.knowledgeViolationCount,
    required this.dismissedCount,
  });

  final String chapterId;
  final int sceneCount;
  final int headHopCount;
  final int knowledgeViolationCount;
  final int dismissedCount;

  bool get isClean => headHopCount == 0 && knowledgeViolationCount == 0;
}

/// Analyzer head-hop murni domain.
class HeadHoppingAnalyzer {
  HeadHoppingAnalyzer({required this.povLedger, required this.knowledgeLedger});

  /// Sumber kebenaran kunci POV (109.33).
  final PovLedger povLedger;

  /// Sumber kebenaran batas pengetahuan (109.34).
  final KnowledgeLedger knowledgeLedger;

  /// Kunci pengabaian: temuan + alasan.
  final Map<AnalysisFinding, String> _dismissals = <AnalysisFinding, String>{};

  /// Menganalisis seluruh beat satu adegan terhadap kunci POV-nya.
  ///
  /// Adegan tanpa kunci [StateError]; mode omniscient bebas head-hop
  /// tapi tetap diperiksa kebocoran pengetahuannya.
  SceneAnalysis analyzeScene({
    required String sceneId,
    required List<NarrationBeat> beats,
  }) {
    final lock = povLedger.povOf(sceneId);
    if (lock == null) {
      throw StateError('scene has no POV lock: $sceneId');
    }
    final findings = <AnalysisFinding>[];
    var dismissed = 0;
    for (final beat in beats) {
      // 1. Head-hop: akses batin pada tokoh lain saat POV bukan
      // omniscient.
      if (lock.mode != PovMode.thirdOmniscient) {
        for (final charId in beat.innerAccessCharacterIds) {
          if (charId == lock.povCharacterId) continue;
          final finding = AnalysisFinding(
            kind: FindingKind.headHop,
            beatId: beat.id,
            beatText: beat.text,
            explanation:
                'narasi masuk kepala $charId padahal POV adegan '
                '$sceneId dikunci ke ${lock.povCharacterId}',
          );
          if (_dismissals.containsKey(finding)) {
            dismissed += 1;
          } else {
            findings.add(finding);
          }
        }
      }
      // 2. Kebocoran pengetahuan: fakta reveal belum diketahui POV
      // pada titik waktu adegan ini.
      for (final factId in beat.revealedFactIds) {
        final known = knowledgeLedger.knows(
          lock.povCharacterId,
          factId: factId,
          at: KnowledgeTime.scene(sceneId),
        );
        if (!known) {
          final finding = AnalysisFinding(
            kind: FindingKind.knowledgeViolation,
            beatId: beat.id,
            beatText: beat.text,
            explanation:
                'narasi mengungkap $factId sebelum ${lock.povCharacterId} '
                'mengetahuinya pada $sceneId',
          );
          if (_dismissals.containsKey(finding)) {
            dismissed += 1;
          } else {
            findings.add(finding);
          }
        }
      }
    }
    return SceneAnalysis(
      sceneId: sceneId,
      rawFindings: findings,
      dismissedCount: dismissed,
      isVisible: (f) => !_dismissals.containsKey(f),
    );
  }

  /// Mengabaikan satu temuan dengan alasan; ganda [StateError].
  void dismiss({required AnalysisFinding finding, required String reason}) {
    if (_dismissals.containsKey(finding)) {
      throw StateError('finding already dismissed');
    }
    _dismissals[finding] = reason;
  }

  /// Alasan pengabaian tersimpan (untuk UI/editor).
  String? dismissalReasonOf(AnalysisFinding finding) => _dismissals[finding];

  /// Merangkum analisis beberapa adegan menjadi laporan bab.
  ChapterReport reportChapter({
    required String chapterId,
    required List<SceneAnalysis> analyses,
  }) {
    var hops = 0;
    var violations = 0;
    var dismissed = 0;
    for (final analysis in analyses) {
      for (final f in analysis.activeFindings) {
        switch (f.kind) {
          case FindingKind.headHop:
            hops += 1;
          case FindingKind.knowledgeViolation:
            violations += 1;
        }
      }
      dismissed += analysis.dismissedCount;
    }
    return ChapterReport(
      chapterId: chapterId,
      sceneCount: analyses.length,
      headHopCount: hops,
      knowledgeViolationCount: violations,
      dismissedCount: dismissed,
    );
  }
}
