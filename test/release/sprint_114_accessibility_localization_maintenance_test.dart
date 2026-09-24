import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/accessibility_localization_maintenance_v114.dart';

void main() {
  group('114.33 Accessibility & Localization Maintenance', () {
    test('empty register is blocked without claiming maintenance', () {
      final report = AccessibilityLocalizationMaintenanceRegister().evaluate();

      expect(report.state, MaintenanceState.blocked);
      expect(report.planCount, 0);
      expect(report.limitations, isNotEmpty);
    });

    test('complete maintenance records all six canonical outputs', () {
      const plan = AccessibilityLocalizationMaintenancePlan(
        maintenanceId: 'A11Y-L10N-001',
        fixes: <String>['Fix focus order after opening the recovery dialog.'],
        keyboardTests: <String>[
          'test/release/sprint_114_accessibility_localization_maintenance_test.dart',
        ],
        screenReaderTests: <String>[
          'test/features/accessibility/screen_reader_journey_test.dart',
        ],
        scalingTests: <String>[
          'test/features/accessibility/text_scaling_layout_test.dart',
        ],
        localeTests: <String>[
          'test/features/localization/locale_catalog_test.dart',
        ],
        multiscriptTests: <String>[
          'test/features/localization/multiscript_name_rendering_test.dart',
        ],
      );

      expect(
        AccessibilityLocalizationMaintenancePlan.requiredFields(plan),
        isEmpty,
      );
      final report = AccessibilityLocalizationMaintenanceRegister()..add(plan);
      final evaluation = report.evaluate();
      expect(evaluation.state, MaintenanceState.pass);
      expect(evaluation.planCount, 1);
    });

    test('incomplete maintenance names every missing output', () {
      final report = AccessibilityLocalizationMaintenanceRegister()
        ..add(
          const AccessibilityLocalizationMaintenancePlan(
            maintenanceId: '',
            fixes: <String>[],
            keyboardTests: <String>[],
            screenReaderTests: <String>[],
            scalingTests: <String>[],
            localeTests: <String>[],
            multiscriptTests: <String>[],
          ),
        );
      final result = report.evaluate();

      expect(result.state, MaintenanceState.fail);
      final notes = result.limitations.join(' ');
      for (final field in <String>[
        'maintenance_id',
        'fixes',
        'keyboard_tests',
        'screen_reader_tests',
        'scaling_tests',
        'locale_tests',
        'multiscript_tests',
      ]) {
        expect(notes, contains(field));
      }
    });

    test('blank output entries are invalid evidence', () {
      const plan = AccessibilityLocalizationMaintenancePlan(
        maintenanceId: 'A11Y-L10N-002',
        fixes: <String>[''],
        keyboardTests: <String>['keyboard test'],
        screenReaderTests: <String>['screen reader test'],
        scalingTests: <String>['scaling test'],
        localeTests: <String>['locale test'],
        multiscriptTests: <String>['multiscript test'],
      );

      expect(
        AccessibilityLocalizationMaintenancePlan.requiredFields(plan),
        contains('fixes'),
      );
    });

    test('manifest records the canonical outputs and external limits', () {
      final manifest =
          json.decode(
                File(
                  'docs/planning/v1.2/sprint_114_accessibility_localization_maintenance.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.33');
      expect(
        manifest['outputs'],
        containsAll(<String>[
          'fixes',
          'keyboard_tests',
          'screen_reader_tests',
          'scaling_tests',
          'locale_tests',
          'multiscript_tests',
        ]),
      );
      expect(manifest['limits'], isNotEmpty);
    });
  });
}
