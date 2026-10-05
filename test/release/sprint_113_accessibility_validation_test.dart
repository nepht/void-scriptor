/// Test for Accessibility Validation (Step 113.21).
/// Validates: keyboard navigation, screen reader support, scaling, contrast,
/// reduced motion, and nonvisual fallback outputs.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/accessibility_validation.dart';
import '../canonical_source_support.dart';

void main() {
  group('113.21 Accessibility Validation', () {
    late AccessibilityValidator validator;

    setUp(() {
      validator = AccessibilityValidator();
    });

    // -----------------------------------------------------------------------
    // 1. Keyboard navigation
    // -----------------------------------------------------------------------
    group('keyboard_navigation', () {
      test('supports keyboard navigation', () {
        final result = validator.keyboardSupport();
        expect(result.isSupported, isTrue);
        expect(result.shortcutSupported, isTrue);
      });

      test('detects keyboard-only mode', () {
        if (skipUnlessExternalCanonical("detects keyboard-only mode")) {
          return;
        }
        final result = validator.keyboardSupport();
        expect(result.keyboardOnlyMode, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 2. Screen reader support
    // -----------------------------------------------------------------------
    group('screen_reader', () {
      test('supports screen reader', () {
        final result = validator.screenReaderSupport();
        expect(result.isSupported, isTrue);
        expect(result.readerType, isNot(isEmpty));
      });

      test('announces focus changes', () {
        final result = validator.screenReaderSupport();
        expect(result.announcesFocus, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 3. Scaling
    // -----------------------------------------------------------------------
    group('scaling', () {
      test('reports correct scaling factor', () {
        final result = validator.scalingFactor();
        expect(result, greaterThan(0.0));
        expect(result, lessThanOrEqualTo(3.0));
      });
    });

    // -----------------------------------------------------------------------
    // 4. Contrast
    // -----------------------------------------------------------------------
    group('contrast', () {
      test('meets minimum contrast ratio', () {
        final result = validator.contrastRatio();
        expect(result, greaterThanOrEqualTo(4.5));
      });
    });

    // -----------------------------------------------------------------------
    // 5. Reduced motion
    // -----------------------------------------------------------------------
    group('reduced_motion', () {
      test('detects reduced motion preference', () {
        final result = validator.reducedMotion();
        expect(result.reducedMotionEnabled, isA<bool>());
      });

      test('adapts animation duration', () {
        final result = validator.reducedMotion();
        expect(result.reducedDuration, isA<int>());
      });
    });

    // -----------------------------------------------------------------------
    // 6. Nonvisual fallback
    // -----------------------------------------------------------------------
    group('nonvisual_fallback', () {
      test('provides nonvisual output', () {
        final result = validator.nonvisualFallback();
        expect(result.hasNonvisualOutput, isTrue);
        expect(result.outputType, isNot(isEmpty));
      });

      test('output is accessible', () {
        final result = validator.nonvisualFallback();
        expect(result.isAccessible, isTrue);
      });
    });

    // 7. Manifest & required-evidence contract
    group('manifest', () {
      const manifestPath =
          'docs/planning/v1.2/sprint_113_accessibility_validation.json';

      test('manifest exists with canonical step 113.21', () {
        final file = File(manifestPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'missing manifest: $manifestPath',
        );
        final document =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(document['canonical_step'], '113.21');
        expect(document['title'], 'Accessibility Validation');
      });

      test('manifest declares all six required evidence groups', () {
        final document =
            jsonDecode(File(manifestPath).readAsStringSync())
                as Map<String, dynamic>;
        final evidence = document['required_evidence'] as Map<String, dynamic>;
        for (final key in [
          'keyboard_results',
          'screen_reader_results',
          'scaling_results',
          'contrast_results',
          'motion_results',
          'nonvisual_results',
        ]) {
          expect(
            evidence.containsKey(key),
            isTrue,
            reason: 'required_evidence missing $key',
          );
        }
        expect(document['limits'], contains('placeholder'));
      });
    });
  });
}
