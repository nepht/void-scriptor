import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/localization_multiscript_health.dart';

void main() {
  group('114.21 Localization & Multiscript Health', () {
    test('absent observations are blocked without health claims', () {
      final report = LocalizationMultiscriptHealth().evaluate(null);

      expect(report.state, LocalizationState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = LocalizationMultiscriptHealth()
          .evaluate(<LocalizationObservation>[
            const LocalizationObservation(
              signal: LocalizationSignal.localeIssue,
              outcome: LocalizationOutcome.ok,
              note: 'Active locale resolves to a complete message catalog.',
            ),
          ]);

      expect(report.state, LocalizationState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <LocalizationSignal>[
        LocalizationSignal.localeIssue,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
          textOverflowNote: '',
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('failed locale_issue is not covered by other ok signals', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.failed,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('locale_issue_unrecovered'));
    });

    test('failed rtl_issue is unrecovered', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.failed,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('rtl_issue_unrecovered'));
    });

    test('failed text_overflow is unrecovered', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.failed,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('text_overflow_unrecovered'));
    });

    test('failed date_issue is unrecovered', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.failed,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('date_issue_unrecovered'));
    });

    test('failed calendar_issue and unit_issue report both violations', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.failed,
          unitIssue: LocalizationOutcome.failed,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('calendar_issue_unrecovered'));
      expect(report.violations, contains('unit_issue_unrecovered'));
    });

    test('failed multiscript_issue is not covered by other ok signals', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.failed,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('multiscript_issue_unrecovered'));
    });

    test('recovered rtl does not excuse a failed locale_issue', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.failed,
          rtlIssue: LocalizationOutcome.recovered,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.fail);
      expect(report.violations, contains('locale_issue_unrecovered'));
    });

    test('honestly recovered signals pass without violations', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.recovered,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.recovered,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
          localeNote:
              'Missing catalog keys backfilled and re-verified for the active locale.',
        ),
      );

      expect(report.state, LocalizationState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all seven signals', () {
      final report = LocalizationMultiscriptHealth().evaluate(
        _observations(
          localeIssue: LocalizationOutcome.ok,
          rtlIssue: LocalizationOutcome.ok,
          textOverflow: LocalizationOutcome.ok,
          dateIssue: LocalizationOutcome.ok,
          calendarIssue: LocalizationOutcome.ok,
          unitIssue: LocalizationOutcome.ok,
          multiscriptIssue: LocalizationOutcome.ok,
        ),
      );

      expect(report.state, LocalizationState.pass);
      expect(report.coveredSignals, <LocalizationSignal>[
        LocalizationSignal.localeIssue,
        LocalizationSignal.rtlIssue,
        LocalizationSignal.textOverflow,
        LocalizationSignal.dateIssue,
        LocalizationSignal.calendarIssue,
        LocalizationSignal.unitIssue,
        LocalizationSignal.multiscriptIssue,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_localization_multiscript_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.21');
      expect(document['required_evidence'], <dynamic>[
        'locale_issue',
        'rtl_issue',
        'text_overflow',
        'date_issue',
        'calendar_issue',
        'unit_issue',
        'multiscript_issue',
      ]);
      expect(document['root_recovery_signal'], isNull);
      expect(document['recovery_model'], 'per_signal_self_recovery');
      expect(document['native_locale_verification'], 'DEFERRED-EXTERNAL');
      expect(document['public_distribution_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<LocalizationObservation> _observations({
  required LocalizationOutcome localeIssue,
  required LocalizationOutcome rtlIssue,
  required LocalizationOutcome textOverflow,
  required LocalizationOutcome dateIssue,
  required LocalizationOutcome calendarIssue,
  required LocalizationOutcome unitIssue,
  required LocalizationOutcome multiscriptIssue,
  String? localeNote,
  String? textOverflowNote,
}) {
  return <LocalizationObservation>[
    LocalizationObservation(
      signal: LocalizationSignal.localeIssue,
      outcome: localeIssue,
      note:
          localeNote ??
          'Active locale resolves to a complete message catalog without fallback gaps.',
    ),
    LocalizationObservation(
      signal: LocalizationSignal.rtlIssue,
      outcome: rtlIssue,
      note: 'RTL locales mirror layout, alignment, and navigation direction.',
    ),
    LocalizationObservation(
      signal: LocalizationSignal.textOverflow,
      outcome: textOverflow,
      note:
          textOverflowNote ??
          'Translated strings fit their containers at supported text scales.',
    ),
    LocalizationObservation(
      signal: LocalizationSignal.dateIssue,
      outcome: dateIssue,
      note: 'Dates format per locale with correct order and separators.',
    ),
    LocalizationObservation(
      signal: LocalizationSignal.calendarIssue,
      outcome: calendarIssue,
      note: 'Non-Gregorian calendar references render consistently.',
    ),
    LocalizationObservation(
      signal: LocalizationSignal.unitIssue,
      outcome: unitIssue,
      note: 'Measurement units follow locale conventions without mixing.',
    ),
    LocalizationObservation(
      signal: LocalizationSignal.multiscriptIssue,
      outcome: multiscriptIssue,
      note: 'Multiscript and conlang names render without glyph loss.',
    ),
  ];
}
