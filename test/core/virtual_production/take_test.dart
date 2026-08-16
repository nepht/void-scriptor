import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/virtual_production/take/take_record.dart';
import 'package:void_scriptor/core/virtual_production/take/take_manager.dart';

void main() {
  test('TakeRecord holds metadata', () {
    const take = TakeRecord(
      id: 't1',
      shotId: 's1',
      takeNumber: 1,
      state: TakeState.review,
      notes: 'good',
    );
    expect(take.shotId, 's1');
    expect(take.takeNumber, 1);
    expect(take.state, TakeState.review);
  });

  test('TakeManager records and retrieves latest take', () {
    final manager = TakeManager();
    manager.record(
      const TakeRecord(
        id: 't1',
        shotId: 's1',
        takeNumber: 1,
        state: TakeState.pending,
      ),
    );
    manager.record(
      const TakeRecord(
        id: 't2',
        shotId: 's1',
        takeNumber: 2,
        state: TakeState.pending,
      ),
    );
    final latest = manager.latestFor('s1');
    expect(latest!.takeNumber, 2);
  });

  test('TakeManager approve marks take approved', () {
    final manager = TakeManager();
    manager.record(
      const TakeRecord(
        id: 't1',
        shotId: 's1',
        takeNumber: 1,
        state: TakeState.review,
      ),
    );
    manager.approve('t1');
    expect(manager.latestFor('s1')!.state, TakeState.approved);
  });
}
