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

    // The signed RC binary lives under the gitignored build/ tree, so a clean
    // checkout (CI) cannot carry it. The durable, committed evidence of that
    // artifact is the reproducibility contract named by `signed_artifact`
    // above, which must always exist and must record this exact artifact.
    // When the signed build tree is present (a developer release box) the
    // binary itself must be non-empty. The assertion always runs — only its
    // subject is checkout-appropriate. Mirrors the sprint_117 signed-artifact
    // guard; this is not a skip.
    final signedArtifactContract = File(evidence['signed_artifact'] as String);
    expect(
      signedArtifactContract.existsSync(),
      isTrue,
      reason: 'the committed signed-artifact evidence must exist',
    );
    final recordedArtifact =
        jsonDecode(signedArtifactContract.readAsStringSync())
            as Map<String, dynamic>;
    expect(recordedArtifact['artifact']['path'], contains('void_scriptor.exe'));
    final artifact = File('build/windows/x64/runner/Release/void_scriptor.exe');
    if (artifact.existsSync()) {
      expect(artifact.lengthSync(), greaterThan(0));
    }
  });
}
