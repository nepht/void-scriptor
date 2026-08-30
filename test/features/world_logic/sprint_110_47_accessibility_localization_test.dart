// Sprint 110.47 - Accessibility & Localization Verification.
//
// Verifier-style slice for the 110.47 acceptance required_outputs:
//   keyboard_results, screen_reader_results, scaling_results,
//   locale_results, calendar_results, fix_status.
//
// Domain-only, deterministic, no persistence/UI/wall clock/random/network.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/accessibility_localization_audit.dart';
import 'package:void_scriptor/features/world_logic/domain/calendar_conversion.dart';
import 'package:void_scriptor/features/world_logic/domain/currency_reference_basket.dart';
import 'package:void_scriptor/features/world_logic/domain/custom_calendar.dart';
import 'package:void_scriptor/features/world_logic/domain/historical_layer_resolver.dart';
import 'package:void_scriptor/features/world_logic/domain/price_wealth_inflation_model.dart';
import 'package:void_scriptor/features/world_logic/domain/tech_tree_workspace.dart';
import 'package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_map_state.dart';

CustomCalendar _standardCalendar() {
  return CustomCalendar(
    months: const <CustomMonth>[
      CustomMonth(name: 'Jan', daysInMonth: 31, indexInYear: 0),
      CustomMonth(name: 'Feb', daysInMonth: 28, indexInYear: 1),
      CustomMonth(name: 'Mar', daysInMonth: 31, indexInYear: 2),
      CustomMonth(name: 'Apr', daysInMonth: 30, indexInYear: 3),
      CustomMonth(name: 'May', daysInMonth: 31, indexInYear: 4),
      CustomMonth(name: 'Jun', daysInMonth: 30, indexInYear: 5),
      CustomMonth(name: 'Jul', daysInMonth: 31, indexInYear: 6),
      CustomMonth(name: 'Aug', daysInMonth: 31, indexInYear: 7),
      CustomMonth(name: 'Sep', daysInMonth: 30, indexInYear: 8),
      CustomMonth(name: 'Oct', daysInMonth: 31, indexInYear: 9),
      CustomMonth(name: 'Nov', daysInMonth: 30, indexInYear: 10),
      CustomMonth(name: 'Dec', daysInMonth: 31, indexInYear: 11),
    ],
  );
}

CustomCalendar _leapStyleCalendar() {
  return CustomCalendar(
    months: const <CustomMonth>[
      CustomMonth(name: 'Ash', daysInMonth: 30, indexInYear: 0),
      CustomMonth(name: 'Ember', daysInMonth: 31, indexInYear: 1),
      CustomMonth(name: 'Verd', daysInMonth: 30, indexInYear: 2),
      CustomMonth(name: 'Soren', daysInMonth: 32, indexInYear: 3),
    ],
  );
}

CustomCalendar _tideCalendar() {
  return CustomCalendar(
    months: const <CustomMonth>[
      CustomMonth(name: 'Tide1', daysInMonth: 28, indexInYear: 0),
      CustomMonth(name: 'Tide2', daysInMonth: 27, indexInYear: 1),
      CustomMonth(name: 'Tide3', daysInMonth: 28, indexInYear: 2),
      CustomMonth(name: 'Tide4', daysInMonth: 27, indexInYear: 3),
      CustomMonth(name: 'Tide5', daysInMonth: 28, indexInYear: 4),
    ],
  );
}

MapTimeSliderController _mapController() {
  final state = TemporalMapState(
    branchId: 'prime',
    locations: <TemporalLocation>[
      TemporalLocation.validated(
        id: 'p0',
        name: 'P0',
        validFrom: 0,
        validUntil: 10,
      ),
    ],
  );
  return MapTimeSliderController.forState(state);
}

TechTreeController _techController() {
  final registry = TechnologyRegistry.validated(
    nodes: <TechnologyNode>[
      TechnologyNode.validated(
        id: 'wheel',
        name: 'Wheel',
        culture: 'common',
        branch: 'prime',
        tier: 1,
        summary: 'rolling aid',
        prerequisites: const <String>[],
        source: TechnologySource.validated(revision: 'std', reason: 'standard'),
      ),
      TechnologyNode.validated(
        id: 'cart',
        name: 'Cart',
        culture: 'common',
        branch: 'prime',
        tier: 2,
        summary: 'wheeled carrier',
        prerequisites: const <String>['wheel'],
        source: TechnologySource.validated(revision: 'std', reason: 'standard'),
      ),
    ],
  );
  final timeline = TechnologyDiscoveryTimeline.validated(
    events: <TechnologyDiscoveryEvent>[],
  );
  return TechTreeController.forRegistry(registry: registry, timeline: timeline);
}

EconomySource _src(String rev) =>
    EconomySource.validated(revision: rev, reason: 'audit seed');

CurrencyReferenceBasket _basket() {
  return CurrencyReferenceBasket.validated(
    currencies: <CurrencyDefinition>[
      CurrencyDefinition.validated(
        id: 'gold',
        name: 'Gold Crown',
        symbol: 'Au',
        validity: const ValidityRange(fromTick: 0, untilTick: 100000),
      ),
    ],
    denominations: <CurrencyDenomination>[
      CurrencyDenomination.validated(
        id: 'crown',
        currencyId: 'gold',
        name: 'Crown',
        value: 1,
        validity: const ValidityRange(fromTick: 0, untilTick: 100000),
      ),
    ],
    exchangeRates: const <CurrencyExchangeRate>[],
    units: <ReferenceUnit>[
      ReferenceUnit.validated(
        id: 'loaf',
        name: 'Loaf',
        symbol: 'lf',
        category: 'volume',
      ),
    ],
    goods: <ReferenceGood>[
      ReferenceGood.validated(
        id: 'bread',
        name: 'Bread',
        unitId: 'loaf',
        prices: <ReferenceGoodPrice>[
          ReferenceGoodPrice.validated(
            currencyId: 'gold',
            amount: 0.05,
            validity: const ValidityRange(fromTick: 0, untilTick: 100000),
          ),
        ],
      ),
    ],
  );
}

