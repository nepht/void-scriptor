import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/privacy_policy.dart';
import 'package:void_scriptor/core/observability/local_usage_journal.dart';
import 'package:void_scriptor/features/intent/domain/sensor_privacy.dart';
import 'package:intl/intl.dart';

void main() {
  group('Privacy Revalidation 113.27', () {
    late LocalUsageJournal journal;

    setUp(() {
      journal = LocalUsageJournal(storageDirectory: Directory.systemTemp.createTempSync('void_privacy_'));
      journal.enabled = true;
    });

    tearDown(() {
      journal.clear();
    });

    // ---- Data Flow ----
    test('data_flow: journal records only whitelisted fields', () {
      // Note: journal.enabled = true in setUp auto-records journal_opted_in (audit trail)
      // so entries.length starts at 1 before record() adds the featured event
      journal.record('feature_surface_viewed', fields: {
        'title': 'Secret Novel Chapter 1',
        'excerpt': 'once upon a time in the void...',
        'durationMs': 1200,
      });
      expect(journal.entries.length, 2);  // journal_opted_in + feature_surface_viewed
      final f = journal.entries.last.fields;
      expect(f.containsKey('title'), isFalse);
      expect(f.containsKey('excerpt'), isFalse);
      expect(f['durationMs'], 1200);
    });

    test('data_flow: unknown event type rejected', () {
      expect(() => journal.record('not_a_real_event'),
          throwsArgumentError);
    });

    // ---- Consent Results ----
    test('consent_results: InputConsent revoked blocks voice', () {
      final policy = PrivacyPolicy(
          consent: InputConsent(voice: true, revoked: true));
      final result =
          policy.evaluate(const PrivacyRequest(input: InputPermission.voice));
      expect(result.allowed, isFalse);
      expect(result.reason, PrivacyDenialReason.consentRevoked);
    });

    test('consent_results: InputConsent active allows voice', () {
      final policy = PrivacyPolicy(consent: InputConsent(voice: true));
      final result =
          policy.evaluate(const PrivacyRequest(input: InputPermission.voice));
      expect(result.allowed, isTrue);
      expect(result.requiresConfirmation, isFalse);
      expect(result.reason, isNull);
    });

    // ---- Telemetry Results ----
    test('telemetry_results: SensorPrivacyPolicy retention session records', () {
      final policy = SensorPrivacyPolicy();
      policy.grant(SensorType.voice);
      policy.setRetention(SensorRetention.session);
      policy.record(SensorType.voice, 'test payload');
      expect(policy.records.length, 1);
    });

    test('telemetry_results: SensorPrivacyPolicy retention none drops records', () {
      final policy = SensorPrivacyPolicy();
      policy.grant(SensorType.voice);
      policy.setRetention(SensorRetention.none);
      policy.record(SensorType.voice, 'test payload');
      expect(policy.records, isEmpty);
    });

    // ---- Metadata Results ----
    test('metadata_results: LocalUsageJournal whitelist only', () {
      journal.enabled = true;
      journal.record(
          'flag_changed',
          fields: {'flag': 'vs12_plot_board', 'outcome': 'enabled'});
      expect(journal.entries.length, 2); // journal_opted_in + flag_changed
      expect(journal.entries.last.fields['flag'], 'vs12_plot_board');
      expect(journal.entries.last.fields['outcome'], 'enabled');
    });

    test('metadata_results: non-whitelisted content fields dropped', () {
      journal.enabled = true;
      journal.record(
          'feature_surface_viewed',
          fields: {
            'title': 'Secret Novel Chapter 1',
            'excerpt': 'once upon a time in the void...',
            'durationMs': 1200,
          });
      expect(journal.entries.length, 2);
      final f = journal.entries.last.fields;
      expect(f.containsKey('title'), isFalse,
          reason: 'content-ish field must never be stored');
      expect(f.containsKey('excerpt'), isFalse,
          reason: 'content-ish field must never be stored');
      expect(f['durationMs'], 1200,
          reason: 'metadata within whitelist is fine');
    });

    // ---- Retention Results ----
    test('retention_results: SensorRetention.session keeps records', () {
      final policy = SensorPrivacyPolicy();
      policy.grant(SensorType.gaze);
      policy.setRetention(SensorRetention.session);
      policy.record(SensorType.gaze, 'gaze data');
      expect(policy.records.length, 1);
    });

    test('retention_results: SensorRetention.none discards immediately', () {
      final policy = SensorPrivacyPolicy();
      policy.grant(SensorType.gesture);
      policy.setRetention(SensorRetention.none);
      policy.record(SensorType.gesture, 'gesture data');
      expect(policy.records, isEmpty);
    });

    // ---- Deletion Results ----
    test('deletion_results: journal.clear() wipes history', () {
      journal.enabled = true;
      journal.record('app_open');
      expect(journal.entries, isNotEmpty);
      journal.clear();
      expect(journal.entries, isEmpty);
    });

    test('deletion_results: journal reset after opt-out', () {
      journal.enabled = false;
      expect(journal.enabled, isFalse);
      journal.enabled = true;
      expect(journal.enabled, isTrue);
      journal.record('app_open');
      journal.clear();
      expect(journal.entries, isEmpty);
    });

    // ---- Sharing Results ----
    test('sharing_results: PrivacyDecision constructs with allowed/reason', () {
      final allowedDecision =
          const PrivacyDecision(allowed: true, requiresConfirmation: false);
      expect(allowedDecision.allowed, isTrue);
      expect(allowedDecision.requiresConfirmation, isFalse);
      expect(allowedDecision.reason, isNull);

      final deniedDecision =
          const PrivacyDecision(allowed: false, requiresConfirmation: false,
              reason: PrivacyDenialReason.consentRequired);
      expect(deniedDecision.allowed, isFalse);
      expect(deniedDecision.requiresConfirmation, isFalse);
      expect(deniedDecision.reason, PrivacyDenialReason.consentRequired);
    });

    // ---- Revoke Tests ----
    test('revoke_tests: SensorPrivacyPolicy revoke removes from allowed + recording', () {
      final policy = SensorPrivacyPolicy();
      policy.grant(SensorType.voice);
      policy.grant(SensorType.gaze);
      policy.startRecording(SensorType.voice);
      expect(policy.isRecording, true);
      policy.revoke(SensorType.voice);
      expect(policy.isRecording, false);
      expect(policy.records.length, 0);
      expect(!policy.isAllowed(SensorType.voice), isTrue);
      expect(policy.isAllowed(SensorType.gaze), isTrue);
    });
  });
}