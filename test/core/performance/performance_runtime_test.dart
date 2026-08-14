import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/performance_runtime.dart';

void main() {
  test('project task owner cancels transient tasks on project close', () async {
    final owner = ProjectTaskOwner('project-1');
    final transient = _CancellableTask('transient');
    final persistent = _CancellableTask('persistent');
    owner.attach(transient, persistent: false);
    owner.attach(persistent, persistent: true);

    await owner.close();

    expect(transient.cancelled, isTrue);
    expect(persistent.cancelled, isFalse);
  });

  test('memory cache policy evicts by item budget', () {
    const policy = MemoryCachePolicy(maxPreviewItems: 100);
    expect(policy.shouldEvict(100), isFalse);
    expect(policy.shouldEvict(101), isTrue);
  });

  test('performance metrics capture project-open phases', () {
    final metrics = PerformanceMetrics();
    metrics.record('manifest', const Duration(milliseconds: 20));
    metrics.record('database', const Duration(milliseconds: 30));
    expect(metrics.durationOf('manifest'), const Duration(milliseconds: 20));
    expect(metrics.total, const Duration(milliseconds: 50));
  });
}

class _CancellableTask implements ProjectOwnedTask {
  _CancellableTask(this.id);
  @override
  final String id;
  bool cancelled = false;
  @override
  Future<void> cancel() async => cancelled = true;
}
