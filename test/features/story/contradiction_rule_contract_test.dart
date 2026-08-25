import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/contradiction_rule.dart';

void main() {
  group('rule_schema', () {
    test('covers the six canonical continuity dimensions', () {
      expect(
        ContradictionDimension.values.map((d) => d.name),
        containsAll([
          'time',
          'age',
          'location',
          'lifeStatus',
          'ownership',
          'canonFact',
        ]),
      );
      expect(ContradictionDimension.values, hasLength(6));
    });

    test('accepts a well-formed rule for every dimension', () {
      const dimensions = ContradictionDimension.values;
      for (final dimension in dimensions) {
        final rule = ContradictionRule(
          id: 'r-$dimension',
          projectId: 'project-1',
          title: 'Aturan ${dimension.name}',
          dimension: dimension,
          subjectKind: 'character',
          attributeKey: 'attr-${dimension.name}',
          comparator: ContradictionComparator.equals,
          expectedValues: const ['nilai-tunggal'],
        );

        expect(rule.validateSchema(), isEmpty, reason: dimension.name);
        expect(rule.enabled, isTrue);
      }
    });

    test('rejects blank title and attribute keys with named problems', () {
      const rule = ContradictionRule(
        id: 'r-jelek',
        projectId: 'project-1',
        title: '   ',
        dimension: ContradictionDimension.age,
        subjectKind: 'character',
        attributeKey: '',
        comparator: ContradictionComparator.equals,
        expectedValues: ['17'],
      );

      final problems = rule.validateSchema();
      expect(problems, hasLength(2));
      expect(problems.first, contains('title'));
      expect(problems.last, contains('attributeKey'));
    });

    test('enforces operand count per comparator', () {
      const single = ContradictionRule(
        id: 'r-1',
        projectId: 'p',
        title: 'Waktu',
        dimension: ContradictionDimension.time,
        subjectKind: 'scene',
        attributeKey: 'year',
        comparator: ContradictionComparator.before,
        expectedValues: ['1200'],
      );
      const rangeWithOne = ContradictionRule(
        id: 'r-2',
        projectId: 'p',
        title: 'Usia',
        dimension: ContradictionDimension.age,
        subjectKind: 'character',
        attributeKey: 'age',
        comparator: ContradictionComparator.withinRange,
        expectedValues: ['17'],
      );
      const rangeWithTwo = ContradictionRule(
        id: 'r-3',
        projectId: 'p',
        title: 'Usia',
        dimension: ContradictionDimension.age,
        subjectKind: 'character',
        attributeKey: 'age',
        comparator: ContradictionComparator.withinRange,
        expectedValues: ['17', '25'],
      );

      expect(single.validateSchema(), isEmpty);
      expect(rangeWithTwo.validateSchema(), isEmpty);

      final problems = rangeWithOne.validateSchema();
      expect(problems, hasLength(1));
      expect(problems.single, contains('withinRange'));
    });

    test('requires an owner project id', () {
      const rule = ContradictionRule(
        id: 'r-x',
        projectId: '',
        title: 'Kepemilikan',
        dimension: ContradictionDimension.ownership,
        subjectKind: 'item',
        attributeKey: 'ownerAssetId',
        comparator: ContradictionComparator.equals,
        expectedValues: ['char-1'],
      );

      expect(rule.validateSchema().single, contains('projectId'));
    });
  });

  group('severity_model', () {
    test('orders info below warning below violation', () {
      expect(
        ContradictionSeverity.info.index,
        lessThan(ContradictionSeverity.warning.index),
      );
      expect(
        ContradictionSeverity.warning.index,
        lessThan(ContradictionSeverity.violation.index),
      );
    });

    test('only violations block publication', () {
      expect(ContradictionSeverity.info.blocksPublication, isFalse);
      expect(ContradictionSeverity.warning.blocksPublication, isFalse);
      expect(ContradictionSeverity.violation.blocksPublication, isTrue);
    });
  });

  group('confidence_model', () {
    test('orders low below medium below high', () {
      expect(
        DetectionConfidence.low.index,
        lessThan(DetectionConfidence.medium.index),
      );
      expect(
        DetectionConfidence.medium.index,
        lessThan(DetectionConfidence.high.index),
      );
    });

    test('confidence stays independent from severity', () {
      // Data parsial boleh melahirkan pelanggaran keras dengan keyakinan
      // rendah — dua sumbu tidak saling menimpa.
      const finding = ContradictionFinding(
        id: 'f-1',
        ruleId: 'r-life',
        subjectId: 'char-9',
        dimension: ContradictionDimension.lifeStatus,
        severity: ContradictionSeverity.violation,
        confidence: DetectionConfidence.low,
        explanation: ContradictionExplanation(
          summary: 'Status hidup bertentangan',
          expectedValue: 'hidup',
          actualValue: 'tewas di bab 3',
        ),
      );

      expect(finding.severity.blocksPublication, isTrue);
      expect(finding.confidence, DetectionConfidence.low);
    });
  });

  group('explanation_contract', () {
    test('renders deterministic human-readable text with sources', () {
      const explanation = ContradictionExplanation(
        summary: 'Lokasi karakter bertentangan antar scene',
        expectedValue: 'Menara Utara',
        actualValue: 'Pelabuhan Selatan',
        sources: [
          ContradictionSourceRef(
            sourceId: 'scene-1',
            label: 'Bab 1 · Pembukaan',
          ),
          ContradictionSourceRef(sourceId: 'scene-7', label: 'Bab 3 · Badai'),
        ],
        suggestion: 'Perbarui lokasi bab 3 atau ubah rute perjalanan.',
      );

      final rendered = explanation.render(
        dimension: ContradictionDimension.location,
      );
      expect(rendered, contains('[location]'));
      expect(rendered, contains('Menara Utara'));
      expect(rendered, contains('Pelabuhan Selatan'));
      expect(rendered, contains('Bab 1 · Pembukaan'));
      expect(rendered, contains('Bab 3 · Badai'));
      expect(rendered, contains('Perbarui lokasi bab 3'));

      // Deterministik: render ulang menghasilkan teks identik.
      expect(
        explanation.render(dimension: ContradictionDimension.location),
        rendered,
      );
    });

    test('keeps source reference ids intact and in order', () {
      const explanation = ContradictionExplanation(
        summary: 'Fakta canon bertentangan',
        expectedValue: 'Kubus lahir di Kutub',
        actualValue: 'Kubus lahir di Gunung Api',
        sources: [
          ContradictionSourceRef(
            sourceId: 'entry-a',
            label: 'Bible · Asal Mula',
          ),
          ContradictionSourceRef(
            sourceId: 'entry-b',
            label: 'Bible · Kronologi',
          ),
          ContradictionSourceRef(
            sourceId: 'entry-c',
            label: 'Bible · Peta Dunia',
          ),
        ],
      );

      expect(explanation.sources.map((s) => s.sourceId).toList(), [
        'entry-a',
        'entry-b',
        'entry-c',
      ]);
    });

    test('finding carries the full contract payload', () {
      const explanation = ContradictionExplanation(
        summary: 'Umur tidak konsisten dengan rentang aturan',
        expectedValue: '17-25',
        actualValue: '300',
      );
      const finding = ContradictionFinding(
        id: 'f-age-1',
        ruleId: 'r-usia',
        subjectId: 'char-maya',
        dimension: ContradictionDimension.age,
        severity: ContradictionSeverity.warning,
        confidence: DetectionConfidence.high,
        explanation: explanation,
      );

      expect(finding.ruleId, 'r-usia');
      expect(finding.subjectId, 'char-maya');
      expect(finding.explanation.summary, contains('Umur'));
      expect(finding.dimension, ContradictionDimension.age);
    });
  });
}
