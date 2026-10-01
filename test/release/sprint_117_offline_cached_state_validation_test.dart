import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/account/domain/account_center_offline_mode.dart';
import 'package:void_scriptor/features/project_resilience/application/project_recovery_services.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_offline_cached_state_validation.dart';

/// 117.27 — drill Offline & Cached-State.
///
/// Mengukur enam area `required_evidence` kanonik (`cached_metadata`,
/// `freshness`, `remote_disabled`, `local_available`, `reconnect`,
/// `cache_clear`) langsung pada mekanisme yang di-ship, lalu menyerahkan
/// faktanya ke gate gagal-tertutup
/// [Sprint117OfflineStateValidation].
///
/// Semua cek berdasar nilai yang diukur, bukan deklarasi. Tidak ada wall
/// clock: setiap waktu yang dihitung berasal dari jam injeksi, dan cache
///_clear diukur pada package sementara yang dibuat di dalam test.
///
/// Umur negatif = bacaan bertimestamp di MASA DEPAN (bukan "5 menit lalu"),
/// jadi helper `_entry` meneruskan `Duration` apa adanya ke
/// [AccountCenterCachedEntry].

const String _manifestPath =
    'docs/evidence/sprint-117-27-manifest-20261001.json';

final DateTime _now = DateTime.utc(2026, 10, 1, 12);

Sprint117OfflineStateCheck _boolCheck({
  required String area,
  required String check,
  required bool ok,
  required String declared,
  required String observed,
  String note = '',
}) => ok
    ? Sprint117OfflineStateCheck.pass(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      )
    : Sprint117OfflineStateCheck.violation(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
        note: note,
      );

AccountCenterCachedEntry _entry(
  String id,
  Duration age, {
  String detail = 'reading',
}) => AccountCenterCachedEntry(
  providerId: id,
  label: id.toUpperCase(),
  measuredAt: _now.subtract(age),
  detail: detail,
);

/// Fakta terukur: verdict [ok] plus nilai yang benar-benar diamati.
typedef Fact = ({bool ok, String observed});

