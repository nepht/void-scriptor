import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_transfer_controls.dart';

void main() {
  group('CloudTransferRequest', () {
    test('requires explicit consent and normalizes transfer metadata', () {
      final request = CloudTransferRequest(
        transferId: ' transfer-1 ',
        accountId: ' account-1 ',
        sourceScope: CloudTransferScope.local,
        destinationScope: CloudTransferScope.cloud,
        operation: CloudTransferOperation.deltaSync,
        totalBytes: 1024,
        explicitConsent: true,
      );

      expect(request.transferId, 'transfer-1');
      expect(request.accountId, 'account-1');
      expect(request.isResumable, isTrue);
      expect(request.requiresExplicitConsent, isTrue);
    });

    test('rejects a cloud transfer without explicit consent', () {
      expect(
        () => CloudTransferRequest(
          transferId: 'transfer-1',
          accountId: 'account-1',
          sourceScope: CloudTransferScope.local,
          destinationScope: CloudTransferScope.cloud,
          operation: CloudTransferOperation.upload,
          totalBytes: 1,
          explicitConsent: false,
        ),
        throwsArgumentError,
      );
    });

    test('tracks pause, resume, retry, and bounded progress', () {
      var transfer = CloudTransferProgress.start(totalBytes: 100);
      expect(transfer.state, CloudTransferState.running);

      transfer = transfer.pause();
      expect(transfer.state, CloudTransferState.paused);
      transfer = transfer.resume();
      transfer = transfer.advance(
        completedBytes: 40,
        bandwidthBytesPerSecond: 20,
      );
      expect(transfer.fraction, 0.4);
      expect(transfer.bandwidthBytesPerSecond, 20);
      expect(transfer.state, CloudTransferState.running);

      transfer = transfer.fail();
      transfer = transfer.retry();
      expect(transfer.retryCount, 1);
      expect(transfer.state, CloudTransferState.running);
      expect(() => transfer.advance(completedBytes: 101), throwsArgumentError);
    });

    test('rejects invalid progress transitions and retry limits', () {
      final complete = CloudTransferProgress.start(
        totalBytes: 10,
      ).advance(completedBytes: 10);
      expect(complete.state, CloudTransferState.completed);
      expect(() => complete.pause(), throwsStateError);
      expect(() => complete.retry(), throwsStateError);

      var failed = CloudTransferProgress.start(totalBytes: 10).fail();
      for (var i = 0; i < 3; i++) {
        failed = failed.retry();
        failed = failed.fail();
      }
      expect(() => failed.retry(), throwsStateError);
    });
  });
}
