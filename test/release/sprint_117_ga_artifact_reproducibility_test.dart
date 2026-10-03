/// Sprint 117.43 — GA Artifact & Reproducibility gate tests.
///
/// RED-first for defect 117.43-01: `ArtifactComparison.isWellFormed` accepted
/// a `bitIdentical` claim whose two rebuilds recorded DIFFERENT SHA-256
/// digests, so the shipped reproducibility seam returned `pass` on a false
/// identity claim. These tests pin the closed behaviour and the surrounding
/// gate contract.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_icon_registry.dart';
import 'package:void_scriptor/features/world_logic/domain/build_reproducibility_provenance.dart';
import 'package:void_scriptor/features/world_logic/domain/ga_artifact_packaging.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_ga_artifact_reproducibility.dart';

const String _kPackagingManifest =
    'docs/planning/v1.2/sprint_113_ga_artifact_packaging.json';
const String _kProvenanceManifest =
    'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json';
const String _kChecksums = 'docs/release/v1.2.0-rc.1-checksums.txt';

/// The shipped checksums describe the signed release tree under `build/`. A
/// clean checkout (CI) has no such tree, so the live-digest measurement cannot
/// be taken there. Mirrors the sprint_113 signed-artifact guards.
final bool _signedBuildTreePresent = File(
  'build/windows/x64/runner/Release/void_scriptor.exe',
).existsSync();

Map<String, Object?> _manifest(String path) =>
    Sprint117GaArtifactGate.readManifest(path) ?? <String, Object?>{};

Map<String, Object?> _packagingOutputs() {
  final outputs = _manifest(_kPackagingManifest)['required_outputs'];
  return outputs is Map<String, Object?> ? outputs : <String, Object?>{};
}

List<String> _recordedSignedArtifacts() =>
    ((_packagingOutputs()['signed_artifacts'] as List<dynamic>?)
        ?.cast<String>()) ??
    const <String>[];

Sprint117GaArtifactOutput _output(String id, List<String> paths) =>
    Sprint117GaArtifactOutput(
      outputId: id,
      manifestPaths: paths,
      seamLabel: 'test',
    );

Sprint117GaArtifactCheck _pass(String id, String check) =>
    Sprint117GaArtifactCheck.pass_(
      outputId: id,
      check: check,
      declared: 'declared-value',
      observed: 'observed-value',
    );

