/// Test for Offline & Local-First Validation (Step 113.19).
///
/// Validates: offline open, edit, analysis, search, local export,
/// provider failure fallback — all six acceptance criteria.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/offline_local_first_validation.dart';

void main() {
  group('113.19 Offline & Local-First Validation', () {
    late OfflineLocalFirstValidation validation;

    setUp(() {
      validation = const OfflineLocalFirstValidation();
    });

    // -----------------------------------------------------------------------
    // 1. Offline open
    // -----------------------------------------------------------------------
    group('offline_open', () {
      test('workflow processes locally without network', () {
        final result = validation.validateOfflineOpen();
        expect(result.workflowProcessesLocally, isTrue);
        expect(result.errors, isEmpty);
      });

      test('empty project ID is rejected', () {
        final result = validation.validateOfflineOpen();
        expect(result.emptyProjectIdRejected, isTrue);
      });

      test('all offline open criteria pass', () {
        final result = validation.validateOfflineOpen();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 2. Offline edit
    // -----------------------------------------------------------------------
    group('offline_edit', () {
      test('draft is modified locally', () {
        final result = validation.validateOfflineEdit();
        expect(result.draftModifiedLocally, isTrue);
        expect(result.errors, isEmpty);
      });

      test('source content is preserved', () {
        final result = validation.validateOfflineEdit();
        expect(result.sourcePreserved, isTrue);
      });

      test('all offline edit criteria pass', () {
        final result = validation.validateOfflineEdit();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 3. Offline analysis
    // -----------------------------------------------------------------------
    group('offline_analysis', () {
      test('preflight detects empty document issue', () {
        final result = validation.validateOfflineAnalysis();
        expect(result.preflightDetectsIssues, isTrue);
        expect(result.errors, isEmpty);
      });

      test('clean export removes markers locally', () {
        final result = validation.validateOfflineAnalysis();
        expect(result.cleanExportTransforms, isTrue);
      });

      test('all offline analysis criteria pass', () {
        final result = validation.validateOfflineAnalysis();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 4. Offline search
    // -----------------------------------------------------------------------
    group('offline_search', () {
      test('index is built locally', () {
        final result = validation.validateOfflineSearch();
        expect(result.indexBuiltLocally, isTrue);
        expect(result.errors, isEmpty);
      });

      test('search returns results', () {
        final result = validation.validateOfflineSearch();
        expect(result.searchReturnsResults, isTrue);
      });

      test('empty query returns empty', () {
        final result = validation.validateOfflineSearch();
        expect(result.emptyQueryReturnsEmpty, isTrue);
      });

      test('all offline search criteria pass', () {
        final result = validation.validateOfflineSearch();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 5. Local export
    // -----------------------------------------------------------------------
    group('local_export', () {
      test('DOCX output is produced locally', () {
        final result = validation.validateLocalExport();
        expect(result.docxOutput, isTrue);
        expect(result.errors, isEmpty);
      });

      test('plain text output is produced locally', () {
        final result = validation.validateLocalExport();
        expect(result.plainTextOutput, isTrue);
      });

      test('web novel output is produced locally', () {
        final result = validation.validateLocalExport();
        expect(result.webNovelOutput, isTrue);
      });

      test('profiles are locally configurable', () {
        final result = validation.validateLocalExport();
        expect(result.profileLocallyConfigurable, isTrue);
      });

      test('all local export criteria pass', () {
        final result = validation.validateLocalExport();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 6. Provider failure fallback
    // -----------------------------------------------------------------------
    group('provider_failure_fallback', () {
      test('actions are queued when provider unavailable', () {
        final result = validation.validateProviderFallback();
        expect(result.queuesWhenUnavailable, isTrue);
        expect(result.errors, isEmpty);
      });

      test('no crash when provider is unavailable', () {
        final result = validation.validateProviderFallback();
        expect(result.noCrashOnUnavailable, isTrue);
      });

      test('all provider fallback criteria pass', () {
        final result = validation.validateProviderFallback();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Aggregate acceptance
    // -----------------------------------------------------------------------
    group('acceptance', () {
      test('all six acceptance criteria pass', () {
        final results = validation.runAll();
        expect(results.length, 6);
        for (final entry in results.entries) {
          expect(
            entry.value,
            isTrue,
            reason: 'Acceptance criterion "${entry.key}" failed',
          );
        }
      });

      test('offline_open is true', () {
        final results = validation.runAll();
        expect(results['offline_open'], isTrue);
      });

      test('offline_edit is true', () {
        final results = validation.runAll();
        expect(results['offline_edit'], isTrue);
      });

      test('offline_analysis is true', () {
        final results = validation.runAll();
        expect(results['offline_analysis'], isTrue);
      });

      test('offline_search is true', () {
        final results = validation.runAll();
        expect(results['offline_search'], isTrue);
      });

      test('local_export is true', () {
        final results = validation.runAll();
        expect(results['local_export'], isTrue);
      });

      test('provider_failure_fallback is true', () {
        final results = validation.runAll();
        expect(results['provider_failure_fallback'], isTrue);
      });
    });
  });
}
