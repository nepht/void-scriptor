import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/custom_calendar.dart';
import 'package:void_scriptor/features/world_logic/domain/route_network.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_world_clock_integration.dart';

void main() {
  final calendar = CustomCalendar(
    months: const <CustomMonth>[
      CustomMonth(name: 'Frost', daysInMonth: 30, indexInYear: 0),
      CustomMonth(name: 'Bloom', daysInMonth: 30, indexInYear: 1),
    ],
  );

  SharedWorldClockIntegration create() => SharedWorldClockIntegration(
    calendar: calendar,
    seasons: const <int, Season>{0: Season.winter, 1: Season.spring},
    eras: const <WorldEra>[
      WorldEra(id: 'first-age', startTick: 0, endTick: 29),
      WorldEra(id: 'second-age', startTick: 30),
    ],
  );

  test('shared_clock is the one absolute tick source', () {
    final integration = create();
    expect(integration.now, 0);
    expect(integration.advance(31), 31);
    expect(integration.now, 31);
  });

  test('calendar_round_trip preserves the absolute tick', () {
    final integration = create()..advance(37);
    final date = integration.date;
    expect(integration.tickFromDate(date), 37);
  });

  test('era_consistency resolves the era from the same tick', () {
    final integration = create()..advance(30);
    expect(integration.era.id, 'second-age');
    expect(integration.era.contains(integration.now), isTrue);
  });

  test('season_consistency resolves the season through the calendar month', () {
    final integration = create()..advance(30);
    expect(integration.season, Season.spring);
  });

  test('branch_awareness keeps timeline branches explicit', () {
    final integration = create();
    integration.createBranch('what-if');
    integration.selectBranch('what-if');
    integration.advance(5);
    expect(integration.branchId, 'what-if');
    expect(integration.snapshot().branchId, 'what-if');
  });
}
