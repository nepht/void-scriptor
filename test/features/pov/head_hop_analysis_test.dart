// Kontrak Head-Hopping Analysis & Report (Step 109.35) — RED pertama.
//
// Acceptance kanonik sprint_109.json: narration_analysis,
// knowledge_violation, jump_to_text, false_positive_control,
// chapter_report.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/pov/domain/head_hop_analysis.dart';
import 'package:void_scriptor/features/pov/domain/knowledge_boundary.dart';
import 'package:void_scriptor/features/pov/domain/pov_lock.dart';

void main() {
  group('narration_analysis', () {
    test('akses batin di luar POV terdeteksi sebagai head-hop', () {
      final pov = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.firstPerson,
        );
      final analyzer = HeadHoppingAnalyzer(
        povLedger: pov,
        knowledgeLedger: KnowledgeLedger(),
      );
      final analysis = analyzer.analyzeScene(
        sceneId: 'sc-01',
        beats: const <NarrationBeat>[
          NarrationBeat(
            id: 'b-1',
            text: 'Aku menahan napas di ambang pintu.',
            innerAccessCharacterIds: <String>['n-kael'],
          ),
          NarrationBeat(
            id: 'b-2',
            text: 'Mira tersenyum getir dalam hati.',
            innerAccessCharacterIds: <String>['n-mira'],
          ),
        ],
      );
      expect(analysis.findings, hasLength(1));
      expect(analysis.activeFindings.single.kind, FindingKind.headHop);
      expect(analysis.activeFindings.single.explanation, contains('n-mira'));
      expect(analysis.activeFindings.single.explanation, contains('n-kael'));

      // Mode omniscient bebas head-hop.
      pov.lockScene(
        sceneId: 'sc-02',
        povCharacterId: 'n-penulis',
        mode: PovMode.thirdOmniscient,
      );
      final omni = analyzer.analyzeScene(
        sceneId: 'sc-02',
        beats: const <NarrationBeat>[
          NarrationBeat(
            id: 'b-9',
            text: 'Keduanya sama-sama menyimpan dendam.',
            innerAccessCharacterIds: <String>['n-kael', 'n-mira'],
          ),
        ],
      );
      expect(omni.activeFindings, isEmpty);

      // Adegan tanpa kunci POV tidak bisa dianalisis.
      expect(
        () => analyzer.analyzeScene(sceneId: 'sc-40', beats: const []),
        throwsStateError,
      );
    });
  });

  group('knowledge_violation', () {
    test('narasi membocorkan fakta yang belum diketahui POV', () {
      final pov = PovLedger()
        ..lockScene(
          sceneId: 'sc-05',
          povCharacterId: 'n-kael',
          mode: PovMode.thirdLimited,
        );
      final know = KnowledgeLedger()
        ..learn(
          characterId: 'n-kael',
          factId: 'f-a',
          at: const KnowledgeTime.scene('sc-03'),
        );
      final analyzer = HeadHoppingAnalyzer(
        povLedger: pov,
        knowledgeLedger: know,
      );
      final analysis = analyzer.analyzeScene(
        sceneId: 'sc-05',
        beats: const <NarrationBeat>[
          NarrationBeat(
            id: 'b-1',
            text: 'Lorong timur memang sudah kosong sejak fajar.',
            revealedFactIds: <String>['f-a'],
          ),
          NarrationBeat(
            id: 'b-2',
            text: 'Rahasia raja akhirnya terbongkar.',
            revealedFactIds: <String>['f-rahasia-raja'],
          ),
        ],
      );
      expect(analysis.findings, hasLength(1));
      expect(
        analysis.activeFindings.single.kind,
        FindingKind.knowledgeViolation,
      );
      expect(
        analysis.activeFindings.single.explanation,
        contains('f-rahasia-raja'),
      );
    });
  });

  group('jump_to_text', () {
    test('temuan membawa blok sumber untuk lompatan editor', () {
      final pov = PovLedger()
        ..lockScene(
          sceneId: 'sc-07',
          povCharacterId: 'n-mira',
          mode: PovMode.thirdLimited,
        );
      final analyzer = HeadHoppingAnalyzer(
        povLedger: pov,
        knowledgeLedger: KnowledgeLedger(),
      );
      final analysis = analyzer.analyzeScene(
        sceneId: 'sc-07',
        beats: const <NarrationBeat>[
          NarrationBeat(
            id: 'b-4',
            text: 'Kael merasakan dinginnya bilah itu.',
            innerAccessCharacterIds: <String>['n-kael'],
          ),
        ],
      );
      final finding = analysis.activeFindings.single;
      expect(finding.beatId, 'b-4');
      expect(finding.beatText, contains('dinginnya bilah'));
    });
  });

  group('false_positive_control', () {
    test('temuan bisa diabaikan beralasan dan bertahan lintas analisis', () {
      final pov = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.firstPerson,
        );
      final analyzer = HeadHoppingAnalyzer(
        povLedger: pov,
        knowledgeLedger: KnowledgeLedger(),
      );
      const beats = <NarrationBeat>[
        NarrationBeat(
          id: 'b-2',
          text: 'Mira tersenyum getir dalam hati.',
          innerAccessCharacterIds: <String>['n-mira'],
        ),
      ];
      final analysis = analyzer.analyzeScene(sceneId: 'sc-01', beats: beats);
      final finding = analysis.activeFindings.single;
      analyzer.dismiss(finding: finding, reason: 'jeda omniscient disengaja');
      expect(analysis.activeFindings, isEmpty);

      // Pengabaian ganda ditolak.
      expect(
        () => analyzer.dismiss(finding: finding, reason: 'lagi'),
        throwsStateError,
      );

      // Analisis ulang adegan sama: temuan tetap tersembunyi namun
      // terhitung sebagai dismissed.
      final again = analyzer.analyzeScene(sceneId: 'sc-01', beats: beats);
      expect(again.activeFindings, isEmpty);
      expect(again.dismissedCount, 1);
    });
  });

  group('chapter_report', () {
    test('laporan bab merangkum jumlah dan status bersih', () {
      final pov = PovLedger()
        ..lockScene(
          sceneId: 'sc-01',
          povCharacterId: 'n-kael',
          mode: PovMode.thirdLimited,
        )
        ..lockScene(
          sceneId: 'sc-02',
          povCharacterId: 'n-mira',
          mode: PovMode.thirdLimited,
        );
      final analyzer = HeadHoppingAnalyzer(
        povLedger: pov,
        knowledgeLedger: KnowledgeLedger(),
      );
      final a1 = analyzer.analyzeScene(
        sceneId: 'sc-01',
        beats: const <NarrationBeat>[
          NarrationBeat(
            id: 'b-1',
            text: 'Mira murka dalam diam.',
            innerAccessCharacterIds: <String>['n-mira'],
          ),
        ],
      );
      final a2 = analyzer.analyzeScene(
        sceneId: 'sc-02',
        beats: const <NarrationBeat>[
          NarrationBeat(
            id: 'b-2',
            text: 'Peta itu sesungguhnya palsu.',
            revealedFactIds: <String>['f-peta-palsu'],
          ),
        ],
      );
      final report = analyzer.reportChapter(
        chapterId: 'ch-01',
        analyses: <SceneAnalysis>[a1, a2],
      );
      expect(report.chapterId, 'ch-01');
      expect(report.sceneCount, 2);
      expect(report.headHopCount, 1);
      expect(report.knowledgeViolationCount, 1);
      expect(report.isClean, isFalse);

      // Bab tanpa temuan bersih.
      final a3 = analyzer.analyzeScene(sceneId: 'sc-01', beats: const []);
      final clean = analyzer.reportChapter(
        chapterId: 'ch-02',
        analyses: <SceneAnalysis>[a3],
      );
      expect(clean.isClean, isTrue);
      expect(clean.headHopCount, 0);
    });
  });
}
