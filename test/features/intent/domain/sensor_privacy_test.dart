import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/sensor_privacy.dart';

void main() {
  test(
    'permission is denied by default and recording indicator follows it',
    () {
      final policy = SensorPrivacyPolicy();
      expect(policy.isAllowed(SensorType.voice), isFalse);
      policy.grant(SensorType.voice);
      expect(policy.isAllowed(SensorType.voice), isTrue);
      expect(RecordingIndicator(policy).isRecording, isFalse);
      policy.startRecording(SensorType.voice);
      expect(RecordingIndicator(policy).isRecording, isTrue);
      policy.stopRecording();
      expect(RecordingIndicator(policy).isRecording, isFalse);
    },
  );

  test(
    'local processing and retention are explicit and payload is not stored',
    () {
      final policy = SensorPrivacyPolicy();
      expect(policy.localProcessingOnly, isTrue);
      policy.setLocalProcessingOnly(false);
      expect(policy.localProcessingOnly, isFalse);
      policy.setRetention(SensorRetention.none);
      policy.record(SensorType.bci, 'raw-secret');
      expect(policy.records, isEmpty);
    },
  );

  test('revoking permission stops recording immediately', () {
    final policy = SensorPrivacyPolicy()..grant(SensorType.gaze);
    policy.startRecording(SensorType.gaze);
    policy.revoke(SensorType.gaze);
    expect(policy.isRecording, isFalse);
    expect(policy.isAllowed(SensorType.gaze), isFalse);
  });
}
