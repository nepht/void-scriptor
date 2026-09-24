import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/technical_debt_deferred_risk_register_v114.dart';

void main() {
  group('114.42 Technical Debt & Deferred Risk Register', () {
    final validItem = TechnicalDebtDeferredRiskItem(
      itemId: 'RISK-114-01',
      kind: TechnicalDebtDeferredRiskKind.externalEvidence,
      item: 'Public release evidence remains unavailable.',
      impact:
          'Release path remains DELAYED; GA and production health are not claimed.',
      evidence: <String>[
        'docs/planning/v1.2/sprint_114_post_release_entry_gate.json',
      ],
      reasonDeferred:
          'No public release, telemetry, or incident channel is active.',
      owner: 'release-owner',
      target: 'When a public release starts its observation window',
      trigger: 'Public release evidence or a live health breach is recorded.',
    );

    test('declares the seven canonical register fields', () {
      expect(TechnicalDebtDeferredRiskRegisterContract.canonicalStep, '114.42');
      expect(TechnicalDebtDeferredRiskRegisterContract.requiredFields, <String>[
        'item',
        'impact',
        'evidence',
        'reason_deferred',
        'owner',
        'target',
        'trigger',
      ]);
      expect(
        TechnicalDebtDeferredRiskRegisterContract.manifestPath,
        endsWith('sprint_114_technical_debt_deferred_risk_register.json'),
      );
    });

    test('empty register is blocked without claiming debt is absent', () {
      final report = TechnicalDebtDeferredRiskRegisterGate().evaluate(
        TechnicalDebtDeferredRiskRegisterDraft(
          items: const <TechnicalDebtDeferredRiskItem>[],
        ),
      );

      expect(report.state, TechnicalDebtDeferredRiskState.blocked);
      expect(report.itemCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete owned deferred-risk item passes with immutable lists', () {
      final register = TechnicalDebtDeferredRiskRegisterDraft(
        items: <TechnicalDebtDeferredRiskItem>[validItem],
        itemIds: const <String>['RISK-114-01'],
      );
      final report = TechnicalDebtDeferredRiskRegisterGate().evaluate(register);

      expect(report.state, TechnicalDebtDeferredRiskState.pass);
      expect(report.itemCount, 1);
      expect(report.violations, isEmpty);
      expect(
        () => report.items.single.evidence.add('late mutation'),
        throwsUnsupportedError,
      );
    });

    test('missing canonical fields fail closed by field name', () {
      final register = TechnicalDebtDeferredRiskRegisterDraft(
        items: <TechnicalDebtDeferredRiskItem>[
          TechnicalDebtDeferredRiskItem(
            itemId: 'RISK-114-02',
            kind: TechnicalDebtDeferredRiskKind.technicalDebt,
            item: ' ',
            impact: '',
            evidence: <String>[],
            reasonDeferred: ' ',
            owner: '',
            target: ' ',
            trigger: '',
          ),
        ],
        itemIds: const <String>['RISK-114-02'],
      );
      final report = TechnicalDebtDeferredRiskRegisterGate().evaluate(register);

      expect(report.state, TechnicalDebtDeferredRiskState.fail);
      expect(
        report.violations,
        containsAll(<String>[
          'RISK-114-02 missing item',
          'RISK-114-02 missing impact',
          'RISK-114-02 missing evidence',
          'RISK-114-02 missing reason_deferred',
          'RISK-114-02 missing owner',
          'RISK-114-02 missing target',
          'RISK-114-02 missing trigger',
        ]),
      );
    });

    test('duplicate or unknown item identifiers are rejected', () {
      final register = TechnicalDebtDeferredRiskRegisterDraft(
        items: <TechnicalDebtDeferredRiskItem>[validItem, validItem],
        itemIds: const <String>['RISK-114-01', 'RISK-114-01', 'UNKNOWN'],
      );
      final report = TechnicalDebtDeferredRiskRegisterGate().evaluate(register);

      expect(report.state, TechnicalDebtDeferredRiskState.fail);
      expect(
        report.violations,
        containsAll(<String>['duplicate_RISK-114-01', 'unknown_UNKNOWN']),
      );
    });

    test('an ownerless risk cannot be represented as deferred', () {
      final register = TechnicalDebtDeferredRiskRegisterDraft(
        items: <TechnicalDebtDeferredRiskItem>[validItem.copyWith(owner: ' ')],
        itemIds: const <String>['RISK-114-01'],
      );
      final report = TechnicalDebtDeferredRiskRegisterGate().evaluate(register);

      expect(report.state, TechnicalDebtDeferredRiskState.fail);
      expect(report.violations, contains('RISK-114-01 missing owner'));
    });

    test(
      'manifest records owned risks without changing external-gate status',
      () {
        final file = File(
          TechnicalDebtDeferredRiskRegisterContract.manifestPath,
        );
        expect(file.existsSync(), isTrue);
        final manifest =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final risks = manifest['risks'] as List<dynamic>;

        expect(manifest['canonical_step'], '114.42');
        expect(manifest['status'], 'VERIFIED-LOCAL');
        expect(manifest['required_fields'], <String>[
          'item',
          'impact',
          'evidence',
          'reason_deferred',
          'owner',
          'target',
          'trigger',
        ]);
        expect(risks, isNotEmpty);
        for (final rawRisk in risks) {
          final risk = rawRisk as Map<String, dynamic>;
          expect(risk['item_id'], isA<String>());
          expect(risk['kind'], isA<String>());
          expect(risk['impact'], isA<String>());
          expect(risk['evidence'], isA<List<dynamic>>());
          expect(risk['reason_deferred'], isA<String>());
          expect(risk['owner'], isA<String>());
          expect(risk['target'], isA<String>());
          expect(risk['trigger'], isA<String>());
          for (final evidence in risk['evidence'] as List<dynamic>) {
            final path = (evidence as String).split('#').first;
            expect(File(path).existsSync(), isTrue, reason: path);
          }
        }
        expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
        expect(manifest['limitations'], isNotEmpty);
      },
    );
  });
}
