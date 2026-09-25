/// Sprint 115.21 — Cloud Transfer & Sync Controls.
///
/// Local, provider-agnostic transfer contract. It models consent and control
/// state without claiming a live connector, network transfer, or credentials.
library;

enum CloudTransferScope { local, cloud, workspace }

enum CloudTransferOperation { upload, download, deltaSync }

enum CloudTransferState { running, paused, failed, completed }

final class CloudTransferRequest {
  CloudTransferRequest({
    required String transferId,
    required String accountId,
    required this.sourceScope,
    required this.destinationScope,
    required this.operation,
    required int totalBytes,
    required bool explicitConsent,
  }) : transferId = _required(transferId, 'transferId'),
       accountId = _required(accountId, 'accountId'),
       totalBytes = _nonNegative(totalBytes, 'totalBytes'),
       _explicitConsent = explicitConsent {
    if (sourceScope != destinationScope && !explicitConsent) {
      throw ArgumentError.value(explicitConsent, 'explicitConsent');
    }
  }

  final String transferId;
  final String accountId;
  final CloudTransferScope sourceScope;
  final CloudTransferScope destinationScope;
  final CloudTransferOperation operation;
  final int totalBytes;
  final bool _explicitConsent;

  bool get requiresExplicitConsent => sourceScope != destinationScope;
  bool get isResumable => true;
  bool get hasExplicitConsent => _explicitConsent;

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }

  static int _nonNegative(int value, String field) {
    if (value < 0) throw ArgumentError.value(value, field);
    return value;
  }
}

final class CloudTransferProgress {
  CloudTransferProgress._({
    required this.totalBytes,
    required this.completedBytes,
    required this.state,
    required this.bandwidthBytesPerSecond,
    required this.retryCount,
  });

  factory CloudTransferProgress.start({required int totalBytes}) {
    if (totalBytes <= 0) throw ArgumentError.value(totalBytes, 'totalBytes');
    return CloudTransferProgress._(
      totalBytes: totalBytes,
      completedBytes: 0,
      state: CloudTransferState.running,
      bandwidthBytesPerSecond: null,
      retryCount: 0,
    );
  }

  final int totalBytes;
  final int completedBytes;
  final CloudTransferState state;
  final int? bandwidthBytesPerSecond;
  final int retryCount;

  double get fraction => completedBytes / totalBytes;

  CloudTransferProgress pause() {
    if (state != CloudTransferState.running) {
      throw StateError('Only a running transfer can be paused.');
    }
    return _copy(state: CloudTransferState.paused);
  }

  CloudTransferProgress resume() {
    if (state != CloudTransferState.paused) {
      throw StateError('Only a paused transfer can be resumed.');
    }
    return _copy(state: CloudTransferState.running);
  }

  CloudTransferProgress advance({
    required int completedBytes,
    int? bandwidthBytesPerSecond,
  }) {
    if (state != CloudTransferState.running) {
      throw StateError('Only a running transfer can advance.');
    }
    if (completedBytes < this.completedBytes ||
        completedBytes > totalBytes ||
        bandwidthBytesPerSecond != null && bandwidthBytesPerSecond < 0) {
      throw ArgumentError.value(completedBytes, 'completedBytes');
    }
    return _copy(
      completedBytes: completedBytes,
      state: completedBytes == totalBytes
          ? CloudTransferState.completed
          : CloudTransferState.running,
      bandwidthBytesPerSecond: bandwidthBytesPerSecond,
    );
  }

  CloudTransferProgress fail() {
    if (state == CloudTransferState.completed) {
      throw StateError('A completed transfer cannot fail.');
    }
    return _copy(state: CloudTransferState.failed);
  }

  CloudTransferProgress retry() {
    if (state != CloudTransferState.failed) {
      throw StateError('Only a failed transfer can be retried.');
    }
    if (retryCount >= 3) throw StateError('Transfer retry limit reached.');
    return _copy(state: CloudTransferState.running, retryCount: retryCount + 1);
  }

  CloudTransferProgress _copy({
    int? completedBytes,
    CloudTransferState? state,
    int? bandwidthBytesPerSecond,
    int? retryCount,
  }) {
    return CloudTransferProgress._(
      totalBytes: totalBytes,
      completedBytes: completedBytes ?? this.completedBytes,
      state: state ?? this.state,
      bandwidthBytesPerSecond:
          bandwidthBytesPerSecond ?? this.bandwidthBytesPerSecond,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
