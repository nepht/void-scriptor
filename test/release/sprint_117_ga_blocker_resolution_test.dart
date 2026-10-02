// Sprint 117.39 — GA Blocker Resolution.
//
// Measures the two fail-open defects found in the SHIPPED crash diagnostics
// sink (lib/app/bootstrap/crash_diagnostics.dart) against the real seam, and
// gates the six canonical `required_outputs` for every blocker claiming GA
// resolution.
//
// Secrets are assembled from parts at runtime so this file contains no live
// credential literal, and every assertion is a boolean/count so the claim
// cannot be softened by reading the expected value out of the test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/bootstrap/crash_diagnostics.dart';
import 'package:void_scriptor/core/security/application/secret_scanner.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_ga_blocker_resolution.dart';

/// Builds a provider-shaped credential at runtime (never a literal here).
String _secret(String prefix, String body, int length) =>
    '$prefix${body * length}';

void main() {
  late Directory diagDir;
  var captureSeq = 0;

  setUp(() {
    diagDir = Directory.systemTemp.createTempSync('vs_11739_blocker');
  });

  tearDown(() {
    try {
      if (diagDir.existsSync()) diagDir.deleteSync(recursive: true);
    } on FileSystemException {
      Future<void>.delayed(const Duration(milliseconds: 50)).then((_) {
        try {
          if (diagDir.existsSync()) diagDir.deleteSync(recursive: true);
        } catch (_) {}
      });
    }
  });

  /// Captures one error and returns the raw artifact text.
  ///
  /// Each capture gets its OWN subdirectory: the aggregate probe captures
  /// several messages, and reusing one directory would leave earlier
  /// artifacts behind so `.single` would throw `Too many elements` — a
  /// harness failure that would be indistinguishable from a real leak.
  String capture(String message) {
    final dir = Directory(
      '${diagDir.path}${Platform.pathSeparator}capture-${captureSeq++}',
    );
    final diag = CrashDiagnostics(directory: dir);
    diag.handleZoneError(Exception(message), StackTrace.current);
    return dir.listSync().whereType<File>().single.readAsStringSync();
  }

  group('117.39 defect 1 — only the FIRST secret of a class was redacted', () {
    // Root cause: _redactSecrets used replaceFirstMapped for each pattern, so
    // a second credential of the SAME class reached the artifact in full.
    // The canonical SecretRedactor (117.32) replaces every occurrence.

    test('a second bearer credential in one message is redacted', () {
      final first = _secret('bearer ', 'A', 16);
      final second = _secret('bearer ', 'B', 16);
      final raw = capture('$first and $second');

      expect(
        raw.contains(second),
        isFalse,
        reason: 'second bearer credential reached the crash artifact',
      );
    });

    test('a second labeled credential in one message is redacted', () {
      final first = 'api_key=${_secret('', 'a', 18)}';
      final second = 'token=${_secret('', 't', 18)}';
      final raw = capture('$first and $second');

      expect(
        raw.contains(_secret('', 't', 18)),
        isFalse,
        reason: 'second labeled credential reached the crash artifact',
      );
    });

    test('a second provider-shaped credential is redacted', () {
      final first = 'sk-${'A' * 18}';
      final second = 'sk-${'B' * 18}';
      final raw = capture('$first and $second');

      expect(
        raw.contains(second),
        isFalse,
        reason: 'second provider-shaped credential reached the artifact',
      );
    });

    test('every credential in a crowded message is redacted, not just one', () {
      final parts = <String>[
        'sk-${'A' * 18}',
        ' and sk-${'B' * 18}',
        ' and sk-${'C' * 18}',
        ' and token=${_secret('', 'x', 20)}',
        ' and token=${_secret('', 'y', 20)}',
        ' and bearer ${_secret('', 'z', 20)}',
      ];
      final raw = capture(parts.join());

      for (final leaked in <String>[
        'sk-${'B' * 18}',
        'sk-${'C' * 18}',
        _secret('', 'x', 20),
        _secret('', 'y', 20),
        _secret('', 'z', 20),
      ]) {
        expect(
          raw.contains(leaked),
          isFalse,
          reason: 'credential reached the crash artifact in full',
        );
      }
    });
  });

  group('117.39 defect 2 — real provider token formats never matched', () {
    // Root cause: the provider-shaped pattern demanded a DASH separator
    // `(?:sk|pk|ghp|gho|github_pat|xox)[-]`, but the real GitHub formats use
    // an UNDERSCORE (`ghp_`, `github_pat_`) and the real Slack format is
    // `xoxb-…`. The repo's own SecretScanner (117.32) lists the true shapes;
    // the crash sink disagreed with it, so credentials it was told to catch
    // by name were never even considered.

    test('a GitHub classic token (ghp_ + underscore) is redacted', () {
      final token = 'ghp_${'C' * 30}';
      final raw = capture('upload failed for $token');

      expect(
        raw.contains(token),
        isFalse,
        reason: 'ghp_ token reached the crash artifact',
      );
    });

    test(
      'a GitHub fine-grained PAT (github_pat_ + underscore) is redacted',
      () {
        final token = 'github_pat_${'D' * 30}';
        final raw = capture('auth failed for $token');

        expect(
          raw.contains(token),
          isFalse,
          reason: 'github_pat_ token reached the crash artifact',
        );
      },
    );

    test('a Slack token (xoxb- + dash) is redacted', () {
      final token = 'xoxb-${'E' * 24}';
      final raw = capture('post rejected, token $token');

      expect(
        raw.contains(token),
        isFalse,
        reason: 'xoxb- token reached the crash artifact',
      );
    });

    test('the crash sink agrees with the canonical SecretScanner formats', () {
      // Same credential families the shipped SecretScanner already knows.
      // A crash artifact must not be a weaker surface than the archive guard.
      // This is the load-bearing test against the root cause: the sink used
      // to keep its own DIVERGED copy of the pattern list, so a family added
      // to the canonical scanner (e.g. AKIA) was silently absent here. Now
      // the sink delegates, so this test fails the moment the two drift apart
      // again, in either direction.
      const scanner = SecretScanner();
      final credentials = <String>[
        'ghp_${'F' * 30}',
        'github_pat_${'G' * 30}',
        'xoxb-${'H' * 24}',
        'sk-${'I' * 24}',
        'AKIA${'J' * 16}',
      ];
      for (final credential in credentials) {
        // The credential is genuinely recognised as secret...
        expect(
          scanner.scan(credential),
          isNotEmpty,
          reason: 'canonical scanner no longer recognises this family',
        );
        // ...and the crash artifact must not retain it.
        final raw = capture('provider rejected $credential');
        expect(
          raw.contains(credential),
          isFalse,
          reason: 'credential family reached the crash artifact',
        );
      }
    });

    test('a second AWS access key in one message is redacted', () {
      final first = 'AKIA${'K' * 16}';
      final second = 'AKIA${'L' * 16}';
      final raw = capture('auth failed for $first and $second');

      expect(
        raw.contains(second),
        isFalse,
        reason: 'second AWS access key reached the crash artifact',
      );
    });
  });

  group('117.39 gate — six required outputs per resolved blocker', () {
    // `tests` names the check id so the gate can tie a claimed defect to a
    // check that actually ran; every other output is real prose.
    const testClaim = 'redacts_every_credential_not_just_the_first';

    Sprint117GaBlockerResolution blocker({
      required String id,
      required String domain,
      required String tests,
      String rootCause = 'measured root cause prose',
      String fix = 'measured fix prose',
      String review = 'review prose',
      String riskUpdate = 'risk update prose',
      String releaseNote = 'release note prose',
      bool resolved = true,
    }) => Sprint117GaBlockerResolution(
      blockerId: id,
      domain: domain,
      resolved: resolved,
      rootCause: rootCause,
      fix: fix,
      tests: tests,
      review: review,
      riskUpdate: riskUpdate,
      releaseNote: releaseNote,
    );

    Sprint117GaBlockerCheck passCheck(String id, String check) =>
        Sprint117GaBlockerCheck.pass_(
          blockerId: id,
          check: check,
          declared: 'the shipped sink redacts this credential',
          observed: 'measured from the captured crash artifact',
        );

    test('a fully evidenced blocker passes and yields the pass verdict', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(id: 'ga-blocker-1', domain: 'security', tests: testClaim),
        ],
        <Sprint117GaBlockerCheck>[passCheck('ga-blocker-1', testClaim)],
      );

      expect(result.verdict, Sprint117GaBlockerResolutionGate.passVerdict);
      expect(result.failures, isEmpty);
      expect(result.domainsMeasured, contains('security'));
    });

    test('claiming resolution with a blank output is a violation', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(
            id: 'ga-blocker-1',
            domain: 'security',
            tests: testClaim,
            releaseNote: '   ',
          ),
        ],
        <Sprint117GaBlockerCheck>[passCheck('ga-blocker-1', testClaim)],
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('missing_output:ga-blocker-1:release_note'),
      );
      expect(
        result.failures,
        contains('resolved_without_evidence:ga-blocker-1'),
      );
    });

    test('a fix with no executed test is rejected, not accepted on claim', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(id: 'ga-blocker-1', domain: 'security', tests: testClaim),
        ],
        <Sprint117GaBlockerCheck>[],
      );

      expect(result.failures, contains('no_check_for_blocker:ga-blocker-1'));
      expect(result.failures, contains('claim_without_test:ga-blocker-1'));
    });

    test('a test claim that names no executed check fails closed', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(
            id: 'ga-blocker-1',
            domain: 'security',
            tests: 'a_defect_no_test_covers',
          ),
        ],
        <Sprint117GaBlockerCheck>[passCheck('ga-blocker-1', testClaim)],
      );

      expect(result.failures, contains('claim_without_test:ga-blocker-1'));
    });

    test('an empty blocker set proves nothing', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[],
        <Sprint117GaBlockerCheck>[],
      );

      expect(result.failures, contains('no_blockers'));
      expect(result.pass, isFalse);
    });

    test('a blocker in a domain outside the canonical nine is rejected', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(id: 'ga-blocker-1', domain: 'telemetry', tests: testClaim),
        ],
        <Sprint117GaBlockerCheck>[passCheck('ga-blocker-1', testClaim)],
      );

      expect(
        result.failures,
        contains('unknown_domain:ga-blocker-1:telemetry'),
      );
    });

    test('unmeasured domains stay visible as unresolved, never as passes', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(id: 'ga-blocker-1', domain: 'security', tests: testClaim),
        ],
        <Sprint117GaBlockerCheck>[passCheck('ga-blocker-1', testClaim)],
      );

      // Only security was measured. The other eight canonical domains are
      // reported as unresolved rather than being assumed closed.
      expect(result.domainsMeasured, <String>['security']);
      expect(result.domainsUnresolved, isNot(contains('security')));
      expect(result.domainsUnresolved, contains('billing'));
      expect(result.domainsUnresolved, contains('accessibility'));
      expect(Sprint117GaBlockerResolutionGate.canonicalDomains.length, 9);
    });

    test('an unmet check is an open item and never a silent pass', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(id: 'ga-blocker-1', domain: 'billing', tests: testClaim),
        ],
        <Sprint117GaBlockerCheck>[
          Sprint117GaBlockerCheck.unmet(
            blockerId: 'ga-blocker-1',
            check: testClaim,
            declared: 'no shipped live billing surface in this build',
            observed: 'external provider settlement is DEFERRED-EXTERNAL',
          ),
        ],
      );

      expect(result.openItems, contains('ga-blocker-1:$testClaim'));
      expect(result.failures, contains('blocker_without_pass:ga-blocker-1'));
    });

    test('a vacuous check never satisfies a blocker', () {
      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          blocker(id: 'ga-blocker-1', domain: 'crash', tests: testClaim),
        ],
        <Sprint117GaBlockerCheck>[
          Sprint117GaBlockerCheck.pass_(
            blockerId: 'ga-blocker-1',
            check: testClaim,
            declared: '   ',
            observed: 'measured from the captured crash artifact',
          ),
        ],
      );

      expect(result.failures, contains('vacuous:ga-blocker-1:$testClaim'));
      expect(result.failures, contains('blocker_without_pass:ga-blocker-1'));
    });
  });

  group('117.39 aggregate verdict is built from probes that ran', () {
    test('the two measured defects satisfy their own gate blockers', () {
      const firstDefect = 'redacts_every_credential_not_just_the_first';
      const secondDefect = 'matches_the_real_provider_token_formats';

      // Re-measure both defects against the LIVE seam, then feed those
      // measurements to the gate. No verdict number is typed by hand.
      final firstProbe = <String, bool>{
        'bearer_second': !capture(
          'bearer ${'A' * 16} and bearer ${'B' * 16}',
        ).contains('B' * 16),
        'labeled_second': !capture(
          'api_key=${'a' * 18} and token=${'t' * 18}',
        ).contains('t' * 18),
        'provider_second': !capture(
          'sk-${'A' * 18} and sk-${'B' * 18}',
        ).contains('B' * 18),
      };
      final secondProbe = <String, bool>{
        'github_classic': !capture(
          'failed for ghp_${'C' * 30}',
        ).contains('C' * 30),
        'github_fine_grained': !capture(
          'failed for github_pat_${'D' * 30}',
        ).contains('D' * 30),
        'slack': !capture('rejected xoxb-${'E' * 24}').contains('E' * 24),
      };

      expect(
        firstProbe.values.every((v) => v),
        isTrue,
        reason: 'probe A measured a leak: $firstProbe',
      );
      expect(
        secondProbe.values.every((v) => v),
        isTrue,
        reason: 'probe B measured a leak: $secondProbe',
      );

      final result = Sprint117GaBlockerResolutionGate.evaluate(
        <Sprint117GaBlockerResolution>[
          Sprint117GaBlockerResolution(
            blockerId: 'ga-blocker-1',
            domain: 'security',
            resolved: true,
            rootCause: 'replaceFirstMapped redacted only the first match',
            fix: 'replaceAll across every pattern',
            tests: firstDefect,
            review: 'probe A: ${firstProbe.length} measurements, all pass',
            riskUpdate: 'second-class credentials previously persisted on disk',
            releaseNote: 'crash artifacts no longer retain a second credential',
          ),
          Sprint117GaBlockerResolution(
            blockerId: 'ga-blocker-2',
            domain: 'crash',
            resolved: true,
            rootCause: 'provider pattern required a dash; real formats use _',
            fix: 'separator alternation covering ghp_ github_pat_ xoxb-',
            tests: secondDefect,
            review: 'probe B: ${secondProbe.length} measurements, all pass',
            riskUpdate: 'named GitHub/Slack tokens were never candidates',
            releaseNote: 'crash sink now matches the canonical token formats',
          ),
        ],
        <Sprint117GaBlockerCheck>[
          Sprint117GaBlockerCheck.pass_(
            blockerId: 'ga-blocker-1',
            check: firstDefect,
            declared: 'every credential in a crash artifact is redacted',
            observed:
                '${firstProbe.values.where((v) => v).length}/'
                '${firstProbe.length} measured',
          ),
          Sprint117GaBlockerCheck.pass_(
            blockerId: 'ga-blocker-2',
            check: secondDefect,
            declared: 'real provider token formats are redacted',
            observed:
                '${secondProbe.values.where((v) => v).length}/'
                '${secondProbe.length} measured',
          ),
        ],
      );

      expect(result.failures, isEmpty, reason: result.failures.join(' | '));
      expect(result.verdict, Sprint117GaBlockerResolutionGate.passVerdict);
      expect(
        result.domainsMeasured,
        containsAll(<String>['security', 'crash']),
      );
      // JSON round-trip: the evidence file must stay machine-readable.
      expect(() => jsonEncode(result.toJson()), returnsNormally);
    });
  });
}