PriceWealthInflationModel _model() {
  return PriceWealthInflationModel.validated(
    basket: _basket(),
    priceHistory: const <PriceHistoryEntry>[],
    wageHistory: const <WageHistoryEntry>[],
    wealthProfiles: <WealthProfile>[
      WealthProfile.validated(
        id: 'wp-1',
        ownerId: 'owner-1',
        currencyId: 'gold',
        assets: 1000,
        liabilities: 100,
        tick: 0,
        source: _src('wp-1'),
      ),
    ],
    scarcityEvents: const <ScarcityEvent>[],
  );
}

CalendarConversionService _conversion({required CustomCalendar primary}) {
  return CalendarConversionService(
    registry: CalendarRegistry(<String, CustomCalendar>{
      'gregory': _standardCalendar(),
      'aelyr': _leapStyleCalendar(),
      'tide': _tideCalendar(),
      'primary': primary,
    }),
    defaultLocale: CalendarLocale.defaultLocale,
  );
}

void main() {
  group('Sprint 110.47 - Accessibility & Localization Verification', () {
    test('keyboard_results: MapTimeKey + TechTreeKey + nav are reachable', () {
      final map = _mapController();
      final tech = _techController();
      final report = const A11yLocaleAuditor().auditKeyboard(
        mapController: map,
        techController: tech,
      );
      expect(report.isClean, isTrue, reason: report.unreachableKeys.toString());
      expect(report.totalKeys, greaterThan(0));
      expect(report.reachableKeys, report.totalKeys);
    });

    test(
      'screen_reader_results: structural labels present, native PARTIAL',
      () {
        final sr = const A11yLocaleAuditor().auditScreenReader();
        expect(sr.isClean, isTrue);
        expect(sr.viewLabels, contains('MapTimeSliderView'));
        expect(sr.viewLabels, contains('TechTreeWorkspaceView'));
        expect(
          sr.nativeCapture,
          isFalse,
          reason: 'PARTIAL until native screen-reader capture is run.',
        );
      },
    );
  });
  group('Sprint 110.47 part 2', () {
    test('scaling_results: large numbers survive int formatting', () {
      final report = const A11yLocaleAuditor().auditScaling(
        basket: _basket(),
        model: _model(),
        extremeTick: 99999,
      );
      expect(report.isClean, isTrue, reason: report.formattedTexts.toString());
      expect(report.largestConvertedTick, 99999);
      expect(report.largestNetWorth, greaterThanOrEqualTo(1000));
    });

    test('locale_results: round-trip across separators/calendars has no '
        'collisions', () {
      final report = const A11yLocaleAuditor().auditLocale(
        conversion: _conversion(primary: _standardCalendar()),
        locales: const <CalendarLocale>[
          CalendarLocale(id: 'en', separator: '-', order: 'ymd'),
          CalendarLocale(id: 'id', separator: '/', order: 'dmy'),
          CalendarLocale(id: 'us', separator: '.', order: 'mdy'),
        ],
        calendarIds: const <String>{'gregory', 'aelyr', 'tide'},
      );
      expect(report.isClean, isTrue, reason: report.collisions.toString());
      expect(report.samples, isNotEmpty);
    });

    test('calendar_results: year boundary and round-trip succeed', () {
      final cal = _standardCalendar();
      final report = const A11yLocaleAuditor().auditCalendar(calendar: cal);
      expect(report.isClean, isTrue);
      expect(report.firstDateOfYear.yearNumber, 1);
      expect(report.firstDateOfYear.dayOfMonth, 1);
      expect(report.lastDateOfYear.dayOfMonth, 31);
      expect(report.lastDateOfYear.monthIndex, 11);
    });

    test('calendar_results: variable-month calendar round-trip succeeds', () {
      final cal = _leapStyleCalendar();
      final report = const A11yLocaleAuditor().auditCalendar(calendar: cal);
      expect(report.leapStyleRoundTrip, isTrue);
      expect(cal.daysPerYear, 123);
      final sorenFirst = cal.dateFromTick(
        cal.months[0].daysInMonth +
            cal.months[1].daysInMonth +
            cal.months[2].daysInMonth,
      );
      expect(sorenFirst.monthIndex, 3);
      expect(sorenFirst.dayOfMonth, 1);
    });

    test('fix_status aggregated acceptable when only screen-reader native '
        'capture is missing', () {
      final map = _mapController();
      final tech = _techController();
      final cal = _standardCalendar();
      final report = const A11yLocaleAuditor().runFull(
        mapController: map,
        techController: tech,
        basket: _basket(),
        model: _model(),
        conversion: _conversion(primary: cal),
        locales: const <CalendarLocale>[
          CalendarLocale(id: 'en', separator: '-', order: 'ymd'),
          CalendarLocale(id: 'id', separator: '/', order: 'dmy'),
        ],
        calendarIds: const <String>{'gregory', 'aelyr', 'tide'},
        calendar: cal,
        extremeTick: 50000,
      );
      expect(report.keyboard.isClean, isTrue);
      expect(report.scaling.isClean, isTrue);
      expect(report.locale.isClean, isTrue);
      expect(report.calendar.isClean, isTrue);
      expect(report.fixStatus, A11yLocaleFixStatus.acceptable);
      expect(report.isClean, isFalse, reason: 'native capture still PARTIAL.');
    });
  });
}
