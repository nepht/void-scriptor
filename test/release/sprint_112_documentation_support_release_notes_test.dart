import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sprint 112.51 — Documentation, Support & Release Notes manifest validation.
///
/// Verifies the manifest records the required outputs, documentation inventory
/// with existence gates, identified gaps, release artifact manifest, decision,
/// and limits. All paths are checked for existence where status is EXISTS.
void main() {
  test('112.51 records documentation, support, and release notes', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_documentation_support_release_notes.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: '112.51 documentation gate manifest must exist',
    );

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.51');
    expect(document['title'], 'Documentation, Support & Release Notes');

    final requiredEvidence = (document['outputs'] as List).cast<String>();
    expect(
      requiredEvidence,
      containsAll(const <String>[
        'user_guides',
        'migration_guide',
        'recovery_guide',
        'privacy_notes',
        'accessibility_notes',
        'model_transparency',
        'known_limits',
        'release_notes',
        'support_playbook',
      ]),
    );

    // Verify every canonical output has one concrete documentation entry.
    final inventory = (document['documentation_inventory'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      inventory.map((entry) => entry['id']).toSet(),
      requiredEvidence.toSet(),
    );
    const dedicatedGuides = <String, String>{
      'recovery_guide': 'docs/release/v1.2.0-rc.1-recovery-guide.md',
      'model_transparency': 'docs/release/v1.2.0-rc.1-model-transparency.md',
      'known_limits': 'docs/release/v1.2.0-rc.1-known-limits.md',
      'support_playbook': 'docs/release/v1.2.0-rc.1-support-playbook.md',
    };
    for (final expected in dedicatedGuides.entries) {
      final entry = inventory.singleWhere((item) => item['id'] == expected.key);
      expect(entry['path'], expected.value);
    }

    for (final entry in inventory) {
      expect(entry['id'], isNotEmpty, reason: 'missing id in inventory');
      expect(entry['title'], isNotEmpty, reason: 'missing title');
      expect(
        entry['status'],
        isNotEmpty,
        reason: 'missing status in ${entry['id']}',
      );
      expect(
        entry['path'],
        isNotEmpty,
        reason: 'missing path in ${entry['id']}',
      );
      expect(
        entry['gates'],
        isNotEmpty,
        reason: 'missing gates in ${entry['id']}',
      );
      // For EXISTS entries, verify the path is a real file
      if (entry['status'] == 'EXISTS') {
        expect(
          File(entry['path'] as String).existsSync(),
          isTrue,
          reason: 'EXISTS path must be real: ${entry['path']}',
        );
      }
    }

    // Verify at least the known gap is recorded
    final gaps = (document['gaps'] as List).cast<Map<String, dynamic>>();
    expect(gaps, isNotEmpty, reason: 'at least one gap should be recorded');
    for (final gap in gaps) {
      expect(gap['finding'], isNotEmpty, reason: gap['id'] as String);
      expect(gap['next_gate'], isNotEmpty, reason: gap['id'] as String);
    }

    // Verify release artifact manifest structure
    final artifactManifest =
        document['release_artifact_manifest'] as Map<String, dynamic>;
    expect(artifactManifest['version'], '1.2.0-rc.1');
    for (final entry in artifactManifest.entries.where(
      (entry) => entry.key != 'version',
    )) {
      expect(
        File(entry.value as String).existsSync(),
        isTrue,
        reason: 'release documentation path must exist: ${entry.value}',
      );
    }

    final releaseNotes = File(
      artifactManifest['release_notes'] as String,
    ).readAsStringSync();
    expect(releaseNotes, contains('112.52–112.54 tetap gate terpisah'));
    expect(releaseNotes, contains('do not exist as verified outputs yet'));
    expect(releaseNotes, isNot(contains('Semua 54 langkah Sprint 112')));
    expect(releaseNotes, isNot(contains('artifact dibangun')));

    // Verify decision format
    expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

    // Verify limits mention external gates
    final limits = (document['limits'] as List).cast<String>().join(' ');
    expect(limits, contains('Native GUI'));
    expect(limits, contains('hosted CI'));
    expect(limits, contains('signing'));
    expect(limits, contains('hardware'));
  });
}
