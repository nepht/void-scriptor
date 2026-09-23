/// Update Channel & Delivery Validation (Step 113.40).
///
/// Domain contract for the seven canonical delivery acceptance items —
/// `update_metadata`, `signature_check`, `download`, `resume`, `retry`,
/// `disk_space_check`, and `rollback_channel` — plus the evaluation state
/// machine that decides whether the update channel is validated,
/// incomplete, or absent.
///
/// Download, resume, and retry are validated against local file-transfer
/// fixtures with real SHA-256 verification; a live CDN/ publication round
/// trip is out of scope until publication is approved by Choirudin.
library;

/// Canonical acceptance item names, in roadmap order.
const List<String> kUpdateChannelAcceptance = <String>[
  'update_metadata',
  'signature_check',
  'download',
  'resume',
  'retry',
  'disk_space_check',
  'rollback_channel',
];

/// Evaluation outcome of update-channel delivery validation.
enum UpdateChannelState {
  /// Every acceptance item is present and well-formed.
  pass,

  /// Some acceptance item is missing or malformed.
  fail,

  /// Nothing was recorded — nothing to evaluate.
  blocked,
}

/// Update metadata for a channel artifact.
class UpdateMetadata {
  const UpdateMetadata({
    this.channel,
    this.version,
    this.artifactPath,
    this.artifactSha256,
    this.artifactSizeBytes,
    this.previousVersion,
  });

  final String? channel;
  final String? version;
  final String? artifactPath;
  final String? artifactSha256;
  final int? artifactSizeBytes;
  final String? previousVersion;

  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  bool get isWellFormed {
    if (channel == null || channel!.trim().isEmpty) return false;
    if (version == null || version!.trim().isEmpty) return false;
    if (artifactPath == null || artifactPath!.trim().isEmpty) return false;
    if (artifactSha256 == null || !_sha256.hasMatch(artifactSha256!)) {
      return false;
    }
    if (artifactSizeBytes == null || artifactSizeBytes! <= 0) return false;
    return true;
  }
}

/// Result of a signature verification against the channel artifact.
class SignatureCheck {
  const SignatureCheck({
    this.status,
    this.verificationExitCode,
    this.thumbprint,
  });

  final String? status;
  final int? verificationExitCode;
  final String? thumbprint;

  static final RegExp _thumbprint = RegExp(r'^[A-F0-9]{40}$');

  bool get isWellFormed =>
      status == 'Valid' &&
      verificationExitCode == 0 &&
      thumbprint != null &&
      _thumbprint.hasMatch(thumbprint!);
}

/// Result of a (resumable) file transfer verified by SHA-256.
class TransferResult {
  const TransferResult({
    this.expectedSha256,
    this.actualSha256,
    this.receivedBytes,
    this.totalBytes,
    this.resumedFromBytes,
  });

  final String? expectedSha256;
  final String? actualSha256;
  final int? receivedBytes;
  final int? totalBytes;

  /// 0 for a fresh download; a positive offset for a resumed transfer.
  final int? resumedFromBytes;

  static final RegExp _sha256 = RegExp(r'^[0-9a-f]{64}$');

  bool get isComplete {
    if (expectedSha256 == null || !_sha256.hasMatch(expectedSha256!)) {
      return false;
    }
    if (actualSha256 == null || actualSha256 != expectedSha256) return false;
    if (totalBytes == null || totalBytes! <= 0) return false;
    if (receivedBytes == null || receivedBytes != totalBytes) return false;
    return true;
  }

  bool get isResumedComplete {
    final offset = resumedFromBytes;
    return isComplete && offset != null && offset > 0;
  }
}

/// Outcome of a bounded retry policy.
class RetryOutcome {
  const RetryOutcome({this.maxAttempts, this.attemptsUsed, this.succeeded});

  final int? maxAttempts;
  final int? attemptsUsed;
  final bool? succeeded;

  bool get isWellFormed {
    if (maxAttempts == null || maxAttempts! <= 0) return false;
    if (attemptsUsed == null || attemptsUsed! <= 0) return false;
    if (attemptsUsed! > maxAttempts!) return false;
    return succeeded == true && attemptsUsed! <= maxAttempts!;
  }
}

/// Disk-space precheck for the channel artifact.
class DiskSpaceCheck {
  const DiskSpaceCheck({this.requiredBytes, this.availableBytes});

  final int? requiredBytes;
  final int? availableBytes;

  bool get isSufficient =>
      requiredBytes != null &&
      availableBytes != null &&
      requiredBytes! > 0 &&
      availableBytes! >= requiredBytes!;
}

