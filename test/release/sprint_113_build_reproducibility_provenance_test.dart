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

  test('117.43-23 one tool recorded with two versions contradicts itself', () {
    final a = 'a' * 64;
    final b = 'b' * 64;

    BuildProvenanceEvidence withToolchain(List<String> versions) =>
        BuildProvenanceEvidence(
          buildInputs: <String>['pubspec.yaml sha256 $a'],
          toolchainVersions: versions,
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
            limits: <String>['fixture: digests deliberately differ'],
          ),
          provenanceRecord: <String>['source_revision $a'],
        );

    // Control 1: the toolchain lines the SHIPPED document actually records.
    // Each tool is named once, so the group states one version per tool and
    // must stay a pass — this is the honest case this rule must not refuse.
    final shipped = File(
      'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json',
    ).readAsStringSync();
    final shippedLines =
        (jsonDecode(shipped) as Map<String, dynamic>)['required_evidence']
            as Map<String, dynamic>;
    final shippedToolchain =
        (shippedLines['toolchain_versions'] as List<dynamic>).cast<String>();
    expect(shippedToolchain, hasLength(greaterThan(3)));
    expect(
      BuildProvenanceEvidence.missingEvidence(withToolchain(shippedToolchain)),
      isEmpty,
      reason: 'the shipped document records one version per tool',
    );

    // Control 2: a line that records NO version number is a non-claim, not a
    // contradiction (117.43-07). `Engine hash <40 hex>` pins a revision, which
    // is a stronger statement than a version number, and a prose line states
    // nothing to agree with.
    expect(
      BuildProvenanceEvidence.missingEvidence(
        withToolchain(<String>[
          'Engine hash d3a3293399556a85388faf8c6f0723a7a5597aa8 '
              '(revision 83675ed276)',
          'Host Windows x64 (MSYS bash runner)',
        ]),
      ),
      isEmpty,
      reason: 'a line carrying no version number contradicts nothing',
    );

    // Control 3: the same tool written with LESS detail is a refinement, not a
    // second version. `Visual Studio Build Tools 2026 18.9.0 ...` and
    // `Visual Studio Build Tools 18.9.0` state the same tool and the same
    // version, one of them with more detail, so refusing that would punish an
    // honest document for being verbose on one line and terse on another.
    expect(
      BuildProvenanceEvidence.missingEvidence(
        withToolchain(<String>[
          'Visual Studio Build Tools 2026 18.9.0 version 18.9.12105.275',
          'Visual Studio Build Tools 18.9.0',
        ]),
      ),
      isEmpty,
      reason: 'one record refining another is not a second version',
    );

    // The defect: `toolchain_versions` was read by `_hasContent` alone, which
    // asks whether each line is a non-blank string and nothing more. A document
    // listing the SAME tool under two different versions therefore printed
    // `toolchain_versions: N item` as though N versions had been checked, while
    // the comparison's whole premise — "same tree and machine", with
    // cross-SDK reproducibility explicitly disclaimed in its own limits —
    // was contradicted by the group that is supposed to say which SDK ran.
    final twoVersions = withToolchain(<String>[
      'Flutter 3.44.6 channel stable revision ee80f08bbf (2026-07-08)',
      'Flutter 3.44.9 channel stable revision ee80f08bbf (2026-07-08)',
      'Dart 3.12.2',
    ]);
    expect(
      BuildProvenanceEvidence.missingEvidence(twoVersions),
      contains('toolchain_versions'),
      reason: 'one build cannot have been produced by two SDK versions',
    );
    expect(
      BuildProvenanceEvidence.evaluate(twoVersions).state,
      isNot(BuildProvenanceState.pass),
    );
  });

  test('117.43-29 one line naming two tools must not discard the second '
      'tool\'s version', () {
    // Sprint 117.43-29 (fail-open, fixed): 117.43-23 taught this group that a
    // tool recorded twice under two versions contradicts itself, and its rule
    // is pairwise over `_ToolchainLine`. But `_readToolchainLine` returns ONE
    // claim per line: the name is read until the first token carrying a digit,
    // and the version is the FIRST dotted number anywhere on the line
    // (`firstWhere` at the version step). So a line that names SEVERAL tools
    // keeps the first tool's version and silently drops every other tool named
    // beside it — exactly the shape 117.43-28 closed on the digest side, one
    // group over: a document only has to put a restatement on a shared line for
    // that claim to reach the verdict unexamined.
    //
    // The drop is not cosmetic. `toolchain_versions` is the group that says
    // WHICH SDK produced the build, and the comparison's own premise is "same
    // tree and machine" with cross-SDK reproducibility disclaimed in its
    // limits. If `Flutter 3.44.6` and `Flutter 3.44.9` are stated on ONE line
    // beside one another, the pairwise loop compares them against nothing and
    // `missingEvidence` reports no missing group, so `evaluate` returns `pass`
    // and the gate prints `toolchain_versions: N item` as though N versions had
    // been compared against each other.
    //
    // Digest-shaped constants are deliberately NOT used as the contradicting
    // values: the 117.43-26 run shipped one RED that failed for the wrong
    // reason (63/65-character constants refused as MALFORMED, not as a
    // contradiction). These are real SDK version strings, and the fixture's
    // other groups carry real 64-hex digests so the ONLY thing each case turns
    // on is the toolchain claim itself.
    const dartSdk = 'Dart 3.12.2';

    BuildProvenanceEvidence withToolchain(
      List<String> versions,
    ) => BuildProvenanceEvidence(
      buildInputs: <String>['pubspec.yaml sha256 ${'a' * 64}'],
      toolchainVersions: versions,
      dependencyLock: <String>['pubspec.lock sha256 ${'b' * 64}'],
      rebuildResults: <RebuildResult>[
        _rebuild('rebuild_a', <String, String>{'void_scriptor.exe': 'a' * 64}),
        _rebuild('rebuild_b', <String, String>{'void_scriptor.exe': 'b' * 64}),
      ],
      artifactComparison: ArtifactComparison(
        method: 'SHA-256 over exe+dll set',
        rebuildA: _rebuild('rebuild_a', <String, String>{
          'void_scriptor.exe': 'a' * 64,
        }),
        rebuildB: _rebuild('rebuild_b', <String, String>{
          'void_scriptor.exe': 'b' * 64,
        }),
        verdict: RebuildVerdict.notBitIdentical,
        limits: <String>['fixture: digests deliberately differ'],
      ),
      provenanceRecord: <String>['source_revision ${'c' * 64}'],
    );

    // Control 1: the toolchain lines the SHIPPED document actually records.
    // Each tool is named once, so the group states one version per tool and
    // must stay a pass — this is the honest case this rule must not refuse.
    final shipped =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final shippedToolchain =
        ((shipped['required_evidence']
                    as Map<String, dynamic>)['toolchain_versions']
                as List<dynamic>)
            .cast<String>();
    expect(shippedToolchain, hasLength(greaterThan(3)));
    expect(
      BuildProvenanceEvidence.missingEvidence(withToolchain(shippedToolchain)),
      isEmpty,
      reason: 'the shipped document records one version per tool',
    );

    // Control 2: TWO DIFFERENT tools on ONE line. A line may name several
    // tools — that is several claims, not a contradiction — and this is the
    // case the 117.43-23 bounds already allow across lines. Naming `Dart`
    // beside `Flutter` states two tools at two versions, which no pairwise
    // rule may refuse.
    expect(
      BuildProvenanceEvidence.missingEvidence(
        withToolchain(<String>['Flutter 3.44.6 and Dart 3.12.2']),
      ),
      isEmpty,
      reason: 'one line naming two different tools is two claims, not a clash',
    );

    // Control 3: the SAME tool and version restated on one line is an
    // idempotent restatement (117.43-26/27/28's shape, one group over).
    expect(
      BuildProvenanceEvidence.missingEvidence(
        withToolchain(<String>['Flutter 3.44.6, Flutter 3.44.6']),
      ),
      isEmpty,
      reason: 'the same tool at the same version twice is a restatement',
    );

    // The defect: BOTH Flutter versions on ONE line. Pre-fix the reader keeps
    // `Flutter 3.44.6` (the first dotted number) and drops `3.44.9`, so the
    // pairwise loop compares a single claim against itself and the group
    // reports `pass` while the document says the build used two SDKs.
    final twoOnOneLine = withToolchain(<String>[
      'Flutter 3.44.6 and Flutter 3.44.9',
      dartSdk,
    ]);
    expect(
      BuildProvenanceEvidence.missingEvidence(twoOnOneLine),
      contains('toolchain_versions'),
      reason:
          'one build cannot have been produced by two SDK versions, '
          'whether they are stated on one line or on two',
    );
    expect(
      BuildProvenanceEvidence.evaluate(twoOnOneLine).state,
      isNot(BuildProvenanceState.pass),
    );

    // The same contradiction reached the other way: the SHIPPED document's own
    // multi-tool line shape must stay a pass, so the fix cannot simply refuse
    // any line naming more than one dotted number.
    expect(
      BuildProvenanceEvidence.missingEvidence(
        withToolchain(<String>[
          'Flutter 3.44.6, Dart 3.12.2, '
              'Visual Studio Build Tools 18.9.0 version 18.9.12105.275',
        ]),
      ),
      isEmpty,
      reason: 'the tools the shipped document names, at one version each',
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
      contains('D:/DevTools/Flutter-SDK-3.44.9/flutter/bin/flutter.bat'),
      reason: 'the provenance record must cite the SDK path this tree builds with',
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

  test('117.43-24 a method stating an artifact scope the records do not match '
      'contradicts the digests it names', () {
    final a = 'a' * 64;
    final b = 'b' * 64;

    // The six artifacts the SHIPPED document records, in the order its
    // method enumerates them. Rebuild B differs on exactly one, so the
    // notBitIdentical verdict below is honest and the ONLY question these
    // cases ask is whether the method's stated scope matches the records.
    const recorded = <String>[
      'void_scriptor.exe',
      'dartjni.dll',
      'file_selector_windows_plugin.dll',
      'flutter_secure_storage_windows_plugin.dll',
      'flutter_windows.dll',
      'sqlite3.dll',
    ];

    ArtifactComparison comparedWith(String method) => ArtifactComparison(
      method: method,
      rebuildA: _rebuild('rebuild_a', <String, String>{
        for (final name in recorded) name: a,
      }),
      rebuildB: _rebuild('rebuild_b', <String, String>{
        for (final name in recorded) name: name == 'dartjni.dll' ? b : a,
      }),
      verdict: RebuildVerdict.notBitIdentical,
      limits: <String>['fixture: digests deliberately differ'],
    );

    // Control 1: the method the SHIPPED document states, read from disk. It
    // says "the 6 exe/dll artifacts" and enumerates six names, and six
    // artifacts are recorded — so the honest document must stay well formed.
    final shipped =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_build_reproducibility_provenance.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final shippedMethod =
        ((shipped['required_evidence']
                    as Map<String, dynamic>)['artifact_comparison']
                as Map<String, dynamic>)['method']
            as String;
    expect(shippedMethod, contains('the 6 exe/dll artifacts'));
    expect(
      comparedWith(shippedMethod).isWellFormed,
      isTrue,
      reason:
          'the shipped method names six artifacts and six are recorded, so '
          'its stated scope agrees with the digests it claims to cover',
    );

    // Control 2: a method stating no count and no enumeration makes no scope
    // claim, so it is not measured — the same non-claim rule 117.43-07
    // settled for windows, commands, logs, and verdict strings.
    expect(
      comparedWith('SHA-256 over exe+dll set').isWellFormed,
      isTrue,
      reason: 'a method that states no artifact count contradicts nothing',
    );
    expect(
      comparedWith('cold rebuilds, cache dropped').isWellFormed,
      isTrue,
      reason:
          'a method that names neither count nor scope contradicts '
          'nothing',
    );

    // The defect, part 1: the count. `method` says HOW MANY artifacts the
    // comparison covered, and 117.43-22 established that this same field is
    // read for the ALGORITHM that produced the digests — but the count and
    // the enumeration beside it were never read by anything. Six digests
    // recorded under a method that claims to have covered four describe a
    // comparison that was never performed as stated.
    for (final method in <String>[
      'SHA-256 over the 4 exe/dll artifacts',
      'SHA-256 over the 7 exe/dll artifacts',
      'SHA-256 over the 1 artifacts',
      'SHA-256 over 12 artifacts',
    ]) {
      expect(
        comparedWith(method).isWellFormed,
        isFalse,
        reason:
            '"$method" states a scope six recorded artifacts do not match, '
            'and a comparison that misstates what it covered is not evidence '
            'about those digests',
      );
    }

    // The defect, part 2: the enumeration. The method names an artifact that
    // no record hashed, so it claims coverage of a digest the same document
    // never recorded.
    expect(
      comparedWith(
        'SHA-256 over the 6 exe/dll artifacts (void_scriptor.exe + '
        'dartjni.dll, file_selector_windows_plugin.dll, '
        'flutter_secure_storage_windows_plugin.dll, flutter_windows.dll, '
        'sqlite3.dll, phantom_driver.dll)',
      ).isWellFormed,
      isFalse,
      reason:
          'a method naming an artifact no record hashed claims coverage of a '
          'digest the document never recorded',
    );

    // Boundary, pinned so the rule cannot over-refuse: an enumeration that
    // illustrates rather than exhausts makes no completeness claim, so a
    // recorded artifact the method does not name is left alone. Requiring the
    // list to be complete would invent an acceptance criterion the evidence
    // never stated, which is the same overclaim this gate exists to refuse.
    expect(
      comparedWith(
        'SHA-256 over the 6 exe/dll artifacts (void_scriptor.exe + '
        'dartjni.dll)',
      ).isWellFormed,
      isTrue,
      reason:
          'an illustrative enumeration claims no completeness, so an artifact '
          'the records hold but the method does not name is not a defect',
    );

    // The same contradiction has to reach the group verdict, not just the
    // comparison object: the gate printed `artifact_comparison: ... (6
    // artifact)` for a method it never read the scope of.
    BuildProvenanceEvidence withMethod(String method) =>
        BuildProvenanceEvidence(
          buildInputs: <String>['pubspec.yaml sha256 $a'],
          toolchainVersions: <String>['Flutter 3.x', 'Dart 3.x'],
          dependencyLock: <String>['pubspec.lock sha256 $a'],
          rebuildResults: <RebuildResult>[
            _rebuild('rebuild_a', <String, String>{
              for (final name in recorded) name: a,
            }),
            _rebuild('rebuild_b', <String, String>{
              for (final name in recorded) name: name == 'dartjni.dll' ? b : a,
            }),
          ],
          artifactComparison: comparedWith(method),
          provenanceRecord: <String>['source_revision $a'],
        );

    final scopeMismatch = withMethod('SHA-256 over the 3 exe/dll artifacts');
    expect(
      BuildProvenanceEvidence.missingEvidence(scopeMismatch),
      contains('artifact_comparison'),
      reason:
          'a comparison that misstates how many artifacts it covered is not '
          'a comparison of those artifacts',
    );
    expect(
      BuildProvenanceEvidence.evaluate(scopeMismatch).state,
      isNot(BuildProvenanceState.pass),
    );

    // The honest document must still pass end to end at this layer.
    expect(
      BuildProvenanceEvidence.missingEvidence(withMethod(shippedMethod)),
      isEmpty,
      reason: 'the shipped method agrees with the six artifacts recorded',
    );
  });

  test('117.43-35 a method stating two artifact counts is compared on both', () {
    final a = 'a' * 64;
    final b = 'b' * 64;
    const recorded = <String>[
      'void_scriptor.exe',
      'dartjni.dll',
      'file_selector_windows_plugin.dll',
      'flutter_secure_storage_windows_plugin.dll',
      'flutter_windows.dll',
      'sqlite3.dll',
    ];

    ArtifactComparison comparedWith(String method) => ArtifactComparison(
      method: method,
      rebuildA: _rebuild('rebuild_a', <String, String>{
        for (final name in recorded) name: a,
      }),
      rebuildB: _rebuild('rebuild_b', <String, String>{
        for (final name in recorded) name: name == 'dartjni.dll' ? b : a,
      }),
      verdict: RebuildVerdict.notBitIdentical,
      limits: <String>['fixture: digests deliberately differ'],
    );

    // Defect 117.43-35: the artifact scope of `method` was read with
    // firstMatch, so only the FIRST total in the sentence was ever
    // compared with the recorded inventory. The sentence below agrees
    // with the six recorded artifacts up front and then claims twelve
    // behind it. The second total is a coverage claim the records do not
    // support, and before this slice the comparison passed anyway.
    const twoTotals =
        'SHA-256 over the 6 exe/dll artifacts, a scope restated as 12 '
        'artifacts after the second pass';
    expect(
      comparedWith(twoTotals).isWellFormed,
      isFalse,
      reason:
          'a second total the recorded inventory does not match is a scope '
          'claim too; reading only the first lets a document disagree with '
          'itself and still pass',
    );

    // The same claim has to reach the group verdict, not just the
    // comparison object: the gate printed `artifact_comparison: ... (6
    // artifact)` for a method it measured against only its first total.
    BuildProvenanceEvidence withMethod(String method) =>
        BuildProvenanceEvidence(
          buildInputs: <String>['pubspec.yaml sha256 $a'],
          toolchainVersions: <String>['Flutter 3.x', 'Dart 3.x'],
          dependencyLock: <String>['pubspec.lock sha256 $a'],
          rebuildResults: <RebuildResult>[
            _rebuild('rebuild_a', <String, String>{
              for (final name in recorded) name: a,
            }),
            _rebuild('rebuild_b', <String, String>{
              for (final name in recorded) name: name == 'dartjni.dll' ? b : a,
            }),
          ],
          artifactComparison: comparedWith(method),
          provenanceRecord: <String>['source_revision $a'],
        );
    expect(
      BuildProvenanceEvidence.missingEvidence(withMethod(twoTotals)),
      contains('artifact_comparison'),
      reason:
          'the contradiction has to reach the group verdict, not only the '
          'comparison object',
    );

    // Boundary pinned so the rule cannot over-refuse: the same total
    // stated twice is one claim recorded twice, which stays benign, the
    // way a path repeated with the same digest stays benign in
    // readChecksumIndex.
    expect(
      comparedWith(
        'SHA-256 over the 6 exe/dll artifacts, restated as 6 artifacts '
        'after the second pass',
      ).isWellFormed,
      isTrue,
      reason:
          'a repeated count that still matches the records states nothing '
          'new to contradict',
    );

    // A number that never names an artifact scope is still not a claim.
    expect(
      comparedWith(
        'SHA-256 over the 6 exe/dll artifacts after two independent '
        'flutter clean + flutter build windows --release cycles',
      ).isWellFormed,
      isTrue,
      reason: 'a number that never names artifacts states no count',
    );

    // The shipped document states one total, so reading every total
    // changes nothing for the honest document.
    final shipped =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_113_build_reproducibility_provenance'
                '.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final shippedMethod =
        ((shipped['required_evidence']
                    as Map<String, dynamic>)['artifact_comparison']
                as Map<String, dynamic>)['method']
            as String;
    expect(
      comparedWith(shippedMethod).isWellFormed,
      isTrue,
      reason:
          'the shipped method states a single total, so comparing every '
          'total leaves the honest document well formed',
    );
  });
}
