/// Test for Platform Validation Matrix (Step 113.20).
///
/// Validates: platforms, os_versions, hardware_profiles, input_modes,
/// results, exceptions — all six required evidence outputs.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/platform_validation_matrix.dart';

void main() {
  group('113.20 Platform Validation Matrix', () {
    late PlatformValidationMatrix matrix;

    setUp(() {
      matrix = const PlatformValidationMatrix();
    });

    // -----------------------------------------------------------------------
    // 1. Platform detection
    // -----------------------------------------------------------------------
    group('platform_detection', () {
      test('detects current platform', () {
        final result = matrix.detectPlatform();
        expect(result.detectedPlatform, isNot(ValidatedPlatform.unknown));
        expect(result.errors, isEmpty);
      });

      test('os_version is non-empty', () {
        final result = matrix.detectPlatform();
        expect(result.osVersion, isNotEmpty);
      });

      test('cpu_arch is non-empty', () {
        final result = matrix.detectPlatform();
        expect(result.cpuArch, isNotEmpty);
      });

      test('platform detection is valid', () {
        final result = matrix.detectPlatform();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 2. Hardware profile
    // -----------------------------------------------------------------------
    group('hardware_profile', () {
      test('detects hardware profile', () {
        final result = matrix.detectHardware();
        expect(result.isValid, isTrue);
        expect(result.cpuArch, isNotEmpty);
      });

      test('matches detected platform', () {
        final platform = matrix.detectPlatform();
        final hardware = matrix.detectHardware();
        expect(hardware.platform, equals(platform.detectedPlatform));
      });

      test('cpu arch is non-empty', () {
        final hardware = matrix.detectHardware();
        expect(hardware.cpuArch, isNotEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // 3. Input modes
    // -----------------------------------------------------------------------
    group('input_modes', () {
      test('detects primary input mode', () {
        final result = matrix.validateInputModes();
        expect(
          result.primaryModeDetected,
          anyOf(equals(InputMode.keyboardMouse), equals(InputMode.touch)),
        );
        expect(result.errors, isEmpty);
      });

      test('keyboard shortcut support on desktop', () {
        final result = matrix.validateInputModes();
        expect(result.keyboardShortcutSupport, isTrue);
        expect(result.mouseOrPointerSupport, isTrue);
      });

      test('all input mode criteria pass', () {
        final result = matrix.validateInputModes();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 4. Core workflow simulation
    // -----------------------------------------------------------------------
    group('workflow', () {
      test('create workflow succeeds', () {
        final result = matrix.validateCoreWorkflow();
        expect(result.createWorkflow, isTrue);
        expect(result.errors, isEmpty);
      });

      test('edit workflow succeeds', () {
        final result = matrix.validateCoreWorkflow();
        expect(result.editWorkflow, isTrue);
      });

      test('export workflow succeeds', () {
        final result = matrix.validateCoreWorkflow();
        expect(result.exportWorkflow, isTrue);
      });

      test('search workflow succeeds', () {
        final result = matrix.validateCoreWorkflow();
        expect(result.searchWorkflow, isTrue);
      });

      test('simulate workflow succeeds', () {
        final result = matrix.validateCoreWorkflow();
        expect(result.simulateWorkflow, isTrue);
      });

      test('all workflow criteria pass', () {
        final result = matrix.validateCoreWorkflow();
        expect(result.allValid, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 5. Exception tracking
    // -----------------------------------------------------------------------
    group('exceptions', () {
      test('no critical exceptions', () {
        final result = matrix.trackExceptions();
        expect(result.hasNoCriticalExceptions, isTrue);
      });

      test('known exceptions are documented', () {
        final result = matrix.trackExceptions();
        // Should have at least one known exception for current platform
        expect(result.knownExceptions, isNotEmpty);
      });

      test('warnings are non-critical', () {
        final result = matrix.trackExceptions();
        // Warnings should not be fatal
        for (final warning in result.warnings) {
          expect(warning, isNotEmpty);
        }
      });
    });

    // -----------------------------------------------------------------------
    // 6. Manifest validation
    // -----------------------------------------------------------------------
    group('manifest', () {
      test('manifest file exists and is valid', () {
        final result = matrix.validateManifest();
        expect(result, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 7. Aggregate validation
    // -----------------------------------------------------------------------
    group('aggregate', () {
      test('all criteria pass', () {
        final result = matrix.runAll();
        expect(result.platformDetection.allValid, isTrue);
        expect(result.hardwareProfile.isValid, isTrue);
        expect(result.inputModes.allValid, isTrue);
        expect(result.workflow.allValid, isTrue);
        expect(result.exceptions.hasNoCriticalExceptions, isTrue);
        expect(result.manifestValid, isTrue);
        expect(result.allValid, isTrue);
      });

      test('platforms result is populated', () {
        final result = matrix.runAll();
        expect(
          result.platformDetection.detectedPlatform,
          isNot(ValidatedPlatform.unknown),
        );
      });

      test('os_versions result is populated', () {
        final result = matrix.runAll();
        expect(result.platformDetection.osVersion, isNotEmpty);
      });

      test('hardware_profiles result is populated', () {
        final result = matrix.runAll();
        expect(result.hardwareProfile.isValid, isTrue);
      });

      test('input_modes result is populated', () {
        final result = matrix.runAll();
        expect(result.inputModes.allValid, isTrue);
      });

      test('results is populated (all workflows pass)', () {
        final result = matrix.runAll();
        expect(result.workflow.allValid, isTrue);
      });

      test('exceptions are tracked', () {
        final result = matrix.runAll();
        expect(result.exceptions.knownExceptions, isNotEmpty);
        expect(result.exceptions.hasNoCriticalExceptions, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // 8. File presence check
    // -----------------------------------------------------------------------
    test('domain source file exists', () {
      final file = File(
        'lib/features/world_logic/domain/platform_validation_matrix.dart',
      );
      expect(file.existsSync(), isTrue);
    });

    test('manifest JSON file exists', () {
      final file = File(
        'docs/planning/v1.2/sprint_113_platform_validation_matrix.json',
      );
      expect(file.existsSync(), isTrue);
    });
  });
}
