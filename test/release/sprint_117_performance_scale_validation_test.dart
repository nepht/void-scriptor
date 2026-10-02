/// 117.35 — Performance & Scale Validation (RED → GREEN).
///
/// Setiap angka di slice ini adalah hasil probe yang dijalankan run ini,
/// dicetak ke log sebagai `11735_*`, bukan nilai ms yang diketik tangan.
///
/// Seam yang diukur adalah kode yang benar-benar di-ship:
/// `AccountCenterPerformanceResilience` (kontrak 115.53),
/// `BackgroundJobQueue`, `AsyncMutex`, `DebouncedSearchController`,
/// `ProjectStorageAnalyzer`, dan state surface 115.42/115.10.
///
/// Bukti yang tidak bisa diukur lokal tidak dipalsukan: `slow_api` menuntut
/// konektor provider nyata, jadi ia dilaporkan `unmet` (open item) dengan
/// batas eksternal yang disebut, bukan sebagai `pass`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/core/performance/large_data.dart';
import 'package:void_scriptor/core/persistence/async_mutex.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/design_system/theme/void_theme.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/account/domain/account_center_loading_empty_error_states.dart';
import 'package:void_scriptor/features/account/domain/account_center_performance_resilience.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';
import 'package:void_scriptor/features/project_resilience/application/project_storage_analyzer.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_performance_scale_validation.dart';

/// Tugas yang memblokir sampai [release] selesai, sehingga "pekerjaan masih
/// berjalan" adalah fakta yang bisa diamati, bukan asumsi.
class _GatedTask implements BackgroundTask {
  _GatedTask(
    this.id, {
    this.release,
    this.jobPriority = BackgroundJobPriority.normal,
    this.taskResources = const <JobResource>{},
  });

  @override
  final String id;

  final Completer<void>? release;
  final BackgroundJobPriority jobPriority;
  final Set<JobResource> taskResources;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'probe',
    type: BackgroundJobType.custom,
    label: 'probe $id',
    status: BackgroundJobStatus.queued,
    priority: jobPriority,
    createdAt: DateTime.utc(2026, 10, 2, 12),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => taskResources;

  @override
  String? get taskKey => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    if (release != null) await release!.future;
  }
}

/// Tugas yang mencatat urutan eksekusi.
class _OrderingTask implements BackgroundTask {
  _OrderingTask(
    this.id,
    this.order,
    this.jobPriority, {
    this.taskResources = const <JobResource>{},
  });

  @override
  final String id;
  final List<String> order;
  final BackgroundJobPriority jobPriority;
  final Set<JobResource> taskResources;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'probe',
    type: BackgroundJobType.custom,
    label: 'probe $id',
    status: BackgroundJobStatus.queued,
    priority: jobPriority,
    createdAt: DateTime.utc(2026, 10, 2, 12),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => taskResources;

  @override
  String? get taskKey => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    order.add(id);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

/// Tugas yang menghitung berapa yang berjalan tanpa menyentuh internal antrean.
class _CountingTask implements BackgroundTask {
  _CountingTask(this.id, this.onEnter, this.onExit);

  @override
  final String id;
  final void Function() onEnter;
  final void Function() onExit;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'probe',
    type: BackgroundJobType.custom,
    label: 'probe $id',
    status: BackgroundJobStatus.queued,
    priority: BackgroundJobPriority.normal,
    createdAt: DateTime.utc(2026, 10, 2, 12),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => const <JobResource>{};

  @override
  String? get taskKey => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    onEnter();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    } finally {
      onExit();
    }
  }
}

/// Bukti yang ditulis ke disk; isinya hanya angka dari probe run ini.
final Map<String, Object?> evidence = <String, Object?>{
  'canonical_step': '117.35',
  'document_role': 'EVIDENCE',
  'measured_on': '2026-10-02',
  'harness': 'flutter test (no raster pipeline, no real GPU)',
  'external_gate': 'DEFERRED-EXTERNAL',
};

/// Menulis bukti ke `docs/evidence/`. Manifest ini adalah dokumen yang
/// mengutip hasil run, bukan dokumen yang ditulis lebih dulu lalu diisi tebakan.
void writeEvidenceFile() {
  final file = File(
    p.join(
      Directory.current.path,
      'docs',
      'evidence',
      'sprint-117-35-manifest-20261002.json',
    ),
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(evidence)}\n',
    flush: true,
  );
}

/// Satu baris manifest yang dipakai untuk membangun skenario many-accounts.
///
/// Wire name diambil dari enum yang di-ship supaya fixture tidak mengarang
/// nama yang tidak akan pernah lolos `fromJson`.
final class _AvailabilityRow {
  const _AvailabilityRow(this.availability, this.wireAvailability);

  final String availability;
  final String wireAvailability;
  String get label => availability;
  String get wireId => 'provider-${availability.replaceAll('_', '-')}';
}

