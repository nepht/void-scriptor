// Sprint 110.20 — Territorial Control State (Temporal World Map).
//
// RED test: validates a territorial control record carrying
// controllerId, locationId, and ValidityRange; verifies the registry
// returns the active controller at an asOfTick, rejects overlapping
// ranges for the same (locationId, controllerId) pair, surfaces the
// provenance via ResultOrigin, and reports a layered history list
// ordered by fromTick.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/territorial_control.dart";
import "package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart"
    show ValidityRange;
import "package:void_scriptor/features/world_logic/domain/derived_result_provenance.dart";

void main() {
  group("TerritorialControl", () {
    test("rejects negative fromTick", () {
      expect(
        () => TerritorialControl(
          controllerId: "c1",
          locationId: "l1",
          validity: ValidityRange(fromTick: -1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test("activeAt returns true only inside ValidityRange", () {
      const v = ValidityRange(fromTick: 10, toTick: 20);
      const rec = TerritorialControl(
        controllerId: "c1",
        locationId: "l1",
        validity: v,
      );
      expect(rec.activeAt(5), isFalse);
      expect(rec.activeAt(10), isTrue);
      expect(rec.activeAt(15), isTrue);
      expect(rec.activeAt(20), isTrue);
      expect(rec.activeAt(21), isFalse);
    });

    test("open-ended validity stays active for any tick >= fromTick", () {
      const rec = TerritorialControl(
        controllerId: "c1",
        locationId: "l1",
        validity: ValidityRange(fromTick: 7),
      );
      expect(rec.activeAt(7), isTrue);
      expect(rec.activeAt(1000000), isTrue);
    });
  });

  group("TerritorialControlRegistry", () {
    test("returns the active controller for a location at asOfTick", () {
      final reg = TerritorialControlRegistry(<TerritorialControl>[
        const TerritorialControl(
          controllerId: "c1",
          locationId: "l1",
          validity: ValidityRange(fromTick: 0, toTick: 50),
        ),
        const TerritorialControl(
          controllerId: "c2",
          locationId: "l1",
          validity: ValidityRange(fromTick: 51, toTick: 100),
        ),
      ]);
      expect(reg.controllerOf("l1", atTick: 25), "c1");
      expect(reg.controllerOf("l1", atTick: 75), "c2");
      expect(reg.controllerOf("l1", atTick: 200), isNull);
    });

    test(
      "rejects overlapping ranges for different controllers on same location",
      () {
        final reg = TerritorialControlRegistry(<TerritorialControl>[]);
        reg.upsert(
          const TerritorialControl(
            controllerId: "c1",
            locationId: "l1",
            validity: ValidityRange(fromTick: 0, toTick: 50),
          ),
        );
        expect(
          () => reg.upsert(
            const TerritorialControl(
              controllerId: "c2",
              locationId: "l1",
              validity: ValidityRange(fromTick: 40, toTick: 80),
            ),
          ),
          throwsA(isA<TerritorialControlOverlap>()),
        );
      },
    );

    test("historyOf returns records ordered by fromTick", () {
      final reg = TerritorialControlRegistry(<TerritorialControl>[
        const TerritorialControl(
          controllerId: "c2",
          locationId: "l1",
          validity: ValidityRange(fromTick: 60, toTick: 100),
        ),
        const TerritorialControl(
          controllerId: "c1",
          locationId: "l1",
          validity: ValidityRange(fromTick: 0, toTick: 50),
        ),
        const TerritorialControl(
          controllerId: "c3",
          locationId: "l1",
          validity: ValidityRange(fromTick: 110),
        ),
      ]);
      final history = reg.historyOf("l1");
      expect(
        history.map((r) => r.controllerId).toList(),
        equals(<String>["c1", "c2", "c3"]),
      );
    });

    test("attachProvenance stamps origin onto the active controller", () {
      const origin = ResultOrigin.simulation(
        sourceRevision: "r1",
        generatedAtTick: 30,
      );
      final reg = TerritorialControlRegistry(<TerritorialControl>[
        const TerritorialControl(
          controllerId: "c1",
          locationId: "l1",
          validity: ValidityRange(fromTick: 0, toTick: 50),
        ),
      ])..attachProvenance("l1", atTick: 25, origin: origin);
      final rec = reg.activeRecord("l1", atTick: 25);
      expect(rec, isNotNull);
      expect(rec!.provenance, same(origin));
    });
  });
}