/// Rollback channel readiness: the previous version must be retained.
class RollbackChannel {
  const RollbackChannel({this.previousMetadata, this.previousManifestPath});

  final UpdateMetadata? previousMetadata;
  final String? previousManifestPath;

  bool get isWellFormed =>
      previousMetadata != null &&
      previousMetadata!.isWellFormed &&
      previousManifestPath != null &&
      previousManifestPath!.trim().isNotEmpty;

  /// Returns the metadata to restore on rollback, or null when rollback
  /// has no retained previous version.
  UpdateMetadata? resolve() => isWellFormed ? previousMetadata : null;
}

/// Immutable snapshot of the seven delivery acceptance items.
class UpdateChannelValidation {
  const UpdateChannelValidation({
    this.updateMetadata,
    this.signatureCheck,
    this.download,
    this.resume,
    this.retry,
    this.diskSpaceCheck,
    this.rollbackChannel,
  });

  final UpdateMetadata? updateMetadata;
  final SignatureCheck? signatureCheck;
  final TransferResult? download;
  final TransferResult? resume;
  final RetryOutcome? retry;
  final DiskSpaceCheck? diskSpaceCheck;
  final RollbackChannel? rollbackChannel;

  /// Returns the canonical names of acceptance items missing or malformed.
  static List<String> missingAcceptance(UpdateChannelValidation validation) {
    final missing = <String>[];
    if (validation.updateMetadata == null ||
        !validation.updateMetadata!.isWellFormed) {
      missing.add('update_metadata');
    }
    if (validation.signatureCheck == null ||
        !validation.signatureCheck!.isWellFormed) {
      missing.add('signature_check');
    }
    if (validation.download == null || !validation.download!.isComplete) {
      missing.add('download');
    }
    if (validation.resume == null || !validation.resume!.isResumedComplete) {
      missing.add('resume');
    }
    if (validation.retry == null || !validation.retry!.isWellFormed) {
      missing.add('retry');
    }
    if (validation.diskSpaceCheck == null ||
        !validation.diskSpaceCheck!.isSufficient) {
      missing.add('disk_space_check');
    }
    if (validation.rollbackChannel == null ||
        !validation.rollbackChannel!.isWellFormed) {
      missing.add('rollback_channel');
    }
    return missing;
  }

  /// Evaluates validation: null or unrecorded validation is
  /// [UpdateChannelState.blocked]; any missing acceptance item fails with
  /// the canonical names in its notes; complete validation passes and
  /// retains the version, channel, byte counts, and rollback target.
  static UpdateChannelEvaluation evaluate(UpdateChannelValidation? validation) {
    if (validation == null || _isUnrecorded(validation)) {
      return const UpdateChannelEvaluation(
        state: UpdateChannelState.blocked,
        notes: <String>['no update channel validation recorded'],
      );
    }

    final missing = missingAcceptance(validation);
    if (missing.isNotEmpty) {
      return UpdateChannelEvaluation(
        state: UpdateChannelState.fail,
        notes: <String>[
          'update channel validation incomplete: missing ${missing.join(', ')}',
        ],
      );
    }

    final metadata = validation.updateMetadata!;
    final notes = <String>[
      'version: ${metadata.version}',
      'channel: ${metadata.channel}',
      'signature_check: ${validation.signatureCheck!.status}',
      'download: ${validation.download!.receivedBytes} byte',
      'resume: offset ${validation.resume!.resumedFromBytes} byte',
      'retry: ${validation.retry!.attemptsUsed}/${validation.retry!.maxAttempts} attempt',
      'disk_space_check: ${validation.diskSpaceCheck!.availableBytes} '
          '>= ${validation.diskSpaceCheck!.requiredBytes} byte',
      'rollback_channel: ${metadata.previousVersion}',
    ];
    return UpdateChannelEvaluation(
      state: UpdateChannelState.pass,
      notes: notes,
    );
  }

  static bool _isUnrecorded(UpdateChannelValidation validation) {
    return validation.updateMetadata == null &&
        validation.signatureCheck == null &&
        validation.download == null &&
        validation.resume == null &&
        validation.retry == null &&
        validation.diskSpaceCheck == null &&
        validation.rollbackChannel == null;
  }
}

/// Result of evaluating [UpdateChannelValidation].
class UpdateChannelEvaluation {
  const UpdateChannelEvaluation({required this.state, required this.notes});

  final UpdateChannelState state;
  final List<String> notes;
}