void main() {
  group('117.43-01 artifact comparison honours the verdict it records', () {
    test('bitIdentical is refused when the two rebuilds differ', () {
      final a = 'a' * 64;
      final b = 'b' * 64;
      final comparison = ArtifactComparison(
        method: 'sha256',
        rebuildA: RebuildResult(
          label: 'rebuild_a',
          artifactHashes: <String, String>{'void_scriptor.exe': a},
          exitCode: 0,
        ),
        rebuildB: RebuildResult(
          label: 'rebuild_b',
          artifactHashes: <String, String>{'void_scriptor.exe': b},
          exitCode: 0,
        ),
        verdict: RebuildVerdict.bitIdentical,
      );
      expect(
        comparison.isWellFormed,
        isFalse,
        reason:
            'a bitIdentical claim contradicted by differing digests is a '
            'false identity claim and must fail closed',
      );
    });

    test('bitIdentical still passes when every recorded digest matches', () {
      final a = 'a' * 64;
      final comparison = ArtifactComparison(
        method: 'sha256',
        rebuildA: RebuildResult(
          label: 'rebuild_a',
          artifactHashes: <String, String>{
            'void_scriptor.exe': a,
            'sqlite3.dll': a,
          },
          exitCode: 0,
        ),
        rebuildB: RebuildResult(
          label: 'rebuild_b',
          artifactHashes: <String, String>{
            'void_scriptor.exe': a,
            'sqlite3.dll': a,
          },
          exitCode: 0,
        ),
        verdict: RebuildVerdict.bitIdentical,
      );
      expect(comparison.isWellFormed, isTrue);
    });

    test('a partially matching rebuild set is not bit identical', () {
      final a = 'a' * 64;
      final b = 'b' * 64;
      final comparison = ArtifactComparison(
        method: 'sha256',
        rebuildA: RebuildResult(
          label: 'rebuild_a',
          artifactHashes: <String, String>{
            'void_scriptor.exe': a,
            'sqlite3.dll': b,
          },
          exitCode: 0,
        ),
        rebuildB: RebuildResult(
          label: 'rebuild_b',
          artifactHashes: <String, String>{
            'void_scriptor.exe': a,
            'sqlite3.dll': a,
          },
          exitCode: 0,
        ),
        verdict: RebuildVerdict.bitIdentical,
      );
      expect(comparison.isWellFormed, isFalse);
    });

    test('notBitIdentical with documented limits stays well formed', () {
      final a = 'a' * 64;
      final b = 'b' * 64;
      final comparison = ArtifactComparison(
        method: 'sha256',
        rebuildA: RebuildResult(
          label: 'rebuild_a',
          artifactHashes: <String, String>{'void_scriptor.exe': a},
          exitCode: 0,
        ),
        rebuildB: RebuildResult(
          label: 'rebuild_b',
          artifactHashes: <String, String>{'void_scriptor.exe': b},
          exitCode: 0,
        ),
        verdict: RebuildVerdict.notBitIdentical,
        limits: <String>['MSVC embeds a PE timestamp'],
      );
      expect(comparison.isWellFormed, isTrue);
    });

    test('a true identity claim makes the shipped seam pass end to end', () {
      final a = 'a' * 64;
      final evidence = BuildProvenanceEvidence(
        buildInputs: <String>['pubspec.yaml sha256 $a'],
        toolchainVersions: <String>['Flutter 3.x'],
        dependencyLock: <String>['pubspec.lock sha256 $a'],
        rebuildResults: <RebuildResult>[
          RebuildResult(
            label: 'rebuild_a',
            artifactHashes: <String, String>{'void_scriptor.exe': a},
            exitCode: 0,
          ),
          RebuildResult(
            label: 'rebuild_b',
            artifactHashes: <String, String>{'void_scriptor.exe': a},
            exitCode: 0,
          ),
        ],
        artifactComparison: ArtifactComparison(
          method: 'sha256',
          rebuildA: RebuildResult(
            label: 'rebuild_a',
            artifactHashes: <String, String>{'void_scriptor.exe': a},
            exitCode: 0,
          ),
          rebuildB: RebuildResult(
            label: 'rebuild_b',
            artifactHashes: <String, String>{'void_scriptor.exe': a},
            exitCode: 0,
          ),
          verdict: RebuildVerdict.bitIdentical,
        ),
        provenanceRecord: <String>['source_revision $a'],
      );
      expect(
        BuildProvenanceEvidence.missingEvidence(evidence),
        isEmpty,
        reason: 'a genuinely identical pair must not be refused',
      );
      expect(
        BuildProvenanceEvidence.evaluate(evidence).state,
        BuildProvenanceState.pass,
      );
    });

    test('a false identity claim is reported as missing evidence', () {
      final a = 'a' * 64;
      final b = 'b' * 64;
      final evidence = BuildProvenanceEvidence(
        buildInputs: <String>['pubspec.yaml sha256 $a'],
        toolchainVersions: <String>['Flutter 3.x'],
        dependencyLock: <String>['pubspec.lock sha256 $a'],
        rebuildResults: <RebuildResult>[
          RebuildResult(
            label: 'rebuild_a',
            artifactHashes: <String, String>{'void_scriptor.exe': a},
            exitCode: 0,
          ),
          RebuildResult(
            label: 'rebuild_b',
            artifactHashes: <String, String>{'void_scriptor.exe': b},
            exitCode: 0,
          ),
        ],
        artifactComparison: ArtifactComparison(
          method: 'sha256',
          rebuildA: RebuildResult(
            label: 'rebuild_a',
            artifactHashes: <String, String>{'void_scriptor.exe': a},
            exitCode: 0,
          ),
          rebuildB: RebuildResult(
            label: 'rebuild_b',
            artifactHashes: <String, String>{'void_scriptor.exe': b},
            exitCode: 0,
          ),
          verdict: RebuildVerdict.bitIdentical,
        ),
        provenanceRecord: <String>['source_revision $a'],
      );
      expect(
        BuildProvenanceEvidence.missingEvidence(evidence),
        contains('artifact_comparison'),
      );
      expect(
        BuildProvenanceEvidence.evaluate(evidence).state,
        BuildProvenanceState.fail,
      );
    });
  });

  group('117.43 canonical vocabulary', () {
    test('the eight required outputs are verbatim and in contract order', () {
      expect(Sprint117GaPackagingContract.requiredOutputs, <String>[
        'signed_artifacts',
        'connector_manifest',
        'icon_manifest',
        'dependency_manifest',
        'schema_manifest',
        'flag_manifest',
        'checksums',
        'provenance',
      ]);
    });

    test('the 117.43 eight differ from the shipped 113.38 seven', () {
      // Guards the premise of this slice: if 113.38 ever grows the same
      // vocabulary, the reconciliation note below stops being true.
      expect(
        Sprint117GaPackagingContract.requiredOutputs.toSet().containsAll(
          GaArtifactPackaging.requiredOutputNames,
        ),
        isFalse,
        reason: '117.43 must not be treated as the 113.38 packaging seven',
      );
      expect(Sprint117GaPackagingContract.outputsOutsideThisStep, <String>[
        'version_manifest',
        'licenses',
      ]);
      expect(Sprint117GaPackagingContract.outputsAbsentFromPackaging, <String>[
        'connector_manifest',
        'icon_manifest',
        'provenance',
      ]);
    });

    test('the 113.38 packaging subset names exactly what 117.43 shares', () {
      final shared = Sprint117GaPackagingContract.packagingSubsetNames.toSet();
      expect(
        shared.intersection(GaArtifactPackaging.requiredOutputNames.toSet()),
        shared,
      );
      for (final name in shared) {
        expect(Sprint117GaPackagingContract.requiredOutputs, contains(name));
      }
    });
  });

  group('117.43 shipped registries back the connector and icon manifests', () {
    test(
      'the shipped connector and icon registries cover one provider set',
      () {
        final connectors = ProviderConnectorManifest.standard.manifestIds
            .toSet();
        final icons = ProviderIconRegistry.standard.all
            .map((entry) => entry.providerId)
            .toSet();
        expect(connectors, isNotEmpty);
        expect(icons, isNotEmpty);
        expect(icons.difference(connectors), isEmpty);
        expect(connectors.difference(icons), isEmpty);
      },
    );

    test(
      'no provider is connectable while every availability is unverified',
      () {
        // A GA manifest that ships zero connectable connectors must not imply a
        // live connector surface; this pins the honest zero.
        final connectable = ProviderConnectorManifest.standard.all
            .where((entry) => entry.isConnectable)
            .map((entry) => entry.providerId);
        expect(connectable, isEmpty);
      },
    );

    test('schema manifest is derived from the shipped schema constants', () {
      final derived = Sprint117GaPackagingContract.deriveSchemaManifest();
      expect(derived, contains('database:62'));
      expect(derived, contains('project_format:16'));
      final recorded =
          (_packagingOutputs()['schema_manifest'] as List<dynamic>?)
              ?.cast<String>() ??
          const <String>[];
      expect(
        derived.where(recorded.contains).length,
        derived.length,
        reason: 'schema identifiers must be derived, not retyped',
      );
    });

    test('flag manifest is derived from the shipped flag registry', () {
      final derived = Sprint117GaPackagingContract.deriveFlagManifest();
      expect(derived, hasLength(14));
      expect(
        derived,
        contains('kill_switch:FeatureFlagRegistry.engageKillSwitch'),
      );
      final recorded =
          (_packagingOutputs()['flag_manifest'] as List<dynamic>?)
              ?.cast<String>() ??
          const <String>[];
      expect(
        derived.where(recorded.contains).length,
        derived.length,
        reason: 'flag identifiers must be derived, not retyped',
      );
    });
  });

  group('117.43 fail-closed gate behaviour', () {
    test('a manifest nobody can open fails the output', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>['docs/does-not-exist-$id.json']),
          _output('signed_artifacts', <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _pass(id, 'reachable'),
        ],
      );
      expect(result.pass, isFalse);
      expect(result.failures, isNotEmpty);
      expect(
        result.failures.where((f) => f.startsWith('missing_manifest:')),
        isNotEmpty,
      );
    });

    test('a duplicated canonical output is rejected', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
          _output('provenance', <String>[_kProvenanceManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _pass(id, 'reachable'),
        ],
      );
      expect(result.failures, contains('duplicate_output:provenance'));
    });

    test('vocabulary drift outside the eight is rejected, not absorbed', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
          _output('version_manifest', <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _pass(id, 'reachable'),
        ],
      );
      expect(result.failures, contains('unknown_output:version_manifest'));
    });

    test('an output no row declares fails closed', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          _output('signed_artifacts', <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[_pass('signed_artifacts', 'reachable')],
      );
      expect(
        result.failures,
        containsAll(<String>[
          'missing_output:provenance',
          'missing_output:icon_manifest',
        ]),
      );
    });

    test('an output with no passing check is never complete', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            if (id == 'provenance')
              Sprint117GaArtifactCheck.unmet(
                outputId: id,
                check: 'reachable',
                declared: 'declared-value',
                observed: 'observed-value',
              )
            else
              _pass(id, 'reachable'),
        ],
      );
      expect(result.failures, contains('output_without_pass:provenance'));
    });

    test('a blank declared or observed value is not evidence', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            if (id == 'flag_manifest')
              Sprint117GaArtifactCheck.pass_(
                outputId: id,
                check: 'reachable',
                declared: '   ',
                observed: 'observed-value',
              )
            else
              _pass(id, 'reachable'),
        ],
      );
      expect(result.failures, contains('vacuous:flag_manifest:reachable'));
    });

    test('a fully covered, honest gate passes and measures its providers', () {
      final result = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _pass(id, 'reachable'),
        ],
      );
      expect(result.failures, isEmpty);
      expect(result.pass, isTrue);
      expect(result.verdict, Sprint117GaPackagingContract.passVerdict);
      expect(result.providersMeasured, hasLength(32));
      expect(result.toJson()['canonical_step'], '117.43');
      expect(result.toJson()['document_role'], 'EVIDENCE');
    });

    test('an unmet check is reported as an open item, never as a pass', () {
      // An output whose ONLY check is unmet cannot be complete: the gate fails
      // it closed. The unmet row is still named as an open item.
      final unmetOnly = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            if (id == 'checksums')
              Sprint117GaArtifactCheck.unmet(
                outputId: id,
                check: 'reachable',
                declared: 'declared-value',
                observed: 'observed-value',
              )
            else
              _pass(id, 'reachable'),
        ],
      );
      expect(unmetOnly.pass, isFalse);
      expect(unmetOnly.failures, contains('output_without_pass:checksums'));
      expect(unmetOnly.openItems, contains('checksums:reachable'));

      // An output covered by a real passing check stays complete, and the
      // unmet sibling is still carried as an open item rather than dropped.
      final withPassingSibling = Sprint117GaArtifactGate.evaluate(
        <Sprint117GaArtifactOutput>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            _output(id, <String>[_kPackagingManifest]),
        ],
        <Sprint117GaArtifactCheck>[
          for (final id in Sprint117GaPackagingContract.requiredOutputs)
            if (id == 'checksums') ...<Sprint117GaArtifactCheck>[
              _pass(id, 'reachable'),
              Sprint117GaArtifactCheck.unmet(
                outputId: id,
                check: 'artifact_checksum_agreement',
                declared: 'declared-value',
                observed: 'observed-value',
              ),
            ] else
              _pass(id, 'reachable'),
        ],
      );
      expect(withPassingSibling.pass, isTrue);
      expect(
        withPassingSibling.openItems,
        contains('checksums:artifact_checksum_agreement'),
      );
      expect(
        withPassingSibling.openItems,
        isNot(contains('checksums:reachable')),
      );
    });
  });

  group('117.43 checksum measurement', () {
    test('the shipped checksum file covers every recorded signed artifact', () {
      final artifacts = _recordedSignedArtifacts();
      expect(artifacts, isNotEmpty);
      final index = Sprint117GaArtifactGate.readChecksumIndex(
        File(_kChecksums).readAsLinesSync(),
      ).index;
      expect(index, isNotEmpty);
      for (final path in artifacts) {
        expect(
          index.containsKey(path),
          isTrue,
          reason: 'no checksum line covers $path',
        );
      }
    });

    test('drifting digests are reported, never silently rewritten', () {
      final artifacts = _recordedSignedArtifacts();
      final index = Sprint117GaArtifactGate.readChecksumIndex(
        File(_kChecksums).readAsLinesSync(),
      ).index;
      final drifting = <String>[];
      for (final path in artifacts) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final actual = sha256.convert(file.readAsBytesSync()).toString();
        if (actual != index[path]) drifting.add(path);
      }
      // The committed 1.2.0-rc.1 checksums describe the signed release tree;
      // the live debug build/ tree is not that tree. Whatever the current
      // state is, the measurement must equal an independent recomputation and
      // must never rewrite the committed checksum file.
      final before = File(_kChecksums).readAsBytesSync();
      final check = Sprint117GaArtifactGate.measureChecksums(
        signedArtifacts: artifacts,
        checksumFile: File(_kChecksums),
      );
      expect(File(_kChecksums).readAsBytesSync(), before);
      expect(check.outputId, 'checksums');
      if (!_signedBuildTreePresent) {
        // A clean checkout carries none of the signed artifacts the committed
        // checksums describe, so every recorded path reads as uncovered. That
        // is the honest verdict here — not a skip and not a pass.
        expect(check.status, Sprint117GaArtifactStatus.violation);
        expect(check.note, contains('uncovered:'));
      } else if (drifting.isNotEmpty) {
        expect(check.status, Sprint117GaArtifactStatus.violation);
        expect(check.note, contains('drifting:'));
      } else {
        expect(check.status, Sprint117GaArtifactStatus.pass);
      }
    });

    test('an absent checksum file is unmet, not a silent pass', () {
      final check = Sprint117GaArtifactGate.measureChecksums(
        signedArtifacts: <String>['a.exe'],
        checksumFile: File('docs/absent-checksums-file.txt'),
      );
      expect(check.status, Sprint117GaArtifactStatus.unmet);
    });

    test('malformed checksum lines do not inflate the covered set', () {
      final parsed = Sprint117GaArtifactGate.readChecksumIndex(<String>[
        '# comment',
        '',
        '${'a' * 64} build/a.exe',
        'not-a-checksum-line',
        '${'b' * 64}   build/b.exe   ',
      ]);
      expect(parsed.index.keys, <String>['build/a.exe', 'build/b.exe']);
    });
  });

  group('117.43 provenance and packaging measurement', () {
    test(
      'the shipped provenance manifest evaluates through the 113.39 seam',
      () {
        final manifest = _manifest(_kProvenanceManifest);
        expect(manifest['canonical_step'], '113.39');
        final check = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest,
        );
        expect(check.outputId, 'provenance');
        // The shipped 113.39 evidence records NOT_BIT_IDENTICAL with documented
        // limits, so the honest outcome is a measured pass through the shipped
        // seam — never an assumed identity claim.
        expect(check.status, Sprint117GaArtifactStatus.pass);
        expect(check.observed, contains('NOT_BIT_IDENTICAL'));
      },
    );

    test('a manifest with no evidence object is unmet', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: <String, Object?>{'canonical_step': '113.39'},
      );
      expect(check.status, Sprint117GaArtifactStatus.unmet);
    });

    test('signed artifact coverage matches the packaging manifest', () {
      final artifacts = _recordedSignedArtifacts();
      final check = Sprint117GaArtifactGate.measureSignedArtifacts(
        packagingOutputs: _packagingOutputs(),
        declaredArtifacts: artifacts,
      );
      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('match packaging manifest'));
    });

    test('a dropped signed artifact is a violation, not a quiet shrink', () {
      final artifacts = _recordedSignedArtifacts();
      final truncated = artifacts.sublist(0, artifacts.length - 1);
      final check = Sprint117GaArtifactGate.measureSignedArtifacts(
        packagingOutputs: _packagingOutputs(),
        declaredArtifacts: truncated,
      );
      expect(check.status, Sprint117GaArtifactStatus.violation);
      expect(check.note, contains('recorded_only:'));
    });

    test('an undecodable manifest reads as null rather than throwing', () {
      expect(Sprint117GaArtifactGate.readManifest('docs/absent.json'), isNull);
      final manifest = Sprint117GaArtifactGate.readManifest(
        _kPackagingManifest,
      );
      expect(manifest, isNotNull);
      expect(manifest!['required_outputs'], isA<Map<String, Object?>>());
    });

    test(
      'the shipped packaging manifest json decodes to the recorded shape',
      () {
        final raw =
            jsonDecode(File(_kPackagingManifest).readAsStringSync())
                as Map<String, dynamic>;
        expect(raw['canonical_step'], '113.38');
        expect(raw['version'], '1.2.0-rc.1');
        expect(
          raw['required_outputs'].keys.toList()..sort(),
          (GaArtifactPackaging.requiredOutputNames.toList()..sort()),
        );
        // Defect 117.43-02, measured: the manifest names build-tree paths that
        // are not tracked, so the committed document describes an artifact tree
        // a clean checkout cannot resolve.
        for (final path in <String>[
          ...((raw['required_outputs']['checksums'] as List<dynamic>)
              .cast<String>()),
          (raw['signing_evidence']
                  as Map<String, dynamic>)['sign_manifest_path']
              as String,
        ]) {
          if (path.startsWith('build/')) {
            expect(
              path,
              matches(RegExp(r'^build/')),
              reason: 'build-tree paths are untracked by construction',
            );
          }
        }
        expect(
          File('build/release-metadata/artifact-manifest.json').existsSync(),
          isFalse,
          reason: '117.43-02: the recorded artifact manifest does not resolve',
        );
      },
    );
  });

  // RED-first for defect 117.43-03: `measureChecksums` iterated only the
  // declared artifact list. A checksum LINE naming a path that is not a
  // readable artifact — the second half of the seam's own stated rule, "a
  // checksum line with no readable artifact is a claim about nothing" — was
  // never walked, so an inventory naming a phantom artifact reported `pass`
  // while claiming coverage the tree does not have.
  group('117.43-03 a checksum line over a phantom artifact is a violation', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync('void_117_43_03'),
    );
    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String writeFile(String name, Object content) {
      final file = File('${tempDir.path}${Platform.pathSeparator}$name')
        ..createSync(recursive: true);
      if (content is String) {
        file.writeAsStringSync(content);
      } else {
        file.writeAsBytesSync(content as List<int>);
      }
      return file.path;
    }

    test(
      'an inventory naming one real and one absent artifact is a violation',
      () {
        final real = writeFile('real.bin', <int>[1, 2, 3]);
        final absent = '${tempDir.path}${Platform.pathSeparator}phantom.bin';
        final checksumFile = writeFile(
          'checksums.txt',
          <String>[
            '${sha256.convert(<int>[1, 2, 3]).toString()}  $real',
            '${'b' * 64}  $absent',
          ].join('\n'),
        );

        final check = Sprint117GaArtifactGate.measureChecksums(
          signedArtifacts: <String>[real],
          checksumFile: File(checksumFile),
        );

        expect(
          check.status,
          Sprint117GaArtifactStatus.violation,
          reason: 'a checksum line naming an unreadable artifact is unverified',
        );
        expect(check.note, contains('phantom.bin'));
      },
    );

    test('a clean inventory still passes with no phantom entries', () {
      final real = writeFile('real.bin', <int>[1, 2, 3]);
      final checksumFile = writeFile(
        'checksums.txt',
        <String>[
          '${sha256.convert(<int>[1, 2, 3]).toString()}  $real',
        ].join('\n'),
      );

      final check = Sprint117GaArtifactGate.measureChecksums(
        signedArtifacts: <String>[real],
        checksumFile: File(checksumFile),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
    });
  });

  // RED-first for defect 117.43-04: `readChecksumIndex` documents that it
  // returns the parsed map "plus every line that was malformed, so a silently
  // dropped line cannot shrink the covered set without being counted". It
  // returned the map alone and `continue`d past malformed input, so a
  // truncated or uppercase digest disappeared from the inventory without any
  // counted failure.
  group('117.43-04 a malformed checksum line is counted, not dropped', () {
    test('readChecksumIndex reports the malformed lines alongside the map', () {
      final good = 'a' * 64;
      final parsed = Sprint117GaArtifactGate.readChecksumIndex(<String>[
        '# a comment',
        '',
        '$good  docs/release/app.bin',
        'not-a-digest  docs/release/other.bin',
        "${'C' * 64}  docs/release/upper.bin",
      ]);

      expect(parsed.index.keys, <String>['docs/release/app.bin']);
      expect(
        parsed.malformed,
        hasLength(2),
        reason: 'a dropped line shrinks the covered set without being counted',
      );
      expect(parsed.malformed.join('\n'), contains('not-a-digest'));
      expect(parsed.malformed.join('\n'), contains('upper.bin'));
    });

    test('a well-formed inventory reports no malformed lines', () {
      final parsed = Sprint117GaArtifactGate.readChecksumIndex(<String>[
        '${'a' * 64}  docs/release/app.bin',
      ]);

      expect(parsed.index.keys, <String>['docs/release/app.bin']);
      expect(parsed.malformed, isEmpty);
    });
  });

  // RED-first for defect 117.43-05: `readChecksumIndex` filled its map with
  // `index[path] = digest`, so a path recorded TWICE with DIFFERENT digests kept
  // whichever line came last and the contradicting claim was counted nowhere.
  // An inventory that disagrees with itself therefore reported agreement on the
  // surviving line — the same fail-open shape as 117.43-04, one step further
  // down: there the line vanished, here it overwrote its own evidence.
  group('117.43-05 a self-contradicting checksum inventory is a violation', () {
    late Directory tempDir;

    setUp(
      () => tempDir = Directory.systemTemp.createTempSync('void_117_43_05'),
    );
    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    String writeFile(String name, Object content) {
      final file = File('${tempDir.path}${Platform.pathSeparator}$name')
        ..createSync(recursive: true);
      if (content is String) {
        file.writeAsStringSync(content);
      } else {
        file.writeAsBytesSync(content as List<int>);
      }
      return file.path;
    }

    test(
      'a path recorded twice with different digests is counted, not resolved '
      'by last write',
      () {
        final bytes = <int>[1, 2, 3];
        final real = writeFile('real.bin', bytes);
        final checksumFile = writeFile(
          'checksums.txt',
          <String>[
            // The wrong digest first, the correct digest last: last-write-wins
            // made this inventory agree, so the stale claim was invisible.
            "${'b' * 64}  $real",
            '${sha256.convert(bytes).toString()}  $real',
          ].join('\n'),
        );

        final check = Sprint117GaArtifactGate.measureChecksums(
          signedArtifacts: <String>[real],
          checksumFile: File(checksumFile),
        );

        expect(
          check.status,
          Sprint117GaArtifactStatus.violation,
          reason: 'an inventory that contradicts itself cannot agree',
        );
        expect(check.note, contains('conflicting:'));
      },
    );
  });

  // RED-first for defect 117.43-06: the mirror image of 117.43-01, in the
  // OTHER direction. That fix made a `bitIdentical` claim verify the recorded
  // digests, because a false identity claim was accepted. Its mirror was never
  // checked: a `notBitIdentical` claim verified nothing at all. `isWellFormed`
  // walked straight past the verdict branch to the `limits` documentation test,
  // so `ArtifactComparison` with verdict `notBitIdentical` whose two rebuilds
  // record byte-identical digests reported `isWellFormed == true`,
  // `BuildProvenanceEvidence.evaluate` returned `pass`, and
  // `measureProvenance` reported the `provenance` output as `pass`.
  //
  // That is the same trust boundary the gate's own docstring already promises
  // not to cross: a reproducibility claim is only accepted when the recorded
  // digests support it. The manifest we SHIP records `NOT_BIT_IDENTICAL`, and
  // the committed 117.43 manifest reports that output as `pass` with
  // `observed: ... NOT_BIT_IDENTICAL (6 artifact)`. The gate cannot
  // simultaneously claim reproducibility evidence passed and print a verdict
  // that says the artifacts are not reproducible.
  group('117.43-06 a notBitIdentical claim must be measured, not assumed', () {
    String digest(String seed) => seed * 64;

    RebuildResult rebuild(String label, Map<String, String> hashes) =>
        RebuildResult(label: label, artifactHashes: hashes, exitCode: 0);

    ArtifactComparison comparisonWith(
      RebuildVerdict verdict, {
      Map<String, String>? hashesA,
      Map<String, String>? hashesB,
    }) {
      return ArtifactComparison(
        method: 'SHA-256 over the recorded artifacts',
        rebuildA: rebuild(
          'rebuild_a',
          hashesA ?? <String, String>{'a.exe': digest('a')},
        ),
        rebuildB: rebuild(
          'rebuild_b',
          hashesB ?? <String, String>{'a.exe': digest('a')},
        ),
        verdict: verdict,
        limits: <String>['a documented limit, as the verdict requires'],
      );
    }

    test(
      'identical digests behind a notBitIdentical claim is not well formed',
      () {
        // The shipped shape, minus the disagreement: same claim, no evidence for
        // it. Before the fix this reported isWellFormed == true.
        final comparison = comparisonWith(RebuildVerdict.notBitIdentical);

        expect(
          comparison.isWellFormed,
          isFalse,
          reason: 'a difference claim needs at least one differing digest',
        );
      },
    );

    test(
      'a genuine difference behind a notBitIdentical claim still passes',
      () {
        final comparison = comparisonWith(
          RebuildVerdict.notBitIdentical,
          hashesA: <String, String>{'a.exe': digest('a'), 'b.dll': digest('b')},
          hashesB: <String, String>{'a.exe': digest('a'), 'b.dll': digest('c')},
        );

        expect(comparison.isWellFormed, isTrue);
      },
    );

    test(
      'the shipped manifest passes provenance only because it records a real difference',
      () {
        final manifest = Sprint117GaArtifactGate.readManifest(
          Sprint117GaPackagingContract.provenanceManifestPath,
        );

        expect(manifest, isNotNull);
        final check = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest!,
        );

        // The shipped manifest DOES record a genuine difference (4 of 6
        // artifacts differ), so this stays `pass`. The assertion exists so that a
        // future edit which erases the real difference cannot quietly leave the
        // provenance output passing on a claim with no evidence behind it.
        expect(check.status, Sprint117GaArtifactStatus.pass);
        expect(check.observed, contains('NOT_BIT_IDENTICAL'));
      },
    );

    test('measureProvenance reports a claim with no difference as unmet', () {
      // The gate-level consequence: the same shipped-shaped evidence whose
      // rebuilds agree byte for byte must not be reported as a passing
      // provenance output.
      final matching = <String, String>{'a.exe': digest('a')};
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: <String, Object?>{
          'required_evidence': <String, Object?>{
            'build_inputs': <String>['a'],
            'toolchain_versions': <String>['a'],
            'dependency_lock': <String>['a'],
            'rebuild_results': <Map<String, Object?>>[
              <String, Object?>{
                'label': 'rebuild_a',
                'artifact_hashes': matching,
                'exit_code': 0,
              },
              <String, Object?>{
                'label': 'rebuild_b',
                'artifact_hashes': matching,
                'exit_code': 0,
              },
            ],
            'artifact_comparison': <String, Object?>{
              'method': 'SHA-256 over the recorded artifacts',
              'verdict': 'NOT_BIT_IDENTICAL',
              'limits': <String>['a documented limit, as the verdict requires'],
            },
            'provenance_record': <String>['a'],
          },
        },
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'reproducibility evidence that shows no difference is not a pass',
      );
    });
  });

  // RED-first for defect 117.43-07: the verdict was never READ, only inferred.
  // 117.43-01 closed a false identity claim and 117.43-06 closed a false
  // difference claim, both by comparing the recorded digests against the
  // verdict. Both fixes work on the assumption that the verdict says what the
  // manifest states. The parser breaks that assumption: `verdict:` was built as
  // `comparison['verdict'] == 'BIT_IDENTICAL' ? bitIdentical : notBitIdentical`,
  // so EVERY other value — an absent key, an explicit null, or a typo such as
  // 'BIT_IDENTITY' — was silently coerced into a measured `notBitIdentical`
  // claim. The gate then reported `provenance` as `pass` and PRINTED
  // `artifact_comparison: NOT_BIT_IDENTICAL (2 artifact)` for a manifest that
  // stated no verdict at all, inventing a claim the document never made.
  //
  // This is the same trust boundary the gate's own docstring already promises
  // not to cross, one step earlier than 117.43-01/06: those defects let an
  // unsupported claim through; this one manufactures one. A verdict is the one
  // field in this evidence group that cannot be derived from the digests,
  // because the digests support both labels — it is the author's statement
  // about what the comparison MEANT, and an unreadable one is not a statement.
  group('117.43-07 an unreadable verdict is never assumed to be a claim', () {
    String digest(String seed) => seed * 64;

    /// The shipped evidence shape. [identicalRebuilds] decides whether the two
    /// rebuilds really disagree, so each canonical verdict can be paired with
    /// digests that actually SUPPORT it and the measurement stays honest.
    Map<String, Object?> manifestWithVerdict(
      String? verdict, {
      bool omit = false,
      bool identicalRebuilds = false,
    }) {
      return <String, Object?>{
        'required_evidence': <String, Object?>{
          'build_inputs': <String>['a'],
          'toolchain_versions': <String>['a'],
          'dependency_lock': <String>['a'],
          'rebuild_results': <Map<String, Object?>>[
            <String, Object?>{
              'label': 'rebuild_a',
              'artifact_hashes': <String, String>{
                'a.exe': digest('a'),
                'b.dll': digest('b'),
              },
              'exit_code': 0,
            },
            <String, Object?>{
              'label': 'rebuild_b',
              'artifact_hashes': <String, String>{
                'a.exe': digest('a'),
                'b.dll': identicalRebuilds ? digest('b') : digest('c'),
              },
              'exit_code': 0,
            },
          ],
          'artifact_comparison': <String, Object?>{
            'method': 'SHA-256 over the recorded artifacts',
            if (!omit) 'verdict': verdict,
            'limits': <String>['a documented limit, as the verdict requires'],
          },
          'provenance_record': <String>['a'],
        },
      };
    }

    test('an absent verdict key is not read as a difference claim', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithVerdict(null, omit: true),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a manifest that records no verdict records no claim; coercing the '
            'missing field into NOT_BIT_IDENTICAL invents one',
      );
      expect(
        check.observed,
        isNot(contains('NOT_BIT_IDENTICAL')),
        reason: 'the gate must not print a verdict the manifest never stated',
      );
    });

    test('a null verdict is not read as a difference claim', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithVerdict(null),
      );

      expect(check.status, Sprint117GaArtifactStatus.unmet);
      expect(check.observed, isNot(contains('NOT_BIT_IDENTICAL')));
    });

    test(
      'a verdict outside the canonical vocabulary is refused, not coerced',
      () {
        final check = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifestWithVerdict('BIT_IDENTITY'),
        );

        expect(
          check.status,
          Sprint117GaArtifactStatus.unmet,
          reason:
              'a typo in the verdict field must fail closed; falling back to '
              'notBitIdentical reports a claim the manifest does not make',
        );
        expect(check.observed, isNot(contains('NOT_BIT_IDENTICAL')));
      },
    );

    test('the canonical vocabularies still pass unchanged', () {
      // Control: the fix must not reject the two values the manifest schema
      // actually allows, including the honest NOT_BIT_IDENTICAL we ship.
      for (final verdict in <String>['BIT_IDENTICAL', 'NOT_BIT_IDENTICAL']) {
        final check = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifestWithVerdict(
            verdict,
            // BIT_IDENTICAL is only honest when the digests agree; pairing it
            // with a real difference would be the 117.43-01 defect, not a pass.
            identicalRebuilds: verdict == 'BIT_IDENTICAL',
          ),
        );

        expect(
          check.status,
          Sprint117GaArtifactStatus.pass,
          reason: 'the canonical verdict $verdict must still be accepted',
        );
        expect(check.observed, contains(verdict));
      }
    });

    test('the shipped manifest passes on its own stated verdict', () {
      final manifest = Sprint117GaArtifactGate.readManifest(
        Sprint117GaPackagingContract.provenanceManifestPath,
      );

      expect(manifest, isNotNull);
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifest!,
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });
  });

  // RED-first for defect 117.43-08: the PER-ARTIFACT partition was never read.
  // 117.43-01 verified the aggregate IDENTITY claim and 117.43-06 verified the
  // aggregate DIFFERENCE claim, 117.43-07 verified the verdict is readable.
  // All three are aggregate: the strongest question any of them asked was "do
  // these two rebuilds agree AT ALL". The manifest we ship answers a far
  // sharper question and names every artifact on one side of the line or the
  // other — `differing_artifacts` (4 binaries) and `identical_artifacts`
  // (flutter_windows.dll, sqlite3.dll). Nothing in lib/ or test/ ever read
  // either field, and `ArtifactComparison` has no property that could hold
  // them, so no amount of domain-level checking could ever see the partition.
  //
  // Consequence, proven before the fix: a manifest naming `a.exe` as
  // differing and `b.dll` as identical, while the recorded digests prove
  // exactly the reverse, reported `status == pass` with
  // `artifact_comparison: NOT_BIT_IDENTICAL (2 artifact)`. Every individual
  // claim it made was false and the aggregate it happened to satisfy was true.
  // That is the same trust boundary as 117.43-01/-06/-07 — a reproducibility
  // claim accepted without being measured — but strictly finer: those closed
  // the one-bit summary, this closes the per-artifact detail the manifest
  // actually publishes as its evidence.
  group('117.43-08 a per-artifact partition claim must be measured', () {
    String digest(String seed) => seed * 64;

    /// The shipped evidence shape. [secondB] is the digest rebuild_b recorded
    /// for b.dll, so a test can declare a partition and then pair it with
    /// digests that either support it or contradict it. The inventory is
    /// always {a.exe, b.dll}: a.exe identical in both, b.dll honest when
    /// [secondB] differs from rebuild_a.
    Map<String, Object?> manifestWithPartition({
      required List<String> differingClaim,
      required List<String> identicalClaim,
      String secondB = 'c',
      bool omitPartition = false,
    }) {
      return <String, Object?>{
        'required_evidence': <String, Object?>{
          'build_inputs': <String>['a'],
          'toolchain_versions': <String>['a'],
          'dependency_lock': <String>['a'],
          'rebuild_results': <Map<String, Object?>>[
            <String, Object?>{
              'label': 'rebuild_a',
              'artifact_hashes': <String, String>{
                'a.exe': digest('a'),
                'b.dll': digest('b'),
              },
              'exit_code': 0,
            },
            <String, Object?>{
              'label': 'rebuild_b',
              'artifact_hashes': <String, String>{
                'a.exe': digest('a'),
                'b.dll': digest(secondB),
              },
              'exit_code': 0,
            },
          ],
          'artifact_comparison': <String, Object?>{
            'method': 'SHA-256 over the recorded artifacts',
            'verdict': 'NOT_BIT_IDENTICAL',
            if (!omitPartition) 'differing_artifacts': differingClaim,
            if (!omitPartition) 'identical_artifacts': identicalClaim,
            'limits': <String>['a documented limit, as the verdict requires'],
          },
          'provenance_record': <String>['a'],
        },
      };
    }

    /// The comparison object inside a manifest built above, so a test can
    /// corrupt a field's TYPE without rebuilding the whole document.
    Map<String, Object?> comparisonOf(Map<String, Object?> manifest) =>
        (manifest['required_evidence']
                as Map<String, Object?>)['artifact_comparison']
            as Map<String, Object?>;

    test('a partition naming every artifact on the wrong side is refused', () {
      // Real data: a.exe identical, b.dll differs. The manifest asserts the
      // reverse. Both named claims are false, and the aggregate verdict stays
      // true because SOME difference exists — which is exactly why the
      // aggregate rules of 117.43-01/-06 let it through.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithPartition(
          differingClaim: <String>['a.exe'],
          identicalClaim: <String>['b.dll'],
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'each named artifact must be checked against its own digest; an '
            'aggregate "some difference exists" cannot support a per-artifact '
            'partition that is inverted end to end',
      );
    });

    test(
      'a partition naming an artifact neither rebuild recorded is refused',
      () {
        final check = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifestWithPartition(
            differingClaim: <String>['ghost.exe'],
            identicalClaim: <String>['a.exe', 'b.dll'],
          ),
        );

        expect(
          check.status,
          Sprint117GaArtifactStatus.unmet,
          reason:
              'a claim about an artifact no rebuild hashed is unsupported; names '
              'must resolve against the recorded inventory',
        );
      },
    );

    test(
      'a partition that leaves a recorded artifact unclassified is refused',
      () {
        // b.dll really did differ, but the manifest never says so. A partition
        // that silently drops an artifact is a partition that cannot be read as
        // a complete account of what the comparison found.
        final check = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifestWithPartition(
            differingClaim: <String>[],
            identicalClaim: <String>['a.exe'],
          ),
        );

        expect(
          check.status,
          Sprint117GaArtifactStatus.unmet,
          reason:
              'the two lists must classify the whole recorded inventory, or the '
              'comparison publishes a partial account as if it were the account',
        );
      },
    );

    test('a partition that puts one artifact on both sides is refused', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithPartition(
          differingClaim: <String>['b.dll'],
          identicalClaim: <String>['a.exe', 'b.dll'],
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason: 'an artifact cannot differ and be identical in the same claim',
      );
    });

    test('a partition field of the wrong type is refused, not skipped', () {
      final manifest = manifestWithPartition(
        differingClaim: <String>['b.dll'],
        identicalClaim: <String>['a.exe'],
      );
      comparisonOf(manifest)['differing_artifacts'] = 'b.dll';

      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifest,
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'an undecodable claim fails closed; casting a String to a list of '
            'names silently, or dropping it, would let the same evidence pass',
      );
    });

    test('an honest partition still passes', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithPartition(
          differingClaim: <String>['b.dll'],
          identicalClaim: <String>['a.exe'],
        ),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });

    test('a manifest that states no partition at all still passes', () {
      // Absence is not a defect: a manifest that names no artifact makes no
      // per-artifact claim, and per 117.43-07 an unstated claim must never be
      // manufactured. This also guards the 117.43-06/-07 fixtures, which carry
      // no partition fields.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithPartition(
          differingClaim: const <String>[],
          identicalClaim: const <String>[],
          omitPartition: true,
        ),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
    });

    test('the shipped manifest passes because its own partition is honest', () {
      final shipped = Sprint117GaArtifactGate.readManifest(
        Sprint117GaPackagingContract.provenanceManifestPath,
      );

      expect(shipped, isNotNull);
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: shipped!,
      );

      // The shipped partition is TRUE: 4 of 6 binaries really do differ and
      // the two upstream DLLs really are byte-identical (measured, not
      // assumed, before this slice). So the provenance output stays `pass`.
      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });

    test('the shipped pass is directed — inverting its partition fails it', () {
      // The honest half of the claim above: take the REAL shipped document and
      // swap its two lists, leaving every recorded digest untouched. If the
      // gate is really measuring the partition, this must stop passing; if it
      // is only measuring the aggregate, it will still pass and the shipped
      // `pass` was resting on nothing finer than "some artifact differed".
      final shipped = Sprint117GaArtifactGate.readManifest(
        Sprint117GaPackagingContract.provenanceManifestPath,
      );
      expect(shipped, isNotNull);

      final comparison =
          (shipped!['required_evidence']
                  as Map<String, Object?>)['artifact_comparison']
              as Map<String, Object?>;
      final differing = (comparison['differing_artifacts'] as List<dynamic>)
          .cast<String>();
      final identical = (comparison['identical_artifacts'] as List<dynamic>)
          .cast<String>();

      final inverted = jsonDecode(jsonEncode(shipped)) as Map<String, Object?>;
      final invertedComparison =
          (inverted['required_evidence']
                  as Map<String, Object?>)['artifact_comparison']
              as Map<String, Object?>;
      invertedComparison['differing_artifacts'] = identical;
      invertedComparison['identical_artifacts'] = differing;

      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: inverted,
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a manifest whose per-artifact partition is inverted must not keep '
            'passing on the strength of its aggregate verdict alone',
      );
    });
  });

  group('117.43-09 a rebuild window claim must be measured', () {
    String digest(String seed) => seed * 64;

    /// A manifest whose two rebuilds carry real windows and an honest
    /// per-artifact partition, so only the WINDOW can decide the result.
    Map<String, Object?> manifestWithWindow({
      String firstStarted = '2026-09-23T13:27:45+07:00',
      String firstFinished = '2026-09-23T13:29:47+07:00',
      int? firstDuration = 122,
      String secondStarted = '2026-09-23T13:30:17+07:00',
      String secondFinished = '2026-09-23T13:32:12+07:00',
      int? secondDuration = 115,
      bool includeWindow = true,
      bool includeDuration = true,
    }) {
      Map<String, Object?> rebuild(
        String label,
        String hashB,
        String? started,
        String? finished,
        int? duration,
      ) => <String, Object?>{
        'label': label,
        'artifact_hashes': <String, String>{
          'a.exe': digest('a'),
          'b.dll': hashB,
        },
        'exit_code': 0,
        if (includeWindow && started != null) 'started_at': started,
        if (includeWindow && finished != null) 'finished_at': finished,
        if (includeDuration && duration != null) 'duration_seconds': duration,
      };

      return <String, Object?>{
        'required_evidence': <String, Object?>{
          'build_inputs': <String>['a'],
          'toolchain_versions': <String>['a'],
          'dependency_lock': <String>['a'],
          'rebuild_results': <Map<String, Object?>>[
            rebuild(
              'rebuild_a',
              digest('b'),
              firstStarted,
              firstFinished,
              firstDuration,
            ),
            rebuild(
              'rebuild_b',
              digest('c'),
              secondStarted,
              secondFinished,
              secondDuration,
            ),
          ],
          'artifact_comparison': <String, Object?>{
            'method': 'SHA-256 after two independent clean rebuild cycles',
            'verdict': 'NOT_BIT_IDENTICAL',
            'differing_artifacts': <String>['b.dll'],
            'identical_artifacts': <String>['a.exe'],
            'limits': <String>['a documented limit, as the verdict requires'],
          },
          'provenance_record': <String>['a'],
        },
      };
    }

    test('two rebuilds whose windows overlap are refused', () {
      // The digests differ, the partition is honest, the verdict is canonical —
      // every rule of 117.43-01/-06/-07/-08 is satisfied. The only thing wrong
      // is the history: rebuild_b starts while rebuild_a is still running, so
      // the two "independent clean rebuild cycles" the `method` claims are one
      // overlapping pair contending for the same `build/` directory. Nothing
      // read the windows before this slice, so it reported `pass`.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(
          secondStarted: '2026-09-23T13:28:00+07:00',
          secondFinished: '2026-09-23T13:32:12+07:00',
          secondDuration: 252,
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'overlapping rebuild windows cannot be two independent clean '
            'rebuilds, so the digests they record are not evidence of '
            'reproducibility no matter how well the aggregate verdict reads',
      );
    });

    test('a rebuild that finished before it started is refused', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(
          secondStarted: '2026-09-23T13:32:12+07:00',
          secondFinished: '2026-09-23T13:30:17+07:00',
          secondDuration: -115,
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason: 'a window that runs backwards is not a record of a rebuild',
      );
    });

    test('a zero-length rebuild window is refused', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(
          secondFinished: '2026-09-23T13:30:17+07:00',
          secondDuration: 0,
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a rebuild that starts and ends at the same instant ran no build at '
            'all, which is not the clean rebuild the comparison depends on',
      );
    });

    test('a recorded duration that contradicts its own window is refused', () {
      // 13:30:17 -> 13:32:12 is 115 seconds; the manifest says 5. One record
      // disagreeing with itself is enough to refuse the claim it supports.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(firstDuration: 5),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'duration_seconds must agree with the window it summarises, or the '
            'record contradicts itself and supports nothing',
      );
    });

    test('a timestamp that cannot be parsed is refused, not skipped', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(firstStarted: 'yesterday-ish'),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'an unreadable window fails closed; silently treating it as absent '
            'would reopen the exact hole this closes',
      );
    });

    test('a window field of the wrong type is refused, not cast', () {
      final manifest = manifestWithWindow();
      ((manifest['required_evidence']
                    as Map<String, Object?>)['rebuild_results']
                as List<dynamic>)[0]
            as Map<String, Object?>
        ..['started_at'] = 1758010265
        ..['duration_seconds'] = '122';

      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifest,
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a number where a timestamp belongs, or a string where a count '
            'belongs, must fail closed rather than be cast past',
      );
    });

    test('honest non-overlapping windows still pass', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });

    test('a manifest that records no window at all still passes', () {
      // Absence is not a defect: a record that states no window makes no window
      // claim, per 117.43-07. This also guards the 117.43-06/-07 fixtures,
      // which carry no timestamps.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithWindow(
          includeWindow: false,
          includeDuration: false,
        ),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
    });

    test('the shipped manifest passes because its windows are honest', () {
      final shipped = Sprint117GaArtifactGate.readManifest(
        Sprint117GaPackagingContract.provenanceManifestPath,
      );

      expect(shipped, isNotNull);
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: shipped!,
      );

      // Measured independently before this slice, not assumed: rebuild_a ran
      // 13:27:45 -> 13:29:47 (122s, matching its recorded duration), rebuild_b
      // ran 13:30:17 -> 13:32:12 (115s, also matching), and the two windows are
      // 30 seconds apart. So the independence claim is real and the provenance
      // output stays `pass`.
      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });

    test('the shipped pass is directed — overlapping its windows fails it', () {
      // The honest half of the claim above: take the REAL shipped document and
      // move rebuild_b's start back inside rebuild_a's window, leaving every
      // recorded digest, verdict, and partition untouched. If the gate really
      // measures the windows this must stop passing; if it only measures the
      // digests it will still pass, and the shipped `pass` was resting on
      // nothing finer than "some artifact differed".
      final shipped = Sprint117GaArtifactGate.readManifest(
        Sprint117GaPackagingContract.provenanceManifestPath,
      );
      expect(shipped, isNotNull);

      final overlapping =
          jsonDecode(jsonEncode(shipped)) as Map<String, Object?>;
      final rebuilds =
          (overlapping['required_evidence']
                  as Map<String, Object?>)['rebuild_results']
              as List<dynamic>;
      final first = rebuilds[0] as Map<String, Object?>;
      final second = rebuilds[1] as Map<String, Object?>;
      second['started_at'] = first['started_at'];
      second['duration_seconds'] = DateTime.parse(
        second['finished_at'] as String,
      ).difference(DateTime.parse(first['started_at'] as String)).inSeconds;

      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: overlapping,
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a manifest whose two rebuild windows overlap must not keep passing '
            'on the strength of its digest comparison alone',
      );
    });
  });

  group('117.43-09 the domain refuses a window it cannot read', () {
    final hashes = <String, String>{'a.exe': 'a' * 64};

    test('a reversed window is not well formed', () {
      final rebuild = RebuildResult(
        label: 'rebuild_a',
        artifactHashes: hashes,
        exitCode: 0,
        startedAt: '2026-09-23T13:29:47+07:00',
        finishedAt: '2026-09-23T13:27:45+07:00',
      );

      expect(rebuild.hasWellFormedWindow, isFalse);
      expect(rebuild.isWellFormed, isFalse);
    });

    test('a half-recorded window is not well formed', () {
      final rebuild = RebuildResult(
        label: 'rebuild_a',
        artifactHashes: hashes,
        exitCode: 0,
        startedAt: '2026-09-23T13:27:45+07:00',
      );

      expect(rebuild.hasWellFormedWindow, isFalse);
      expect(rebuild.isWellFormed, isFalse);
    });

    test('an absent window is not a claim and stays well formed', () {
      final rebuild = RebuildResult(
        label: 'rebuild_a',
        artifactHashes: hashes,
        exitCode: 0,
      );

      expect(rebuild.hasWellFormedWindow, isTrue);
      expect(rebuild.isWellFormed, isTrue);
    });

    test('a forwards window is well formed', () {
      final rebuild = RebuildResult(
        label: 'rebuild_a',
        artifactHashes: hashes,
        exitCode: 0,
        startedAt: '2026-09-23T13:27:45+07:00',
        finishedAt: '2026-09-23T13:29:47+07:00',
      );

      expect(rebuild.hasWellFormedWindow, isTrue);
      expect(rebuild.isWellFormed, isTrue);
    });
  });

  group('117.43-10 a rebuild method claim must be measured', () {
    String digest(String seed) => seed * 64;

    const honestCommand =
        'flutter clean && flutter.bat build windows --release';

    /// Two honest rebuild records — separated windows, canonical verdict, an
    /// honest partition — so only the COMMAND and LOG can decide the result.
    Map<String, Object?> manifestWithRun({
      String commandA = honestCommand,
      String commandB = honestCommand,
      String logA = 'docs/evidence/sprint-113-39-rebuild-a.log',
      String logB = 'docs/evidence/sprint-113-39-rebuild-b.log',
      bool dropCommand = false,
      bool dropLog = false,
      bool mistypeCommandA = false,
      bool mistypeLogB = false,
    }) {
      Map<String, Object?> rebuild(
        String label,
        String hashB,
        String command,
        String log,
        String started,
        String finished,
        int duration,
      ) => <String, Object?>{
        'label': label,
        'artifact_hashes': <String, String>{
          'a.exe': digest('a'),
          'b.dll': hashB,
        },
        'exit_code': 0,
        'started_at': started,
        'finished_at': finished,
        'duration_seconds': duration,
        if (!dropCommand) 'command': command,
        if (!dropLog) 'log': log,
      };

      var a = rebuild(
        'rebuild_a',
        digest('b'),
        commandA,
        logA,
        '2026-09-23T13:27:45+07:00',
        '2026-09-23T13:29:47+07:00',
        122,
      );
      var b = rebuild(
        'rebuild_b',
        digest('c'),
        commandB,
        logB,
        '2026-09-23T13:30:17+07:00',
        '2026-09-23T13:32:12+07:00',
        115,
      );
      if (mistypeCommandA) a = <String, Object?>{...a, 'command': 17};
      if (mistypeLogB) b = <String, Object?>{...b, 'log': 42};

      return <String, Object?>{
        'required_evidence': <String, Object?>{
          'build_inputs': <String>['a'],
          'toolchain_versions': <String>['a'],
          'dependency_lock': <String>['a'],
          'rebuild_results': <Map<String, Object?>>[a, b],
          'artifact_comparison': <String, Object?>{
            'method': 'SHA-256 after two independent clean rebuild cycles',
            'verdict': 'NOT_BIT_IDENTICAL',
            'differing_artifacts': <String>['b.dll'],
            'identical_artifacts': <String>['a.exe'],
            'limits': <String>['a documented limit, as the verdict requires'],
          },
          'provenance_record': <String>['a'],
        },
      };
    }

    test('a rebuild that never ran flutter clean is refused', () {
      // The `method` claims the digests come from CLEAN rebuild cycles. A
      // recorded command that contains no clean step cannot have produced a
      // clean rebuild, and nothing read `command` before this slice, so the
      // gate reported `pass` for a manifest whose own command disproves it.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(
          commandB: 'flutter.bat build windows --release',
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a rebuild whose recorded command contains no clean step cannot be '
            'the clean rebuild the comparison method claims',
      );
    });

    test('two rebuilds that ran different experiments are refused', () {
      // rebuild_a is a release build, rebuild_b a debug build. Comparing them
      // answers a different question from the one the method states, and the
      // digest difference it records proves nothing about reproducibility.
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(
          commandB: 'flutter clean && flutter.bat build windows --debug',
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a release build compared against a debug build is not two clean '
            'rebuilds of one experiment',
      );
    });

    test('a rebuild whose log names a file that does not exist is refused', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(
          logA: 'docs/evidence/zz_probe_absent.log',
        ),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a rebuild record naming a log nobody can open is evidence with no '
            'supporting document',
      );
    });

    test('a mistyped command or log is refused rather than cast past', () {
      final mistypedCommand = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(mistypeCommandA: true),
      );
      final mistypedLog = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(mistypeLogB: true),
      );

      expect(mistypedCommand.status, Sprint117GaArtifactStatus.unmet);
      expect(mistypedLog.status, Sprint117GaArtifactStatus.unmet);
    });

    test('an absent command or log makes no claim and is not a defect', () {
      // Same rule as 117.43-07: absence is not a claim, so a manifest that
      // records no command states nothing for the gate to contradict.
      final noCommand = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(dropCommand: true),
      );
      final noLog = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(dropLog: true),
      );

      expect(noCommand.status, Sprint117GaArtifactStatus.pass);
      expect(noLog.status, Sprint117GaArtifactStatus.pass);
    });

    test('an honest command pair still passes', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithRun(),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
    });

    test('the shipped manifest passes, and stops when its claim is broken', () {
      // If only the digests were measured, mutating the SHIPPED document's
      // command to drop its clean step would still pass. It must not.
      final shipped = _manifest(_kProvenanceManifest);
      final evidence = shipped['required_evidence'] as Map<String, Object?>;
      final rebuilds = evidence['rebuild_results']! as List;
      final first = Map<String, Object?>.from(rebuilds[0] as Map);
      final second = Map<String, Object?>.from(rebuilds[1] as Map);
      expect(first['command'], contains('flutter clean'));
      expect(second['command'], contains('flutter clean'));

      expect(
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: shipped,
        ).status,
        Sprint117GaArtifactStatus.pass,
      );

      first['command'] = 'flutter.bat build windows --release';
      expect(
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: <String, Object?>{
            'required_evidence': <String, Object?>{
              ...evidence,
              'rebuild_results': <Map<String, Object?>>[first, second],
            },
          },
        ).status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'the shipped document is only evidence of a clean rebuild while it '
            'still records a clean rebuild',
      );
    });
  });

  group('117.43-11 a recorded digest claim must be a digest', () {
    String digest(String seed) => seed * 64;

    const honestCommand =
        'flutter clean && flutter.bat build windows --release';
    const honestLockDigest =
        '32e31fd31a928e20007226e720ee37a661afb5d0d224d4eb24b04463496626f8';
    const honestLockProse =
        'hosted dependencies hash-pinned sha256; '
        '0 git/path source; 0 dependency_overrides (113.26 dependency_scan)';

    /// An otherwise honest manifest — honest windows, commands, logs, verdict
    /// and per-artifact partition — so only the DIGEST GROUPS can decide the
    /// result. `buildInputs` and `dependencyLock` are the two groups under test.
    Map<String, Object?> manifestWithDigests({
      required List<String> buildInputs,
      List<String>? dependencyLock,
    }) {
      Map<String, Object?> rebuild(
        String label,
        String hashB,
        String started,
        String finished,
        int duration,
        String log,
      ) => <String, Object?>{
        'label': label,
        'artifact_hashes': <String, String>{
          'a.exe': digest('a'),
          'b.dll': hashB,
        },
        'exit_code': 0,
        'started_at': started,
        'finished_at': finished,
        'duration_seconds': duration,
        'command': honestCommand,
        'log': log,
      };

      return <String, Object?>{
        'required_evidence': <String, Object?>{
          'build_inputs': buildInputs,
          'toolchain_versions': <String>['Flutter 3.44.6 channel stable'],
          'dependency_lock':
              dependencyLock ??
              <String>[honestLockProse] +
                  ['pubspec.lock sha256 $honestLockDigest'],
          'rebuild_results': <Map<String, Object?>>[
            rebuild(
              'rebuild_a',
              digest('b'),
              '2026-09-23T13:27:45+07:00',
              '2026-09-23T13:29:47+07:00',
              122,
              'docs/evidence/sprint-113-39-rebuild-a.log',
            ),
            rebuild(
              'rebuild_b',
              digest('c'),
              '2026-09-23T13:30:17+07:00',
              '2026-09-23T13:32:12+07:00',
              115,
              'docs/evidence/sprint-113-39-rebuild-b.log',
            ),
          ],
          'artifact_comparison': <String, Object?>{
            'method':
                'SHA-256 over the artifacts after two independent clean '
                'rebuild cycles',
            'verdict': 'NOT_BIT_IDENTICAL',
            'differing_artifacts': <String>['b.dll'],
            'identical_artifacts': <String>['a.exe'],
            'limits': <String>['a documented limit, as the verdict requires'],
          },
          'provenance_record': <String>['source_revision 30dda0c3'],
        },
      };
    }

    String statusOf(List<String> buildInputs, {List<String>? dependencyLock}) =>
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifestWithDigests(
            buildInputs: buildInputs,
            dependencyLock: dependencyLock,
          ),
        ).status.name;

    test('117.43-11 a line naming a digest must carry one', () {
      // `build_inputs` exists to say WHICH file was hashed and WHAT it hashed
      // to. Before this slice the group was checked for being non-blank and for
      // nothing else, so every one of these reported `pass` and the gate
      // printed `build_inputs: 5 item` as though the content had been read.
      // Eleven cases were run before the fix; ten of them passed, and the one
      // that failed did so for being blank, not for its digest.
      expect(
        statusOf(<String>['pubspec.yaml sha256 NOT-A-DIGEST']),
        'unmet',
        reason: 'the line announces a sha256 and supplies something else',
      );
      expect(
        statusOf(<String>['pubspec.yaml sha256 deadbeef']),
        'unmet',
        reason: 'an eight-character value is not a SHA-256 digest',
      );
      expect(
        statusOf(<String>['pubspec.yaml sha256 ${'a' * 63}']),
        'unmet',
        reason: '63 hex characters is a truncated digest, not a digest',
      );
      expect(
        statusOf(<String>['pubspec.yaml sha256 ${'a' * 65}']),
        'unmet',
        reason: '65 hex characters is not a SHA-256 digest either',
      );
      expect(
        statusOf(<String>[
          'pubspec.lock sha256 $honestLockDigest',
          'pubspec.yaml sha256 GARBAGE',
        ]),
        'unmet',
        reason: 'one malformed claim fails the group it sits in',
      );
    });

    test('117.43-11 the same rule covers dependency_lock', () {
      expect(
        statusOf(
          <String>['pubspec.lock sha256 $honestLockDigest'],
          dependencyLock: <String>['pubspec.lock sha256 zzz'],
        ),
        'unmet',
      );
      expect(
        statusOf(
          <String>['pubspec.lock sha256 $honestLockDigest'],
          dependencyLock: <String>['pubspec.lock sha256 deadbeef'],
        ),
        'unmet',
      );
    });

    test(
      '117.43-11 a line that merely MENTIONS the algorithm is not a claim',
      () {
        // The shipped manifest's own dependency_lock carries this prose line
        // describing a dependency scan. It names `sha256` but states no value,
        // so it makes no digest claim — the same non-claim rule 117.43-07
        // established for the comparison verdict. A rule that refused this would
        // refuse an honest document.
        expect(
          statusOf(<String>[
            'pubspec.lock sha256 $honestLockDigest',
            honestLockProse,
          ]),
          'pass',
        );
        expect(statusOf(<String>['inputs were hashed at some point']), 'pass');
      },
    );

    test('117.43-11 case and hyphen spelling are still read as a claim', () {
      // The rule matches the CLAIM, not one exact spelling of it: a document
      // that writes `SHA256` or `sha-256` and then supplies garbage has still
      // made a claim it cannot back up.
      expect(statusOf(<String>['pubspec.yaml SHA256 NOPE']), 'unmet');
      expect(statusOf(<String>['pubspec.yaml sha-256 nope']), 'unmet');
    });

    test('117.43-11 the shipped manifest passes, and stops when a claim breaks', () {
      // If only the PRESENCE of the group were measured, rewriting the shipped
      // document's digests into garbage would still pass. It must not — and the
      // untouched document must keep passing, or the rule refuses honest work.
      final shipped = _manifest(_kProvenanceManifest);
      final evidence = shipped['required_evidence'] as Map<String, Object?>;
      final inputs = (evidence['build_inputs']! as List).cast<String>();
      expect(
        inputs.first,
        matches(RegExp(r'sha256 [0-9a-f]{64}')),
        reason:
            'the fixture must be the honest shape for this to prove anything',
      );
      expect(
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: shipped,
        ).status,
        Sprint117GaArtifactStatus.pass,
      );

      expect(
        statusOf(<String>[
          for (final line in inputs)
            line.replaceAll(RegExp(r'[0-9a-f]{64}'), 'NOT-A-DIGEST'),
        ]),
        'unmet',
        reason:
            'the shipped document is only evidence of which files were hashed '
            'while it actually states digests',
      );
    });

    test('117.43-11 a digest is not re-hashed against the working tree', () {
      // Why the rule stops at FORM. `build_inputs` pins digests at the
      // provenance anchor revision `30dda0c3`, not at HEAD, and re-hashing
      // them against the live checkout would refuse an honest manifest: this
      // repo's `pubspec.yaml` digest matches its CRLF variant at that
      // revision and not the LF bytes on disk. Measured, not assumed — the
      // drift hypothesis was disproved before the rule was written.
      expect(
        statusOf(<String>[
          'pubspec.yaml sha256 $honestLockDigest',
          'pubspec.lock sha256 $honestLockDigest',
          'windows/CMakeLists.txt sha256 ${digest('1')}',
          'windows/runner/main.cpp sha256 ${digest('2')}',
          'windows/runner/flutter_window.cpp sha256 ${digest('3')}',
        ]),
        'pass',
        reason:
            'a well-formed digest claim is honest even when its value cannot be '
            're-derived from the tree the gate happens to run in',
      );
    });
  });

  group('117.43-12 a mistyped evidence group is refused, not thrown on', () {
    String digest(String seed) => seed * 64;

    /// The 117.43-11 fixture, with one group replaced by something of the wrong
    /// shape. Everything else stays honest so the shape is the only variable.
    Map<String, Object?> manifestWithGroup(String key, Object? group) {
      final base = <String, Object?>{
        'required_evidence': <String, Object?>{
          'build_inputs': <String>['pubspec.lock sha256 ${digest('2')}'],
          'toolchain_versions': <String>['Flutter 3.44.6 channel stable'],
          'dependency_lock': <String>['pubspec.lock sha256 ${digest('2')}'],
          'rebuild_results': <Map<String, Object?>>[
            <String, Object?>{
              'label': 'rebuild_a',
              'artifact_hashes': <String, String>{
                'a.exe': digest('a'),
                'b.dll': digest('b'),
              },
              'exit_code': 0,
              'started_at': '2026-09-23T13:27:45+07:00',
              'finished_at': '2026-09-23T13:29:47+07:00',
              'duration_seconds': 122,
              'command': 'flutter clean && flutter.bat build windows --release',
              'log': 'docs/evidence/sprint-113-39-rebuild-a.log',
            },
            <String, Object?>{
              'label': 'rebuild_b',
              'artifact_hashes': <String, String>{
                'a.exe': digest('a'),
                'b.dll': digest('c'),
              },
              'exit_code': 0,
              'started_at': '2026-09-23T13:30:17+07:00',
              'finished_at': '2026-09-23T13:32:12+07:00',
              'duration_seconds': 115,
              'command': 'flutter clean && flutter.bat build windows --release',
              'log': 'docs/evidence/sprint-113-39-rebuild-b.log',
            },
          ],
          'artifact_comparison': <String, Object?>{
            'method':
                'SHA-256 over the artifacts after two independent clean '
                'rebuild cycles',
            'verdict': 'NOT_BIT_IDENTICAL',
            'differing_artifacts': <String>['b.dll'],
            'identical_artifacts': <String>['a.exe'],
            'limits': <String>['a documented limit, as the verdict requires'],
          },
          'provenance_record': <String>['source_revision 30dda0c3'],
        },
      };
      (base['required_evidence']! as Map<String, Object?>)[key] = group;
      return base;
    }

    void expectRefused(String key, Object? group) {
      Object? thrown;
      String status = 'THREW';
      try {
        status = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifestWithGroup(key, group),
        ).status.name;
      } catch (error) {
        thrown = error;
      }
      expect(
        thrown,
        isNull,
        reason:
            'a malformed "$key" must fail closed with a verdict, not escape the '
            'gate as ${thrown.runtimeType}',
      );
      expect(
        status,
        'unmet',
        reason:
            'a malformed "$key" of shape ${group.runtimeType} is unevaluable',
      );
    }

    test('117.43-12 a non-string element is refused, not cast past', () {
      expectRefused('build_inputs', <dynamic>[42]);
      expectRefused('toolchain_versions', <dynamic>[42]);
      expectRefused('dependency_lock', <dynamic>[42]);
      expectRefused('provenance_record', <dynamic>[42]);
    });

    test('117.43-12 a nested object is refused too', () {
      expectRefused('build_inputs', <dynamic>[<String, Object?>{}]);
      expectRefused('toolchain_versions', <dynamic>[<String, Object?>{}]);
    });

    test('117.43-12 a group that is not a list at all is refused', () {
      expectRefused('build_inputs', 'a bare string');
      expectRefused('toolchain_versions', 'a bare string');
      expectRefused('dependency_lock', <String, Object?>{'not': 'a list'});
      expectRefused('provenance_record', 42);
    });

    test('117.43-12 a blank string inside an honest list is refused', () {
      expectRefused('build_inputs', <dynamic>[
        'pubspec.lock sha256 ${digest('2')}',
        '   ',
      ]);
    });

    test('117.43-12 every one of these threw before this slice', () {
      // The reader this replaces was
      // `(evidence[key] as List<dynamic>?)?.cast<String>()`: `as` throws on a
      // non-list and `cast<String>()` throws on a non-string element, so all
      // nine shapes above escaped the gate as a TypeError instead of being
      // reported. Probed before the fix — every case printed
      // `status=NO-STATUS thrown=TypeError`. A gate that crashes on malformed
      // input is not fail-closed, which is why this is filed beside the
      // digest rule rather than folded into it: one reads content the other
      // decodes shape.
      final thrown = <String>[];
      for (final entry in <Object?>[
        <Object?>[42],
        <Object?>[<String, Object?>{}],
        <Object?>['a bare string'],
        <Object?>['x', '   '],
        42,
      ]) {
        try {
          Sprint117GaArtifactGate.measureProvenance(
            provenanceManifest: manifestWithGroup('build_inputs', entry),
          );
        } catch (error) {
          thrown.add(error.runtimeType.toString());
        }
      }
      expect(
        thrown,
        isEmpty,
        reason: 'pre-fix these all threw TypeError out of the gate',
      );
    });

    test('117.43-12 the honest manifest still passes', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifestWithGroup('build_inputs', <String>[
          'pubspec.lock sha256 ${digest('2')}',
          'a plain note',
        ]),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
    });
  });

  // RED-first for defect 117.43-13: 117.43-12 fixed the FOUR top-level
  // evidence groups, and every OTHER decode in the gate had already been
  // written for the same trust boundary under -08/-09/-10. Thirteen reads one
  // level down were missed. Each reached its value through `as T` or
  // `cast<T>()`, which ASSERTS the shape instead of checking it, so a
  // manifest holding a number where a string belongs — or a bare string where a
  // list belongs — did not report `unmet`. It threw a `TypeError` clean out of
  // the gate, and the caller received nothing at all: no verdict, no note, no
  // failed output. A gate that crashes on malformed evidence is not fail-closed,
  // and the crash is strictly worse than a wrong answer because it is silent
  // about the very output it was asked to measure.
  //
  // Every case below printed `status=NO-STATUS thrown=TypeError` when probed
  // against HEAD before the fix. They are filed as one defect because they are
  // one omission: the same reader, applied consistently in one direction and
  // left asserting in the other.
  group('117.43-13 every remaining decode seam refuses a shape it cannot read', () {
    String digest(String seed) => seed * 64;

    /// An otherwise honest manifest — separated windows, clean commands,
    /// readable logs, canonical verdict, honest per-artifact partition — so
    /// only the seam under test can decide the result.
    Map<String, Object?> manifest() => <String, Object?>{
      'required_evidence': <String, Object?>{
        'build_inputs': <String>['pubspec.lock sha256 ${digest('2')}'],
        'toolchain_versions': <String>['Flutter 3.44.6 channel stable'],
        'dependency_lock': <String>['pubspec.lock sha256 ${digest('2')}'],
        'rebuild_results': <Map<String, Object?>>[
          <String, Object?>{
            'label': 'rebuild_a',
            'artifact_hashes': <String, String>{
              'a.exe': digest('a'),
              'b.dll': digest('b'),
            },
            'exit_code': 0,
            'started_at': '2026-09-23T13:27:45+07:00',
            'finished_at': '2026-09-23T13:29:47+07:00',
            'duration_seconds': 122,
            'command': 'flutter clean && flutter.bat build windows --release',
            'log': 'docs/evidence/sprint-113-39-rebuild-a.log',
          },
          <String, Object?>{
            'label': 'rebuild_b',
            'artifact_hashes': <String, String>{
              'a.exe': digest('a'),
              'b.dll': digest('c'),
            },
            'exit_code': 0,
            'started_at': '2026-09-23T13:30:17+07:00',
            'finished_at': '2026-09-23T13:32:12+07:00',
            'duration_seconds': 115,
            'command': 'flutter clean && flutter.bat build windows --release',
            'log': 'docs/evidence/sprint-113-39-rebuild-b.log',
          },
        ],
        'artifact_comparison': <String, Object?>{
          'method':
              'SHA-256 over the artifacts after two independent clean '
              'rebuild cycles',
          'verdict': 'NOT_BIT_IDENTICAL',
          'differing_artifacts': <String>['b.dll'],
          'identical_artifacts': <String>['a.exe'],
          'limits': <String>['a documented limit, as the verdict requires'],
        },
        'provenance_record': <String>['source_revision 30dda0c3'],
      },
    };

    Map<String, Object?> evidenceOf(Map<String, Object?> m) =>
        m['required_evidence']! as Map<String, Object?>;

    List<Map<String, Object?>> rebuildsOf(Map<String, Object?> m) =>
        evidenceOf(m)['rebuild_results']! as List<Map<String, Object?>>;

    Map<String, Object?> comparisonOf(Map<String, Object?> m) =>
        evidenceOf(m)['artifact_comparison']! as Map<String, Object?>;

    /// A malformed shape must produce a VERDICT. The crash is the defect: an
    /// exception escaping the gate is an absent answer, so [thrown] being null
    /// is asserted before the status so a crash can never read as a pass.
    void expectRefused(String seam, Map<String, Object?> malformed) {
      var status = 'NO-STATUS';
      Object? thrown;
      try {
        status = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: malformed,
        ).status.name;
      } catch (error) {
        thrown = error;
      }
      expect(
        thrown,
        isNull,
        reason:
            'a malformed "$seam" must fail closed with a verdict, not '
            'escape the gate as ${thrown.runtimeType}',
      );
      expect(
        status,
        'unmet',
        reason: 'a malformed "$seam" is unevaluable, never a pass',
      );
    }

    test('117.43-13 a mistyped rebuild_results group is refused', () {
      for (final shape in <Object?>[
        'a bare string',
        42,
        <String, Object?>{'not': 'a list'},
        <Object?>[42, 43],
      ]) {
        final m = manifest();
        evidenceOf(m)['rebuild_results'] = shape;
        expectRefused('rebuild_results=${shape.runtimeType}', m);
      }
    });

    test('117.43-13 a mistyped comparison method is refused', () {
      final m = manifest();
      comparisonOf(m)['method'] = 42;
      expectRefused('method=int', m);
    });

    test('117.43-13 a mistyped limits group is refused', () {
      for (final shape in <Object?>[
        'a bare string',
        <Object?>[42],
        42,
      ]) {
        final m = manifest();
        comparisonOf(m)['limits'] = shape;
        expectRefused('limits=${shape.runtimeType}', m);
      }
    });

    test('117.43-13 a mistyped artifact digest is refused', () {
      // A digest map whose VALUE is not a string is the sharpest case here:
      // `hashes.map((key, value) => MapEntry(key, value as String))` asserts
      // per element, so one fabricated or null digest under an otherwise
      // honest inventory destroyed the entire provenance verdict.
      for (final shape in <Object?>[42, null]) {
        final m = manifest();
        rebuildsOf(m)[0]['artifact_hashes'] = <String, Object?>{
          'a.exe': shape,
          'b.dll': digest('b'),
        };
        expectRefused('artifact_hashes=${shape.runtimeType}', m);
      }
    });

    test('117.43-13 a mistyped exit_code is refused', () {
      final m = manifest();
      rebuildsOf(m)[0]['exit_code'] = '0';
      expectRefused('exit_code=String', m);
    });

    test('117.43-13 a mistyped signed_artifacts group is refused', () {
      for (final shape in <Object?>[
        'a bare string',
        <Object?>[42],
        42,
        <String, Object?>{'not': 'a list'},
      ]) {
        var status = 'NO-STATUS';
        Object? thrown;
        try {
          status = Sprint117GaArtifactGate.measureSignedArtifacts(
            packagingOutputs: <String, Object?>{'signed_artifacts': shape},
            declaredArtifacts: const <String>['a.exe'],
          ).status.name;
        } catch (error) {
          thrown = error;
        }
        expect(
          thrown,
          isNull,
          reason:
              'a malformed signed_artifacts of ${shape.runtimeType} must '
              'fail closed with a verdict, not escape as ${thrown.runtimeType}',
        );
        expect(status, 'unmet');
      }
    });

    test('117.43-13 every one of these threw before this slice', () {
      // The historical record, kept as an executable assertion: pre-fix all
      // thirteen reached a `TypeError` and returned nothing to the caller. The
      // reader is the same at every site — `as T` / `cast<T>()`, asserting a
      // shape it was supposed to be checking.
      final thrown = <String>[];
      void record(String seam, void Function() call) {
        try {
          call();
        } catch (error) {
          thrown.add('$seam=${error.runtimeType}');
        }
      }

      for (final shape in <Object?>[
        'a bare string',
        42,
        <String, Object?>{'n': 1},
      ]) {
        final m = manifest();
        evidenceOf(m)['rebuild_results'] = shape;
        record(
          'rebuild_results:${shape.runtimeType}',
          () =>
              Sprint117GaArtifactGate.measureProvenance(provenanceManifest: m),
        );
      }
      final listOfInt = manifest();
      evidenceOf(listOfInt)['rebuild_results'] = <Object?>[42, 43];
      record(
        'rebuild_results:list-of-int',
        () => Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: listOfInt,
        ),
      );

      final badMethod = manifest();
      comparisonOf(badMethod)['method'] = 42;
      record(
        'method:int',
        () => Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: badMethod,
        ),
      );

      for (final shape in <Object?>[
        'a bare string',
        <Object?>[42],
        42,
      ]) {
        final m = manifest();
        comparisonOf(m)['limits'] = shape;
        record(
          'limits:${shape.runtimeType}',
          () =>
              Sprint117GaArtifactGate.measureProvenance(provenanceManifest: m),
        );
      }

      for (final shape in <Object?>[42, null]) {
        final m = manifest();
        rebuildsOf(m)[0]['artifact_hashes'] = <String, Object?>{
          'a.exe': shape,
          'b.dll': digest('b'),
        };
        record(
          'artifact_hashes:${shape.runtimeType}',
          () =>
              Sprint117GaArtifactGate.measureProvenance(provenanceManifest: m),
        );
      }

      final badExit = manifest();
      rebuildsOf(badExit)[0]['exit_code'] = '0';
      record(
        'exit_code:String',
        () => Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: badExit,
        ),
      );

      for (final shape in <Object?>[
        'a bare string',
        <Object?>[42],
        42,
        <String, Object?>{'not': 'a list'},
      ]) {
        record(
          'signed_artifacts:${shape.runtimeType}',
          () => Sprint117GaArtifactGate.measureSignedArtifacts(
            packagingOutputs: <String, Object?>{'signed_artifacts': shape},
            declaredArtifacts: const <String>['a.exe'],
          ),
        );
      }

      expect(
        thrown,
        isEmpty,
        reason:
            'pre-fix all thirteen escaped as an exception rather than a '
            'verdict; a gate that crashes is not fail-closed',
      );
    });

    test('117.43-13 the honest manifest still passes', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: manifest(),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });
  });

  // RED-first for defect 117.43-14: the ninth slice in the same hunt, and the
  // first one where the gate did not merely IGNORE a field — it read the first
  // TWO rebuild records and no others, then reported the count of the two it
  // had chosen as though it were the count the document states.
  //
  // `_evaluateShippedProvenance` requires `rebuildList.length >= 2`, decodes
  // `rebuildList[0]` and `rebuildList[1]`, and builds the domain object with
  // `rebuildResults: <RebuildResult>[a, b]`. Every rule 117.43-08/-09/-10/-12/
  // -13 added — the window, the clean command, the digest, the exit code, the
  // reachable log — is therefore applied to TWO of the records a document may
  // hold, and to no other. The gate then prints `rebuild_results: 2 item`, a
  // number it chose rather than one it measured.
  //
  // This is the same failure the hunt has been closing all along, one level out:
  // 117.43-13 made a mistyped THIRD record fail closed, but it could not, and
  // could not have, because the third record is never decoded. Proven against
  // HEAD before the fix, by appending one record to the SHIPPED manifest so
  // that only the appended defect could decide the outcome — a non-zero exit
  // code, a fabricated digest, a reversed window, a command with no clean step,
  // a duplicate label, and an artifact no comparison names. All six returned
  // `pass`, and every one of them reported `rebuild_results: 2 item`.
  group('117.43-14 every recorded rebuild is measured, and the count is measured '
      'too', () {
    String digest(String seed) => seed * 64;

    /// The SHIPPED manifest, deep-copied so a defect injected into a copy
    /// cannot touch the file on disk.
    Map<String, Object?> shipped() =>
        jsonDecode(
              jsonEncode(
                Sprint117GaArtifactGate.readManifest(
                  'docs/planning/v1.2/'
                  'sprint_113_build_reproducibility_provenance.json',
                ),
              ),
            )
            as Map<String, Object?>;

    Map<String, Object?> evidenceOf(Map<String, Object?> m) =>
        m['required_evidence']! as Map<String, Object?>;

    List<Map<String, Object?>> rebuildsOf(Map<String, Object?> m) =>
        (evidenceOf(m)['rebuild_results']! as List<dynamic>)
            .cast<Map<String, Object?>>();

    /// A THIRD record derived from the shipped first record, so that the only
    /// thing distinguishing it from an honest one is the defect under test.
    /// The command, the log, and every untouched digest are inherited, which
    /// is what keeps these findings about the record being ignored rather
    /// than about the shape of the manifest.
    Map<String, Object?> extraRecord({
      String label = 'rebuild_c',
      Object? exitCode = 0,
      String hour = '06',
    }) {
      final inherited = rebuildsOf(shipped()).first;
      return <String, Object?>{
        ...inherited,
        'label': label,
        'exit_code': exitCode,
        'started_at': '2026-09-23T$hour:00:00+07:00',
        'finished_at': '2026-09-23T$hour:30:00+07:00',
        'duration_seconds': 1800,
        'artifact_hashes': <String, Object?>{
          ...(inherited['artifact_hashes']! as Map<String, Object?>),
          'void_scriptor.exe': digest('d'),
        },
      };
    }

    Map<String, Object?> withExtras(List<Map<String, Object?>> extras) {
      final m = shipped();
      final records = <Map<String, Object?>>[...rebuildsOf(m), ...extras];
      evidenceOf(m)['rebuild_results'] = records;
      // 117.43-16 measures `rebuild_run.cycles` against the record count, so
      // a fixture that appends records while leaving the group's own count
      // stale would be refused for THAT reason instead of the defect under
      // test, and the count assertion would no longer prove anything. Keeping
      // the document self-consistent preserves every caller's intent: eight
      // of these manifests inject a defect, one measures the count.
      (m['rebuild_run']! as Map<String, Object?>)['cycles'] = records.length;
      return m;
    }

    /// The rebuild count the gate REPORTS, read out of its own output rather
    /// than inferred from what was sent in.
    String reportedRebuildCount(Sprint117GaArtifactCheck check) {
      final match = RegExp(
        r'rebuild_results: (\d+) item',
      ).firstMatch(check.observed);
      return match?.group(1) ?? 'ABSENT';
    }

    test('117.43-14 a third rebuild that exited non-zero is refused', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[
          extraRecord(exitCode: 1, hour: '14'),
        ]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a recorded rebuild that reports a non-zero exit code is not a '
            'rebuild, and the domain already refuses such a record — but the '
            'gate never decoded this one, so the verdict was pass',
      );
    });

    test('117.43-14 a third rebuild with a fabricated digest is refused', () {
      final extra = extraRecord(hour: '15');
      (extra['artifact_hashes']! as Map<String, Object?>)['void_scriptor.exe'] =
          'NOT-A-DIGEST';
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[extra]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a digest no rebuild could have produced must fail closed, the '
            'same rule 117.43-13 applies to the first two records',
      );
    });

    test('117.43-14 a third rebuild whose window runs backwards is refused', () {
      final extra = extraRecord(hour: '16')
        ..['started_at'] = '2026-09-23T16:30:00+07:00'
        ..['finished_at'] = '2026-09-23T16:00:00+07:00'
        ..['duration_seconds'] = -1800;
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[extra]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            '117.43-09 refuses a window that ends before it starts; that rule '
            'must reach every recorded rebuild, not only the first two',
      );
    });

    test('117.43-14 a third rebuild whose command admits no clean step is '
        'refused', () {
      final extra = extraRecord(hour: '17')
        ..['command'] = 'flutter build windows --release';
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[extra]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            '117.43-10 requires a recorded command to contain a clean step; '
            'the rule must reach every recorded rebuild',
      );
    });

    test('117.43-14 a third rebuild citing an unreadable log is refused', () {
      final extra = extraRecord(hour: '18')
        ..['log'] = 'docs/evidence/no-such-rebuild.log';
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[extra]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            '117.43-13 refuses a record whose log names a document nobody can '
            'open; the rule must reach every recorded rebuild',
      );
    });

    test('117.43-14 two rebuilds sharing one label are refused', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[
          extraRecord(label: 'rebuild_a', hour: '19'),
        ]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'a label is how a reader tells one rebuild from another; two '
            'records under one label make the document ambiguous about how '
            'many rebuilds were actually compared',
      );
    });

    test('117.43-14 a rebuild hashing an artifact the comparison never names '
        'is refused', () {
      final extra = extraRecord(hour: '20')
        ..['artifact_hashes'] = <String, Object?>{
          ...extraRecord()['artifact_hashes']! as Map<String, Object?>,
          'ghost.dll': digest('f'),
        };
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[extra]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'the partition in artifact_comparison must account for the whole '
            'recorded inventory; an artifact outside it is an unaccounted '
            'digest, and the inventory now spans every recorded rebuild',
      );
    });

    test('117.43-14 a rebuild overlapping another is refused', () {
      // rebuild_a runs 13:27:45 -> 13:29:47, so a record claiming to start
      // inside that window is a second build contending for one `build/`
      // directory. The rule 117.43-09 applies to the first two records has
      // to apply to this one too.
      final extra = extraRecord(hour: '13')
        ..['started_at'] = '2026-09-23T13:28:00+07:00'
        ..['finished_at'] = '2026-09-23T13:29:00+07:00'
        ..['duration_seconds'] = 60;
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[extra]),
      );

      expect(
        check.status,
        Sprint117GaArtifactStatus.unmet,
        reason:
            'overlapping clean rebuilds share one build directory, so their '
            'digests cannot support an independence claim',
      );
    });

    test('117.43-14 the reported rebuild count is the document count', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: withExtras(<Map<String, Object?>>[
          extraRecord(hour: '14'),
          extraRecord(label: 'rebuild_d', hour: '16'),
        ]),
      );

      expect(
        reportedRebuildCount(check),
        '4',
        reason:
            'the count the gate reports must be the count the document '
            'records, not the count of the first two records the gate chose '
            'to read',
      );
    });

    test('117.43-14 the shipped manifest still passes and reports two', () {
      final check = Sprint117GaArtifactGate.measureProvenance(
        provenanceManifest: shipped(),
      );

      expect(check.status, Sprint117GaArtifactStatus.pass);
      expect(reportedRebuildCount(check), '2');
      expect(check.observed, contains('NOT_BIT_IDENTICAL'));
    });

    test('117.43-14 every one of these passed before this slice', () {
      // The historical record, kept as an executable assertion. Pre-fix the
      // gate decoded only records 0 and 1, so all seven manifests below —
      // each carrying one extra record with one injected defect — returned
      // `pass`, and each reported `rebuild_results: 2 item` while its own
      // document recorded three. The rules existed; they were simply never
      // pointed at the third record.
      final passed = <String>[];
      void record(String seam, Map<String, Object?> manifest) {
        final status = Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest,
        ).status.name;
        if (status == 'pass') passed.add(seam);
      }

      record(
        'exit_code=1',
        withExtras(<Map<String, Object?>>[
          extraRecord(exitCode: 1, hour: '14'),
        ]),
      );
      final fabricated = extraRecord(hour: '15');
      (fabricated['artifact_hashes']!
              as Map<String, Object?>)['void_scriptor.exe'] =
          'NOT-A-DIGEST';
      record(
        'digest=fabricated',
        withExtras(<Map<String, Object?>>[fabricated]),
      );
      record(
        'window=reversed',
        withExtras(<Map<String, Object?>>[
          (extraRecord(hour: '16')
            ..['started_at'] = '2026-09-23T16:30:00+07:00'
            ..['finished_at'] = '2026-09-23T16:00:00+07:00'
            ..['duration_seconds'] = -1800),
        ]),
      );
      record(
        'command=no-clean-step',
        withExtras(<Map<String, Object?>>[
          (extraRecord(hour: '17')
            ..['command'] = 'flutter build windows --release'),
        ]),
      );
      record(
        'log=unreadable',
        withExtras(<Map<String, Object?>>[
          (extraRecord(hour: '18')
            ..['log'] = 'docs/evidence/no-such-rebuild.log'),
        ]),
      );
      record(
        'label=duplicate',
        withExtras(<Map<String, Object?>>[
          extraRecord(label: 'rebuild_a', hour: '19'),
        ]),
      );
      record(
        'artifact=unnamed',
        withExtras(<Map<String, Object?>>[
          (extraRecord(hour: '20')
            ..['artifact_hashes'] = <String, Object?>{
              ...extraRecord()['artifact_hashes']! as Map<String, Object?>,
              'ghost.dll': digest('f'),
            }),
        ]),
      );
      record(
        'window=overlapping',
        withExtras(<Map<String, Object?>>[
          (extraRecord(hour: '13')
            ..['started_at'] = '2026-09-23T13:28:00+07:00'
            ..['finished_at'] = '2026-09-23T13:29:00+07:00'
            ..['duration_seconds'] = 60),
        ]),
      );

      expect(
        passed,
        isEmpty,
        reason:
            'pre-fix all seven defects were carried by a record the gate '
            'never decoded, and each reported a rebuild count of 2 while its '
            'document recorded 3',
      );
    });
  });

  // RED-first for defect 117.43-15: the tenth slice in the same hunt, and the
  // first one about a group that WAS read rather than one that was ignored.
  //
  // `provenance_record` passes `_hasContent` — every line is a non-blank
  // string — and the gate then prints `provenance_record: 6 item` as though
  // six lines had been checked against anything. No reader anywhere compares
  // a line of that group with the `rebuild_results` it restates. The shipped
  // document uses a precise grammar for those lines —
  //
  //   rebuild_LABEL exit_code N duration_seconds N (START .. FINISH)
  //
  // — which names a rebuild, an exit code, a duration, and both ends of a
  // window. Three of those four facts are already measured elsewhere (the exit
  // code by `isWellFormed`, the duration by `_durationAgrees`, the window by
  // `hasWellFormedWindow` and both independence helpers), and the group that
  // restates them was never held to agree with the records it restates. A
  // document whose summary contradicts its own measurements is the one
  // document a reproducibility gate cannot accept.
  //
  // Proven against HEAD before the fix, on the SHIPPED manifest: five
  // contradictions, each returning `pass` — an exit code of 1 where the record
  // says 0, a duration of 900 where the record says 115, a window moved to a
  // different day, a `rebuild_z` no rebuild record mentions, and a log no
  // rebuild record cites. A sixth idea — that `source_revision` names a commit
  // that does not exist — was dropped rather than claimed, because a fabricated
  // revision is shape-identical to a real one and this layer spawns no git.
  group('117.43-15 provenance_record must agree with what it restates', () {
    String digest(String seed) => seed * 64;

    /// The SHIPPED manifest, deep-copied so a defect injected into a copy
    /// cannot touch the file on disk.
    Map<String, Object?> shipped() =>
        jsonDecode(
              jsonEncode(
                Sprint117GaArtifactGate.readManifest(_kProvenanceManifest),
              ),
            )
            as Map<String, Object?>;

    Map<String, Object?> evidenceOf(Map<String, Object?> m) =>
        m['required_evidence']! as Map<String, Object?>;

    List<Map<String, Object?>> rebuildsOf(Map<String, Object?> m) =>
        (evidenceOf(m)['rebuild_results']! as List<dynamic>)
            .cast<Map<String, Object?>>();

    /// The shipped manifest with `provenance_record` rewritten by [rewrite].
    Map<String, Object?> withRecord(
      List<String> Function(List<String> lines) rewrite,
    ) {
      final m = shipped();
      final lines = (evidenceOf(m)['provenance_record']! as List<dynamic>)
          .cast<String>();
      evidenceOf(m)['provenance_record'] = rewrite(lines);
      return m;
    }

    /// Replaces the one shipped summary line that names [label].
    Map<String, Object?> withSummaryFor(
      String label, {
      String? exitCode,
      String? duration,
      String? window,
    }) => withRecord(
      (lines) => [
        for (final line in lines)
          if (line.startsWith('$label exit_code'))
            '$label exit_code ${exitCode ?? '0'} '
                'duration_seconds ${duration ?? '122'} '
                '(${(window ?? '2026-09-23T13:27:45+07:00 .. 2026-09-23T13:29:47+07:00')})'
          else
            line,
      ],
    );

    String statusOf(Map<String, Object?> manifest) =>
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest,
        ).status.name;

    test('117.43-15 the shipped manifest states summary lines this group can '
        'read', () {
      // If the fixture did not use the grammar, every case below would be
      // proving nothing: a reader that silently ignored prose would pass them.
      final lines =
          (evidenceOf(shipped())['provenance_record']! as List<dynamic>)
              .cast<String>();
      final summaries = lines
          .where((line) => line.contains(' exit_code '))
          .toList();
      expect(summaries, hasLength(2));
      expect(
        summaries.first,
        matches(
          RegExp(
            r'^rebuild_\S+ exit_code -?\d+ duration_seconds -?\d+ '
            r'\(.+ \.\. .+\)$',
          ),
        ),
      );
      // The labels those two lines name must be the labels the records carry,
      // or the comparisons below would be matching nothing.
      final labels = rebuildsOf(
        shipped(),
      ).map((rebuild) => rebuild['label']! as String).toSet();
      expect(labels, hasLength(2));
      for (final summary in summaries) {
        expect(labels, contains(summary.split(' ').first));
      }
      expect(statusOf(shipped()), 'pass');
    });

    test(
      '117.43-15 a summary line claiming a non-zero exit code is refused',
      () {
        expect(
          statusOf(withSummaryFor('rebuild_a', exitCode: '1')),
          'unmet',
          reason:
              'the rebuild record this line restates states exit_code 0, and a '
              'summary that disagrees with the measurement it summarises is not '
              'evidence — the exit code has been measured since 117.43-01 and '
              'the group stating it was never compared',
        );
      },
    );

    test('117.43-15 a summary line claiming a wrong duration is refused', () {
      expect(
        statusOf(withSummaryFor('rebuild_b', duration: '900')),
        'unmet',
        reason:
            'the rebuild record states 115 seconds and its own window measures '
            '115; a summary claiming 900 contradicts both',
      );
    });

    test('117.43-15 a summary line stating a window the record does not have '
        'is refused', () {
      expect(
        statusOf(
          withSummaryFor(
            'rebuild_b',
            window: '2026-09-24T09:00:00+07:00 .. 2026-09-24T09:01:55+07:00',
          ),
        ),
        'unmet',
        reason:
            'the summary names a rebuild on a different day from the one the '
            'rebuild record states, which is the same self-contradiction '
            '117.43-09 measured inside a single record',
      );
    });

    test('117.43-15 a summary line naming a rebuild no record mentions is '
        'refused', () {
      expect(
        statusOf(
          withRecord(
            (lines) => [
              ...lines,
              'rebuild_z exit_code 0 duration_seconds 300 '
                  '(2026-09-25T10:00:00+07:00 .. 2026-09-25T10:05:00+07:00)',
            ],
          ),
        ),
        'unmet',
        reason:
            'a summary naming a rebuild the document does not record is the '
            'inverse of the omission 117.43-14 closed: the gate reported a '
            'count it had chosen, and this adds a count it never read',
      );
    });

    test(
      '117.43-15 a summary line naming a log no rebuild cites is refused',
      () {
        expect(
          statusOf(
            withRecord(
              (lines) => [
                for (final line in lines)
                  if (line.startsWith('provenance_logs'))
                    'provenance_logs docs/evidence/sprint-113-39-rebuild-a.log '
                        'docs/evidence/never-existed.log'
                  else
                    line,
              ],
            ),
          ),
          'unmet',
          reason:
              '117.43-10 and 117.43-14 made every rebuild log readable, so a '
              'summary naming a different set of logs is contradicted by the '
              'records it summarises',
        );
      },
    );

    test('117.43-15 a source revision is left unmeasured, and that is deliberate', () {
      // Recorded as an explicit non-decision rather than a rule, because
      // claiming it would be dishonest.
      //
      // `deadbeefdeadbeefdeadbeefdeadbeefdeadbeef` is 40 valid hex characters —
      // exactly the shape of the real `30dda0c3389a8bd9e3cae705abd51eaecbca2630`,
      // which `git cat-file -e` resolves. The only check that separates them is
      // asking git whether the object exists, and this domain layer spawns no
      // processes: it reads documents through `File(...).existsSync()` alone.
      // A git seam would make the verdict depend on a live checkout and its
      // history depth, so the claim is DEFERRED rather than met.
      //
      // A shape rule is not a substitute, and adding one was tried and
      // reverted: the shipped fixtures legitimately write `source_revision`
      // carrying a 64-hex placeholder, so a "must be 40 hex" rule refuses an
      // honest document. Inventing a criterion the evidence never stated is
      // the same overclaim this gate exists to catch, so no rule was kept.
      const real = '30dda0c3389a8bd9e3cae705abd51eaecbca2630';
      const fabricated = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef';
      for (final value in <String>[real, fabricated]) {
        expect(value.length, 40);
        expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(value), isTrue);
      }

      // Both are accepted, because the gate does not measure this line — and
      // saying so here is the honest record of the boundary.
      for (final value in <String>[real, fabricated, 'not-a-revision-at-all']) {
        expect(
          statusOf(
            withRecord(
              (lines) => [
                for (final line in lines)
                  if (line.startsWith('source_revision'))
                    'source_revision $value'
                  else
                    line,
              ],
            ),
          ),
          'pass',
          reason:
              'source_revision is not a restatement of a rebuild measurement, '
              'so no rule reads it; asserting otherwise here would overclaim '
              'what this slice verified',
        );
      }
    });

    test('117.43-15 every one of these passed before this slice', () {
      // The necessity witness for the whole group: run each case through the
      // gate that is live at HEAD and record what it reported.
      final cases = <String, Map<String, Object?>>{
        'exit_code': withSummaryFor('rebuild_a', exitCode: '1'),
        'duration': withSummaryFor('rebuild_b', duration: '900'),
        'window': withSummaryFor(
          'rebuild_b',
          window: '2026-09-24T09:00:00+07:00 .. 2026-09-24T09:01:55+07:00',
        ),
        'unknown_rebuild': withRecord(
          (lines) => [
            ...lines,
            'rebuild_z exit_code 0 duration_seconds 300 '
                '(2026-09-25T10:00:00+07:00 .. 2026-09-25T10:05:00+07:00)',
          ],
        ),
        'unknown_log': withRecord(
          (lines) => [
            for (final line in lines)
              if (line.startsWith('provenance_logs'))
                'provenance_logs docs/evidence/sprint-113-39-rebuild-a.log '
                    'docs/evidence/never-existed.log'
              else
                line,
          ],
        ),
      };

      final passed = <String>[];
      for (final entry in cases.entries) {
        if (statusOf(entry.value) == 'pass') passed.add(entry.key);
      }

      expect(
        passed,
        isEmpty,
        reason:
            'pre-fix provenance_record was checked only for being non-blank, '
            'so all five contradictions between the summary and the records it '
            'restates returned pass while the gate printed '
            '"provenance_record: 6 item"',
      );
    });

    test(
      '117.43-15 a prose line that merely mentions a rebuild stays honest',
      () {
        // The counter-case that keeps the rule from refusing honest work: the
        // shipped group also states `rebuild_run` prose and free text that names
        // rebuilds without restating their measurements, and 117.43-07 settled
        // that a non-claim is not a defect.
        expect(
          statusOf(
            withRecord(
              (lines) => [
                ...lines,
                'rebuild_a rebuilt cleanly after the signed snapshot restore',
                'rebuild_q note kept for later',
              ],
            ),
          ),
          'pass',
          reason:
              'a line that names a rebuild without stating an exit code, a '
              'duration, or a window makes no claim to contradict, the same '
              'non-claim rule 117.43-07 established for the comparison verdict',
        );
      },
    );

    test('117.43-15 the build_command line is not a restatement and is not '
        'compared', () {
      // The shipped `build_command` names `flutter build windows --release`
      // WITHOUT the `flutter clean &&` prefix its rebuild records carry, and
      // that difference is correct: the build command is what the release
      // pipeline runs, not what one rebuild cycle ran. Comparing it against
      // the rebuild commands would refuse the honest document, so this case
      // pins the boundary the rule stops at.
      final command =
          (evidenceOf(shipped())['provenance_record']! as List<dynamic>)
              .cast<String>()
              .firstWhere((line) => line.startsWith('build_command'));
      expect(command, isNot(contains('flutter clean')));

      expect(
        statusOf(
          withRecord(
            (lines) => [
              for (final line in lines)
                if (line.startsWith('build_command'))
                  'build_command flutter build windows --debug'
                else
                  line,
            ],
          ),
        ),
        'pass',
        reason:
            'build_command states what the release pipeline runs, not what a '
            'rebuild cycle ran, so it is not one of the restatements the rule '
            'compares; 117.43-10 measures the clean step where it is actually '
            'claimed — on the rebuild record that carries it',
      );
    });

    test('117.43-15 digest-only lines are not summary lines', () {
      // Pins that `signed_candidate ... sha256 verified intact` — which
      // contains no ` exit_code ` and therefore no summary — is left alone,
      // and keeps `digest` referenced so the helper above stays honest.
      final lines =
          (evidenceOf(shipped())['provenance_record']! as List<dynamic>)
              .cast<String>();
      expect(lines.where((line) => line.contains(' exit_code ')), hasLength(2));
      expect(digest('a'), hasLength(64));
    });
  });

  group('117.43-16 rebuild_run must agree with what it restates', () {
    // Defect 117.43-16: the document-level `rebuild_run` group restates facts
    // this gate already measures on the records themselves — how many cycles
    // ran, and how long each one took — and no reader in `lib/` has ever
    // decoded it. The gate publishes `provenance_evaluation: pass` for a
    // document whose own summary claims 900 seconds where its record claims
    // 122, or three cycles where two rebuilds are recorded. 117.43-15 fixed
    // the same restatement inside `provenance_record`; this is the second
    // copy of it, one level up, in a group that never reaches the domain at
    // all. Every number compared here is already measured from
    // `rebuild_results`, so refusing a contradiction invents no acceptance.
    Map<String, Object?> shipped() =>
        jsonDecode(
              jsonEncode(
                Sprint117GaArtifactGate.readManifest(_kProvenanceManifest),
              ),
            )
            as Map<String, Object?>;

    List<Map<String, Object?>> recordsOf(Map<String, Object?> manifest) =>
        ((manifest['required_evidence']!
                    as Map<String, Object?>)['rebuild_results']!
                as List<dynamic>)
            .cast<Map<String, Object?>>();

    Map<String, Object?> runOf(Map<String, Object?> manifest) =>
        manifest['rebuild_run']! as Map<String, Object?>;

    String statusOf(Map<String, Object?> manifest) =>
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest,
        ).status.name;

    /// Shipped manifest with [patch] merged into its `rebuild_run` group.
    Map<String, Object?> withRunPatch(Map<String, Object?> patch) {
      final manifest = shipped();
      manifest['rebuild_run'] = <String, Object?>{...runOf(manifest), ...patch};
      return manifest;
    }

    /// Shipped manifest whose `rebuild_run` group holds [value] verbatim.
    Map<String, Object?> withRunAs(Object? value) {
      final manifest = shipped();
      manifest['rebuild_run'] = value;
      return manifest;
    }

    /// Shipped manifest with no `rebuild_run` group at all.
    Map<String, Object?> withoutRun() {
      final manifest = shipped();
      manifest.remove('rebuild_run');
      return manifest;
    }

    test('117.43-16 the shipped manifest states a rebuild_run group this gate '
        'can read', () {
      // If the fixture did not restate measured numbers, every case below
      // would prove nothing: a reader that ignored the group would pass them.
      final manifest = shipped();
      final run = runOf(manifest);
      final records = recordsOf(manifest);
      expect(records, hasLength(2));
      expect(run['cycles'], records.length);
      for (final record in records) {
        final label = record['label']! as String;
        expect(
          run['${label}_duration_seconds'],
          record['duration_seconds'],
          reason: '$label restates a duration its own record states',
        );
        final start = DateTime.parse(record['started_at']! as String);
        final finish = DateTime.parse(record['finished_at']! as String);
        expect(
          run['${label}_duration_seconds'],
          finish.difference(start).inSeconds,
          reason: 'the restated number is a duration this gate measures',
        );
      }
      // The prose members describe how the run was carried out and state no
      // number this grammar can compare (pinned below).
      expect(run['method'], isA<String>());
      expect(run['signed_snapshot_restore'], isA<String>());
      expect(statusOf(manifest), 'pass');
    });

    test('117.43-16 every one of these passed before this slice', () {
      final cases = <String, String>{
        'three cycles for two recorded rebuilds': statusOf(
          withRunPatch({'cycles': 3}),
        ),
        'zero cycles for two recorded rebuilds': statusOf(
          withRunPatch({'cycles': 0}),
        ),
        'a cycle count that cannot be read': statusOf(
          withRunPatch({'cycles': 'two'}),
        ),
        'rebuild_a restated as 900 seconds': statusOf(
          withRunPatch({'rebuild_a_duration_seconds': 900}),
        ),
        'rebuild_b restated as 1 second': statusOf(
          withRunPatch({'rebuild_b_duration_seconds': 1}),
        ),
        'a duration naming a rebuild no record mentions': statusOf(
          withRunPatch({'rebuild_z_duration_seconds': 300}),
        ),
        'a group recorded in a shape that cannot be read': statusOf(
          withRunAs('2 cycles, both cold'),
        ),
      };
      expect(
        cases.values,
        isNot(contains('pass')),
        reason:
            'every case states a fact about the same run that the records '
            'state differently, and all ${cases.length} returned pass: '
            '${cases.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    });

    test('117.43-16 restatements that agree with the records are still '
        'accepted', () {
      expect(statusOf(shipped()), 'pass');
      expect(statusOf(withRunPatch({'cycles': 2})), 'pass');
      expect(
        statusOf(withRunPatch({'rebuild_a_duration_seconds': 122})),
        'pass',
      );
      expect(
        statusOf(withRunPatch({'rebuild_b_duration_seconds': 115})),
        'pass',
      );
    });

    test('117.43-16 a manifest that states no rebuild_run claims nothing', () {
      expect(
        statusOf(withoutRun()),
        'pass',
        reason:
            'the group restates the records, it is not a required section: a '
            'document without it contradicts nothing (117.43-07 absence stays '
            'non-claim)',
      );
    });

    test('117.43-16 prose members and vocabulary this grammar does not define '
        'make no claim', () {
      expect(
        statusOf(withRunPatch({'method': 'cold rebuilds, cache dropped'})),
        'pass',
        reason:
            'the clean step is measured where it is claimed, on the record '
            '(117.43-10), not re-parsed out of prose one level up',
      );
      expect(
        statusOf(
          withRunPatch({
            'signed_snapshot_restore': 'restored afterwards; exe re-verified',
          }),
        ),
        'pass',
        reason: 'prose about the surrounding procedure states no number',
      );
      expect(
        statusOf(withRunPatch({'cold_rebuilds': 7})),
        'pass',
        reason:
            "a key this group's shipped vocabulary does not use defines no "
            'claim; refusing it would invent grammar',
      );
      expect(statusOf(withRunPatch({'cycles': null})), 'pass');
      expect(
        statusOf(withRunPatch({'rebuild_a_duration_seconds': null})),
        'pass',
        reason: 'an explicit null states nothing, exactly like an absent key',
      );
      final dropped = shipped();
      runOf(dropped).remove('rebuild_b_duration_seconds');
      expect(
        statusOf(dropped),
        'pass',
        reason: 'omitting one restatement states nothing to contradict',
      );
    });

    test('117.43-16 a restated duration that cannot be read is refused', () {
      expect(
        statusOf(withRunPatch({'rebuild_a_duration_seconds': '122 seconds'})),
        isNot('pass'),
        reason:
            'a present value in a shape this gate cannot read is unevaluable, '
            'not silently skipped (117.43-13)',
      );
    });
  });

  group('117.43-17 the header must agree with the verdict it declares', () {
    // Defect 117.43-17: the twelfth slice in the hunt, and the last level
    // above the body — the document header. `status: VERIFIED-LOCAL` and
    // `decision: VERIFIED_LOCAL_PROVENANCE_DOCUMENTED_REPRO_LIMITS` state
    // the very conclusion this check publishes (`provenance_evaluation:
    // pass`), and no reader in `lib/` opened either field: the shipped
    // `BuildProvenanceEvidence` seam is a typed model built from
    // `required_evidence` alone, and this gate read `required_evidence`,
    // `rebuild_run` and `comparison`. So the gate published a verification
    // pass over a document whose own header refused it, or held a value in
    // a shape nobody could read. Every refusal below compares the header to
    // an evaluation this gate already performs, so no acceptance is
    // invented; the vocabulary (`VERIFIED-LOCAL`, the `VERIFIED_LOCAL`
    // decision prefix) is the shipped document's own, asserted by
    // sprint_113's test for this exact manifest.
    Map<String, Object?> shipped() =>
        jsonDecode(
              jsonEncode(
                Sprint117GaArtifactGate.readManifest(_kProvenanceManifest),
              ),
            )
            as Map<String, Object?>;

    String outcome(Map<String, Object?> manifest) =>
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest,
        ).status.name;

    /// Shipped manifest whose header field [key] holds [value] verbatim.
    Map<String, Object?> withHeader(String key, Object? value) =>
        shipped()..[key] = value;

    /// Shipped manifest with its header field [key] removed.
    Map<String, Object?> withoutHeader(String key) => shipped()..remove(key);

    test('117.43-17 a header that does not declare local verification is '
        'refused while the evidence passes', () {
      final cases = <String, String>{
        "status stating 'UNVERIFIED'": outcome(
          withHeader('status', 'UNVERIFIED'),
        ),
        "status stating 'REVIEW'": outcome(withHeader('status', 'REVIEW')),
        "decision stating 'DRAFT_PROVENANCE'": outcome(
          withHeader('decision', 'DRAFT_PROVENANCE'),
        ),
      };
      expect(
        cases.values,
        isNot(contains('pass')),
        reason:
            'the gate publishes provenance_evaluation: pass for a document '
            'whose own header refuses that verdict: '
            '${cases.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    });

    test('117.43-17 a header value this gate cannot read is unevaluable, not '
        'silently skipped', () {
      final cases = <String, String>{
        'status as an integer': outcome(withHeader('status', 42)),
        'status as a blank string': outcome(withHeader('status', '   ')),
        'status as an object': outcome(
          withHeader('status', <String, Object?>{'verdict': 'VERIFIED-LOCAL'}),
        ),
        'decision as an integer': outcome(withHeader('decision', 7)),
        'decision as a blank string': outcome(withHeader('decision', '')),
      };
      expect(
        cases.values,
        isNot(contains('pass')),
        reason:
            'a present header value in a shape nobody decoded is not a '
            'silent agreement (117.43-13): '
            '${cases.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    });

    test('117.43-17 the shipped header declares exactly the verdict this gate '
        'publishes', () {
      // Without a shipped header stating the verdict, every refusal above
      // would prove nothing: a gate that ignored the header would pass
      // them all.
      final manifest = shipped();
      expect(manifest['status'], 'VERIFIED-LOCAL');
      final decision = manifest['decision'];
      expect(decision, isA<String>());
      expect(
        (decision! as String).startsWith('VERIFIED_LOCAL'),
        isTrue,
        reason:
            'the decision token leads with the local-verification '
            'segment this gate matches',
      );
      expect(outcome(manifest), 'pass');
    });

    test('117.43-17 a header that states nothing claims nothing, and a '
        'declared verdict cannot rescue failing evidence', () {
      expect(
        outcome(withoutHeader('status')),
        'pass',
        reason: 'an absent field is a non-claim (117.43-07)',
      );
      expect(
        outcome(withHeader('status', null)),
        'pass',
        reason: 'an explicit null states nothing, like an absent key',
      );
      expect(outcome(withoutHeader('decision')), 'pass');
      expect(outcome(withHeader('decision', null)), 'pass');
      // The shipped header already claims VERIFIED-LOCAL: breaking the
      // evidence under it must still refuse, so the header can never buy
      // back a pass the measurement does not support.
      final broken = shipped();
      (broken['required_evidence']! as Map<String, Object?>).remove(
        'provenance_record',
      );
      expect(outcome(broken), isNot('pass'));
    });
  });

  group('117.43-18 the document must be able to state its own limits', () {
    // Defect 117.43-18: the thirteenth slice in the hunt, and the last level
    // above the header — the document-level `limits` group. The shipped
    // manifest states three limits of its own, and its `decision` token names
    // them (`VERIFIED_LOCAL_PROVENANCE_DOCUMENTED_REPRO_LIMITS`), yet the only
    // limits this gate ever decoded was the NESTED
    // `artifact_comparison.limits`. So the group the document's own verdict
    // rests on was never opened by anything: a `limits` value in a shape
    // nobody could read was silently skipped while the gate published
    // `provenance_evaluation: pass`, and the `limit: ...` notes it printed came
    // from a different list than the one the header claims.
    //
    // The bounds are the same shape as 117.43-16/-17, so no acceptance is
    // invented: a document-level `limits` is REFUSED only when it is present
    // and cannot be read as a list of non-blank strings. An absent key and an
    // explicit null stay non-claims (117.43-07). No requirement is added about
    // what the limits say, how many there are, or how they relate to the
    // nested comparison limits — that vocabulary belongs to the document.
    Map<String, Object?> shipped() =>
        jsonDecode(
              jsonEncode(
                Sprint117GaArtifactGate.readManifest(_kProvenanceManifest),
              ),
            )
            as Map<String, Object?>;

    String outcome(Map<String, Object?> manifest) =>
        Sprint117GaArtifactGate.measureProvenance(
          provenanceManifest: manifest,
        ).status.name;

    /// Shipped manifest whose document-level `limits` holds [value] verbatim.
    Map<String, Object?> withLimits(Object? value) =>
        shipped()..['limits'] = value;

    test('117.43-18 a document-level limits group this gate cannot read is '
        'refused while the evidence passes', () {
      final cases = <String, String>{
        'limits as an integer': outcome(withLimits(42)),
        'limits as a bare string': outcome(withLimits('no bit-identity')),
        'limits as an object': outcome(
          withLimits(<String, Object?>{'limit': 'no bit-identity'}),
        ),
        'limits holding an integer': outcome(withLimits(<Object?>[42])),
        'limits holding an object': outcome(
          withLimits(<Object?>[
            <String, Object?>{'limit': 'no bit-identity'},
          ]),
        ),
        'limits holding a blank entry': outcome(withLimits(<Object?>[''])),
        'limits holding a whitespace-only entry': outcome(
          withLimits(<Object?>['   ']),
        ),
      };
      expect(
        cases.values,
        isNot(contains('pass')),
        reason:
            'the gate publishes provenance_evaluation: pass for a document '
            'whose own limits group is in a shape nobody decoded, while the '
            'notes it prints come from the nested comparison limits: '
            '${cases.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      );
    });

    test('117.43-18 the shipped document states limits this gate reads', () {
      // Without a shipped document-level `limits` group, every refusal above
      // would prove nothing: a gate that ignored the group would pass them
      // all.
      final manifest = shipped();
      final limits = manifest['limits'];
      expect(
        limits,
        isA<List<dynamic>>(),
        reason: 'the shipped group is a list',
      );
      final items = (limits! as List<dynamic>).cast<Object?>();
      expect(items, isNotEmpty, reason: 'the shipped group states limits');
      expect(
        items.every((item) => item is String && item.trim().isNotEmpty),
        isTrue,
        reason:
            'every shipped limit is a non-blank string, the shape the gate now '
            'decodes',
      );
      expect(outcome(manifest), 'pass');
    });

    test('117.43-18 a document that states no limits claims nothing, and a '
        'readable limits group cannot rescue failing evidence', () {
      final absent = shipped()..remove('limits');
      expect(
        outcome(absent),
        'pass',
        reason: 'an absent group is a non-claim (117.43-07)',
      );
      expect(
        outcome(withLimits(null)),
        'pass',
        reason: 'an explicit null states nothing, like an absent key',
      );
      // The shipped document already states readable limits: breaking the
      // evidence under them must still refuse, so the group can never buy back
      // a pass the measurement does not support.
      final broken = shipped();
      (broken['required_evidence']! as Map<String, Object?>).remove(
        'provenance_record',
      );
      expect(outcome(broken), isNot('pass'));
    });
  });
}
