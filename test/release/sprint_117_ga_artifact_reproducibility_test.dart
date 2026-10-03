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
      if (drifting.isNotEmpty) {
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
}
