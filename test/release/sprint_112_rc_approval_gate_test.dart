import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.53 records a fail-closed RC approval decision', () {
    final contract = File(
      'docs/planning/v1.2/sprint_112_rc_approval_gate.json',
    );
    expect(contract.existsSync(), isTrue);

    final document =
        jsonDecode(contract.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.53');
    expect(document['version'], '1.2.0-rc.1');
    expect(document['status'], 'PARTIAL');
    expect(document['decision'], 'DEFERRED_EXTERNAL_GATES');

    final evidence = document['required_evidence'] as Map<String, dynamic>;
    expect(
      evidence['feature_evidence'],
      'docs/planning/v1.2/sprint_112_feature_evidence_inventory.json',
    );
    expect(evidence['integration_results'], isNotEmpty);
    expect(evidence['migration_results'], isNotEmpty);
    expect(evidence['quality_gates'], isNotEmpty);
    expect(
      evidence['signed_artifact'],
      contains('sprint_112_rc_artifact_reproducibility.json'),
    );

    final openIssues = document['open_issues'] as List<dynamic>;
    expect(openIssues, isNotEmpty);
    expect(
      openIssues.any((issue) => '$issue'.toLowerCase().contains('hosted ci')),
      isTrue,
    );
    expect(
      openIssues.any((issue) => '$issue'.toLowerCase().contains('public')),
      isTrue,
    );

    final rollback = document['rollback_readiness'] as Map<String, dynamic>;
    expect(rollback['status'], 'READY_FOR_LIMITED_LOCAL_VALIDATION');
    expect(rollback['backup_before_migration'], isTrue);
    expect(rollback['recovery_guide'], isNotEmpty);

    final artifact = File('build/windows/x64/runner/Release/void_scriptor.exe');
    expect(artifact.existsSync(), isTrue);
  });
}
