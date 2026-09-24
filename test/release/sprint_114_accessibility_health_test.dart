import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/accessibility_health.dart';

void main() {
  group('114.20 Accessibility Health', () {
    test('absent observations are blocked without health claims', () {
      final report = AccessibilityHealth().evaluate(null);

      expect(report.state, AccessibilityState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = AccessibilityHealth().evaluate(<AccessibilityObservation>[
        const AccessibilityObservation(
          signal: AccessibilitySignal.keyboardBlocker,
          outcome: AccessibilityOutcome.ok,
          note: 'Keyboard-only traversal reaches every primary workflow.',
        ),
      ]);

      expect(report.state, AccessibilityState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <AccessibilitySignal>[
        AccessibilitySignal.keyboardBlocker,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.ok,
          scalingNote: '',
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('failed keyboard_blocker is not covered by other ok signals', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.failed,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.ok,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('keyboard_blocker_unrecovered'));
    });

    test('failed screen_reader_blocker is unrecovered', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.failed,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.ok,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('screen_reader_blocker_unrecovered'));
    });

    test('failed focus_loss is unrecovered', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.failed,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.ok,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('focus_loss_unrecovered'));
    });

    test('failed scaling_break is unrecovered', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.failed,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.ok,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('scaling_break_unrecovered'));
    });

    test('failed contrast_issue and motion_issue report both violations', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.failed,
          motionIssue: AccessibilityOutcome.failed,
          nonvisualGap: AccessibilityOutcome.ok,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('contrast_issue_unrecovered'));
      expect(report.violations, contains('motion_issue_unrecovered'));
    });

    test('failed nonvisual_gap is not covered by other ok signals', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.failed,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('nonvisual_gap_unrecovered'));
    });

    test('recovered nonvisual fallback does not excuse a failed blocker', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.failed,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.recovered,
        ),
      );

      expect(report.state, AccessibilityState.fail);
      expect(report.violations, contains('contrast_issue_unrecovered'));
    });

    test('honestly recovered blockers pass without violations', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.recovered,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.recovered,
          keyboardNote:
              'Focus order re-tested after remediation; blocker cleared.',
        ),
      );

      expect(report.state, AccessibilityState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all seven signals', () {
      final report = AccessibilityHealth().evaluate(
        _observations(
          keyboardBlocker: AccessibilityOutcome.ok,
          screenReaderBlocker: AccessibilityOutcome.ok,
          focusLoss: AccessibilityOutcome.ok,
          scalingBreak: AccessibilityOutcome.ok,
          contrastIssue: AccessibilityOutcome.ok,
          motionIssue: AccessibilityOutcome.ok,
          nonvisualGap: AccessibilityOutcome.ok,
        ),
      );

      expect(report.state, AccessibilityState.pass);
      expect(report.coveredSignals, <AccessibilitySignal>[
        AccessibilitySignal.keyboardBlocker,
        AccessibilitySignal.screenReaderBlocker,
        AccessibilitySignal.focusLoss,
        AccessibilitySignal.scalingBreak,
        AccessibilitySignal.contrastIssue,
        AccessibilitySignal.motionIssue,
        AccessibilitySignal.nonvisualGap,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_accessibility_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.20');
      expect(document['required_evidence'], <dynamic>[
        'keyboard_blocker',
        'screen_reader_blocker',
        'focus_loss',
        'scaling_break',
        'contrast_issue',
        'motion_issue',
        'nonvisual_gap',
      ]);
      expect(document['root_recovery_signal'], isNull);
      expect(document['recovery_model'], 'per_signal_self_recovery');
      expect(document['native_at_verification'], 'DEFERRED-EXTERNAL');
      expect(document['public_distribution_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<AccessibilityObservation> _observations({
  required AccessibilityOutcome keyboardBlocker,
  required AccessibilityOutcome screenReaderBlocker,
  required AccessibilityOutcome focusLoss,
  required AccessibilityOutcome scalingBreak,
  required AccessibilityOutcome contrastIssue,
  required AccessibilityOutcome motionIssue,
  required AccessibilityOutcome nonvisualGap,
  String? keyboardNote,
  String? scalingNote,
}) {
  return <AccessibilityObservation>[
    AccessibilityObservation(
      signal: AccessibilitySignal.keyboardBlocker,
      outcome: keyboardBlocker,
      note:
          keyboardNote ??
          'Keyboard-only traversal reaches every primary workflow.',
    ),
    AccessibilityObservation(
      signal: AccessibilitySignal.screenReaderBlocker,
      outcome: screenReaderBlocker,
      note: 'Screen reader announces focus, results, and errors.',
    ),
    AccessibilityObservation(
      signal: AccessibilitySignal.focusLoss,
      outcome: focusLoss,
      note: 'Focus stays visible and returns after dialogs close.',
    ),
    AccessibilityObservation(
      signal: AccessibilitySignal.scalingBreak,
      outcome: scalingBreak,
      note:
          scalingNote ??
          'Layouts hold from 100% to 300% text scaling without clipping.',
    ),
    AccessibilityObservation(
      signal: AccessibilitySignal.contrastIssue,
      outcome: contrastIssue,
      note: 'Text and controls meet WCAG AA contrast ratios.',
    ),
    AccessibilityObservation(
      signal: AccessibilitySignal.motionIssue,
      outcome: motionIssue,
      note: 'Reduced-motion preference disables non-essential animation.',
    ),
    AccessibilityObservation(
      signal: AccessibilitySignal.nonvisualGap,
      outcome: nonvisualGap,
      note: 'Nonvisual fallback output exists and is labeled accessibly.',
    ),
  ];
}