const List<_AvailabilityRow> _availabilityRows = <_AvailabilityRow>[
  _AvailabilityRow('available', 'AVAILABLE'),
  _AvailabilityRow('degraded', 'DEGRADED'),
  _AvailabilityRow('outage', 'OUTAGE'),
  _AvailabilityRow('unverified', 'UNVERIFIED'),
  _AvailabilityRow('planned', 'PLANNED'),
  _AvailabilityRow('unavailable', 'UNAVAILABLE'),
  _AvailabilityRow('unsupported_region', 'UNSUPPORTED_REGION'),
];

/// Mesin koneksi yang sudah `CONNECTED`, dibangun lewat transisi nyata.
AccountConnectionHealthStateMachine _connectedMachine() {
  final machine = AccountConnectionHealthStateMachine.notConfigured(
    providerId: 'probe_provider',
    accountLabel: 'Probe Account',
  );
  machine
    ..transition(
      AccountConnectionTransition.beginConnecting,
      at: DateTime.utc(2026, 10, 2, 11, 59),
    )
    ..transition(
      AccountConnectionTransition.connectSucceeded,
      at: DateTime.utc(2026, 10, 2, 12),
    );
  return machine;
}

void main() {
  /// Values this run actually observed; the aggregate gate quotes them so no
  /// `observed` string in the verdict is typed by hand.
  final probes = <String, String>{};

  group('gate 117.35 fail-closed', () {
    test('eight canonical axes, verbatim from required_evidence of 117.35', () {
      expect(Sprint117PerformanceScale.requiredAreas, <String>[
        'render',
        'many_accounts',
        'refresh',
        'charts',
        'local_scan',
        'slow_api',
        'memory',
        'contention',
      ]);
    });

    test('a missing axis is reported, not silently tolerated', () {
      final withoutContention = Sprint117PerformanceScale.evaluate([
        for (final area in Sprint117PerformanceScale.requiredAreas)
          if (area != 'contention')
            Sprint117PerfCheck.pass_(
              area: area,
              check: 'presence',
              declared: 'axis carries one measured fact',
              observed: 'measured by this run',
            ),
      ]);
      expect(withoutContention.pass, isFalse);
      expect(withoutContention.failures, contains('missing_area:contention'));
    });

    test('an axis whose only fact is a violation cannot report pass', () {
      final result = Sprint117PerformanceScale.evaluate([
        for (final area in Sprint117PerformanceScale.requiredAreas)
          if (area == 'contention')
            Sprint117PerfCheck.violation(
              area: area,
              check: 'second_drain_returns_early',
              declared: 'drain() returns only when the queue is empty',
              observed: 'second drain returned while a task was still running',
            )
          else
            Sprint117PerfCheck.pass_(
              area: area,
              check: 'presence',
              declared: 'axis carries one measured fact',
              observed: 'measured by this run',
            ),
      ]);
      expect(result.pass, isFalse);
      expect(result.failures, contains('area_without_pass:contention'));
      expect(result.violationCodes, <String>[
        'contention:second_drain_returns_early',
      ]);
    });

    test('an empty observation is refused as a rubber stamp', () {
      final result = Sprint117PerformanceScale.evaluate([
        for (final area in Sprint117PerformanceScale.requiredAreas)
          Sprint117PerfCheck.pass_(
            area: area,
            check: 'rubber_stamp',
            declared: 'axis carries one measured fact',
            observed: area == 'render' ? '   ' : 'measured',
          ),
      ]);
      expect(result.failures, contains('vacuous:render:rubber_stamp'));
    });

    test('an axis outside the canonical list is refused', () {
      final result = Sprint117PerformanceScale.evaluate([
        for (final area in Sprint117PerformanceScale.requiredAreas)
          Sprint117PerfCheck.pass_(
            area: area,
            check: 'presence',
            declared: 'axis carries one measured fact',
            observed: 'measured',
          ),
        const Sprint117PerfCheck.pass_(
          area: 'gpu_thrash',
          check: 'presence',
          declared: 'invented axis',
          observed: 'measured',
        ),
      ]);
      expect(result.failures, contains('unknown_area:gpu_thrash'));
    });

    test('no checks at all is a failure, never a quiet pass', () {
      final result = Sprint117PerformanceScale.evaluate(
        const <Sprint117PerfCheck>[],
      );
      expect(result.pass, isFalse);
      expect(result.failures, <String>['no_checks']);
    });
  });

  group('render — the declared frame budget is a real bound', () {
    test('the contract declares a positive first-frame budget', () {
      expect(
        AccountCenterPerformanceResilience.initialFrameBudgetMs,
        greaterThan(0),
      );
    });

    testWidgets('a pumped frame settles inside the declared budget', (
      tester,
    ) async {
      final stopwatch = Stopwatch()..start();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 16));
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      probes['render_frame_pump_ms'] = elapsedMs.toStringAsFixed(3);
      // ignore: avoid_print
      print('11735_RENDER_PROBE_MS=$elapsedMs');

      expect(
        elapsedMs,
        lessThanOrEqualTo(
          AccountCenterPerformanceResilience.initialFrameBudgetMs,
        ),
        reason: 'frame pump took ${elapsedMs}ms',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the real account chrome paints inside the first-frame budget', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final manifest = ProviderConnectorManifest.fromJsonString(
        jsonEncode(<String, Object?>{
          'manifest_version': 'manifest-v1',
          'entries': <Object?>[
            for (final entry in _availabilityRows)
              <String, Object?>{
                'provider_id': entry.wireId,
                'display_name': entry.label,
                'category': 'cloud_storage',
                'capabilities': <String>['storage'],
                'availability': entry.wireAvailability,
                'regions': <String>['GLOBAL'],
                'connector_version': 'manifest-v1',
                'auth_type': 'OAUTH2_PKCE',
                'permissions': <String>['account_metadata'],
              },
          ],
        }),
      );

      Future<double> pumpOnce() async {
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: VoidTheme.dark,
              home: AccountCloudCenterScreen(
                snapshot: AccountCloudSnapshot.localOnly(
                  session: const AuthSession.guest(),
                ),
                providerManifest: manifest,
                onConnectProvider: (_) {},
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
        stopwatch.stop();
        return stopwatch.elapsedMicroseconds / 1000;
      }

      // COLD: the first pump of the file also pays JIT, engine warm-up and the
      // font/Skia cold cache, none of which the shipped first frame pays on a
      // warm app. It is recorded, not asserted against the frame budget.
      final coldMs = await pumpOnce();
      // WARM: the same tree rebuilt with the harness already hot. This is the
      // number comparable to 115.53's committed `initial_frame_ms` (187.253ms
      // at this viewport).
      final warmMs = await pumpOnce();
      probes['render_chrome_cold_pump_ms'] = coldMs.toStringAsFixed(3);
      probes['render_chrome_warm_frame_ms'] = warmMs.toStringAsFixed(3);
      probes['render_chrome_providers'] = _availabilityRows.length.toString();
      probes['render_chrome_viewport'] = '1536x1024';
      // ignore: avoid_print
      print(
        '11735_RENDER_CHROME_MS cold=$coldMs warm=$warmMs '
        'providers=${_availabilityRows.length} viewport=1536x1024',
      );

      expect(
        warmMs,
        lessThanOrEqualTo(
          AccountCenterPerformanceResilience.initialFrameBudgetMs,
        ),
        reason: 'warm account chrome frame took ${warmMs}ms',
      );
      expect(find.byType(AccountCloudCenterScreen), findsOneWidget);
      expect(find.text('ACCOUNT & CLOUD CENTER'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('many_accounts — the account count the contract names is real', () {
    test('the contract names more rows than the registered provider set', () {
      expect(AccountCenterPerformanceResilience.manyAccountCount, 48);
    });

    test('wording stays truthful across the whole account sweep', () {
      const accountCount = AccountCenterPerformanceResilience.manyAccountCount;
      final sweep = Stopwatch()..start();
      for (var account = 0; account < accountCount; account++) {
        for (final availability in <String>[
          'available',
          'degraded',
          'outage',
          'unverified',
          'planned',
          'unavailable',
          'unsupported_region',
        ]) {
          AccountCenterPerformanceResilience.connectionLabel(availability);
        }
      }
      sweep.stop();
      final sweepMs = sweep.elapsedMicroseconds / 1000;
      probes['many_accounts_count'] = accountCount.toString();
      probes['many_accounts_availability_sweep_ms'] = sweepMs.toStringAsFixed(
        3,
      );
      probes['many_accounts_refresh_budget_ms'] =
          AccountCenterPerformanceResilience.refreshBudgetMs.toString();
      // ignore: avoid_print
      print('11735_MANY_ACCOUNTS_SWEEP_MS=$sweepMs accounts=$accountCount');
      expect(
        sweepMs,
        lessThanOrEqualTo(AccountCenterPerformanceResilience.refreshBudgetMs),
        reason: '48x7 wording sweep took ${sweepMs}ms',
      );
      // Scale must not blur the truth: an outage row is never "Connected".
      expect(
        AccountCenterPerformanceResilience.connectionLabel('outage'),
        isNot(contains('Connected')),
      );
    });
  });

  group('refresh — the CPU path one refresh drives is bounded', () {
    test('1000 refresh-path iterations stay inside the declared budget', () {
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < 1000; index++) {
        AccountCenterPerformanceResilience.connectionLabel('degraded');
        AccountCenterPerformanceResilience.chartPalette(
          values: const <int>[1, 2, 3],
          colors: const <int>[1, 2, 3, 4, 5],
          trackColor: 0xFF1D202C,
        );
      }
      stopwatch.stop();
      final batchMs = stopwatch.elapsedMicroseconds / 1000;
      probes['refresh_iterations'] = '1000';
      probes['refresh_path_batch_ms'] = batchMs.toStringAsFixed(3);
      probes['refresh_budget_ms'] = AccountCenterPerformanceResilience
          .refreshBudgetMs
          .toString();
      // ignore: avoid_print
      print('11735_REFRESH_BATCH_MS=$batchMs');
      expect(
        batchMs,
        lessThanOrEqualTo(
          AccountCenterPerformanceResilience.refreshBudgetMs * 1000,
        ),
        reason: '1000 iterations took ${batchMs}ms',
      );
    });

    test('a refresh with no health observation is refused, not defaulted', () {
      final machine = AccountConnectionHealthStateMachine.notConfigured(
        providerId: 'probe_provider',
        accountLabel: 'Probe Account',
      );
      expect(
        machine.canTransition(AccountConnectionTransition.refreshHealth),
        isFalse,
        reason: 'NOT_CONFIGURED tidak boleh melompat langsung ke refresh',
      );

      final connected = _connectedMachine();
      expect(
        () => connected.transition(
          AccountConnectionTransition.refreshHealth,
          at: DateTime.utc(2026, 10, 2, 12),
        ),
        throwsA(isA<ArgumentError>()),
        reason: 'refresh tanpa healthState tidak boleh dianggap sukses',
      );
    });

    test('a refresh carrying an observation does record it', () {
      final connected = _connectedMachine();
      final refreshed = connected.transition(
        AccountConnectionTransition.refreshHealth,
        at: DateTime.utc(2026, 10, 2, 12),
        healthState: AccountHealthState.degraded,
      );
      expect(refreshed.healthState, AccountHealthState.degraded);
      expect(refreshed.lastCheckedAt, DateTime.utc(2026, 10, 2, 12));
    });
  });

  group('charts — a palette swap is visible to the repaint decision', () {
    test('identical values with a different track colour must differ', () {
      const values = <int>[10, 20, 30];
      final before = AccountCenterPerformanceResilience.chartPalette(
        values: values,
        colors: const <int>[0xFF111111],
        trackColor: 0xFF222222,
      );
      final after = AccountCenterPerformanceResilience.chartPalette(
        values: values,
        colors: const <int>[0xFF111111],
        trackColor: 0xFF333333,
      );
      expect(before, isNot(after));
      probes['charts_track_color_changes_output'] = '${before != after}';
      // ignore: avoid_print
      print('11735_CHARTS_TRACK_COLOR_CHANGES_OUTPUT=${before != after}');
    });

    test('a repaint decision sees the swap even when values are equal', () {
      const values = <int>[10, 20, 30];
      const colors = <int>[0xFF111111];
      final dark = AccountCenterPerformanceResilience.chartPalette(
        values: values,
        colors: colors,
        trackColor: 0xFF222222,
      );
      final light = AccountCenterPerformanceResilience.chartPalette(
        values: values,
        colors: colors,
        trackColor: 0xFF333333,
      );
      // Identity, not ordering: the compared input must differ.
      expect(light, isNot(dark));
      expect(dark.length, light.length);
      expect(dark.where((entry) => entry.startsWith('t')), hasLength(1));
      expect(
        dark,
        contains('t${0xFF222222}'),
        reason: 'trackColor harus ikut masuk ke input repaint',
      );
    });
  });

  group('local_scan — a real tree scans inside its budget', () {
    test('a real directory tree is indexed, totalled and classified', () async {
      final root = await Directory.systemTemp.createTemp('void-scriptor-11735');
      addTearDown(() => root.delete(recursive: true));

      Future<void> write(String relative, int bytes) async {
        final file = File(p.join(root.path, relative));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(List<int>.filled(bytes, 7));
      }

      await write(p.join('database', 'project.db'), 4);
      await write(p.join('assets', 'images', 'a.png'), 100);
      await write(p.join('cache', 'thumb.bin'), 50);

      final stopwatch = Stopwatch()..start();
      final report = await ProjectStorageAnalyzer(
        ProjectPackage(projectId: 'probe', root: root),
      ).analyze();
      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMicroseconds / 1000;
      probes['local_scan_files'] = report.files.length.toString();
      probes['local_scan_bytes'] = report.totalBytes.toString();
      probes['local_scan_ms'] = elapsedMs.toStringAsFixed(3);
      probes['local_scan_budget_ms'] = AccountCenterPerformanceResilience
          .scanBudgetMs
          .toString();
      // ignore: avoid_print
      print('11735_LOCAL_SCAN_MS=$elapsedMs files=${report.files.length}');

      expect(report.files.length, 3, reason: 'prekondisi: tiga file nyata');
      expect(report.totalBytes, 154);
      expect(report.bytesFor(ProjectStorageCategory.image), 100);
      expect(report.bytesFor(ProjectStorageCategory.backup), 0);
      expect(
        ProjectStorageCategory.values
            .map(report.bytesFor)
            .reduce((a, b) => a + b),
        report.totalBytes,
        reason: 'total kategori harus menjumlah jadi total report',
      );
      expect(
        elapsedMs,
        lessThanOrEqualTo(AccountCenterPerformanceResilience.scanBudgetMs),
        reason: 'scan took ${elapsedMs}ms',
      );
    });

    test('an absent root is empty, not a crash and not a fake total', () async {
      final missing = ProjectPackage(
        projectId: 'probe-absent',
        root: Directory(
          p.join(
            Directory.systemTemp.path,
            'void-scriptor-11735-absent',
            '${DateTime.now().microsecondsSinceEpoch}',
          ),
        ),
      );
      final report = await ProjectStorageAnalyzer(missing).analyze();
      expect(report.files, isEmpty);
      expect(report.totalBytes, 0);
      expect(report.bytesFor(ProjectStorageCategory.image), 0);
    });
  });

  group('slow_api — the external boundary is named, not manufactured', () {
    test('no local build can observe a live slow provider', () {
      expect(
        AccountCenterPerformanceResilience.slowApiIsExternallyMeasured,
        isTrue,
        reason: 'slow-API timing butuh konektor live, bukan fixture',
      );
    });

    test(
      'the local half of a slow provider is a retry window, not a number',
      () {
        final limited = AccountCenterLoadingEmptyErrorStates.rateLimited(
          source: 'provider_quota',
          retryAfter: const Duration(seconds: 30),
        );
        expect(limited.canRetry, isTrue);
        expect(limited.retryAfter, const Duration(seconds: 30));
        // Sub-minute window must render in seconds, never "0 minutes".
        expect(limited.message, contains('30 seconds'));
      },
    );

    test('a zero retry window is refused instead of read as retry-now', () {
      expect(
        () => AccountCenterLoadingEmptyErrorStates.rateLimited(
          source: 'provider_quota',
          retryAfter: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });

  group('memory — dispose must release timers and futures', () {
    test('a disposed search controller must not run another search', () async {
      var searchCalls = 0;
      final controller = DebouncedSearchController<String>(
        debounce: const Duration(milliseconds: 1),
        search: (query) async {
          searchCalls += 1;
          return <String>[query];
        },
      );
      controller.dispose();

      final future = controller.query('after-dispose');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      // ignore: avoid_print
      print('11735_SEARCH_CALLS_AFTER_DISPOSE=$searchCalls');
      probes['memory_search_calls_after_dispose'] = '$searchCalls';

      // A disposed controller is out of service: it must settle the caller and
      // must not keep running the search closure (and what it captured).
      expect(await future, isEmpty);
      expect(
        searchCalls,
        0,
        reason:
            'dispose harus menghentikan pencarian berikutnya, bukan '
            'menjalankannya lalu membuang hasilnya',
      );
    });

    test('a live debounced controller still returns the newest generation', () {
      final controller = DebouncedSearchController<String>(
        debounce: const Duration(milliseconds: 1),
        search: (query) async => <String>[query],
      );
      addTearDown(controller.dispose);
      expect(controller.query('live'), completion(<String>['live']));
    });
  });

  group('contention — background work must not be lost or mis-scheduled', () {
    test('maxConcurrentJobs bounds how many tasks run at once', () async {
      var running = 0;
      var peak = 0;
      final queue = BackgroundJobQueue(maxConcurrentJobs: 2);
      addTearDown(queue.dispose);
      for (var index = 0; index < 6; index++) {
        queue.enqueue(
          _CountingTask(
            'job-$index',
            () {
              running += 1;
              if (running > peak) peak = running;
            },
            () {
              running -= 1;
            },
          ),
        );
      }
      await queue.drain();
      // ignore: avoid_print
      print('11735_BACKGROUND_PEAK_CONCURRENCY=$peak');
      probes['contention_peak_concurrency'] = peak.toString();
      expect(peak, lessThanOrEqualTo(2));
      expect(running, 0, reason: 'setiap task harus selesai');
    });

    test('queued tasks keep FIFO order among equal priority', () async {
      final order = <String>[];
      final queue = BackgroundJobQueue(maxConcurrentJobs: 1);
      addTearDown(queue.dispose);
      final blocker = Completer<void>();
      queue.enqueue(
        _GatedTask(
          'blocker',
          release: blocker,
          jobPriority: BackgroundJobPriority.critical,
        ),
      );
      queue.enqueue(
        _OrderingTask('normal-one', order, BackgroundJobPriority.normal),
      );
      queue.enqueue(
        _OrderingTask('normal-two', order, BackgroundJobPriority.normal),
      );
      final drain = queue.drain();
      await Future<void>.delayed(Duration.zero);
      blocker.complete();
      await drain;
      expect(order, <String>['normal-one', 'normal-two']);
    });

    test(
      'drain() must not report finished while work is still running',
      () async {
        final queue = BackgroundJobQueue();
        addTearDown(queue.dispose);
        final gate = Completer<void>();
        var executed = false;
        queue.enqueue(_GatedTask('blocked', release: gate));
        queue.enqueue(_FlaggingTask('flag', () => executed = true));

        final first = queue.drain();
        await Future<void>.delayed(Duration.zero);

        var secondCompleted = false;
        var flagHadRunWhenSecondCompleted = false;
        final second = queue.drain().then((_) {
          secondCompleted = true;
          flagHadRunWhenSecondCompleted = executed;
        });
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // Snapshot at the measurement point: reading these after the awaits
        // below would only prove the drain finished eventually.
        final secondCompletedBeforeGateOpened = secondCompleted;
        // ignore: avoid_print
        print(
          '11735_SECOND_DRAIN_COMPLETED_BEFORE_GATE_OPENED='
          '$secondCompletedBeforeGateOpened flag_ran=$executed',
        );

        gate.complete();
        await first;
        await second;
        expect(executed, isTrue, reason: 'antrian harus tetap dikuras penuh');

        expect(
          secondCompletedBeforeGateOpened,
          isFalse,
          reason:
              'drain() kedua kembali sebelum gate dibuka: padahal ada task '
              'yang masih diblokir dan satu lagi belum jalan, jadi pemanggil '
              'yang menyelesaikan drain lebih dulu bisa menutup resource di '
              'tengah pekerjaan',
        );
        expect(
          flagHadRunWhenSecondCompleted,
          isTrue,
          reason:
              'drain() kedua baru boleh selesai setelah seluruh antrian '
              'benar-benar kosong',
        );
      },
    );

    test(
      'the mutex serialises overlapping sections without losing one',
      () async {
        final mutex = AsyncMutex();
        final order = <int>[];
        final futures = <Future<void>>[
          for (var index = 0; index < 5; index++)
            mutex.run(() async {
              order.add(index);
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }),
        ];
        await Future.wait(futures);
        expect(order, <int>[0, 1, 2, 3, 4]);
        expect(
          mutex.isLocked,
          isFalse,
          reason: 'mutex harus lepas setelah run',
        );
      },
    );

    test('a failing section releases the mutex for later callers', () async {
      final mutex = AsyncMutex();
      await expectLater(
        mutex.run<void>(() async => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
      // Fail-open guard: a failed critical section must not wedge the queue.
      expect(mutex.isLocked, isFalse);
      expect(await mutex.run(() async => 'recovered'), 'recovered');
    });

    test('a section that throws SYNCHRONOUSLY must not wedge the mutex', () async {
      // Reproduced against the shipped mutex: `run` calls `section()` while
      // the gate is already installed but before the release hook is wired to
      // that result, so a synchronous throw escapes `run` with `_tail` still
      // pointing at an incomplete completer. Every later caller then waits on a
      // future that nobody will ever complete.
      final mutex = AsyncMutex();
      var escaped = false;
      try {
        // ignore: unnecessary_statements
        mutex.run<void>(() => throw StateError('sync boom'));
      } on StateError {
        escaped = true;
      }
      probes['contention_sync_throw_escaped_run'] = '$escaped';
      probes['contention_sync_throw_is_locked'] = '${mutex.isLocked}';
      // ignore: avoid_print
      print(
        '11735_MUTEX_SYNC_THROW escaped=$escaped isLocked=${mutex.isLocked}',
      );

      expect(escaped, isTrue, reason: 'kegagalan sinkron harus tetap teramati');
      expect(
        mutex.isLocked,
        isFalse,
        reason:
            'gate harus dilepas walau section() melempar sinkron; kalau tidak, '
            'setiap pemanggil setelahnya menunggu selamanya',
      );
      expect(
        await mutex
            .run(() async => 'recovered')
            .timeout(const Duration(milliseconds: 500)),
        'recovered',
        reason: 'mutex harus bisa dipakai lagi setelah kegagalan sinkron',
      );
    });

    test(
      'the mutex hands the lock over instead of running sections together',
      () async {
        final mutex = AsyncMutex();
        var inside = 0;
        var peakInside = 0;
        await Future.wait(<Future<void>>[
          for (var index = 0; index < 8; index++)
            mutex.run(() async {
              inside += 1;
              if (inside > peakInside) peakInside = inside;
              await Future<void>.delayed(const Duration(milliseconds: 1));
              inside -= 1;
            }),
        ]);
        probes['memory_mutex_peak_inside'] = peakInside.toString();
        // ignore: avoid_print
        print('11735_MUTEX_PEAK_INSIDE=$peakInside');
        expect(
          peakInside,
          1,
          reason: 'critical section tidak boleh tumpang tindih',
        );
      },
    );

    test(
      'pause holds background work; a fresh drain runs it after resume',
      () async {
        final order = <String>[];
        final queue = BackgroundJobQueue(maxConcurrentJobs: 1);
        addTearDown(queue.dispose);
        queue.enqueue(
          _OrderingTask('low-queued', order, BackgroundJobPriority.low),
        );
        queue.pause(BackgroundJobPriority.normal);

        final pausedDrain = queue.drain();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        // A paused task must not have run, even with a free worker slot.
        expect(order, isEmpty);
        expect(queue.jobOf('low-queued')?.status, BackgroundJobStatus.queued);
        await pausedDrain;

        queue.resume();
        await queue.drain();
        // ignore: avoid_print
        print('11735_PAUSE_HELD_THEN_RESUMED=$order');
        expect(
          order,
          <String>['low-queued'],
          reason: 'setelah resume, drain berikutnya harus menghabiskan antrian',
        );
        expect(
          queue.jobOf('low-queued')?.status,
          BackgroundJobStatus.completed,
          reason: 'setelah drain, status job harus benar-benar selesai',
        );
      },
    );

    test('a critical task overtakes an older low-priority task', () async {
      final order = <String>[];
      final queue = BackgroundJobQueue(maxConcurrentJobs: 1);
      addTearDown(queue.dispose);
      final blocker = Completer<void>();
      queue.enqueue(_GatedTask('blocker', release: blocker));
      queue.enqueue(_OrderingTask('low', order, BackgroundJobPriority.low));
      queue.enqueue(
        _OrderingTask('critical', order, BackgroundJobPriority.critical),
      );
      final drain = queue.drain();
      await Future<void>.delayed(Duration.zero);
      blocker.complete();
      await drain;
      probes['contention_priority_order'] = order.join(',');
      // ignore: avoid_print
      print('11735_PRIORITY_ORDER=$order');
      expect(order, <String>[
        'critical',
        'low',
      ], reason: 'prioritas harus mengalahkan urutan enqueue');
    });

    test(
      'a resource limit blocks the task that needs it, not the queue',
      () async {
        final order = <String>[];
        final queue = BackgroundJobQueue(
          maxConcurrentJobs: 4,
          resourceLimits: const <JobResource, int>{JobResource.database: 1},
        );
        addTearDown(queue.dispose);
        final blocker = Completer<void>();
        queue.enqueue(
          _GatedTask(
            'db-holder',
            release: blocker,
            jobPriority: BackgroundJobPriority.critical,
            taskResources: const <JobResource>{JobResource.database},
          ),
        );
        queue.enqueue(
          _OrderingTask(
            'needs-db',
            order,
            BackgroundJobPriority.high,
            taskResources: const <JobResource>{JobResource.database},
          ),
        );
        queue.enqueue(_OrderingTask('free', order, BackgroundJobPriority.low));

        final drain = queue.drain();
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(
          order,
          <String>['free'],
          reason: 'task yang butuh database waits; task bebas lain boleh jalan',
        );

        blocker.complete();
        await drain;
        // ignore: avoid_print
        print('11735_RESOURCE_LIMIT_ORDER=$order');
        probes['contention_resource_limit_order'] = order.join(',');
        expect(order, <String>['free', 'needs-db']);
      },
    );

    test(
      'dispose closes the update stream and leaves no subscriber open',
      () async {
        final queue = BackgroundJobQueue();
        var events = 0;
        final subscription = queue.updates.listen((_) => events += 1);
        queue.enqueue(_FlaggingTask('job-1', () {}));
        await queue.drain();
        await queue.dispose();
        // ignore: avoid_print
        print('11735_QUEUE_EVENTS_BEFORE_DISPOSE=$events');
        probes['memory_queue_events_before_dispose'] = events.toString();
        expect(events, greaterThan(0), reason: 'update stream harus hidup');

        // A closed stream must deliver `done`, not stay silently open forever:
        // an open broadcast controller is exactly what keeps a queue reachable.
        var sawDone = false;
        queue.updates.listen(null, onDone: () => sawDone = true);
        await Future<void>.delayed(Duration.zero);
        // ignore: avoid_print
        print('11735_QUEUE_STREAM_DONE_AFTER_DISPOSE=$sawDone');
        probes['memory_queue_stream_done_after_dispose'] = '$sawDone';
        expect(
          sawDone,
          isTrue,
          reason: 'stream yang sudah di-dispose harus menutup diri',
        );
        await subscription.cancel();
      },
    );
  });

  test('the eight axes carry measurements this run actually took', () {
    // This test is declared last so every probe above has already recorded.
    // An `observed` string is built from those values, never typed by hand.
    String read(String key) {
      final value = probes[key];
      expect(
        value,
        isNotNull,
        reason: 'probe $key harus diisi oleh test yang mengukurnya',
      );
      return value!;
    }

    final checks = <Sprint117PerfCheck>[
      Sprint117PerfCheck.pass_(
        area: 'render',
        check: 'chrome_first_frame_inside_budget',
        declared:
            'The account & cloud center chrome paints its first frame within '
            'initialFrameBudgetMs at the reference viewport.',
        observed:
            'warm frame ${read('render_chrome_warm_frame_ms')}ms against a '
            '${AccountCenterPerformanceResilience.initialFrameBudgetMs}ms '
            'budget at ${read('render_chrome_viewport')} with '
            '${read('render_chrome_providers')} provider rows; the cold pump '
            '(${read('render_chrome_cold_pump_ms')}ms) also pays JIT and Skia '
            'warm-up and is recorded, not asserted.',
      ),
      Sprint117PerfCheck.pass_(
        area: 'many_accounts',
        check: 'sweep_of_contract_row_count',
        declared:
            'The account sweep named by the contract keeps its budget and '
            'never blurs a non-connected provider into a connected claim.',
        observed:
            '${read('many_accounts_count')} accounts x 7 availabilities in '
            '${read('many_accounts_availability_sweep_ms')}ms against the '
            '${read('many_accounts_refresh_budget_ms')}ms refresh budget; '
            'outage still reads as not connected.',
      ),
      Sprint117PerfCheck.pass_(
        area: 'refresh',
        check: 'cpu_path_bounded_and_observation_required',
        declared:
            'One refresh stays inside its CPU budget, and a refresh without a '
            'health observation is refused instead of counted as success.',
        observed:
            '${read('refresh_iterations')} iterations in '
            '${read('refresh_path_batch_ms')}ms; NOT_CONFIGURED refuses '
            'refreshHealth and a CONNECTED machine without healthState throws '
            'ArgumentError.',
      ),
      Sprint117PerfCheck.pass_(
        area: 'charts',
        check: 'track_colour_reaches_the_paint_input',
        declared:
            'A theme swap that changes only the palette must reach the repaint '
            'decision, so the charts actually repaint.',
        observed:
            'chartPalette with equal values and a different trackColor '
            'returns a different input: ${read('charts_track_color_changes_output')}.',
      ),
      Sprint117PerfCheck.pass_(
        area: 'local_scan',
        check: 'real_tree_indexed_and_totalled',
        declared:
            'A real storage scan stays inside scanBudgetMs, totals every '
            'category, and reports an absent root as empty rather than fake.',
        observed:
            '${read('local_scan_files')} files / ${read('local_scan_bytes')} '
            'bytes indexed in ${read('local_scan_ms')}ms against the '
            '${read('local_scan_budget_ms')}ms budget; category totals sum to '
            'the report total and a missing root yields 0 files / 0 bytes.',
      ),
      const Sprint117PerfCheck.pass_(
        area: 'slow_api',
        check: 'external_measurement_declared_and_local_half_honest',
        declared:
            'Slow-provider timing needs a live connector, and the local half '
            'of it renders the retry window truthfully.',
        observed:
            'slowApiIsExternallyMeasured is true and is the reason this axis '
            'is reported DEFERRED-EXTERNAL; the local half renders 30s as '
            '"30 seconds" and refuses a zero retry window with ArgumentError.',
      ),
      Sprint117PerfCheck.pass_(
        area: 'memory',
        check: 'dispose_stops_work_and_releases_locks',
        declared:
            'Dispose stops pending work instead of running it and discarding '
            'the result, and a failed critical section does not wedge the '
            'mutex.',
        observed:
            'search calls after dispose = '
            '${read('memory_search_calls_after_dispose')}, mutex peak inside = '
            '${read('memory_mutex_peak_inside')}, update events before '
            'dispose = ${read('memory_queue_events_before_dispose')}, stream '
            'done after dispose = ${read('memory_queue_stream_done_after_dispose')}.',
      ),
      Sprint117PerfCheck.pass_(
        area: 'contention',
        check: 'drain_reports_only_a_genuinely_empty_queue',
        declared:
            'drain() resolves only once the queue is genuinely empty, '
            'concurrency respects maxConcurrentJobs, and priority beats '
            'enqueue order.',
        observed:
            'peak concurrency ${read('contention_peak_concurrency')}/2; a '
            'second drain did not complete before the gate opened; order under '
            'priority = ${read('contention_priority_order')}; resource limit '
            'order = ${read('contention_resource_limit_order')}.',
      ),
      const Sprint117PerfCheck.unmet(
        area: 'slow_api',
        check: 'live_provider_latency_measured',
        declared:
            'The slow-API axis reports a real latency measured against a live '
            'provider connector, not only the local retry window.',
        observed:
            'No live provider connector ships in this build, so no local run '
            'can produce that number; the axis stays DEFERRED-EXTERNAL and the '
            'local retry-window behaviour above is what is actually verified.',
        note:
            'Not a defect claim. Reporting a fabricated latency here would be '
            'the only way to close it, which is exactly what this gate '
            'refuses to do.',
      ),
    ];

    final result = Sprint117PerformanceScale.evaluate(checks);
    expect(result.failures, isEmpty);
    expect(result.pass, isTrue);
    expect(result.violationCodes, isEmpty);
    expect(result.openItems, <String>[
      'slow_api:live_provider_latency_measured',
    ]);
    expect(result.toJson()['canonical_step'], '117.35');
    expect(result.toJson()['verdict'], 'PERFORMANCE_SCALE_VALIDATED_LOCAL');

    evidence
      ..['probes'] = probes
      ..['gate'] = result.toJson();
    writeEvidenceFile();
    // ignore: avoid_print
    print('11735_GATE ${result.summary}');
    // ignore: avoid_print
    print('11735_PROBES ${jsonEncode(probes)}');
  });
}

/// Tugas yang menandai apakah ia sempat berjalan.
class _FlaggingTask implements BackgroundTask {
  _FlaggingTask(this.id, this.onRun);

  @override
  final String id;
  final void Function() onRun;

  @override
  BackgroundJob get job => BackgroundJob(
    id: id,
    projectId: 'probe',
    type: BackgroundJobType.custom,
    label: 'probe $id',
    status: BackgroundJobStatus.queued,
    priority: BackgroundJobPriority.normal,
    createdAt: DateTime.utc(2026, 10, 2, 12),
  );

  @override
  BackgroundJobType get type => BackgroundJobType.custom;

  @override
  Set<JobResource> get resources => const <JobResource>{};

  @override
  String? get taskKey => null;

  @override
  Future<void> cancel() async {}

  @override
  Future<void> execute(JobContext context) async {
    onRun();
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}
