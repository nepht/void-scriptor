import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/autopilot_governance.dart';

void main() {
  test('autopilot is bounded, pausable, and dry-run first', () {
    final control = AutopilotControl();
    expect(control.mode, AutopilotMode.dryRun);
    control.start();
    expect(control.isRunning, isTrue);
    control.pause();
    expect(control.isRunning, isFalse);
    expect(control.canExecute('delete'), isFalse);
  });

  test('approval gates and least privilege protect important actions', () {
    final governance = GovernancePolicy();
    final approval = governance.request('publish', important: true);
    expect(approval.status, ApprovalStatus.pending);
    expect(governance.execute(approval.id), isFalse);
    governance.approve(approval.id);
    expect(governance.execute(approval.id), isTrue);
    expect(governance.permission('temporary-tool').allows('read'), isTrue);
    expect(governance.permission('temporary-tool').allows('write'), isFalse);
  });
}
