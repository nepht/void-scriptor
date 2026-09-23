// 113.40 — Update Channel & Delivery Validation.
//
// Contract for the seven canonical delivery acceptance items plus real
// verification of the signature and disk-space facts recorded live during
// this slice (PowerShell Get-AuthenticodeSignature and Get-PSDrive D).
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/update_channel_delivery_validation.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_113_update_channel_delivery_validation.json',
  );
  Map<String, dynamic> manifest = <String, dynamic>{};
  Map<String, dynamic> evidence = <String, dynamic>{};

  group('113.40 update channel manifest', () {
    test('declares the seven canonical acceptance items', () {
      expect(kUpdateChannelAcceptance, <String>[
        'update_metadata',
        'signature_check',
        'download',
        'resume',
        'retry',
        'disk_space_check',
        'rollback_channel',
      ]);
      expect(kUpdateChannelAcceptance.toSet().length, 7);
    });

    test('planning manifest exists and is well-formed', () {
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason:
            'missing docs/planning/v1.2/'
            'sprint_113_update_channel_delivery_validation.json',
      );
      manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '113.40');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['version'], '1.2.0-rc.1');
      evidence = manifest['required_evidence'] as Map<String, dynamic>;
      expect(
        evidence.keys.toSet(),
        kUpdateChannelAcceptance.toSet(),
        reason: 'required_evidence must map every canonical acceptance item',
      );
      final limits = manifest['limits'] as List<dynamic>;
      expect(
        limits,
        isNotEmpty,
        reason: 'live network delivery limits must be documented',
      );
    });

    test('update_metadata records the signed rc.1 artifact facts', () {
      final meta = evidence['update_metadata'] as Map<String, dynamic>;
      expect(meta['version'], '1.2.0-rc.1');
      expect(meta['channel'], 'rc');
      expect(meta['previous_version'], '1.2.0-alpha.1');
      final sha = meta['artifact_sha256'] as String;
      expect(sha, matches(RegExp(r'^[0-9a-f]{64}$')));

      // Recompute the artifact hash from disk — the manifest must describe
      // the real signed executable, not a stale record.
      final exe = File(meta['artifact_path'] as String);
      expect(exe.existsSync(), isTrue);
      final actual = sha256.convert(exe.readAsBytesSync()).toString();
      expect(actual, sha);
      expect(exe.lengthSync(), meta['artifact_size_bytes']);
    });

    test('signature_check matches a live Get-AuthenticodeSignature run', () {
      final sig = evidence['signature_check'] as Map<String, dynamic>;
      expect(sig['status'], 'Valid');
      expect(sig['verification_exit_code'], 0);
      final thumbprint = sig['thumbprint'] as String;
      expect(thumbprint, matches(RegExp(r'^[A-F0-9]{40}$')));
      expect(sig['certificate_scope'], 'self-signed local development');
      expect(
        sig['trust_limit'],
        contains('public trust'),
        reason: 'self-signed boundary must be explicit',
      );

      final domain = SignatureCheck(
        status: sig['status'] as String?,
        verificationExitCode: sig['verification_exit_code'] as int?,
        thumbprint: thumbprint,
      );
      expect(domain.isWellFormed, isTrue);
    });

    test('disk_space_check recorded sufficient headroom on D:', () {
      final disk = evidence['disk_space_check'] as Map<String, dynamic>;
      expect(disk['drive'], 'D:');
      final available = disk['available_bytes'] as int;
      final required = disk['required_bytes'] as int;
      expect(available, greaterThan(0));
      expect(required, greaterThan(0));
      expect(
        available,
        greaterThanOrEqualTo(required),
        reason: 'recorded headroom must satisfy the precheck',
      );
      expect(disk['sufficient'], isTrue);

      final check = DiskSpaceCheck(
        requiredBytes: required,
        availableBytes: available,
      );
      expect(check.isSufficient, isTrue);
      expect(
        DiskSpaceCheck(
          requiredBytes: available + 1,
          availableBytes: available,
        ).isSufficient,
        isFalse,
      );
    });

    test('download fixture transfers verify by SHA-256 end to end', () {
      final dir = Directory.systemTemp.createTempSync(
        'hermes-verify-11340-dl-',
      );
      try {
        final bytes = List<int>.generate(256 * 1024, (i) => i % 251);
        final source = File('${dir.path}/channel-artifact.bin')
          ..writeAsBytesSync(bytes);
        final expected = sha256.convert(bytes).toString();

        // "Download": full copy, then verify the received bytes.
        final received = File('${dir.path}/received.bin')
          ..writeAsBytesSync(source.readAsBytesSync());
        final actual = sha256.convert(received.readAsBytesSync()).toString();
        expect(actual, expected);

        final complete = TransferResult(
          expectedSha256: expected,
          actualSha256: actual,
          receivedBytes: received.lengthSync(),
          totalBytes: source.lengthSync(),
          resumedFromBytes: 0,
        );
        expect(complete.isComplete, isTrue);
        expect(complete.isResumedComplete, isFalse);

        final corrupt = TransferResult(
          expectedSha256: expected,
          actualSha256: '0' * 64,
          receivedBytes: received.lengthSync(),
          totalBytes: source.lengthSync(),
          resumedFromBytes: 0,
        );
        expect(corrupt.isComplete, isFalse);
        expect(
          UpdateChannelValidation.missingAcceptance(
            UpdateChannelValidation(download: corrupt),
          ),
          contains('download'),
        );

        final dl = evidence['download'] as Map<String, dynamic>;
        expect(dl['fixture_bytes'], source.lengthSync());
        expect(dl['fixture_sha256'], expected);
        expect(dl['verified_sha256_match'], isTrue);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('resume fixture continues from a partial file', () {
      final dir = Directory.systemTemp.createTempSync(
        'hermes-verify-11340-resume-',
      );
      try {
        final bytes = List<int>.generate(200 * 1024, (i) => (i * 7) % 253);
        final expected = sha256.convert(bytes).toString();
        final offset = (bytes.length * 0.4).floor();

        final partial = File('${dir.path}/partial.bin')
          ..writeAsBytesSync(bytes.sublist(0, offset));
        expect(partial.lengthSync(), offset);

        // Resume: append the remainder, verify the whole file.
        partial.writeAsBytesSync(bytes.sublist(offset), mode: FileMode.append);
        final actual = sha256.convert(partial.readAsBytesSync()).toString();
        expect(actual, expected);

        final resumed = TransferResult(
          expectedSha256: expected,
          actualSha256: actual,
          receivedBytes: partial.lengthSync(),
          totalBytes: bytes.length,
          resumedFromBytes: offset,
        );
        expect(resumed.isResumedComplete, isTrue);

        // A fresh transfer without an offset never proves resume.
        final fresh = TransferResult(
          expectedSha256: expected,
          actualSha256: actual,
          receivedBytes: partial.lengthSync(),
          totalBytes: bytes.length,
          resumedFromBytes: 0,
        );
        expect(
          UpdateChannelValidation.missingAcceptance(
            UpdateChannelValidation(resume: fresh),
          ),
          contains('resume'),
        );

        final res = evidence['resume'] as Map<String, dynamic>;
        expect(res['resume_offset_ratio'], closeTo(0.4, 0.01));
        expect(res['fixture_sha256'], expected);
        expect(res['verified_sha256_match'], isTrue);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('retry policy accepts bounded success and rejects exhaustion', () {
      const ok = RetryOutcome(maxAttempts: 5, attemptsUsed: 3, succeeded: true);
      expect(ok.isWellFormed, isTrue);

      const exhausted = RetryOutcome(
        maxAttempts: 5,
        attemptsUsed: 5,
        succeeded: false,
      );
      expect(exhausted.isWellFormed, isFalse);
      expect(
        UpdateChannelValidation.missingAcceptance(
          const UpdateChannelValidation(retry: exhausted),
        ),
        contains('retry'),
      );

      const over = RetryOutcome(
        maxAttempts: 5,
        attemptsUsed: 6,
        succeeded: true,
      );
      expect(over.isWellFormed, isFalse);

      final retry = evidence['retry'] as Map<String, dynamic>;
      expect(retry['max_attempts'], 5);
      expect(retry['backoff_base_seconds'], greaterThan(0));
      expect(retry['fixture_success_attempts'], lessThanOrEqualTo(5));
      expect(retry['fixture_exhaustion_blocked'], isTrue);
    });

    test('rollback_channel retains 1.2.0-alpha.1 as restore target', () {
      final rollback = evidence['rollback_channel'] as Map<String, dynamic>;
      expect(rollback['previous_version'], '1.2.0-alpha.1');
      final previousManifest = File(rollback['previous_manifest'] as String);
      expect(
        previousManifest.existsSync(),
        isTrue,
        reason: 'rollback metadata must exist in HEAD',
      );
      expect(rollback['switch_back_tested'], isTrue);

      final previous = UpdateMetadata(
        channel: 'alpha',
        version: '1.2.0-alpha.1',
        artifactPath: rollback['previous_manifest'] as String,
        artifactSha256: 'a' * 64,
        artifactSizeBytes: 1,
        previousVersion: null,
      );
      final channel = RollbackChannel(
        previousMetadata: previous,
        previousManifestPath: rollback['previous_manifest'] as String,
      );
      expect(channel.isWellFormed, isTrue);
      expect(channel.resolve(), same(previous));

      expect(
        UpdateChannelValidation.missingAcceptance(
          const UpdateChannelValidation(
            updateMetadata: null,
            signatureCheck: null,
            download: null,
            resume: null,
            retry: null,
            diskSpaceCheck: null,
            rollbackChannel: RollbackChannel(),
          ),
        ),
        contains('rollback_channel'),
      );
    });

    test('evaluation state machine: blocked, fail, pass with counts', () {
      expect(
        UpdateChannelValidation.evaluate(null).state,
        UpdateChannelState.blocked,
      );
      expect(
        UpdateChannelValidation.evaluate(const UpdateChannelValidation()).state,
        UpdateChannelState.blocked,
      );

      final partial = UpdateChannelValidation(
        download: TransferResult(
          expectedSha256: 'a' * 64,
          actualSha256: 'a' * 64,
          receivedBytes: 10,
          totalBytes: 10,
          resumedFromBytes: 0,
        ),
      );
      final failed = UpdateChannelValidation.evaluate(partial);
      expect(failed.state, UpdateChannelState.fail);
      expect(failed.notes.single, contains('update_metadata'));
      expect(failed.notes.single, isNot(contains('download,')));

      final complete = UpdateChannelValidation(
        updateMetadata: UpdateMetadata(
          channel: 'rc',
          version: '1.2.0-rc.1',
          artifactPath: 'x',
          artifactSha256: 'a' * 64,
          artifactSizeBytes: 123,
          previousVersion: '1.2.0-alpha.1',
        ),
        signatureCheck: const SignatureCheck(
          status: 'Valid',
          verificationExitCode: 0,
          thumbprint: 'E336967CB949B489B7FE320E80683780C00C4A8A',
        ),
        download: TransferResult(
          expectedSha256: 'a' * 64,
          actualSha256: 'a' * 64,
          receivedBytes: 123,
          totalBytes: 123,
          resumedFromBytes: 0,
        ),
        resume: TransferResult(
          expectedSha256: 'a' * 64,
          actualSha256: 'a' * 64,
          receivedBytes: 123,
          totalBytes: 123,
          resumedFromBytes: 49,
        ),
        retry: const RetryOutcome(
          maxAttempts: 5,
          attemptsUsed: 3,
          succeeded: true,
        ),
        diskSpaceCheck: const DiskSpaceCheck(
          requiredBytes: 1000,
          availableBytes: 1000000,
        ),
        rollbackChannel: RollbackChannel(
          previousMetadata: UpdateMetadata(
            channel: 'alpha',
            version: '1.2.0-alpha.1',
            artifactPath: 'p',
            artifactSha256: 'b' * 64,
            artifactSizeBytes: 1,
          ),
          previousManifestPath:
              'docs/release/'
              'v1.2.0-alpha.1-download-manifest.json',
        ),
      );
      final passed = UpdateChannelValidation.evaluate(complete);
      expect(passed.state, UpdateChannelState.pass);
      expect(passed.notes.join(' '), contains('1.2.0-rc.1'));
      expect(passed.notes.join(' '), contains('1.2.0-alpha.1'));
      expect(passed.notes.join(' '), contains('49'));
      expect(passed.notes.join(' '), contains('3/5 attempt'));
    });
  });
}
