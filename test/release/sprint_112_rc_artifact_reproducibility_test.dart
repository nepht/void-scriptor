import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.52 records reproducibility evidence without secrets', () {
    final contract = File(
      'docs/planning/v1.2/sprint_112_rc_artifact_reproducibility.json',
    );
    final manifest = File(
      'docs/evidence/sprint-112-52-rc-reproducibility-manifest.json',
    );
    expect(contract.existsSync(), isTrue);
    expect(manifest.existsSync(), isTrue);

    final document =
        jsonDecode(contract.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.52');
    expect(document['version'], '1.2.0-rc.1');
    expect(document['status'], 'PARTIAL');
    expect(document['artifact']['signing']['status'], 'UNSIGNED_LOCAL_ONLY');
    expect(
      document['artifact']['signing']['key_material'],
      'NOT_PRESENT_IN_REPOSITORY',
    );
    expect(
      document['decision'],
      'PARTIAL_REPRODUCIBILITY_VERIFIED_SIGNING_BLOCKED',
    );

    final artifactPath = document['artifact']['path'] as String;
    expect(File(artifactPath).existsSync(), isTrue);
    final reproducibility =
        jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>;
    expect(reproducibility['format'], 'void-scriptor-rc-reproducibility-v1');
    expect(reproducibility['version'], '1.2.0-rc.1');
    expect(reproducibility['schema']['database'], 62);
    expect(reproducibility['flags']['vs12_world_logic_shared'], isFalse);
    expect(
      reproducibility['dependencies']['pubspec_lock_sha256'],
      hasLength(64),
    );
    final artifacts = reproducibility['artifacts'] as List<dynamic>;
    expect(artifacts, isNotEmpty);
    for (final entry in artifacts.cast<Map<String, dynamic>>()) {
      expect(entry['path'], isNotEmpty);
      expect(entry['size'], greaterThan(0));
      expect(entry['sha256'], hasLength(64));
    }
  });
}
