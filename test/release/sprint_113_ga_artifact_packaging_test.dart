import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/features/world_logic/domain/ga_artifact_packaging.dart';

void main() {
  test('113.38 domain declares the seven canonical packaging outputs', () {
    expect(GaArtifactPackaging.requiredOutputNames, <String>[
      'signed_artifacts',
      'checksums',
      'version_manifest',
      'dependency_manifest',
      'schema_manifest',
      'flag_manifest',
      'licenses',
    ]);
    expect(
      GaArtifactPackaging.missingOutputs(const GaArtifactPackaging()),
      unorderedEquals(GaArtifactPackaging.requiredOutputNames),
    );
  });

  test('113.38 domain reports each missing output by canonical name', () {
    const partial = GaArtifactPackaging(
      signedArtifacts: <String>[
        'build/windows/x64/runner/Release/void_scriptor.exe',
      ],
      checksums: <String>['docs/release/v1.2.0-rc.1-checksums.txt'],
      versionManifest: '   ',
      dependencyManifest: <String>['pubspec.lock'],
      schemaManifest: <String>['database:62'],
    );
    expect(
      GaArtifactPackaging.missingOutputs(partial),
      unorderedEquals(<String>[
        'version_manifest',
        'flag_manifest',
        'licenses',
      ]),
    );

    const blankItem = GaArtifactPackaging(
      signedArtifacts: <String>['a.exe'],
      checksums: <String>['checksums.txt'],
      versionManifest: '1.2.0-rc.1',
      dependencyManifest: <String>['pubspec.lock'],
      schemaManifest: <String>['database:62', ''],
      flagManifest: <String>['vs12_lore_links'],
      licenses: <String>['LICENSE'],
    );
    expect(
      GaArtifactPackaging.missingOutputs(blankItem),
      unorderedEquals(<String>['schema_manifest']),
      reason: 'a blank item inside schema_manifest is a missing output',
    );
  });

  test('113.38 evaluate blocks when nothing is recorded', () {
    final evaluation = GaArtifactPackaging.evaluate(null);
    expect(evaluation.state, GaPackagingState.blocked);
    expect(
      evaluation.notes.join(' '),
      contains('no ga artifact packaging recorded'),
    );

    final unrecorded = GaArtifactPackaging.evaluate(
      const GaArtifactPackaging(),
    );
    expect(unrecorded.state, GaPackagingState.blocked);
  });

  test('113.38 evaluate fails and names every missing output', () {
    final evaluation = GaArtifactPackaging.evaluate(
      const GaArtifactPackaging(versionManifest: '1.2.0-rc.1'),
    );
    expect(evaluation.state, GaPackagingState.fail);
    final note = evaluation.notes.join(' ');
    expect(note, contains('signed_artifacts'));
    expect(note, contains('checksums'));
    expect(note, contains('flag_manifest'));
    expect(note, contains('licenses'));
    expect(note, isNot(contains('version_manifest')));
  });

  test('113.38 evaluate passes and retains version and item counts', () {
    const complete = GaArtifactPackaging(
      signedArtifacts: <String>['a.exe', 'b.dll'],
      checksums: <String>['checksums.txt'],
      versionManifest: '1.2.0-rc.1',
      dependencyManifest: <String>['pubspec.lock', 'sbom.cdx.json'],
      schemaManifest: <String>['database:62'],
      flagManifest: <String>['vs12_lore_links'],
      licenses: <String>['LICENSE'],
    );
    final evaluation = GaArtifactPackaging.evaluate(complete);
    expect(evaluation.state, GaPackagingState.pass);
    final note = evaluation.notes.join(' ');
    expect(note, contains('version: 1.2.0-rc.1'));
    expect(note, contains('signed_artifacts: 2 item'));
    expect(note, contains('licenses: 1 item'));
  });

  test(
    '113.38 GA package manifest records all seven outputs for 1.2.0-rc.1',
    () {
      final file = File(
        'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
      );
      expect(file.existsSync(), isTrue, reason: 'step manifest missing');
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '113.38');
      expect(manifest['version'], '1.2.0-rc.1');
      expect(manifest['status'], 'VERIFIED-LOCAL');

      final outputs = manifest['required_outputs'] as Map<String, dynamic>;
      expect(
        outputs.keys.toList()..sort(),
        (GaArtifactPackaging.requiredOutputNames.toList()..sort()),
      );

      final package = GaArtifactPackaging(
        signedArtifacts: (outputs['signed_artifacts'] as List<dynamic>)
            .cast<String>(),
        checksums: (outputs['checksums'] as List<dynamic>).cast<String>(),
        versionManifest: outputs['version_manifest'] as String?,
        dependencyManifest: (outputs['dependency_manifest'] as List<dynamic>)
            .cast<String>(),
        schemaManifest: (outputs['schema_manifest'] as List<dynamic>)
            .cast<String>(),
        flagManifest: (outputs['flag_manifest'] as List<dynamic>)
            .cast<String>(),
        licenses: (outputs['licenses'] as List<dynamic>).cast<String>(),
      );
      expect(GaArtifactPackaging.missingOutputs(package), isEmpty);
      final evaluation = GaArtifactPackaging.evaluate(package);
      expect(evaluation.state, GaPackagingState.pass);

      final limits = manifest['limits'] as List<dynamic>;
      expect(limits, isNotEmpty);
      final joined = limits.join(' ');
      expect(joined, contains('SELF_SIGNED_TEST'));
    },
  );

  test(
    '113.38 signed artifacts exist and signing evidence verifies locally',
    () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final outputs = manifest['required_outputs'] as Map<String, dynamic>;
      final signedPaths = (outputs['signed_artifacts'] as List<dynamic>)
          .cast<String>();
      expect(signedPaths, isNotEmpty);
      for (final path in signedPaths) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'signed artifact missing: $path',
        );
      }

      final signingEvidence =
          manifest['signing_evidence'] as Map<String, dynamic>;
      expect(signingEvidence['status'], 'SELF_SIGNED_LOCAL_VERIFIED');
      expect(signingEvidence['algorithm'], 'Authenticode-SHA256');
      expect(signingEvidence['verification_exit_code'], 0);
      expect(signingEvidence['key_material'], 'NOT_PRESENT_IN_REPOSITORY');
      expect(signingEvidence['public_trust_label'], 'UNSIGNED_PUBLIC_TRUST');
      final thumbprint = signingEvidence['certificate_thumbprint'] as String;
      expect(RegExp(r'^[A-F0-9]{40}$').hasMatch(thumbprint), isTrue);

      final signManifestPath = signingEvidence['sign_manifest_path'] as String;
      final signManifestFile = File(signManifestPath);
      expect(signManifestFile.existsSync(), isTrue);
      final signManifest =
          jsonDecode(signManifestFile.readAsStringSync())
              as Map<String, dynamic>;
      expect(signManifest['version'], '1.2.0-rc.1');
      expect(signManifest['signing']['verification_exit_code'], 0);
      expect(signManifest['signing']['certificate_thumbprint'], thumbprint);
      final signedEntries = signManifest['artifacts'] as List<dynamic>;
      expect(signedEntries.length, signedPaths.length);
      for (final entry in signedEntries.cast<Map<String, dynamic>>()) {
        expect(entry['authenticode_status'], 'Valid');
        expect(entry['sha256'], hasLength(64));
      }
    },
  );

  test('113.38 checksums match the signed artifacts byte for byte', () {
    final checksumsFile = File('docs/release/v1.2.0-rc.1-checksums.txt');
    expect(checksumsFile.existsSync(), isTrue);
    final lines = checksumsFile
        .readAsStringSync()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    expect(lines, isNotEmpty);

    final byPath = <String, String>{};
    for (final line in lines) {
      final match = RegExp(r'^([0-9a-f]{64})\s+(\S+)$').firstMatch(line);
      expect(match, isNotNull, reason: 'malformed checksum line: $line');
      byPath[match!.group(2)!] = match.group(1)!;
    }

    const exePath = 'build/windows/x64/runner/Release/void_scriptor.exe';
    expect(byPath.containsKey(exePath), isTrue);
    final digest = sha256.convert(File(exePath).readAsBytesSync()).toString();
    expect(
      byPath[exePath],
      digest,
      reason: 'recorded checksum drifted from artifact bytes',
    );
  });

  test('113.38 version manifest matches pubspec and applicationVersion', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final outputs = manifest['required_outputs'] as Map<String, dynamic>;
    final recorded = outputs['version_manifest'] as String;
    final pubspec = File('pubspec.yaml')
        .readAsStringSync()
        .split('\n')
        .firstWhere((line) => line.startsWith('version:'));
    expect(recorded, pubspec.substring('version:'.length).trim());
    expect(recorded, VoidProjectFormat.applicationVersion);
    expect(recorded, '1.2.0-rc.1');
  });

  test('113.38 dependency manifest matches live lockfile and SBOM', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final outputs = manifest['required_outputs'] as Map<String, dynamic>;
    final dependencyPaths = (outputs['dependency_manifest'] as List<dynamic>)
        .cast<String>();
    expect(dependencyPaths, contains('pubspec.lock'));

    final lockFile = File('pubspec.lock');
    expect(lockFile.existsSync(), isTrue);
    final lockDigest = sha256.convert(lockFile.readAsBytesSync()).toString();
    expect(manifest['dependency_evidence']['pubspec_lock_sha256'], lockDigest);

    final sbomPath = dependencyPaths.firstWhere(
      (path) => path.endsWith('sbom.cdx.json'),
    );
    final sbomFile = File(sbomPath);
    expect(sbomFile.existsSync(), isTrue);
    final sbom =
        jsonDecode(sbomFile.readAsStringSync()) as Map<String, dynamic>;
    expect(sbom['bomFormat'], 'CycloneDX');
    final components = sbom['components'] as List<dynamic>;
    expect(components, isNotEmpty);
    final rootVersion =
        (sbom['metadata']['component'] as Map<String, dynamic>)['version'];
    expect(rootVersion, '1.2.0-rc.1');
  });

  test('113.38 schema manifest matches live schema constants', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final outputs = manifest['required_outputs'] as Map<String, dynamic>;
    final schemaEntries = (outputs['schema_manifest'] as List<dynamic>)
        .cast<String>();
    final databaseSource = File(
      'lib/database/project/project_database.dart',
    ).readAsStringSync();
    final schemaMatch = RegExp(
      r'static const currentSchemaVersion = (\d+);',
    ).firstMatch(databaseSource);
    expect(schemaMatch, isNotNull);
    final liveDatabaseSchema = int.parse(schemaMatch!.group(1)!);

    expect(schemaEntries, contains('database:$liveDatabaseSchema'));
    expect(
      schemaEntries,
      contains('project_format:${VoidProjectFormat.currentSchema}'),
    );
    expect(liveDatabaseSchema, 62);
    expect(VoidProjectFormat.currentSchema, 16);
    expect(manifest['schema_evidence']['database'], liveDatabaseSchema);
    expect(
      manifest['schema_evidence']['project_format'],
      VoidProjectFormat.currentSchema,
    );
  });

  test('113.38 flag manifest mirrors the live flag registry defaults', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final outputs = manifest['required_outputs'] as Map<String, dynamic>;
    final flagEntries = (outputs['flag_manifest'] as List<dynamic>)
        .cast<String>();

    final liveIds = flagEntries
        .where((entry) => entry.startsWith('vs12_'))
        .toSet();
    expect(liveIds, kVs12FeatureFlags.toSet());
    expect(kVs12FeatureFlags, hasLength(13));
    expect(
      flagEntries,
      contains('kill_switch:FeatureFlagRegistry.engageKillSwitch'),
    );

    final defaults =
        manifest['flag_evidence']['default_states'] as Map<String, dynamic>;
    expect(defaults.length, kVs12FeatureFlags.length);
    for (final id in kVs12FeatureFlags) {
      expect(defaults[id], isFalse, reason: '$id must default OFF');
    }
    expect(manifest['flag_evidence']['kill_switch'], isFalse);
  });

  test('113.38 licenses cover the project and hosted dependencies', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final outputs = manifest['required_outputs'] as Map<String, dynamic>;
    final licensePaths = (outputs['licenses'] as List<dynamic>).cast<String>();

    expect(licensePaths, contains('LICENSE'));
    expect(File('LICENSE').existsSync(), isTrue);
    expect(File('LICENSE').readAsStringSync().trim(), isNotEmpty);

    final noticesPath = licensePaths.firstWhere(
      (path) => path
          .toLowerCase()
          .replaceAll('-', '_')
          .contains('third_party_notices'),
    );
    final noticesFile = File(noticesPath);
    expect(noticesFile.existsSync(), isTrue);
    final notices = noticesFile.readAsStringSync();
    expect(notices.trim(), isNotEmpty);
    expect(notices, contains('drift'));
    expect(notices.length, greaterThan(1000));
    expect(manifest['license_evidence']['hosted_packages_licensed'], isTrue);
  });
}
