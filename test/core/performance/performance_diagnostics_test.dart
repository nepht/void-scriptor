import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/performance_mode.dart';
import 'package:void_scriptor/core/performance/slow_query_log.dart';

void main() {
  test('performance mode defaults to balanced', () {
    expect(PerformanceMode.defaultMode, PerformanceMode.balanced);
  });

  test('performance mode maps thumbnail quality and worker count', () {
    expect(
      PerformanceMode.low.thumbnailQuality,
      lessThanOrEqualTo(PerformanceMode.balanced.thumbnailQuality),
    );
    expect(
      PerformanceMode.low.backgroundWorkers,
      lessThanOrEqualTo(PerformanceMode.balanced.backgroundWorkers),
    );
    expect(
      PerformanceMode.high.thumbnailQuality,
      greaterThanOrEqualTo(PerformanceMode.balanced.thumbnailQuality),
    );
  });

  test('slow query log records queries exceeding threshold', () async {
    final log = SlowQueryLog(threshold: const Duration(milliseconds: 10));
    await log.run('SELECT 1', () async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });

    expect(log.entries, hasLength(1));
    expect(log.entries.single.query, 'SELECT 1');
    expect(
      log.entries.single.duration,
      greaterThanOrEqualTo(const Duration(milliseconds: 10)),
    );
  });

  test('slow query log ignores fast queries', () async {
    final log = SlowQueryLog(threshold: const Duration(seconds: 5));
    await log.run('SELECT 1', () async {});

    expect(log.entries, isEmpty);
  });

  test('slow query log accumulates in order and can clear', () async {
    final log = SlowQueryLog(threshold: Duration.zero);
    await log.run('SELECT 1', () async {});
    await log.run('SELECT 2', () async {});
    expect(log.entries, hasLength(2));
    expect(log.entries.map((e) => e.query), ['SELECT 1', 'SELECT 2']);

    log.clear();
    expect(log.entries, isEmpty);
  });
}
