import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/command_bus.dart';
import 'package:void_scriptor/core/commands/command_event_bus.dart';
import 'package:void_scriptor/core/commands/workspace_event_contract.dart';
import 'package:void_scriptor/core/plugin/domain/plugin_api_version.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/database/project/project_database.dart';

void main() {
  group('112.40 contract compatibility', () {
    test('required output manifest records all compatibility boundaries', () {
      final file = File(
        'docs/planning/v1.2/sprint_112_contract_compatibility_verification.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.40');
      expect(
        document.keys,
        containsAll(<String>[
          'contract_results',
          'plugin_results',
          'file_format_results',
          'event_results',
          'breaking_changes',
          'fix_status',
        ]),
      );
      expect(document['breaking_changes'], isEmpty);
      expect(document['decision'], 'PASS_LOCAL_WITH_RESIDUAL_WIRING');
    });

    test('Wave 1-3 frozen format and plugin contracts remain compatible', () {
      expect(VoidProjectFormat.currentSchema, 16);
      expect(ProjectDatabase.currentSchemaVersion, 62);
      expect(
        const PluginApiVersion(
          1,
          0,
        ).isCompatibleWith(const PluginApiVersion(1, 9)),
        isTrue,
      );
      expect(
        const PluginApiVersion(
          2,
          0,
        ).isCompatibleWith(const PluginApiVersion(1, 9)),
        isFalse,
      );
    });

    test('WS-EVENTS v1 exposes stable names without canon payload', () {
      const event = WorkspaceContractEvent(
        name: WorkspaceEventName.linkModeChanged,
        projectId: 'project-1',
        entityIds: <String>['novel-1', 'character-1'],
      );

      expect(
        WorkspaceEventName.linkModeChanged.wireName,
        'ws.link.mode_changed',
      );
      expect(event.toJson(), <String, Object?>{
        'schema': 'ws-events/v1',
        'name': 'ws.link.mode_changed',
        'project_id': 'project-1',
        'entity_ids': <String>['novel-1', 'character-1'],
      });
      expect(WorkspaceContractEvent.fromJson(event.toJson()), event);
      expect(event.toJson().keys, isNot(contains('payload')));
    });

    test('WS-EVENTS rejects unknown schema and event names', () {
      expect(
        () => WorkspaceContractEvent.fromJson(<String, Object?>{
          'schema': 'ws-events/v2',
          'name': 'ws.link.created',
          'project_id': 'project-1',
          'entity_ids': <String>['novel-1'],
        }),
        throwsFormatException,
      );
      expect(
        () => WorkspaceContractEvent.fromJson(<String, Object?>{
          'schema': 'ws-events/v1',
          'name': 'ws.unknown',
          'project_id': 'project-1',
          'entity_ids': <String>['novel-1'],
        }),
        throwsFormatException,
      );
    });

    test('legacy mutation events remain source compatible', () {
      const legacy = ProjectMutationEvent(
        projectId: 'project-1',
        commandType: 'character.rename',
        sequence: 1,
        type: CommandEventType.commandExecuted,
        source: 'workspace',
      );
      const typed = WorkspaceContractEvent(
        name: WorkspaceEventName.projectionInvalidated,
        projectId: 'project-1',
        entityIds: <String>['character-1'],
      );
      const current = ProjectMutationEvent(
        projectId: 'project-1',
        commandType: 'character.rename',
        sequence: 2,
        type: CommandEventType.commandExecuted,
        source: 'workspace',
        workspaceEvent: typed,
      );

      expect(legacy.workspaceEvent, isNull);
      expect(current.workspaceEvent, typed);
    });
  });
}
