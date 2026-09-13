import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/studio/domain/autopilot_governance.dart';

// Regression lock for vs-hunt-20260913-studio STU-BUG-02 (Referee verdict:
// REAL BUG). The destructive-command guard compared the raw command string,
// so case or whitespace variants ('DELETE', 'Delete', 'delete ') bypassed it.
void main() {
  AutopilotControl runningControl() {
    final control = AutopilotControl()
      ..mode = AutopilotMode.supervised
      ..start();
    return control;
  }

  test('delete guard blocks case and whitespace variants', () {
    final control = runningControl();
    expect(control.canExecute('delete'), isFalse);
    expect(
      control.canExecute('DELETE'),
      isFalse,
      reason: 'uppercase must not bypass the destructive-command guard',
    );
    expect(
      control.canExecute('Delete'),
      isFalse,
      reason: 'mixed case must not bypass the destructive-command guard',
    );
    expect(
      control.canExecute(' delete '),
      isFalse,
      reason: 'surrounding whitespace must not bypass the guard',
    );
  });

  test('non-destructive commands still execute when autopilot is eligible', () {
    final control = runningControl();
    expect(control.canExecute('summarize'), isTrue);
    expect(
      control.canExecute('  summarize  '),
      isTrue,
      reason: 'normalization must not reject ordinary commands',
    );
  });

  test('dry-run and paused states keep blocking every command', () {
    final dryRun = AutopilotControl()..start();
    expect(dryRun.canExecute('summarize'), isFalse);
    final paused = AutopilotControl()
      ..mode = AutopilotMode.active
      ..start()
      ..pause();
    expect(paused.canExecute('summarize'), isFalse);
  });
}
