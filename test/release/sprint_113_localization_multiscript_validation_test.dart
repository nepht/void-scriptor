/// Test for Localization & Multiscript Validation (Step 113.22).
/// Validates: locale, RTL, text expansion, calendar, unit/date, and
/// multiscript/conlang names.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/localization_multiscript_validation.dart';
import 'package:void_scriptor/l10n/app_localizations.dart';

void main() {
  group('113.22 Localization & Multiscript Validation', () {
    late LocalizationMultiscriptValidator validator;

    setUp(() {
      validator = LocalizationMultiscriptValidator();
    });

    // 1. Locale
    group('locale_results', () {
      test('app declares supported locales en and id', () {
        final codes = AppLocalizations.supportedLocales
            .map((l) => l.languageCode)
            .toList();
        expect(codes, containsAll(<String>['en', 'id']));
      });

      test('supported and unsupported locale detection', () {
        final result = validator.localeResults();
        expect(result.supportedLocales, containsAll(<String>['en', 'id']));
        expect(result.isSupported('en'), isTrue);
        expect(result.isSupported('id'), isTrue);
        expect(result.isSupported('fr'), isFalse);
      });

      test('unknown locale falls back to en', () {
        final result = validator.localeResults();
        expect(result.fallbackFor('fr'), 'en');
        expect(result.fallbackFor('id'), 'id');
      });
    });

    // 2. RTL
    group('rtl_results', () {
      test('rtl locales are detected', () {
        final result = validator.rtlResults();
        expect(result.rtlLocales, containsAll(<String>['ar', 'he']));
        expect(result.directionFor('ar'), LocalizedTextDirection.rtl);
        expect(result.directionFor('he'), LocalizedTextDirection.rtl);
      });

      test('ltr locales default and are not mirrored', () {
        final result = validator.rtlResults();
        expect(result.directionFor('en'), LocalizedTextDirection.ltr);
        expect(result.directionFor('id'), LocalizedTextDirection.ltr);
        expect(result.requiresMirroring('en'), isFalse);
        expect(result.requiresMirroring('he'), isTrue);
      });
    });

    // 3. Text expansion
    group('expansion_results', () {
      test('ui labels stay within expansion budget', () {
        final result = validator.expansionResults();
        expect(result.withinBudget, isTrue);
        expect(result.maxFactor, lessThanOrEqualTo(result.budget));
        expect(result.longestLocale, isNotEmpty);
      });

      test('german expansion measured against english baseline', () {
        final result = validator.expansionResults();
        expect(result.factorFor('de'), greaterThan(1.0));
        expect(result.factorFor('de'), lessThanOrEqualTo(result.budget));
      });
    });

    // 4. Calendar
    group('calendar_results', () {
      test('custom calendar renders per locale order', () {
        final result = validator.calendarResults();
        expect(result.daysPerYear, greaterThan(0));
        expect(result.monthCount, greaterThan(0));
        expect(result.ymdText, isNotEmpty);
        expect(result.dmyText, isNotEmpty);
        expect(result.dmyText, isNot(equals(result.ymdText)));
      });

      test('format parse round trip returns same tick', () {
        final result = validator.calendarResults();
        expect(result.roundTripTick, isTrue);
        expect(result.parsedTick, result.sourceTick);
      });
    });

    // 5. Units & dates
    group('unit_results', () {
      test('metric imperial conversion round trips', () {
        final result = validator.unitResults();
        expect(result.roundTrip, isTrue);
      });

      test('decimal and thousands separators differ per locale', () {
        final result = validator.unitResults();
        expect(result.formatQuantity(1234.5, 'en'), '1,234.5 km');
        expect(result.formatQuantity(1234.5, 'id'), '1.234,5 km');
      });
    });

    // 6. Multiscript names
    group('multiscript_results', () {
      test('names across scripts are preserved', () {
        final result = validator.multiscriptResults();
        expect(result.samples.length, greaterThanOrEqualTo(4));
        expect(result.allPreserved, isTrue);
        for (final sample in result.samples) {
          expect(sample.preserved, isTrue, reason: sample.script);
        }
      });

      test('empty or replacement-character names are rejected', () {
        expect(validator.isValidName(''), isFalse);
        expect(validator.isValidName('   '), isFalse);
        expect(validator.isValidName('Void\uFFFD'), isFalse);
        expect(validator.isValidName('虚空立方'), isTrue);
      });
    });

    // 7. Manifest & required-evidence contract
    group('manifest', () {
      const manifestPath =
          'docs/planning/v1.2/sprint_113_localization_multiscript_validation.json';

      test('manifest exists with canonical step 113.22', () {
        final file = File(manifestPath);
        expect(file.existsSync(), isTrue, reason: 'missing manifest');
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(document['canonical_step'], '113.22');
        expect(document['title'], 'Localization & Multiscript Validation');
      });

      test('manifest declares all six required evidence groups', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        final evidence = document['required_evidence'] as Map<String, dynamic>;
        for (final key in [
          'locale_results',
          'rtl_results',
          'expansion_results',
          'calendar_results',
          'unit_results',
          'multiscript_results',
        ]) {
          expect(
            evidence.containsKey(key),
            isTrue,
            reason: 'required_evidence missing $key',
          );
        }
        expect(document['limits'], contains('DEFERRED'));
      });
    });
  });
}