void main() {
  group('117.27 offline & cached-state validation', () {
    test('gate passes on facts measured from the shipped offline seam', () async {
      final checks = <Sprint117OfflineStateCheck>[];

      // ============================================================
      // 1-2. cached_metadata + freshness
      // ============================================================
      final offline = AccountCenterOfflineMode.cached(
        entries: <AccountCenterCachedEntry>[
          _entry('drive', const Duration(hours: 3), detail: 'fresh'),
          _entry('github', const Duration(days: 3), detail: 'old'),
          _entry('dropbox', const Duration(days: 30), detail: 'expired'),
          _entry('onedrive', const Duration(minutes: -5), detail: 'future'),
        ],
        now: _now,
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
      final byId = <String, AccountCenterCachedEntryView>{
        for (final view in offline.entries) view.providerId: view,
      };

      checks.add(
        _boolCheck(
          area: 'cached_metadata',
          check: 'every_cached_entry_keeps_its_own_identity',
          ok:
              byId.keys.length == 4 &&
              byId['drive']!.label == 'DRIVE' &&
              byId['github']!.detail == 'old',
          declared:
              'setiap entri cache membawa providerId/label/detail miliknya sendiri',
          observed:
              '${byId.keys.length} entri: '
              '${byId.entries.map((e) => '${e.key}=${e.value.detail}').join(', ')}',
          note: '115.44 AccountCenterCachedEntry',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'cached_metadata',
          check: 'absent_local_data_is_unavailable_not_zero',
          ok: _absentLocalDataFact().ok,
          declared:
              'detail lokal yang absen tetap unavailable, bukan nol karangan',
          observed: _absentLocalDataFact().observed,
          note: '115.44: absent summary stays null, never zero bytes',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'freshness',
          check: 'classify_separates_fresh_stale_expired_future',
          ok:
              byId['drive']!.freshness == AccountCenterOfflineFreshness.live &&
              byId['github']!.freshness ==
                  AccountCenterOfflineFreshness.stale &&
              byId['dropbox']!.freshness ==
                  AccountCenterOfflineFreshness.expired &&
              byId['onedrive']!.freshness ==
                  AccountCenterOfflineFreshness.futureTimestamped,
          declared: 'umur 3j/3h/30h/5m -> live/stale/expired/futureTimestamped',
          observed:
              '3j=${byId['drive']!.freshness.name} '
              '3d=${byId['github']!.freshness.name} '
              '30d=${byId['dropbox']!.freshness.name} '
              'kunu=${byId['onedrive']!.freshness.name}',
          note: '115.44 policy staleAfter=24h expiresAfter=7d',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'freshness',
          check: 'non_live_reading_always_carries_a_label',
          ok:
              byId['drive']!.staleLabel == null &&
              byId['github']!.staleLabel == 'Stale' &&
              byId['dropbox']!.staleLabel == 'Expired' &&
              byId['onedrive']!.staleLabel == 'Timestamped in the future' &&
              byId['drive']!.isUsable &&
              byId['github']!.isUsable &&
              !byId['dropbox']!.isUsable &&
              !byId['onedrive']!.isUsable,
          declared:
              'live tanpa label dan usable; stale usable tapi berlabel; '
              'expired/future tidak usable dan tetap berlabel',
          observed:
              'live=${byId['drive']!.staleLabel} '
              'stale=${byId['github']!.staleLabel} '
              'expired=${byId['dropbox']!.staleLabel} '
              'future=${byId['onedrive']!.staleLabel} '
              'futureUsable=${byId['onedrive']!.isUsable}',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'freshness',
          check: 'ttl_boundary_stays_fresh_and_past_it_stales',
          ok: _ttlBoundaryFact().ok,
          declared: 'umur tepat staleAfter masih live; 1 detik lewatnya stale',
          observed: _ttlBoundaryFact().observed,
          note: 'batas diukur pada jam injeksi, bukan label pilihan',
        ),
      );

      // ============================================================
      // 3. remote_disabled
      // ============================================================
      final refusals = <String>[];
      for (final action in AccountCenterRemoteAction.values) {
        final result = offline.performRemoteAction(action);
        refusals.add(
          '${action.name}=allowed:${result.allowed},completed:${result.completed}',
        );
      }
      checks.add(
        _boolCheck(
          area: 'remote_disabled',
          check: 'every_remote_action_refused_while_offline',
          ok:
              refusals.every(
                (r) =>
                    r.contains('allowed:false') &&
                    r.contains('completed:false'),
              ) &&
              offline.remoteActionsEnabled == false,
          declared:
              'ketua aksi remote ditolak fail-closed dan tidak pernah selesai',
          observed: refusals.join(' | '),
          note: '7 aksi dari AccountCenterRemoteAction',
        ),
      );

      // ============================================================
      // 4. local_available
      // ============================================================
      checks.add(
        _boolCheck(
          area: 'local_available',
          check: 'device_scoped_data_survives_the_offline_session',
          ok:
              offline.localSettingsAvailable &&
              offline.localSettingsCount == 1 &&
              offline.localSettings.single.value == 'Void Purple, dark' &&
              offline.localStorageAvailable &&
              offline.localStorage!.totalBytes == 12884901888 &&
              offline.localStorage!.largestCategory == 'assets',
          declared:
              'local settings dan local storage tetap terbaca saat offline',
          observed:
              'settings=${offline.localSettingsCount} '
              'storage=${offline.localStorageAvailable} '
              'bytes=${offline.localStorage?.totalBytes} '
              'category=${offline.localStorage?.largestCategory}',
          note:
              '115.44 acceptance local_settings_available/local_storage_available',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'local_available',
          check: 'nonsensical_local_detail_is_refused_at_the_boundary',
          ok: _nonsensicalLocalDetailFact().ok,
          declared:
              'detail lokal yang tidak masuk akal ditolak di sumber, bukan diteruskan',
          observed: _nonsensicalLocalDetailFact().observed,
          note:
              'label kosong / byte negatif tidak boleh jadi keputusan kontrak',
        ),
      );

      // ============================================================
      // 5. reconnect
      // ============================================================
      final plan = offline.reconnectPlan();
      checks.add(
        _boolCheck(
          area: 'reconnect',
          check: 'plan_is_explicit_before_it_happens',
          ok:
              plan.requiresNetworkConnection &&
              plan.replacesCache &&
              !plan.discardsLocalData &&
              plan.preservesLocalSettings &&
              plan.preservesLocalStorage &&
              plan.affectedProviders.length == 4,
          declared:
              'rencana reconnect dinyatakan dulu: butuh jaringan, ganti cache, '
              'buang data lokal = tidak',
          observed:
              'needsNetwork=${plan.requiresNetworkConnection} '
              'replaces=${plan.replacesCache} '
              'discardsLocal=${plan.discardsLocalData} '
              'providers=${plan.affectedProviders.length}',
          note: '115.44 AccountCenterReconnectPlan',
        ),
      );
      final after = plan.apply(
        freshEntries: <AccountCenterCachedEntry>[
          _entry('drive', Duration.zero, detail: 'live'),
        ],
        now: _now,
      );
      checks.add(
        _boolCheck(
          area: 'reconnect',
          check: 'refresh_replaces_cache_and_keeps_local_data',
          ok:
              !after.isOffline &&
              after.remoteActionsEnabled &&
              after.isFullyFresh &&
              after.staleEntryCount == 0 &&
              after.localSettingsCount == 1 &&
              after.localStorage!.totalBytes == 12884901888,
          declared:
              'setelah reconnect: cache=live, aksi remote hidup, local data utuh',
          observed:
              'offline=${after.isOffline} '
              'remote=${after.remoteActionsEnabled} '
              'fresh=${after.isFullyFresh} '
              'stale=${after.staleEntryCount} '
              'settings=${after.localSettingsCount} '
              'storage=${after.localStorage?.totalBytes}',
        ),
      );
      checks.add(
        _boolCheck(
          area: 'reconnect',
          check: 'state_notice_matches_the_actual_connection_state',
          ok: _noticeStateFact(offline, after).ok,
          declared:
              'notice menyatakan offline/konek + berapa bacaan basi, dan catatan '
              '"remote actions disabled" hanya muncul saat memang offline',
          observed: _noticeStateFact(offline, after).observed,
          note:
              'defect 117.27: notice tetap mengklaim remote disabled '
              'setelah reconnect berhasil',
        ),
      );

      // ============================================================
      // 6. cache_clear
      // ============================================================
      final cleared = await _clearCacheOnTemporaryPackage();
      checks.add(
        _boolCheck(
          area: 'cache_clear',
          check: 'clear_removes_every_cached_entry_not_just_the_top_level',
          ok: cleared.startsWith('ok|'),
          declared:
              'clear mengosongkan cache sampai entri bersarang dan tetap idempoten',
          observed: cleared,
          note: 'ProjectCacheService.clear pada package sementara',
        ),
      );

      // ============================================================
      // EVALUASI GATE
      // ============================================================
      final result = Sprint117OfflineStateValidation.evaluate(checks);
      final dump = checks
          .map(
            (c) =>
                '${c.status.name} ${c.code} declared=${c.declared} '
                'observed=${c.observed}',
          )
          .join('\n');
      expect(result.pass, isTrue, reason: 'failures=${result.failures}\n$dump');
      expect(
        result.checks.map((c) => c.area).toSet(),
        Sprint117OfflineStateValidation.requiredAreas.toSet(),
        reason: 'enam area required_evidence harus terukur',
      );
      expect(
        result.violationCodes,
        isEmpty,
        reason: result.violationCodes.join(', '),
      );

      final writeManifest =
          Platform.environment['SPRINT_117_27_MANIFEST'] == '1';
      if (writeManifest) {
        File(_manifestPath).writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(result.toJson())}\n',
        );
      }
    });

    test('gate fails closed on structural holes', () {
      List<Sprint117OfflineStateCheck> minimal() => [
        for (final area in Sprint117OfflineStateValidation.requiredAreas)
          Sprint117OfflineStateCheck.pass(
            area: area,
            check: 'probe',
            declared: 'decl',
            observed: 'obs',
          ),
      ];

      expect(
        Sprint117OfflineStateValidation.evaluate(const []).pass,
        isFalse,
        reason: 'no_checks',
      );
      expect(Sprint117OfflineStateValidation.evaluate(minimal()).pass, isTrue);

      final withoutCacheClear = minimal()
          .where((c) => c.area != 'cache_clear')
          .toList();
      final resMissing = Sprint117OfflineStateValidation.evaluate(
        withoutCacheClear,
      );
      expect(resMissing.pass, isFalse);
      expect(resMissing.failures, contains('missing_area:cache_clear'));

      final withUnknown = [
        ...minimal(),
        Sprint117OfflineStateCheck.pass(
          area: 'sync_health',
          check: 'foo',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resUnknown = Sprint117OfflineStateValidation.evaluate(withUnknown);
      expect(resUnknown.pass, isFalse);
      expect(resUnknown.failures, contains('unknown_area:sync_health'));

      final withDup = [
        ...minimal(),
        Sprint117OfflineStateCheck.pass(
          area: 'freshness',
          check: 'probe',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resDup = Sprint117OfflineStateValidation.evaluate(withDup);
      expect(resDup.pass, isFalse);
      expect(resDup.failures, contains('duplicate_check:freshness:probe'));

      final withVac = [
        for (final c in minimal())
          if (c.area == 'freshness')
            Sprint117OfflineStateCheck.pass(
              area: 'freshness',
              check: 'probe',
              declared: '  ',
              observed: '',
            )
          else
            c,
      ];
      final resVac = Sprint117OfflineStateValidation.evaluate(withVac);
      expect(resVac.pass, isFalse);
      expect(
        resVac.failures,
        containsAll([
          'vacuous_declared:freshness:probe',
          'vacuous:freshness:probe',
        ]),
      );

      final withoutPass = [
        for (final c in minimal())
          if (c.area == 'reconnect')
            Sprint117OfflineStateCheck.unmet(
              area: 'reconnect',
              check: 'probe',
              declared: 'd',
              observed: 'o',
            )
          else
            c,
      ];
      final resNoPass = Sprint117OfflineStateValidation.evaluate(withoutPass);
      expect(resNoPass.pass, isFalse);
      expect(resNoPass.failures, contains('area_without_pass:reconnect'));

      final withViolation = [
        ...minimal(),
        Sprint117OfflineStateCheck.violation(
          area: 'remote_disabled',
          check: 'bad',
          declared: 'd',
          observed: 'o',
        ),
      ];
      final resViol = Sprint117OfflineStateValidation.evaluate(withViolation);
      expect(resViol.pass, isFalse);
      expect(resViol.failures, contains('violation:remote_disabled:bad'));
    });
  });
}

Fact _absentLocalDataFact() {
  final empty = AccountCenterOfflineMode.cached(
    entries: const <AccountCenterCachedEntry>[],
    now: _now,
  );
  final ok =
      !empty.localSettingsAvailable &&
      !empty.localStorageAvailable &&
      empty.localStorage == null;
  return (
    ok: ok,
    observed:
        'settings=${empty.localSettingsAvailable} '
        'storage=${empty.localStorageAvailable} '
        'storageIsNull=${empty.localStorage == null}',
  );
}

Fact _ttlBoundaryFact() {
  final policy = AccountCenterOfflineFreshnessPolicy();
  final atBoundary = AccountCenterOfflineMode.cached(
    entries: <AccountCenterCachedEntry>[
      _entry('drive', const Duration(hours: 24)),
    ],
    now: _now,
    policy: policy,
  );
  final past = AccountCenterOfflineMode.cached(
    entries: <AccountCenterCachedEntry>[
      _entry('drive', const Duration(hours: 24, seconds: 1)),
    ],
    now: _now,
    policy: policy,
  );
  final atLabel = atBoundary.entries.single.freshness.name;
  final pastLabel = past.entries.single.freshness.name;
  return (
    ok: atLabel == 'live' && pastLabel == 'stale',
    observed: 'tepat 24j=$atLabel, 24j+1s=$pastLabel',
  );
}

Fact _nonsensicalLocalDetailFact() {
  try {
    AccountCenterOfflineMode.cached(
      entries: const <AccountCenterCachedEntry>[],
      now: _now,
      localSettings: const <AccountCenterLocalSetting>[
        AccountCenterLocalSetting(id: 'theme', label: '   ', value: ''),
      ],
      localStorage: const AccountCenterLocalStorageDetails(
        totalBytes: -1,
        largestCategory: '',
      ),
    );
  } on ArgumentError {
    return (ok: true, observed: 'ArgumentError saat konstruksi');
  }
  return (
    ok: false,
    observed: 'label="   ", value="", totalBytes=-1, category="" diterima',
  );
}

Fact _noticeStateFact(
  AccountCenterOfflineMode offline,
  AccountCenterOfflineMode after,
) {
  final offlineNotice = offline.notice;
  final afterNotice = after.notice;
  final ok =
      offlineNotice.contains('Offline') &&
      offlineNotice.contains('4 connection(s)') &&
      offlineNotice.contains('3 of 4') &&
      offlineNotice.contains('Remote actions are disabled') &&
      afterNotice.contains('Connected') &&
      afterNotice.contains('1 live reading(s)') &&
      !afterNotice.contains('Remote actions are disabled');
  return (ok: ok, observed: 'offline=$offlineNotice | after=$afterNotice');
}

Future<String> _clearCacheOnTemporaryPackage() async {
  final root = await Directory.systemTemp.createTemp('hermes-11727-');
  try {
    final ProjectPackage package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'OfflineCacheClear');

    final flat = File(p.join(package.cacheDirectory.path, 'preview.tmp'))
      ..writeAsStringSync('flat');
    final nestedDir = Directory(
      p.join(package.cacheDirectory.path, 'thumbnails'),
    )..createSync(recursive: true);
    final nested = File(p.join(nestedDir.path, 'a.bin'))
      ..writeAsBytesSync(<int>[1, 2, 3]);
    final deepDir = Directory(p.join(nestedDir.path, 'deep'))
      ..createSync(recursive: true);
    final deep = File(p.join(deepDir.path, 'b.bin'))
      ..writeAsBytesSync(<int>[4, 5, 6]);

    await ProjectCacheService(package).clear();
    final leftovers = await package.cacheDirectory.exists()
        ? (await package.cacheDirectory.list().toList()).length
        : 0;
    // Idempoten: pemanggilan kedua pada cache yang sudah kosong tidak melempar.
    await ProjectCacheService(package).clear();

    final ok =
        !flat.existsSync() &&
        !nested.existsSync() &&
        !deep.existsSync() &&
        leftovers == 0;
    final detail =
        'leftovers=$leftovers flat=${flat.existsSync()} '
        'nested=${nested.existsSync()} deep=${deep.existsSync()} '
        'repeatClear=noThrow';
    return ok ? 'ok|$detail' : 'RESIDUE|$detail';
  } finally {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}
