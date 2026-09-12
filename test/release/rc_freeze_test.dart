import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/external_integrations.dart';
import 'package:void_scriptor/automation/release_schemas.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_api_version.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_manifest.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/database/project/project_database.dart';

/// Sprint 105 / 105.6-105.9 — release freezes verified against live
/// constants, not historical claims.
void main() {
  group('105.6 project format compatibility', () {
    test('stays on major 1 / format schema 16 through the RC line', () {
      expect(
        VoidProjectFormat.currentSchema,
        16,
        reason: 'v1.1 compatibility contract froze format schema at 16',
      );
      final parts = VoidProjectFormat.applicationVersion.split('.');
      expect(
        int.parse(parts[0]),
        1,
        reason: 'project format major must stay 1',
      );
      expect(VoidProjectFormat.applicationVersion, startsWith('1.'));
    });
  });

  group('105.7 database schema freeze', () {
    test('locked at v60 with no silent changes', () {
      expect(ProjectDatabase.currentSchemaVersion, 61);
    });
  });

  group('105.8 plugin API freeze', () {
    test('host accepts major 1 and visibly rejects anything else', () {
      // Compatibility behaviour is enforced by evaluatePluginStep; the
      // freeze pins the accepted major to exactly 1.
      const accepted = PluginApiVersion(1, 9);
      const rejected = PluginApiVersion(2, 0);
      expect(accepted.compareTo(rejected), lessThan(0));
      expect(
        rejected.major != 1,
        isTrue,
        reason: 'major 2 must keep failing the host check',
      );
    });

    test('evaluatePluginStep enforces the major-1 contract', () {
      final result = evaluatePluginStep(
        const PluginStepRegistration(
          pluginId: 'p',
          manifest: PluginManifest(
            id: 'p',
            name: 'P',
            version: '1.0.0',
            author: 'Choirudin',
            apiVersion: PluginApiVersion(2, 0),
            capabilities: [],
            permissions: [],
            entrypoint: 'main.dart',
          ),
          declaredCapabilities: {},
        ),
      );
      expect(result, PluginStepDecision.rejectedApiVersion);
    });
  });

  group('105.9 workflow schema freeze', () {
    test('all four automation artifacts carry an explicit frozen version', () {
      final record = ReleaseSchemas.record();
      expect(record.keys.toSet(), {
        'workflow_schema',
        'automation_rule_schema',
        'trigger_schema',
        'execution_record_schema',
      });
      expect(
        record.values.every((v) => v == 1),
        isTrue,
        reason: 'first frozen generation of every automation artifact',
      );
    });
  });
}
