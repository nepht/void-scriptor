import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/build_reproducibility_provenance.dart';

RebuildResult _rebuild(
  String label,
  Map<String, String> hashes, {
  int exitCode = 0,
}) {
  return RebuildResult(
    label: label,
    artifactHashes: hashes,
    exitCode: exitCode,
    startedAt: '2026-09-23T13:30:00+07:00',
    finishedAt: '2026-09-23T13:34:00+07:00',
  );
}

void main() {
  // 113.39 asserts facts about the locally-built, locally-signed Windows
  // candidate (build/windows/x64/runner/Release/void_scriptor.exe). That
  // artifact is produced by the release-train Windows job and is gitignored
  // (/build/), so the assertion can only run on the machine that produced it.
  // Skipping when it is absent keeps the check honest — it still runs where
  // the artifact exists — instead of failing every ubuntu-latest CI run.
  final signedArtifactPresent = File(
    'build/windows/x64/runner/Release/void_scriptor.exe',
  ).existsSync();
  test('113.39 declares the six canonical provenance evidence groups', () {
    expect(kBuildProvenanceRequiredEvidence, <String>[
      'build_inputs',
      'toolchain_versions',
      'dependency_lock',
      'rebuild_results',
      'artifact_comparison',
      'provenance_record',
    ]);
    expect(
      BuildProvenanceEvidence.missingEvidence(const BuildProvenanceEvidence()),
      unorderedEquals(kBuildProvenanceRequiredEvidence),
    );
    expect(
      BuildProvenanceEvidence.evaluate(null).state,
      BuildProvenanceState.blocked,
    );
    expect(
      BuildProvenanceEvidence.evaluate(const BuildProvenanceEvidence()).state,
      BuildProvenanceState.blocked,
    );
    expect(
      BuildProvenanceEvidence.evaluate(
        const BuildProvenanceEvidence(),
      ).notes.join(' '),
      contains('no build provenance recorded'),
    );
  });

  test('113.39 malformed rebuilds and comparisons are reported missing', () {
    final a = 'a' * 64;
    final b = 'b' * 64;
    final badExit = BuildProvenanceEvidence(
      buildInputs: <String>['pubspec.yaml sha256 $a'],
      toolchainVersions: <String>['Flutter 3.x'],
      dependencyLock: <String>['pubspec.lock sha256 $a'],
      rebuildResults: <RebuildResult>[
        _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
        _rebuild('rebuild_b', <String, String>{
          'void_scriptor.exe': b,
        }, exitCode: 1),
      ],
      artifactComparison: ArtifactComparison(
        method: 'sha256',
        rebuildA: _rebuild('rebuild_a', <String, String>{
          'void_scriptor.exe': a,
        }),
        rebuildB: _rebuild('rebuild_b', <String, String>{
          'void_scriptor.exe': b,
        }),
        // Sprint 117.43-01: this fixture used to record `bitIdentical` while
        // recording two DIFFERENT digests. That is a false identity claim,
        // which the seam now refuses, so the fixture hid a fail-open verdict.
        // Different digests are honestly `notBitIdentical` with a documented
        // limit, which is what this fixture now records; the non-zero exit
        // code on rebuild_b stays the defect this case is actually about.
        verdict: RebuildVerdict.notBitIdentical,
        limits: <String>['fixture: digests deliberately differ'],
      ),
      provenanceRecord: <String>['source_revision $a'],
    );
    expect(
      BuildProvenanceEvidence.missingEvidence(badExit),
      unorderedEquals(<String>['rebuild_results']),
    );

    // The regression that shipped the false identity claim: a comparison
    // asserting bitIdentical while its two rebuilds record different digests
    // must be reported as missing evidence, not accepted.
    final falseIdentity = BuildProvenanceEvidence(
      buildInputs: <String>['pubspec.yaml sha256 $a'],
      toolchainVersions: <String>['Flutter 3.x'],
      dependencyLock: <String>['pubspec.lock sha256 $a'],
      rebuildResults: <RebuildResult>[
        _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
        _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': b}),
      ],
      artifactComparison: ArtifactComparison(
        method: 'sha256',
        rebuildA: _rebuild('rebuild_a', <String, String>{
          'void_scriptor.exe': a,
        }),
        rebuildB: _rebuild('rebuild_b', <String, String>{
          'void_scriptor.exe': b,
        }),
        verdict: RebuildVerdict.bitIdentical,
        limits: <String>[],
      ),
      provenanceRecord: <String>['source_revision $a'],
    );
    expect(
      BuildProvenanceEvidence.missingEvidence(falseIdentity),
      contains('artifact_comparison'),
    );

    final diffNoLimits = BuildProvenanceEvidence(
      buildInputs: <String>['pubspec.yaml sha256 $a'],
      toolchainVersions: <String>['Flutter 3.x'],
      dependencyLock: <String>['pubspec.lock sha256 $a'],
      rebuildResults: <RebuildResult>[
        _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
        _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': b}),
      ],
      artifactComparison: ArtifactComparison(
        method: 'sha256',
        rebuildA: _rebuild('rebuild_a', <String, String>{
          'void_scriptor.exe': a,
        }),
        rebuildB: _rebuild('rebuild_b', <String, String>{
          'void_scriptor.exe': b,
        }),
        verdict: RebuildVerdict.notBitIdentical,
        limits: <String>[],
      ),
      provenanceRecord: <String>['source_revision $a'],
    );
    expect(
      BuildProvenanceEvidence.missingEvidence(diffNoLimits),
      unorderedEquals(<String>['artifact_comparison']),
      reason: 'NOT_BIT_IDENTICAL without documented limits is incomplete',
    );
  });

  test('113.39 complete evidence passes and retains verdict and limits', () {
    final a = 'a' * 64;
    final b = 'b' * 64;
    final complete = BuildProvenanceEvidence(
      buildInputs: <String>[
        'pubspec.yaml sha256 $a',
        'windows/runner/CMakeLists.txt sha256 $b',
      ],
      toolchainVersions: <String>['Flutter 3.x', 'Dart 3.x'],
      dependencyLock: <String>['pubspec.lock sha256 $a'],
      rebuildResults: <RebuildResult>[
        _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
        _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': b}),
      ],
      artifactComparison: ArtifactComparison(
        method: 'SHA-256 over exe+dll set',
        rebuildA: _rebuild('rebuild_a', <String, String>{
          'void_scriptor.exe': a,
        }),
        rebuildB: _rebuild('rebuild_b', <String, String>{
          'void_scriptor.exe': b,
        }),
        verdict: RebuildVerdict.notBitIdentical,
        limits: <String>['MSVC embeds a non-deterministic PE timestamp'],
      ),
      provenanceRecord: <String>['source_revision $a'],
    );
    final evaluation = BuildProvenanceEvidence.evaluate(complete);
    expect(evaluation.state, BuildProvenanceState.pass);
    final note = evaluation.notes.join(' ');
    expect(note, contains('NOT_BIT_IDENTICAL'));
    expect(note, contains('rebuild_results: 2 item'));
    expect(
      note,
      contains('limit: MSVC embeds a non-deterministic PE timestamp'),
    );
  });

  test('117.43-21 the same path restated in two groups must agree', () {
    final a = 'a' * 64;
    final b = 'b' * 64;
    final other = 'c' * 64;

    BuildProvenanceEvidence withLocks({
      required String buildInputLock,
      required List<String> dependencyLockLines,
    }) {
      return BuildProvenanceEvidence(
        buildInputs: <String>[
          'pubspec.yaml sha256 $other',
          'pubspec.lock sha256 $buildInputLock',
        ],
        toolchainVersions: <String>['Flutter 3.x', 'Dart 3.x'],
        dependencyLock: dependencyLockLines,
        rebuildResults: <RebuildResult>[
          _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
          _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': b}),
        ],
        artifactComparison: ArtifactComparison(
          method: 'SHA-256 over exe+dll set',
          rebuildA: _rebuild('rebuild_a', <String, String>{
            'void_scriptor.exe': a,
          }),
          rebuildB: _rebuild('rebuild_b', <String, String>{
            'void_scriptor.exe': b,
          }),
          verdict: RebuildVerdict.notBitIdentical,
          limits: <String>['MSVC embeds a non-deterministic PE timestamp'],
        ),
        provenanceRecord: <String>['source_revision $a'],
      );
    }

    // Control 1: both groups state the same digest, as the shipped 113.39
    // document does. This is the honest case and must stay a pass.
    final agreeing = withLocks(
      buildInputLock: a,
      dependencyLockLines: <String>['pubspec.lock sha256 $a'],
    );
    expect(BuildProvenanceEvidence.missingEvidence(agreeing), isEmpty);
    expect(
      BuildProvenanceEvidence.evaluate(agreeing).state,
      BuildProvenanceState.pass,
    );

    // Control 2: a line that only NAMES the algorithm states no digest, so it
    // is not a restatement and cannot contradict the other group (117.43-11).
    final proseOnly = withLocks(
      buildInputLock: a,
      dependencyLockLines: <String>[
        'hosted dependencies hash-pinned sha256; 0 git/path source',
      ],
    );
    expect(
      BuildProvenanceEvidence.missingEvidence(proseOnly),
      isEmpty,
      reason: 'a prose mention is a non-claim, not a contradiction',
    );

    // Control 3: a path named by only ONE group has nothing to contradict.
    final singleGroup = withLocks(
      buildInputLock: a,
      dependencyLockLines: <String>['hosted dependencies hash-pinned; 0 git'],
    );
    expect(BuildProvenanceEvidence.missingEvidence(singleGroup), isEmpty);

    // The defect: `build_inputs` and `dependency_lock` both state a digest for
    // `pubspec.lock`, both digests are well-formed 64-hex values, and they are
    // DIFFERENT. Each group passes its own shape check while the document
    // states two different hashes for one file.
    final contradicted = withLocks(
      buildInputLock: a,
      dependencyLockLines: <String>['pubspec.lock sha256 $b'],
    );
    expect(
      BuildProvenanceEvidence.missingEvidence(contradicted),
      isNotEmpty,
      reason: 'one path cannot hash to two different values in one document',
    );
    expect(
      BuildProvenanceEvidence.evaluate(contradicted).state,
      isNot(BuildProvenanceState.pass),
    );
  });

  test('117.43-22 a method naming another digest algorithm contradicts the '
      'digests it records', () {
    final a = 'a' * 64;
    final b = 'b' * 64;

    ArtifactComparison comparedWith(String method) => ArtifactComparison(
      method: method,
      rebuildA: _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
      rebuildB: _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': b}),
      // An honest non-identity claim: the two rebuilds really do differ, and
      // the limits document it, so the ONLY question these cases ask is the
      // method's shape.
      verdict: RebuildVerdict.notBitIdentical,
      limits: <String>['fixture: digests deliberately differ'],
    );

    // Control 1: the algorithm the records are actually validated as. Both
    // spellings of SHA-256 the shipped documents use stay well formed.
    expect(comparedWith('SHA-256 over exe+dll set').isWellFormed, isTrue);
    expect(comparedWith('sha256').isWellFormed, isTrue);

    // Control 2: a method that names no algorithm at all makes no algorithm
    // claim, so it is not measured (the same non-claim rule 117.43-07 settled
    // for windows, commands, logs, and verdict strings).
    expect(
      comparedWith('cold rebuilds, cache dropped').isWellFormed,
      isTrue,
      reason: 'a method that names no algorithm contradicts nothing',
    );

    // The defect: `method` states how the recorded digests were produced, and
    // `isWellFormed` has already decided every one of them is exactly 64 hex
    // characters. A method naming a different digest algorithm states that the
    // comparison was performed with something whose output cannot have the
    // width the records carry — and nothing asked, because the only test on
    // this field was "is it blank?".
    for (final method in <String>[
      'MD5 over the 6 exe/dll artifacts',
      'SHA-1 over the recorded artifacts',
      'SHA-512 over the recorded artifacts',
      'crc32 over the recorded artifacts',
    ]) {
      expect(
        comparedWith(method).isWellFormed,
        isFalse,
        reason:
            '"$method" names an algorithm the 64-hex digests cannot be, and a '
            'comparison that misstates how it hashed is not evidence',
      );
    }

    // The same contradiction has to reach the group verdict, not just the
    // comparison object: the gate printed `artifact_comparison: ...` for a
    // method it never read.
    final methodMismatch = BuildProvenanceEvidence(
      buildInputs: <String>['pubspec.yaml sha256 $a'],
      toolchainVersions: <String>['Flutter 3.x', 'Dart 3.x'],
      dependencyLock: <String>['pubspec.lock sha256 $a'],
      rebuildResults: <RebuildResult>[
        _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': a}),
        _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': b}),
      ],
      artifactComparison: comparedWith('MD5 over the recorded artifacts'),
      provenanceRecord: <String>['source_revision $a'],
    );
    expect(
      BuildProvenanceEvidence.missingEvidence(methodMismatch),
      contains('artifact_comparison'),
      reason: 'a comparison that misstates its algorithm is not a comparison',
    );
    expect(
      BuildProvenanceEvidence.evaluate(methodMismatch).state,
      isNot(BuildProvenanceState.pass),
    );
  });

  test('113.39 provenance manifest records all six evidence groups', () {
    final file = File(
      'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json',
    );
    expect(file.existsSync(), isTrue, reason: 'step manifest missing');
    final manifest =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(manifest['canonical_step'], '113.39');
    expect(manifest['version'], '1.2.0-rc.1');
    expect(manifest['status'], 'VERIFIED-LOCAL');

    final evidence = manifest['required_evidence'] as Map<String, dynamic>;
    expect(
      evidence.keys.toList()..sort(),
      (kBuildProvenanceRequiredEvidence.toList()..sort()),
    );

    final limits = manifest['limits'] as List<dynamic>;
    expect(limits, isNotEmpty);

    final rebuildList = (evidence['rebuild_results'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(rebuildList, hasLength(2));
    for (final rebuild in rebuildList) {
      expect(rebuild['exit_code'], 0);
      expect(rebuild['label'], isNotEmpty);
      final hashes = rebuild['artifact_hashes'] as Map<String, dynamic>;
      expect(hashes, isNotEmpty);
      for (final entry in hashes.entries) {
        expect(
          RegExp(r'^[0-9a-f]{64}$').hasMatch(entry.value as String),
          isTrue,
        );
      }
    }

    final comparison = evidence['artifact_comparison'] as Map<String, dynamic>;
    expect(comparison['method'], isNotEmpty);
    expect(comparison['verdict'], anyOf('BIT_IDENTICAL', 'NOT_BIT_IDENTICAL'));
    if (comparison['verdict'] == 'NOT_BIT_IDENTICAL') {
      final comparisonLimits = (comparison['limits'] as List<dynamic>);
      expect(comparisonLimits, isNotEmpty);
      expect(comparisonLimits.join(' ').trim(), isNotEmpty);
    }

    // Build the domain object from the manifest and require a pass.
    final domain = BuildProvenanceEvidence(
      buildInputs: (evidence['build_inputs'] as List<dynamic>).cast<String>(),
      toolchainVersions: (evidence['toolchain_versions'] as List<dynamic>)
          .cast<String>(),
      dependencyLock: (evidence['dependency_lock'] as List<dynamic>)
          .cast<String>(),
      rebuildResults: rebuildList
          .map(
            (rebuild) => RebuildResult(
              label: rebuild['label'] as String,
              artifactHashes:
                  (rebuild['artifact_hashes'] as Map<String, dynamic>).map(
                    (key, value) => MapEntry(key, value as String),
                  ),
              exitCode: rebuild['exit_code'] as int?,
              startedAt: rebuild['started_at'] as String?,
              finishedAt: rebuild['finished_at'] as String?,
            ),
          )
          .toList(),
      artifactComparison: ArtifactComparison(
        method: comparison['method'] as String,
        rebuildA: RebuildResult(
          label: rebuildList[0]['label'] as String,
          artifactHashes:
              (rebuildList[0]['artifact_hashes'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, value as String),
              ),
          exitCode: rebuildList[0]['exit_code'] as int?,
        ),
        rebuildB: RebuildResult(
          label: rebuildList[1]['label'] as String,
          artifactHashes:
              (rebuildList[1]['artifact_hashes'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, value as String),
              ),
          exitCode: rebuildList[1]['exit_code'] as int?,
        ),
        verdict: comparison['verdict'] == 'BIT_IDENTICAL'
            ? RebuildVerdict.bitIdentical
            : RebuildVerdict.notBitIdentical,
        limits: (comparison['limits'] as List<dynamic>).cast<String>(),
      ),
      provenanceRecord: (evidence['provenance_record'] as List<dynamic>)
          .cast<String>(),
    );
    expect(BuildProvenanceEvidence.missingEvidence(domain), isEmpty);
    final evaluation = BuildProvenanceEvidence.evaluate(domain);
    expect(evaluation.state, BuildProvenanceState.pass);
  });

  test('113.39 dependency lock evidence matches the live lockfile', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final evidence = manifest['required_evidence'] as Map<String, dynamic>;
    final liveSha = sha256
        .convert(File('pubspec.lock').readAsBytesSync())
        .toString();
    final dependencyLock = (evidence['dependency_lock'] as List<dynamic>)
        .cast<String>();
    expect(dependencyLock.join(' '), contains(liveSha));
    expect(liveSha, hasLength(64));
  });

  test('113.39 provenance record is well formed', () {
    final manifest =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final evidence = manifest['required_evidence'] as Map<String, dynamic>;
    final provenance = (evidence['provenance_record'] as List<dynamic>)
        .cast<String>();
    expect(provenance.join(' '), contains('source_revision'));
    final revision = provenance
        .firstWhere((item) => item.startsWith('source_revision'))
        .split(' ')
        .last;
    expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(revision), isTrue);
    expect(provenance.join(' '), contains('build_command'));
    expect(
      provenance.join(' '),
      contains('D:/DevTools/Flutter SDK/flutter/bin/flutter.bat'),
    );

    final toolchain = (evidence['toolchain_versions'] as List<dynamic>)
        .cast<String>();
    expect(toolchain.join(' '), contains('Flutter'));
    expect(toolchain.join(' '), contains('Dart'));
    for (final entry in toolchain) {
      expect(entry.trim(), isNotEmpty);
    }

    final inputs = (evidence['build_inputs'] as List<dynamic>).cast<String>();
    expect(inputs, isNotEmpty);
    expect(inputs.join(' '), contains('pubspec.yaml'));
    for (final entry in inputs) {
      expect(entry, contains('sha256'));
      expect(entry.split('sha256').last.trim(), hasLength(64));
    }
  });

  test(
    '113.39 signed release artifact from 113.38 remains intact',
    skip: signedArtifactPresent
        ? null
        : 'requires the locally-built Windows candidate artifact',
    () {
      // Rebuilding for provenance must not clobber the signed candidate:
      // the committed checksum of the signed executable has to still match.
      final checksums = File(
        'docs/release/v1.2.0-rc.1-checksums.txt',
      ).readAsStringSync().split('\n').map((line) => line.trim()).toList();
      const exePath = 'build/windows/x64/runner/Release/void_scriptor.exe';
      final line = checksums.firstWhere(
        (entry) => entry.endsWith('  $exePath'),
      );
      final expected = line.split(RegExp(r'\s+')).first;
      final actual = sha256.convert(File(exePath).readAsBytesSync()).toString();
      expect(
        actual,
        expected,
        reason: 'signed 1.2.0-rc.1 artifact must survive provenance rebuilds',
      );
    },
  );
}
