/// Test for Publishing & Clean Export Validation (Step 113.18).
///
/// Validates: profiles, preflight, clean export, format rendering,
/// ownership manifest, watermark policy — all six acceptance criteria.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/publishing_clean_export_validation.dart';

void main() {
  group('113.18 Publishing & Clean Export Validation', () {
    late PublishingCleanExportValidation validation;

    setUp(() {
      validation = const PublishingCleanExportValidation();
    });

    // -----------------------------------------------------------------------
    // Profile validation
    // -----------------------------------------------------------------------
    group('profile_results', () {
      test('all three default profiles have correct format', () {
        final result = validation.validateProfiles();
        expect(result.docxValid, isTrue);
        expect(result.plainTextValid, isTrue);
        expect(result.webNovelValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('preset round-trip preserves format and settings', () {
        final result = validation.validateProfiles();
        expect(result.presetRoundTrip, isTrue);
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Preflight validation
    // -----------------------------------------------------------------------
    group('preflight_results', () {
      test('empty document is blocked by preflight', () {
        final result = validation.validatePreflight();
        expect(result.emptyDocBlocked, isTrue);
        expect(result.errors, isEmpty);
      });

      test('missing asset is blocked by preflight', () {
        final result = validation.validatePreflight();
        expect(result.missingAssetBlocked, isTrue);
      });

      test('unresolved spoilers detected as warnings', () {
        final result = validation.validatePreflight();
        expect(result.spoilersDetected, isTrue);
      });

      test('clean document passes preflight', () {
        final result = validation.validatePreflight();
        expect(result.cleanDocReady, isTrue);
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Clean export validation
    // -----------------------------------------------------------------------
    group('format_results', () {
      test('private notes are removed', () {
        final result = validation.validateCleanExport();
        expect(result.privateNotesRemoved, isTrue);
        expect(result.errors, isEmpty);
      });

      test('scene links are removed', () {
        final result = validation.validateCleanExport();
        expect(result.sceneLinksRemoved, isTrue);
      });

      test('lore links are removed', () {
        final result = validation.validateCleanExport();
        expect(result.loreLinksRemoved, isTrue);
      });

      test('bare links are removed', () {
        final result = validation.validateCleanExport();
        expect(result.bareLinksRemoved, isTrue);
      });

      test('fingerprint is deterministic', () {
        final result = validation.validateCleanExport();
        expect(result.fingerprintDeterministic, isTrue);
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Format render validation
    // -----------------------------------------------------------------------
    group('render_results', () {
      test('DOCX output contains title and chapter', () {
        final result = validation.validateFormatRender();
        expect(result.docxContainsTitle, isTrue);
        expect(result.docxContainsChapter, isTrue);
        expect(result.errors, isEmpty);
      });

      test('plain text output contains title and chapter', () {
        final result = validation.validateFormatRender();
        expect(result.plainTextContainsTitle, isTrue);
        expect(result.plainTextContainsChapter, isTrue);
      });

      test('web novel output contains title and chapter', () {
        final result = validation.validateFormatRender();
        expect(result.webNovelContainsTitle, isTrue);
        expect(result.webNovelContainsChapter, isTrue);
      });

      test('all formats render without errors', () {
        final result = validation.validateFormatRender();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Metadata validation
    // -----------------------------------------------------------------------
    group('metadata_results', () {
      test('ownership manifest is deterministic', () {
        final result = validation.validateMetadata();
        expect(result.manifestDeterministic, isTrue);
        expect(result.errors, isEmpty);
      });

      test('watermark applied for preview use', () {
        final result = validation.validateMetadata();
        expect(result.watermarkAppliedForPreview, isTrue);
      });

      test('watermark skipped for private master', () {
        final result = validation.validateMetadata();
        expect(result.watermarkSkippedForPrivate, isTrue);
      });

      test('ownership fields present in manifest', () {
        final result = validation.validateMetadata();
        expect(result.ownershipFieldsPresent, isTrue);
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

      test('profile_preset_round_trip is true', () {
        final results = validation.runAll();
        expect(results['profile_preset_round_trip'], isTrue);
      });

      test('preflight_blocks_empty_and_missing is true', () {
        final results = validation.runAll();
        expect(results['preflight_blocks_empty_and_missing'], isTrue);
      });

      test('clean_export_removes_internal_markers is true', () {
        final results = validation.runAll();
        expect(results['clean_export_removes_internal_markers'], isTrue);
      });

      test('format_render_preserves_chapter_structure is true', () {
        final results = validation.runAll();
        expect(results['format_render_preserves_chapter_structure'], isTrue);
      });

      test('ownership_manifest_deterministic is true', () {
        final results = validation.runAll();
        expect(results['ownership_manifest_deterministic'], isTrue);
      });

      test('watermark_policy_applies_by_use_case is true', () {
        final results = validation.runAll();
        expect(results['watermark_policy_applies_by_use_case'], isTrue);
      });
    });
  });
}
