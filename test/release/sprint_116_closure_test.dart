import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_116_closure.dart';

Sprint116ClosureCriterion _criterion(
  String name, {
  bool passed = true,
  String evidence = 'test evidence',
}) => Sprint116ClosureCriterion(name: name, passed: passed, evidence: evidence);

List<Sprint116ClosureCriterion> _healthyCriteria() => [
  for (final name in Sprint116Closure.criteriaNames) _criterion(name),
];

void main() {
  group('116.52 Sprint Closure', () {
    test('declares the canonical seven definition-of-done criteria', () {
      expect(Sprint116Closure.criteriaNames, const <String>[
        '32_providers_accounted_for',
        'no_bulk_fake_certification',
        'icons_reviewed',
        'quality_gates_complete',
        'uncertified_hidden_or_labeled',
        'beta_decision_recorded',
        'remaining_risks_owned',
      ]);
    });

    test('manifest records local deferred closure and external boundary', () {
      final file = File(Sprint116Closure.manifestPath);
      expect(file.existsSync(), isTrue, reason: 'missing manifest');
      final raw = file.readAsStringSync();
      final decoded = jsonDecode(raw);
      expect(decoded, isA<Map<String, dynamic>>());
      final manifest = decoded as Map<String, dynamic>;
      expect(manifest['canonical_step'], '116.52');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['closure_decision'], 'CLOSED_LOCAL_DEFERRED_EXTERNAL');
      expect(
        manifest['external_gates'],
        'DEFERRED-EXTERNAL',
        reason:
            'Manifest must explicitly defer external beta execution, credentials, provider live handshake, hosted CI, billing settlement, hardware, and publication.',
      );
    });

    test(
      'all criteria pass means local closure is ready and decision is recorded',
      () {
        final report = Sprint116Closure.evaluate(
          criteria: _healthyCriteria(),
          betaDecision: Sprint116Closure.betaDecisionLocalScope,
        );
        expect(
          report.decision,
          Sprint116ClosureDecision.closedLocalDeferredExternal,
        );
        expect(report.isClosed, isTrue);
        expect(report.passedCount, Sprint116Closure.criteriaNames.length);
        expect(report.unmetCriteria, isEmpty);
        expect(
          report.summary,
          contains('decision=closedLocalDeferredExternal'),
        );
        expect(report.summary, contains('passed=7/7'));
        expect(report.summary, contains('beta=BETA_ACCEPTANCE_LOCAL_READY'));
      },
    );

    test('an unmet criterion blocks closure and names the criterion', () {
      final criteria = [
        _criterion('32_providers_accounted_for'),
        _criterion('no_bulk_fake_certification'),
        _criterion('icons_reviewed', passed: false),
        _criterion('quality_gates_complete'),
        _criterion('uncertified_hidden_or_labeled'),
        _criterion('beta_decision_recorded'),
        _criterion('remaining_risks_owned'),
      ];
      final report = Sprint116Closure.evaluate(
        criteria: criteria,
        betaDecision: Sprint116Closure.betaDecisionLocalScope,
      );
      expect(report.decision, Sprint116ClosureDecision.blocked);
      expect(report.isClosed, isFalse);
      expect(report.unmetCriteria, ['icons_reviewed']);
      expect(report.passedCount, 6);
    });

    test('unknown beta decision fails closed', () {
      expect(
        () => Sprint116Closure.evaluate(
          criteria: _healthyCriteria(),
          betaDecision: 'UNKNOWN_DECISION',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('only BETA_ACCEPTANCE_LOCAL_READY is permitted'),
          ),
        ),
      );
    });

    test('blank evidence fails closed', () {
      final criteria = [
        _criterion('32_providers_accounted_for', evidence: ''),
        ..._healthyCriteria().skip(1),
      ];
      expect(
        () => Sprint116Closure.evaluate(
          criteria: criteria,
          betaDecision: Sprint116Closure.betaDecisionLocalScope,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('requires non-empty evidence'),
          ),
        ),
      );
    });

    test('rejects criteria that are not exactly the canonical set', () {
      final wrong = [
        _criterion('32_providers_accounted_for'),
        _criterion('UNKNOWN_CRITERION'),
      ];
      expect(
        () => Sprint116Closure.evaluate(
          criteria: wrong,
          betaDecision: Sprint116Closure.betaDecisionLocalScope,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('must contain exactly the canonical seven criteria'),
          ),
        ),
      );
    });
  });
}
