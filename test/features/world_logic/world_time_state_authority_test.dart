// Sprint 110.3 — World Time & State Authority.
// Canonical requirements: canonical_clock, calendar_adapter,
// state_snapshot, branch_awareness, provenance.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/world_time_state_authority.dart';

void main() {
  group('canonical_clock', () {
    test('clock hanya maju dengan input eksplisit dan dapat diulang', () {
      final clock = WorldClock(initialTick: 10);
      expect(clock.now, 10);
      expect(clock.advance(5), 15);
      expect(clock.now, 15);
      expect(() => clock.advance(-1), throwsArgumentError);
      final replay = WorldClock(initialTick: 10)..advance(5);
      expect(replay.now, clock.now);
    });
  });

  group('calendar_adapter', () {
    test('adapter kalender memetakan tick secara deterministik', () {
      final calendar = FixedCalendar(daysPerYear: 360, daysPerMonth: 30);
      expect(calendar.fromTick(0), const WorldDate(year: 1, month: 1, day: 1));
      expect(
        calendar.fromTick(359),
        const WorldDate(year: 1, month: 12, day: 30),
      );
      expect(
        calendar.fromTick(360),
        const WorldDate(year: 2, month: 1, day: 1),
      );
      expect(
        () => FixedCalendar(daysPerYear: 0, daysPerMonth: 30),
        throwsArgumentError,
      );
    });
  });

  group('state_snapshot', () {
    test('snapshot immutable dan memuat state pada tick tertentu', () {
      final authority = WorldStateAuthority(clock: WorldClock(initialTick: 4));
      authority.putState(key: 'weather', value: 'storm');
      final snapshot = authority.snapshot(label: 'before-crossing');
      expect(snapshot.tick, 4);
      expect(snapshot.values['weather'], 'storm');
      authority.putState(key: 'weather', value: 'clear');
      expect(snapshot.values['weather'], 'storm');
      expect(snapshot.provenance.origin, 'simulation');
    });
  });

  group('branch_awareness', () {
    test('branch terisolasi dan snapshot membawa branch id', () {
      final authority = WorldStateAuthority(clock: WorldClock());
      authority.createBranch(id: 'what-if');
      authority.selectBranch('what-if');
      authority.putState(key: 'fate', value: 'split');
      expect(authority.snapshot(label: 'branch').branchId, 'what-if');
      authority.selectBranch('main');
      expect(
        authority.snapshot(label: 'main').values.containsKey('fate'),
        isFalse,
      );
      expect(() => authority.selectBranch('missing'), throwsStateError);
    });
  });

  group('provenance', () {
    test('snapshot memiliki source revision dan alasan', () {
      final authority = WorldStateAuthority(clock: WorldClock());
      final snapshot = authority.snapshot(
        label: 'manual-checkpoint',
        provenance: const StateProvenance(
          origin: 'manual',
          sourceId: 'writer',
          sourceRevision: 'rev-7',
          reason: 'uji kontinuitas',
        ),
      );
      expect(snapshot.provenance.origin, 'manual');
      expect(snapshot.provenance.sourceId, 'writer');
      expect(snapshot.provenance.sourceRevision, 'rev-7');
      expect(snapshot.provenance.reason, 'uji kontinuitas');
    });
  });
}

extension _AuthorityTestAccess on WorldStateAuthority {
  void putState({required String key, required String value}) =>
      setState(key: key, value: value);
}
