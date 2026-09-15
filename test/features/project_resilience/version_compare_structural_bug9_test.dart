import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/project_resilience/application/project_version_control_service.dart';

// Regression for vs-hunt-20260915-resilience BUG-9 (Low, REAL BUG per Referee):
// `compare` used shallow `!=` on snapshot values. Snapshots are decoded from
// separate JSON files, so nested maps/lists always have distinct identities --
// equal nested content was reported as `changed`, producing a false diff.
void main() {
  test('compare treats structurally equal nested JSON values as unchanged '
      '(vs-hunt-20260915-resilience BUG-9)', () async {
    final root = await Directory.systemTemp.createTemp('bug9-structural-');
    addTearDown(() => root.delete(recursive: true));
    final package = ProjectPackage(projectId: 'p1', root: root);
    final service = ProjectVersionControlService(package);

    // Identical nested content, written through two separate encode/decode
    // round-trips so the in-memory maps/lists cannot share identity.
    final first = await service.createSnapshot(
      label: 'Initial',
      assetType: 'character',
      assetId: 'c1',
      data: {
        'name': 'Qowner',
        'traits': {
          'powers': ['void-sense', 'cube-lock'],
          'limits': {'cost': 'memori', 'severity': 3},
        },
      },
    );
    final second = await service.createSnapshot(
      label: 'Rename only',
      assetType: 'character',
      assetId: 'c1',
      data: {
        'name': 'Void Scriptor',
        'traits': {
          'powers': ['void-sense', 'cube-lock'],
          'limits': {'cost': 'memori', 'severity': 3},
        },
      },
    );

    final diff = await service.compare(first.id, second.id);

    // Only the scalar rename is a real change; the equal nested structure
    // must not appear in `changed` (shallow identity comparison said it did).
    expect(diff.changed.keys, ['name']);
    expect(diff.changed['name'], {
      'before': 'Qowner',
      'after': 'Void Scriptor',
    });
    expect(diff.added, isEmpty);
    expect(diff.removed, isEmpty);
  });

  test('compare still reports genuinely changed nested values with '
      'before/after payloads', () async {
    final root = await Directory.systemTemp.createTemp('bug9-realchange-');
    addTearDown(() => root.delete(recursive: true));
    final package = ProjectPackage(projectId: 'p1', root: root);
    final service = ProjectVersionControlService(package);

    final first = await service.createSnapshot(
      label: 'Initial',
      assetType: 'character',
      assetId: 'c1',
      data: {
        'traits': {
          'powers': ['void-sense'],
          'limits': {'cost': 'memori'},
        },
      },
    );
    final second = await service.createSnapshot(
      label: 'Power gained',
      assetType: 'character',
      assetId: 'c1',
      data: {
        'traits': {
          'powers': ['void-sense', 'cube-lock'],
          'limits': {'cost': 'memori'},
        },
      },
    );

    final diff = await service.compare(first.id, second.id);

    expect(diff.changed.keys, ['traits']);
    final entry = diff.changed['traits']!;
    expect(entry['before'], isA<Map>());
    expect((entry['after'] as Map)['powers'], ['void-sense', 'cube-lock']);
  });
}
