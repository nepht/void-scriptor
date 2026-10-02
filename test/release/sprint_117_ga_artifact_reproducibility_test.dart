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
}
