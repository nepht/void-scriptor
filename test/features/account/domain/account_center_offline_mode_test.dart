/// Sprint 115.44 — Offline Account Center.
///
/// Pins the canonical step, the freshness vocabulary taken from the 115.40/115.41
/// contracts, and the offline behaviour required by the sprint: cached metadata
/// with a stale label, remote actions disabled fail-closed, device-scoped local
/// settings and local storage details still available, and an explicit
/// reconnect-and-refresh plan.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_offline_mode.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_115_offline_account_center.json',
  );
  const canonicalStepsPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  final now = DateTime.utc(2026, 9, 27, 2, 0);

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue, reason: '115.44 manifest');
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  test('pins the canonical step and acceptance vocabulary', () {
    final manifest = readManifest();
    expect(manifest['canonical_step'], '115.44');
    expect(manifest['title'], 'Offline Account Center');
    expect(
      manifest['acceptance'],
      AccountCenterOfflineMode.canonicalAcceptance,
    );
    expect(
      AccountCenterOfflineMode.canonicalSprintSha256,
      canonicalSprintSha256,
    );
  });

  test('acceptance matches the canonical sprint step definition', () {
    final file = File(canonicalStepsPath);
    expect(file.existsSync(), isTrue, reason: 'canonical sprint_115.json');
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final steps = document['steps'] as List<dynamic>;
    final step = steps.cast<Map<String, dynamic>>().firstWhere(
      (entry) => entry['id'] == '115.44',
    );
    expect(step['title'], 'Offline Account Center');
    expect(
      step['acceptance'],
      AccountCenterOfflineMode.canonicalAcceptance,
      reason: 'acceptance must be transcribed, not invented',
    );
    expect(
      sha256.convert(file.readAsBytesSync()).toString(),
      canonicalSprintSha256,
      reason: 'canonical sprint hash drift',
    );
  });

  test('cached metadata keeps a freshness label instead of a live claim', () {
    final policy = AccountCenterOfflineFreshnessPolicy();
    final mode = AccountCenterOfflineMode.cached(
      entries: <AccountCenterCachedEntry>[
        AccountCenterCachedEntry(
          providerId: 'drive',
          label: 'Work Drive',
          measuredAt: now.subtract(const Duration(hours: 3)),
          detail: '2.4 GB of 15 GB used',
        ),
        AccountCenterCachedEntry(
          providerId: 'github',
          label: 'GitHub',
          measuredAt: now.subtract(const Duration(days: 3)),
          detail: '412 repositories linked',
        ),
        AccountCenterCachedEntry(
          providerId: 'dropbox',
          label: 'Dropbox',
          measuredAt: now.add(const Duration(minutes: 5)),
          detail: '1.1 GB of 2 GB used',
        ),
      ],
      policy: policy,
      now: now,
      localSettings: const <AccountCenterLocalSetting>[
        AccountCenterLocalSetting(
          id: 'theme',
          label: 'Appearance',
          value: 'Void Purple, dark',
        ),
      ],
      localStorage: const AccountCenterLocalStorageDetails(
        totalBytes: 12884901888,
        largestCategory: 'assets',
      ),
    );

    expect(mode.isOffline, isTrue);
    expect(mode.cachedEntryCount, 3);
    expect(mode.isFullyFresh, isFalse);

    final byId = <String, AccountCenterCachedEntryView>{
      for (final view in mode.entries) view.providerId: view,
    };
    expect(byId['drive']!.freshness, AccountCenterOfflineFreshness.live);
    expect(byId['github']!.freshness, AccountCenterOfflineFreshness.stale);
    expect(
      byId['dropbox']!.freshness,
      AccountCenterOfflineFreshness.futureTimestamped,
    );

    expect(
      byId['drive']!.isUsable,
      isTrue,
      reason: 'a live cached reading is still shown while offline',
    );
    expect(
      byId['github']!.isUsable,
      isTrue,
      reason: 'a stale cached reading is still shown, but always with a label',
    );
    expect(
      byId['dropbox']!.isUsable,
      isFalse,
      reason: 'a future timestamp is a defect and is not presented as a value',
    );
    expect(byId['github']!.staleLabel, 'Stale');
    expect(byId['drive']!.staleLabel, isNull);
    expect(
      byId['dropbox']!.staleLabel,
      'Timestamped in the future',
      reason: 'a future timestamp is a data defect, not a fresh reading',
    );
    expect(mode.notice, contains('Offline'));
    expect(mode.notice, contains('2 of 3'), reason: 'stale count is explicit');
  });

  test('remote actions are disabled fail-closed and name the action', () {
    final mode = AccountCenterOfflineMode.cached(
      entries: const <AccountCenterCachedEntry>[],
      now: now,
    );

    for (final action in AccountCenterRemoteAction.values) {
      final result = mode.performRemoteAction(action);
      expect(result.allowed, isFalse, reason: 'offline: $action');
      expect(
        result.reason,
        'Offline mode. ${action.label} needs a network connection.',
      );
      expect(result.completed, isFalse);
    }
    expect(
      mode.remoteActionsEnabled,
      isFalse,
      reason: 'no remote action may be enabled while offline',
    );
  });

  test('local settings and local storage stay available offline', () {
    final mode = AccountCenterOfflineMode.cached(
      entries: const <AccountCenterCachedEntry>[],
      now: now,
      localSettings: const <AccountCenterLocalSetting>[
        AccountCenterLocalSetting(
          id: 'theme',
          label: 'Appearance',
          value: 'Void Purple, dark',
        ),
        AccountCenterLocalSetting(
          id: 'startup',
          label: 'Startup behaviour',
          value: 'Restore last workspace',
        ),
      ],
      localStorage: const AccountCenterLocalStorageDetails(
        totalBytes: 12884901888,
        largestCategory: 'assets',
      ),
    );

    expect(mode.localSettingsAvailable, isTrue);
    expect(mode.localSettingsCount, 2);
    expect(mode.localSettings.first.label, 'Appearance');
    expect(mode.localSettings.first.value, 'Void Purple, dark');
    expect(mode.localStorageAvailable, isTrue);
    expect(mode.localStorage!.totalBytes, 12884901888);
    expect(mode.localStorage!.largestCategory, 'assets');

    final empty = AccountCenterOfflineMode.cached(
      entries: const <AccountCenterCachedEntry>[],
      now: now,
    );
    expect(empty.localSettingsAvailable, isFalse);
    expect(empty.localStorageAvailable, isFalse);
    expect(
      empty.localStorage,
      isNull,
      reason: 'absent local storage is unavailable, never a fabricated zero',
    );
    expect(empty.notice, contains('unavailable'));
  });

  test(
    'reconnect and refresh is explicit, replaces the cache, keeps local data',
    () {
      final before = AccountCenterOfflineMode.cached(
        entries: <AccountCenterCachedEntry>[
          AccountCenterCachedEntry(
            providerId: 'drive',
            label: 'Work Drive',
            measuredAt: now.subtract(const Duration(hours: 30)),
            detail: 'stale reading',
          ),
        ],
        now: now,
        localSettings: const <AccountCenterLocalSetting>[
          AccountCenterLocalSetting(
            id: 'theme',
            label: 'Appearance',
            value: 'Void Purple, dark',
          ),
        ],
        localStorage: const AccountCenterLocalStorageDetails(
          totalBytes: 12884901888,
          largestCategory: 'assets',
        ),
      );
      expect(
        before.entries.first.freshness,
        AccountCenterOfflineFreshness.stale,
      );

      final plan = before.reconnectPlan();
      expect(plan.requiresNetworkConnection, isTrue);
      expect(plan.replacesCache, isTrue);
      expect(plan.discardsLocalData, isFalse);
      expect(plan.preservesLocalSettings, isTrue);
      expect(plan.preservesLocalStorage, isTrue);
      expect(plan.label, 'Reconnect and refresh');
      expect(plan.affectedProviders, ['drive']);

      final after = plan.apply(
        freshEntries: <AccountCenterCachedEntry>[
          AccountCenterCachedEntry(
            providerId: 'drive',
            label: 'Work Drive',
            measuredAt: now,
            detail: '2.9 GB of 15 GB used',
          ),
        ],
        now: now,
      );
      expect(after.isOffline, isFalse);
      expect(after.remoteActionsEnabled, isTrue);
      expect(
        after.entries.single.freshness,
        AccountCenterOfflineFreshness.live,
      );
      expect(after.entries.single.staleLabel, isNull);
      expect(
        after.localSettings.single.value,
        'Void Purple, dark',
        reason: 'reconnect must not touch device-scoped settings',
      );
      expect(after.localStorage!.totalBytes, 12884901888);
    },
  );

  test('rejects blank identities, duplicate providers, and empty details', () {
    expect(
      () => AccountCenterCachedEntry(
        providerId: '  ',
        label: 'Drive',
        measuredAt: now,
        detail: 'x',
      ),
      throwsArgumentError,
    );
    expect(
      () => AccountCenterCachedEntry(
        providerId: 'drive',
        label: 'Drive',
        measuredAt: now,
        detail: ' ',
      ),
      throwsArgumentError,
    );
    expect(
      () => AccountCenterOfflineMode.cached(
        entries: <AccountCenterCachedEntry>[
          AccountCenterCachedEntry(
            providerId: 'drive',
            label: 'Drive',
            measuredAt: now,
            detail: 'a',
          ),
          AccountCenterCachedEntry(
            providerId: 'drive',
            label: 'Drive (again)',
            measuredAt: now,
            detail: 'b',
          ),
        ],
        now: now,
      ),
      throwsArgumentError,
      reason: 'one provider cannot appear twice in the cache',
    );
    expect(
      () => AccountCenterOfflineFreshnessPolicy(
        staleAfter: const Duration(hours: 5),
        expiresAfter: const Duration(hours: 2),
      ),
      throwsArgumentError,
    );
  });
}
