// Regresi vs-hunt-20260914-story (run306) — empat REAL BUG verdict Referee
// (referee_report_story_domain_exporters.md, HEAD 9a549f4):
//   STORY-01 Medium: scan() diam-diam membuang snapshot ketika dua subjek
//            memakai subjectId sama.
//   STORY-03 Medium: recordWords() menerima scopeKey blank padahal
//            setTarget() menolaknya.
//   STORY-07 Low: fidelity menghitung substring judul mentah — judul yang
//            sah muncul ulang di sinopsis atau ter-escape XML di DOCX
//            menghasilkan kegagalan palsu terhadap struktur yang benar.
//   STORY-08 Low: fromUtcInstant() menerima DateTime non-UTC padahal
//            kontraknya menyebut instan UTC.
// BUG-STORY-04/05/06 dismissal: File.rename terbukti menggantikan target
// yang ada pada Windows SDK ini (probe parent) — tidak ada perbaikan.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/application/story_export_fidelity.dart';
import 'package:void_scriptor/features/story/domain/contradiction_analysis.dart';
import 'package:void_scriptor/features/story/domain/contradiction_rule.dart';
import 'package:void_scriptor/features/story/domain/word_targets.dart';

void main() {
  group('vs-hunt-20260914-story STORY-01', () {
    test('scan menolak subjectId duplikat alih-alih membuang diam-diam', () {
      final pipeline = ContradictionAnalysisPipeline();
      const first = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-kembar',
        attributes: {'age': '9'},
      );
      const second = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-kembar',
        attributes: {'age': '42'},
      );
      expect(
        () => pipeline.scan(
          rules: const <ContradictionRule>[],
          subjects: const <SubjectSnapshot>[first, second],
        ),
        throwsArgumentError,
      );
    });

    test('scan tetap menerima subjectId unik', () {
      final pipeline = ContradictionAnalysisPipeline();
      const a = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-a',
        attributes: {'age': '17'},
      );
      const b = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-b',
        attributes: {'age': '17'},
      );
      final result = pipeline.scan(
        rules: const <ContradictionRule>[],
        subjects: const <SubjectSnapshot>[a, b],
      );
      expect(result.evaluatedSubjects, 0);
    });
  });

  group('vs-hunt-20260914-story STORY-03', () {
    test('recordWords menolak scopeKey blank seperti setTarget', () {
      final tracker = WordTargetTracker();
      expect(
        () => tracker.recordWords(
          level: WordTargetLevel.scene,
          scopeKey: '   ',
          count: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => tracker.recordWords(
          level: WordTargetLevel.scene,
          scopeKey: '',
          count: 10,
        ),
        throwsArgumentError,
      );
    });
  });

  group('vs-hunt-20260914-story STORY-08', () {
    test('fromUtcInstant menolak DateTime non-UTC', () {
      final local = DateTime(2026, 8, 26, 18, 30);
      expect(
        () => WordTargetDayStamp.fromUtcInstant(local, offsetMinutes: 420),
        throwsArgumentError,
      );
    });

    test('fromUtcInstant tetap menerima instan UTC', () {
      final stamp = WordTargetDayStamp.fromUtcInstant(
        DateTime.utc(2026, 8, 26, 18, 30),
        offsetMinutes: 420,
      );
      expect(stamp.dayKey, '2026-08-27');
    });
  });

  group('vs-hunt-20260914-story STORY-07', () {
    test('markdown fidelity meloloskan struktur benar saat teks judul '
        'muncul ulang di sinopsis', () {
      const markdown =
          '# Alpha\n\nAlpha Returns dibuka.\n\n'
          '## Bab Satu\n\n### S1\n\nAlpha Returns lagi.';
      final report = const StoryExportFidelity().markdownReport(
        markdown,
        expectTitle: 'Alpha',
        expectSynopsis: 'Alpha Returns dibuka.',
        expectHunks: const [
          FidelityHunk(
            title: 'Bab Satu',
            children: [
              FidelityHunk(title: 'S1', lines: ['Alpha Returns lagi.']),
            ],
          ),
        ],
      );
      expect(report.failures, isEmpty, reason: '${report.failures}');
    });

    test('docx fidelity meloloskan judul dengan entitas XML', () {
      const documentXml =
          '<w:p><w:pPr><w:pStyle w:val="Title"/></w:pPr>'
          '<w:r><w:t>Void &amp; Cube</w:t></w:r></w:p>';
      final report = const StoryExportFidelity().docxReport(
        documentXml,
        expectTitle: 'Void & Cube',
        expectHunks: const <FidelityHunk>[],
      );
      expect(report.failures, isEmpty, reason: '${report.failures}');
    });

    test('docx fidelity tetap menolak judul hilang dari posisi Title', () {
      const documentXml = '<w:p><w:r><w:t>Void &amp; Cube</w:t></w:r></w:p>';
      final report = const StoryExportFidelity().docxReport(
        documentXml,
        expectTitle: 'Void & Cube',
        expectHunks: const <FidelityHunk>[],
      );
      expect(report.ok, isFalse);
    });
  });
}
