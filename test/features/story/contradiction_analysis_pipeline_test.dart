import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/contradiction_rule.dart';
import 'package:void_scriptor/features/story/domain/contradiction_analysis.dart';

/// Kontrak Step 109.13 — Contradiction Analysis Pipeline.
///
/// Lima kelompok tes memetakan 1:1 ke acceptance kanonik:
/// incremental_scan, source_citations, deterministic_rules,
/// dismissal_state, rescan. Pipeline murni domain: tanpa Drift, tanpa UI.
void main() {
  const ruleAge = ContradictionRule(
    id: 'r-age',
    projectId: 'p-1',
    title: 'Usia Nova terkunci',
    dimension: ContradictionDimension.age,
    subjectKind: 'character',
    attributeKey: 'age',
    comparator: ContradictionComparator.equals,
    expectedValues: ['17'],
    description: 'Perbarui kronologi atau usia agar konsisten.',
  );

  const ruleLife = ContradictionRule(
    id: 'r-life',
    projectId: 'p-1',
    title: 'Marek masih hidup',
    dimension: ContradictionDimension.lifeStatus,
    subjectKind: 'character',
    attributeKey: 'lifeStatus',
    comparator: ContradictionComparator.equals,
    expectedValues: ['hidup'],
  );

  const ruleRange = ContradictionRule(
    id: 'r-range',
    projectId: 'p-1',
    title: 'Usia kru dewasa 15–40',
    dimension: ContradictionDimension.age,
    subjectKind: 'character',
    attributeKey: 'age',
    comparator: ContradictionComparator.withinRange,
    expectedValues: ['15', '40'],
  );

  const novaAgeCitation = ContradictionSourceRef(
    sourceId: 'sc-1',
    label: 'Bab 1 · Pembukaan',
  );
  const novaBeatCitation = ContradictionSourceRef(
    sourceId: 'beat-7',
    label: 'Bab 2 · Beat pelarian',
  );

  const nova = SubjectSnapshot(
    subjectKind: 'character',
    subjectId: 'c-nova',
    attributes: {'age': '18', 'lifeStatus': 'hidup'},
    sources: {
      'age': [novaAgeCitation, novaBeatCitation],
      'lifeStatus': [novaAgeCitation],
    },
  );
  const marek = SubjectSnapshot(
    subjectKind: 'character',
    subjectId: 'c-marek',
    attributes: {'lifeStatus': 'mati'},
  );
  const kai = SubjectSnapshot(
    subjectKind: 'character',
    subjectId: 'c-kai',
    attributes: {'age': '17', 'lifeStatus': 'hidup'},
  );
  const veteran = SubjectSnapshot(
    subjectKind: 'character',
    subjectId: 'c-tua',
    attributes: {'age': '55'},
  );
  const sceneNine = SubjectSnapshot(
    subjectKind: 'scene',
    subjectId: 'sc-9',
    attributes: {'age': 'bukan angka'},
  );

  const allSubjects = [nova, marek, kai, veteran, sceneNine];
  const activeRules = [ruleAge, ruleLife, ruleRange];

  ContradictionAnalysisPipeline buildPipeline({
    ContradictionDismissalStore? dismissals,
    DateTime Function()? clock,
  }) {
    return ContradictionAnalysisPipeline(dismissals: dismissals, clock: clock);
  }

  group('incremental_scan', () {
    test('evaluates only subjects inside the scope', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(
        rules: activeRules,
        subjects: allSubjects,
        scope: const ContradictionScanScope(subjectIds: {'c-marek'}),
      );

      expect(result.isIncremental, isTrue);
      expect(result.evaluatedSubjects, 3, reason: '3 aturan x 1 subjek');
      expect(result.findings, hasLength(1));
      expect(result.findings.single.ruleId, 'r-life');
      expect(result.findings.single.subjectId, 'c-marek');
    });

    test('empty scope means full scan and covers every comparable pair', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(rules: activeRules, subjects: allSubjects);

      expect(result.isIncremental, isFalse);
      expect(result.evaluatedSubjects, 12, reason: '3 aturan x 4 karakter');
      // Urutan deterministik: aturan luar, subjek dalam sesuai input.
      // c-tua (55) melanggar r-age DAN r-range sekaligus.
      expect(
        result.findings.map((f) => '${f.ruleId}:${f.subjectId}').toList(),
        ['r-age:c-nova', 'r-age:c-tua', 'r-life:c-marek', 'r-range:c-tua'],
      );
    });

    test('skips disabled and schema-invalid rules without crashing', () {
      final pipeline = buildPipeline();
      const disabled = ContradictionRule(
        id: 'r-mati',
        projectId: 'p-1',
        title: 'Aturan dimatikan',
        dimension: ContradictionDimension.location,
        subjectKind: 'character',
        attributeKey: 'location',
        comparator: ContradictionComparator.equals,
        expectedValues: ['Pelabuhan'],
        enabled: false,
      );
      const broken = ContradictionRule(
        id: 'r-rusak',
        projectId: 'p-1',
        title: 'Range satu operand',
        dimension: ContradictionDimension.age,
        subjectKind: 'character',
        attributeKey: 'age',
        comparator: ContradictionComparator.withinRange,
        expectedValues: ['15'],
      );

      final result = pipeline.scan(
        rules: [...activeRules, disabled, broken],
        subjects: allSubjects,
      );

      expect(result.skippedRules, 2);
      expect(result.evaluatedRules, 3);
      expect(
        result.findings.map((f) => f.ruleId),
        isNot(contains(anyOf('r-mati', 'r-rusak'))),
      );
    });

    test('scope with unknown subject ids yields an empty clean result', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(
        rules: activeRules,
        subjects: allSubjects,
        scope: const ContradictionScanScope(subjectIds: {'hantu'}),
      );

      expect(result.findings, isEmpty);
      expect(result.evaluatedSubjects, 0);
    });
  });

  group('source_citations', () {
    test('finding carries the attribute citations verbatim and in order', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(rules: activeRules, subjects: allSubjects);

      final novaFinding = result.findings.singleWhere(
        (f) => f.subjectId == 'c-nova',
      );
      expect(novaFinding.explanation.sources, hasLength(2));
      expect(novaFinding.explanation.sources.first.sourceId, 'sc-1');
      expect(novaFinding.explanation.sources.first.label, 'Bab 1 · Pembukaan');
      expect(novaFinding.explanation.sources.last.sourceId, 'beat-7');
    });

    test('provenance-backed values score high, bare values score low', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(rules: activeRules, subjects: allSubjects);

      final novaFinding = result.findings.singleWhere(
        (f) => f.subjectId == 'c-nova',
      );
      final marekBare = result.findings.singleWhere(
        (f) => f.subjectId == 'c-marek',
      );
      expect(novaFinding.confidence, DetectionConfidence.high);
      expect(marekBare.confidence, DetectionConfidence.low);
      expect(marekBare.explanation.sources, isEmpty);
    });

    test('rendered report embeds the citation lines deterministically', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(rules: activeRules, subjects: allSubjects);

      final rendered = result.findings
          .singleWhere((f) => f.subjectId == 'c-nova')
          .explanation
          .render(dimension: ContradictionDimension.age);
      expect(rendered, contains('[age]'));
      expect(rendered, contains('• Bab 1 · Pembukaan (sc-1)'));
      expect(rendered, contains('• Bab 2 · Beat pelarian (beat-7)'));
    });
  });

  group('deterministic_rules', () {
    test('two identical scans produce identical findings and reports', () {
      final pipeline = buildPipeline();

      final first = pipeline.scan(rules: activeRules, subjects: allSubjects);
      final second = pipeline.scan(rules: activeRules, subjects: allSubjects);

      expect(second.findings.length, first.findings.length);
      for (var i = 0; i < first.findings.length; i++) {
        expect(second.findings[i].id, first.findings[i].id);
        expect(second.findings[i].ruleId, first.findings[i].ruleId);
        expect(second.findings[i].subjectId, first.findings[i].subjectId);
        expect(
          second.findings[i].explanation.render(
            dimension: first.findings[i].dimension,
          ),
          first.findings[i].explanation.render(
            dimension: first.findings[i].dimension,
          ),
        );
      }
    });

    test('finding id is a stable ruleId::subjectId fingerprint', () {
      final pipeline = buildPipeline();

      final result = pipeline.scan(rules: activeRules, subjects: allSubjects);

      // c-tua (55) melanggar dua aturan: r-age dan r-range.
      expect(result.findings.map((f) => f.id).toSet(), {
        'r-age::c-nova',
        'r-age::c-tua',
        'r-life::c-marek',
        'r-range::c-tua',
      });
    });

    test('numeric comparison wins over lexicographic for ranges', () {
      final pipeline = buildPipeline();
      // '9' secara leksikografis berada di antara '15' dan '40', tetapi
      // secara numerik berada di bawah rentang — harus dilaporkan.
      const youngCadet = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-cadet',
        attributes: {'age': '9'},
      );

      final result = pipeline.scan(rules: [ruleRange], subjects: [youngCadet]);

      expect(result.findings, hasLength(1));
      expect(result.findings.single.subjectId, 'c-cadet');
    });
  });

  group('dismissal_state', () {
    test('dismiss stores reason, actor, timestamp and suppresses findings', () {
      final fixedTime = DateTime(2026, 8, 26, 10, 30);
      final dismissals = ContradictionDismissalStore();
      final pipeline = buildPipeline(
        dismissals: dismissals,
        clock: () => fixedTime,
      );

      final firstRun = pipeline.scan(rules: activeRules, subjects: allSubjects);
      final marekFinding = firstRun.findings.singleWhere(
        (f) => f.subjectId == 'c-marek',
      );

      final record = pipeline.dismiss(
        finding: marekFinding,
        reason: 'Plot twist disepakati editor',
        actor: 'choirudin',
      );

      expect(dismissals.records, hasLength(1));
      expect(record.ruleId, 'r-life');
      expect(record.subjectId, 'c-marek');
      expect(record.reason, 'Plot twist disepakati editor');
      expect(record.actor, 'choirudin');
      expect(record.dismissedAt, fixedTime);

      final secondRun = pipeline.scan(
        rules: activeRules,
        subjects: allSubjects,
      );
      expect(
        secondRun.findings.where((f) => f.subjectId == 'c-marek'),
        isEmpty,
      );
      // c-tua tetap melanggar dua aturan (r-age + r-range).
      expect(secondRun.findings, hasLength(3));
    });

    test('restore brings a dismissed finding back on the next scan', () {
      final dismissals = ContradictionDismissalStore();
      final pipeline = buildPipeline(dismissals: dismissals);

      final firstRun = pipeline.scan(rules: activeRules, subjects: allSubjects);
      final record = pipeline.dismiss(
        finding: firstRun.findings.singleWhere((f) => f.subjectId == 'c-marek'),
        reason: 'Ditunda',
      );

      expect(pipeline.restore(record.id), isTrue);
      expect(pipeline.restore(record.id), isFalse, reason: 'sudah dihapus');

      final rerun = pipeline.scan(rules: activeRules, subjects: allSubjects);
      expect(
        rerun.findings.where((f) => f.subjectId == 'c-marek'),
        hasLength(1),
      );
    });

    test('dismissal store round-trips through JSON', () {
      final dismissals = ContradictionDismissalStore();
      final pipeline = buildPipeline(
        dismissals: dismissals,
        clock: () => DateTime(2026, 8, 26, 9),
      );

      final firstRun = pipeline.scan(rules: activeRules, subjects: allSubjects);
      final record = pipeline.dismiss(
        finding: firstRun.findings.singleWhere((f) => f.subjectId == 'c-marek'),
        reason: 'Kanon alternatif',
        actor: 'editor',
      );

      final restored = ContradictionDismissalStore.fromJson(
        (dismissals.toJson() as Map).cast<String, Object?>(),
      );

      expect(
        restored.isDismissed(
          ruleId: record.ruleId,
          subjectId: record.subjectId,
        ),
        isTrue,
      );
      final back = restored.records.single;
      expect(back.reason, 'Kanon alternatif');
      expect(back.actor, 'editor');
      expect(back.dismissedAt, DateTime(2026, 8, 26, 9));
    });
  });

  group('rescan', () {
    test('rescan re-evaluates changed data while keeping dismissals', () {
      final dismissals = ContradictionDismissalStore();
      final pipeline = buildPipeline(dismissals: dismissals);

      final firstRun = pipeline.scan(rules: activeRules, subjects: allSubjects);
      pipeline.dismiss(
        finding: firstRun.findings.singleWhere((f) => f.subjectId == 'c-marek'),
        reason: 'Disepakati',
      );

      // Data berubah: Nova diperbaiki menjadi 17, Kai menua jadi 70.
      final changedNova = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-nova',
        attributes: const {'age': '17', 'lifeStatus': 'hidup'},
        sources: nova.sources,
      );
      const agedKai = SubjectSnapshot(
        subjectKind: 'character',
        subjectId: 'c-kai',
        attributes: {'age': '70', 'lifeStatus': 'hidup'},
      );

      final rescan = pipeline.scan(
        rules: activeRules,
        subjects: [changedNova, marek, agedKai, veteran],
      );

      // Pelanggaran yang sudah diperbaiki hilang untuk Nova; kru tua
      // (c-kai 70, c-tua 55) tetap melanggar r-age DAN r-range.
      expect(
        rescan.findings
            .where((f) => f.ruleId == 'r-age')
            .map((f) => f.subjectId),
        ['c-kai', 'c-tua'],
        reason: 'Nova diperbaiki; pelanggar usia tersisa c-kai dan c-tua',
      );
      // …pelanggaran baru muncul…
      expect(rescan.findings.any((f) => f.subjectId == 'c-kai'), isTrue);
      // …dan dismissal tetap menekan temuan Marek meski datanya tak berubah.
      expect(rescan.findings.where((f) => f.subjectId == 'c-marek'), isEmpty);
      expect(rescan.findings, hasLength(4));
    });
  });
}
