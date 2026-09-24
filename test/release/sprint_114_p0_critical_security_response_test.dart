import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/p0_critical_security_response_v114.dart';

void main() {
  group('114.28 P0 & Critical Security Response', () {
    test('empty response register is blocked without claiming an incident', () {
      final report = CriticalSecurityResponseRegister().evaluate();

      expect(report.status, CriticalResponseStatus.blocked);
      expect(report.caseCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete response records every emergency-path output', () {
      const response = CriticalResponseCase(
        incidentId: 'SEC-001',
        containment: 'Feature path isolated locally.',
        userProtection:
            'User data remains readable and no further writes occur.',
        rootCause: 'Invalid permission transition.',
        fix: 'Reject the transition before persistence.',
        tests: <String>['regression test'],
        advisory: 'Local advisory is ready for review.',
        rollbackOrPatch: 'Patch is available; rollback remains possible.',
      );

      expect(CriticalSecurityResponseRegister.missingFields(response), isEmpty);
      final register = CriticalSecurityResponseRegister()..add(response);
      expect(register.evaluate().status, CriticalResponseStatus.pass);
    });

    test('incomplete response fails with field evidence', () {
      const response = CriticalResponseCase(
        incidentId: 'SEC-002',
        containment: '',
        userProtection: 'Protection recorded.',
        rootCause: '',
        fix: 'Fix recorded.',
        tests: <String>[],
        advisory: 'Advisory recorded.',
        rollbackOrPatch: '',
      );

      final report = CriticalSecurityResponseRegister()..add(response);
      final result = report.evaluate();

      expect(result.status, CriticalResponseStatus.fail);
      expect(result.limitations.join(' '), contains('containment'));
      expect(result.limitations.join(' '), contains('root_cause'));
      expect(result.limitations.join(' '), contains('tests'));
      expect(result.limitations.join(' '), contains('rollback_or_patch'));
    });
  });
}
