// Sprint 111.21 - Ownership Lineage & Historical Events.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/encyclopedia_ownership_lineage.dart";

void main() {
  group("TransferType", () {
    test("has a defined set of transfer kinds with labels", () {
      expect(TransferType.values.length, greaterThanOrEqualTo(6));
      for (final t in TransferType.values) {
        expect(t.label, isNotEmpty);
      }
    });
    test("covers sale, gift, inheritance, theft and seizure", () {
      final names = TransferType.values.map((t) => t.name).toSet();
      expect(
        names,
        containsAll(["sale", "gift", "inheritance", "theft", "seizure"]),
      );
    });
  });

  group("LossKind", () {
    test("has a defined loss ladder with labels", () {
      expect(LossKind.values.length, greaterThanOrEqualTo(4));
      for (final k in LossKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
    test("covers stolen, battle, wreck and unknown", () {
      final names = LossKind.values.map((k) => k.name).toSet();
      expect(names, containsAll(["stolen", "battle", "wreck", "unknown"]));
    });
  });

  group("RecoveryKind", () {
    test("has a defined recovery ladder with labels", () {
      expect(RecoveryKind.values.length, greaterThanOrEqualTo(4));
      for (final k in RecoveryKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
    test("covers found, returned, ransomed and excavated", () {
      final names = RecoveryKind.values.map((k) => k.name).toSet();
      expect(
        names,
        containsAll(["found", "returned", "ransomed", "excavated"]),
      );
    });
  });

  group("CustodyRole", () {
    test("has a defined custody role set with labels", () {
      expect(CustodyRole.values.length, greaterThanOrEqualTo(4));
      for (final r in CustodyRole.values) {
        expect(r.label, isNotEmpty);
      }
    });
    test("roles carry strictly increasing trust weight", () {
      final weights = CustodyRole.values.map((r) => r.weight).toList();
      for (int i = 1; i < weights.length; i++) {
        expect(weights[i], greaterThan(weights[i - 1]));
      }
    });
  });

  group("OwnershipPeriod", () {
    test("rejects empty period id", () {
      expect(
        () => OwnershipPeriod.validated(
          periodId: " ",
          holderId: "h1",
          holderName: "Kala",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty holder id", () {
      expect(
        () => OwnershipPeriod.validated(
          periodId: "p1",
          holderId: "",
          holderName: "Kala",
        ),
        throwsArgumentError,
      );
    });
    test("rejects empty holder name", () {
      expect(
        () => OwnershipPeriod.validated(
          periodId: "p1",
          holderId: "h1",
          holderName: "  ",
        ),
        throwsArgumentError,
      );
    });
    test("rejects blank markers when provided", () {
      expect(
        () => OwnershipPeriod.validated(
          periodId: "p1",
          holderId: "h1",
          holderName: "Kala",
          startMarker: " ",
        ),
        throwsArgumentError,
      );
      expect(
        () => OwnershipPeriod.validated(
          periodId: "p1",
          holderId: "h1",
          holderName: "Kala",
          endMarker: " ",
        ),
        throwsArgumentError,
      );
    });
    test("trims fields and keeps optional markers", () {
      final p = OwnershipPeriod.validated(
        periodId: " p1 ",
        holderId: " h1 ",
        holderName: " Kala ",
        startMarker: " First Era ",
        endMarker: " Second Era ",
        note: " inherited ",
      );
      expect(p.periodId, "p1");
      expect(p.holderId, "h1");
      expect(p.holderName, "Kala");
      expect(p.startMarker, "First Era");
      expect(p.endMarker, "Second Era");
      expect(p.note, "inherited");
    });
    test("isOpenPeriod true only without end marker", () {
      expect(
        OwnershipPeriod.validated(
          periodId: "p1",
          holderId: "h1",
          holderName: "Kala",
        ).isOpenPeriod,
        isTrue,
      );
      expect(
        OwnershipPeriod.validated(
          periodId: "p2",
          holderId: "h1",
          holderName: "Kala",
          endMarker: "Later",
        ).isOpenPeriod,
        isFalse,
      );
    });
  });

  group("CustodyArrangement", () {
    test("rejects empty ids and names", () {
      expect(
        () => CustodyArrangement.validated(
          custodyId: "",
          custodianId: "c1",
          custodianName: "Order of the Quiet",
          role: CustodyRole.templeGuardian,
        ),
        throwsArgumentError,
      );
      expect(
        () => CustodyArrangement.validated(
          custodyId: "cu1",
          custodianId: " ",
          custodianName: "Order of the Quiet",
          role: CustodyRole.templeGuardian,
        ),
        throwsArgumentError,
      );
      expect(
        () => CustodyArrangement.validated(
          custodyId: "cu1",
          custodianId: "c1",
          custodianName: "",
          role: CustodyRole.templeGuardian,
        ),
        throwsArgumentError,
      );
    });
    test("requires a role", () {
      final cu = CustodyArrangement.validated(
        custodyId: "cu1",
        custodianId: "c1",
        custodianName: "Order of the Quiet",
        role: CustodyRole.templeGuardian,
        institution: "Vault",
        terms: "Never removed",
      );
      expect(cu.role, CustodyRole.templeGuardian);
      expect(cu.institution, "Vault");
      expect(cu.terms, "Never removed");
    });
    test("rejects blank optional fields", () {
      expect(
        () => CustodyArrangement.validated(
          custodyId: "cu1",
          custodianId: "c1",
          custodianName: "Order",
          role: CustodyRole.templeGuardian,
          institution: "  ",
        ),
        throwsArgumentError,
      );
      expect(
        () => CustodyArrangement.validated(
          custodyId: "cu1",
          custodianId: "c1",
          custodianName: "Order",
          role: CustodyRole.templeGuardian,
          terms: "  ",
        ),
        throwsArgumentError,
      );
    });
  });

  group("TransferEvent", () {
    test("rejects empty ids", () {
      expect(
        () => TransferEvent.validated(
          transferId: "",
          type: TransferType.sale,
          fromHolderId: "h1",
          toHolderId: "h2",
        ),
        throwsArgumentError,
      );
      expect(
        () => TransferEvent.validated(
          transferId: "t1",
          type: TransferType.sale,
          fromHolderId: " ",
          toHolderId: "h2",
        ),
        throwsArgumentError,
      );
      expect(
        () => TransferEvent.validated(
          transferId: "t1",
          type: TransferType.sale,
          fromHolderId: "h1",
          toHolderId: "",
        ),
        throwsArgumentError,
      );
    });
    test("rejects self-transfer", () {
      expect(
        () => TransferEvent.validated(
          transferId: "t1",
          type: TransferType.sale,
          fromHolderId: "h1",
          toHolderId: "h1",
        ),
        throwsArgumentError,
      );
    });
    test("keeps fields with marker and note", () {
      final t = TransferEvent.validated(
        transferId: " t1 ",
        type: TransferType.theft,
        fromHolderId: "h1",
        toHolderId: "h2",
        marker: " Night of Ash ",
        note: " unsolved ",
      );
      expect(t.transferId, "t1");
      expect(t.type, TransferType.theft);
      expect(t.fromHolderId, "h1");
      expect(t.toHolderId, "h2");
      expect(t.marker, "Night of Ash");
      expect(t.note, "unsolved");
    });
    test("isViolent true only for theft, seizure and ransom", () {
      expect(
        TransferEvent.validated(
          transferId: "t1",
          type: TransferType.theft,
          fromHolderId: "a",
          toHolderId: "b",
        ).isViolent,
        isTrue,
      );
      expect(
        TransferEvent.validated(
          transferId: "t2",
          type: TransferType.seizure,
          fromHolderId: "a",
          toHolderId: "b",
        ).isViolent,
        isTrue,
      );
      expect(
        TransferEvent.validated(
          transferId: "t3",
          type: TransferType.sale,
          fromHolderId: "a",
          toHolderId: "b",
        ).isViolent,
        isFalse,
      );
    });
  });

  group("LossEvent", () {
    test("rejects empty id and description", () {
      expect(
        () => LossEvent.validated(
          lossId: "",
          kind: LossKind.stolen,
          description: "taken",
        ),
        throwsArgumentError,
      );
      expect(
        () => LossEvent.validated(
          lossId: "l1",
          kind: LossKind.stolen,
          description: "  ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps optional location link and marker", () {
      final l = LossEvent.validated(
        lossId: " l1 ",
        kind: LossKind.wreck,
        description: " Ship broke up ",
        locationId: " loc1 ",
        marker: " Third Era ",
        note: " cargo manifest lost ",
      );
      expect(l.lossId, "l1");
      expect(l.kind, LossKind.wreck);
      expect(l.description, "Ship broke up");
      expect(l.locationId, "loc1");
      expect(l.marker, "Third Era");
      expect(l.note, "cargo manifest lost");
    });
    test("rejects blank optional fields", () {
      expect(
        () => LossEvent.validated(
          lossId: "l1",
          kind: LossKind.stolen,
          description: "taken",
          locationId: " ",
        ),
        throwsArgumentError,
      );
    });
  });

  group("RecoveryEvent", () {
    test("rejects empty ids", () {
      expect(
        () => RecoveryEvent.validated(
          recoveryId: "",
          lossId: "l1",
          kind: RecoveryKind.found,
          description: "found",
          recoveredById: "h1",
        ),
        throwsArgumentError,
      );
      expect(
        () => RecoveryEvent.validated(
          recoveryId: "r1",
          lossId: " ",
          kind: RecoveryKind.found,
          description: "found",
          recoveredById: "h1",
        ),
        throwsArgumentError,
      );
      expect(
        () => RecoveryEvent.validated(
          recoveryId: "r1",
          lossId: "l1",
          kind: RecoveryKind.found,
          description: "",
          recoveredById: "h1",
        ),
        throwsArgumentError,
      );
      expect(
        () => RecoveryEvent.validated(
          recoveryId: "r1",
          lossId: "l1",
          kind: RecoveryKind.found,
          description: "found",
          recoveredById: " ",
        ),
        throwsArgumentError,
      );
    });
    test("keeps trimmed fields", () {
      final r = RecoveryEvent.validated(
        recoveryId: " r1 ",
        lossId: " l1 ",
        kind: RecoveryKind.excavated,
        description: " Dug out ",
        recoveredById: " h9 ",
        marker: " now ",
        note: " cracked ",
      );
      expect(r.recoveryId, "r1");
      expect(r.lossId, "l1");
      expect(r.kind, RecoveryKind.excavated);
      expect(r.description, "Dug out");
      expect(r.recoveredById, "h9");
      expect(r.marker, "now");
      expect(r.note, "cracked");
    });
  });

  group("LocationRecord", () {
    test("rejects empty ids and place name", () {
      expect(
        () => LocationRecord.validated(
          locationId: "",
          placeId: "pl1",
          placeName: "Keep",
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationRecord.validated(
          locationId: "loc1",
          placeId: " ",
          placeName: "Keep",
        ),
        throwsArgumentError,
      );
      expect(
        () => LocationRecord.validated(
          locationId: "loc1",
          placeId: "pl1",
          placeName: "",
        ),
        throwsArgumentError,
      );
    });
    test("keeps markers and reports open residence", () {
      final loc = LocationRecord.validated(
        locationId: "loc1",
        placeId: "pl1",
        placeName: "Sunken Keep",
        startMarker: "First Era",
      );
      expect(loc.locationId, "loc1");
      expect(loc.placeName, "Sunken Keep");
      expect(loc.startMarker, "First Era");
      expect(loc.isCurrent, isTrue);
      final closed = LocationRecord.validated(
        locationId: "loc2",
        placeId: "pl1",
        placeName: "Sunken Keep",
        endMarker: "Second Era",
      );
      expect(closed.isCurrent, isFalse);
    });
  });

  group("OwnershipLineageRecord", () {
    OwnershipPeriod p1() => OwnershipPeriod.validated(
      periodId: "p1",
      holderId: "h1",
      holderName: "Kala",
    );
    OwnershipPeriod p2() => OwnershipPeriod.validated(
      periodId: "p2",
      holderId: "h2",
      holderName: "Renti",
      endMarker: "Now",
    );
    CustodyArrangement cu1() => CustodyArrangement.validated(
      custodyId: "cu1",
      custodianId: "c1",
      custodianName: "Order",
      role: CustodyRole.templeGuardian,
    );
    TransferEvent t1() => TransferEvent.validated(
      transferId: "t1",
      type: TransferType.sale,
      fromHolderId: "h1",
      toHolderId: "h2",
    );
    TransferEvent t2() => TransferEvent.validated(
      transferId: "t2",
      type: TransferType.theft,
      fromHolderId: "h2",
      toHolderId: "h3",
    );
    LossEvent l1() => LossEvent.validated(
      lossId: "l1",
      kind: LossKind.stolen,
      description: "taken",
    );
    RecoveryEvent r1() => RecoveryEvent.validated(
      recoveryId: "r1",
      lossId: "l1",
      kind: RecoveryKind.ransomed,
      description: "bought back",
      recoveredById: "h2",
    );
    LocationRecord loc1() => LocationRecord.validated(
      locationId: "loc1",
      placeId: "pl1",
      placeName: "Keep",
    );

    test("rejects empty artifact id", () {
      expect(
        () => OwnershipLineageRecord.validated(artifactId: "  "),
        throwsArgumentError,
      );
    });
    test("accepts minimal record with only artifact id", () {
      final rec = OwnershipLineageRecord.validated(artifactId: " art1 ");
      expect(rec.artifactId, "art1");
      expect(rec.periods, isEmpty);
      expect(rec.custodies, isEmpty);
      expect(rec.transfers, isEmpty);
      expect(rec.losses, isEmpty);
      expect(rec.recoveries, isEmpty);
      expect(rec.locations, isEmpty);
    });
    test("rejects duplicate ids within each collection", () {
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          periods: [p1(), p1()],
        ),
        throwsArgumentError,
      );
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          custody: [cu1(), cu1()],
        ),
        throwsArgumentError,
      );
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          transfers: [t1(), t1()],
        ),
        throwsArgumentError,
      );
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          losses: [l1(), l1()],
        ),
        throwsArgumentError,
      );
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          losses: [l1()],
          recoveries: [r1(), r1()],
        ),
        throwsArgumentError,
      );
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          locations: [loc1(), loc1()],
        ),
        throwsArgumentError,
      );
    });
    test("rejects recovery referencing unknown loss", () {
      expect(
        () => OwnershipLineageRecord.validated(
          artifactId: "a",
          losses: [],
          recoveries: [r1()],
        ),
        throwsArgumentError,
      );
    });
    test("accepts recovery chained to known loss", () {
      final rec = OwnershipLineageRecord.validated(
        artifactId: "a",
        losses: [l1()],
        recoveries: [r1()],
      );
      expect(rec.openLossCount, 0);
    });
    test("counts collections and open losses", () {
      final rec = OwnershipLineageRecord.validated(
        artifactId: "a",
        periods: [p1(), p2()],
        transfers: [t1(), t2()],
        losses: [l1()],
      );
      expect(rec.periodCount, 2);
      expect(rec.transferCount, 2);
      expect(rec.lossCount, 1);
      expect(rec.openLossCount, 1);
      expect(rec.isMissing, isTrue);
    });
    test("collections are immutable", () {
      final rec = OwnershipLineageRecord.validated(
        artifactId: "a",
        periods: [p1()],
      );
      expect(() => rec.periods.add(p2()), throwsUnsupportedError);
    });
    test("hasHolder and holderName lookup", () {
      final rec = OwnershipLineageRecord.validated(
        artifactId: "a",
        periods: [p1(), p2()],
      );
      expect(rec.hasHolder("h1"), isTrue);
      expect(rec.hasHolder("h9"), isFalse);
      expect(rec.holderNameFor("h2"), "Renti");
      expect(rec.holderNameFor("h9"), isNull);
    });
    test("hasViolentTransfer detects violent kinds", () {
      final violent = OwnershipLineageRecord.validated(
        artifactId: "a",
        transfers: [t2()],
      );
      final clean = OwnershipLineageRecord.validated(
        artifactId: "a",
        transfers: [t1()],
      );
      expect(violent.hasViolentTransfer, isTrue);
      expect(clean.hasViolentTransfer, isFalse);
    });
    test("isHeldByCustodian checks custody set", () {
      final rec = OwnershipLineageRecord.validated(
        artifactId: "a",
        custody: [cu1()],
      );
      expect(rec.isCustodianKnown("c1"), isTrue);
      expect(rec.isCustodianKnown("nope"), isFalse);
    });
    test("currentLocation returns open residence place name", () {
      final rec = OwnershipLineageRecord.validated(
        artifactId: "a",
        locations: [
          LocationRecord.validated(
            locationId: "locOld",
            placeId: "pl1",
            placeName: "Old Keep",
            endMarker: "X",
          ),
          loc1(),
        ],
      );
      expect(rec.currentLocation, "Keep");
      final gone = OwnershipLineageRecord.validated(
        artifactId: "b",
        locations: [
          LocationRecord.validated(
            locationId: "l",
            placeId: "p",
            placeName: "Only",
            endMarker: "Z",
          ),
        ],
      );
      expect(gone.currentLocation, isNull);
    });
  });

  group("ProvenanceEntry", () {
    test("rejects empty ids and ref", () {
      expect(
        () => ProvenanceEntry.validated(
          entryId: "",
          sequence: 0,
          kind: ProvenanceKind.period,
          refId: "p1",
        ),
        throwsArgumentError,
      );
      expect(
        () => ProvenanceEntry.validated(
          entryId: "e1",
          sequence: 0,
          kind: ProvenanceKind.period,
          refId: " ",
        ),
        throwsArgumentError,
      );
    });
    test("rejects negative sequence", () {
      expect(
        () => ProvenanceEntry.validated(
          entryId: "e1",
          sequence: -1,
          kind: ProvenanceKind.transfer,
          refId: "t1",
        ),
        throwsArgumentError,
      );
    });
    test("kinds cover the six acceptance families", () {
      final names = ProvenanceKind.values.map((k) => k.name).toSet();
      expect(
        names,
        containsAll([
          "period",
          "custody",
          "transfer",
          "loss",
          "recovery",
          "location",
        ]),
      );
    });
    test("trims ids and keeps summary", () {
      final e = ProvenanceEntry.validated(
        entryId: " e1 ",
        sequence: 2,
        kind: ProvenanceKind.transfer,
        refId: " t1 ",
        summary: " sold to Renti ",
      );
      expect(e.entryId, "e1");
      expect(e.refId, "t1");
      expect(e.summary, "sold to Renti");
      expect(e.sequence, 2);
    });
  });

  group("ProvenanceLedger", () {
    ProvenanceEntry e1() => ProvenanceEntry.validated(
      entryId: "e1",
      sequence: 1,
      kind: ProvenanceKind.period,
      refId: "p1",
    );
    ProvenanceEntry e2() => ProvenanceEntry.validated(
      entryId: "e2",
      sequence: 2,
      kind: ProvenanceKind.transfer,
      refId: "t1",
    );
    ProvenanceEntry e5() => ProvenanceEntry.validated(
      entryId: "e5",
      sequence: 5,
      kind: ProvenanceKind.loss,
      refId: "l1",
    );

    test("empty ledger has length zero", () {
      expect(ProvenanceLedger.empty("a").length, 0);
    });
    test("rejects empty artifact id", () {
      expect(() => ProvenanceLedger.empty(" "), throwsArgumentError);
    });
    test("rejects duplicate entry ids and duplicate sequences", () {
      expect(
        () => ProvenanceLedger.withEntries(
          artifactId: "a",
          entries: [e1(), e1()],
        ),
        throwsArgumentError,
      );
      expect(
        () => ProvenanceLedger.withEntries(
          artifactId: "a",
          entries: [e1(), e1().copyWithSequence(9)],
        ),
        throwsArgumentError,
      );
    });
    test("entries sorted by sequence", () {
      final l = ProvenanceLedger.withEntries(
        artifactId: "a",
        entries: [e5(), e2(), e1()],
      );
      expect(l.entries.map((e) => e.sequence).toList(), [1, 2, 5]);
      expect(l.length, 3);
    });
    test("entriesForKind filters deterministically", () {
      final l = ProvenanceLedger.withEntries(
        artifactId: "a",
        entries: [e1(), e2(), e5()],
      );
      expect(
        l
            .entriesForKind(ProvenanceKind.transfer)
            .map((e) => e.entryId)
            .toList(),
        ["e2"],
      );
      expect(l.entriesForKind(ProvenanceKind.custody), isEmpty);
    });
    test("chain describes ordered entries", () {
      final l = ProvenanceLedger.withEntries(
        artifactId: "a",
        entries: [e1(), e2()],
      );
      final c = l.chain();
      expect(c.length, 2);
      expect(c.first, contains("#1"));
      expect(c.first, contains("Period"));
      expect(c[1], contains("Transfer"));
    });
    test("hasRef finds linked ids", () {
      final l = ProvenanceLedger.withEntries(
        artifactId: "a",
        entries: [e1(), e2()],
      );
      expect(l.hasRef("t1"), isTrue);
      expect(l.hasRef("nope"), isFalse);
    });
    test("missingRefIds reports dangling links", () {
      final l = ProvenanceLedger.withEntries(artifactId: "a", entries: [e1()]);
      expect(l.danglingRefs(availableRefs: {"p1"}), isEmpty);
      expect(l.danglingRefs(availableRefs: const {}), ["p1"]);
    });
  });

  group("OwnershipLineageCatalog", () {
    OwnershipLineageRecord recA() =>
        OwnershipLineageRecord.validated(artifactId: "a");
    OwnershipLineageRecord recB() => OwnershipLineageRecord.validated(
      artifactId: "b",
      periods: [
        OwnershipPeriod.validated(
          periodId: "p1",
          holderId: "h1",
          holderName: "Kala",
        ),
      ],
    );
    test("empty catalog", () {
      final c = OwnershipLineageCatalog.empty();
      expect(c.length, 0);
      expect(c.recordFor("a"), isNull);
    });
    test("rejects duplicate artifact ids", () {
      expect(
        () => OwnershipLineageCatalog.withRecords([recA(), recA()]),
        throwsArgumentError,
      );
    });
    test("records sorted by artifact id", () {
      final c = OwnershipLineageCatalog.withRecords([recB(), recA()]);
      expect(c.records.map((r) => r.artifactId).toList(), ["a", "b"]);
      expect(c.length, 2);
      expect(c.recordFor("b"), isNotNull);
    });
    test("holdersAnywhere scans all lineages deterministically", () {
      final c = OwnershipLineageCatalog.withRecords([recB(), recA()]);
      expect(c.holderIds(), ["h1"]);
    });
    test("missingCount counts records with open losses", () {
      final missing = OwnershipLineageRecord.validated(
        artifactId: "m",
        losses: [
          LossEvent.validated(
            lossId: "l1",
            kind: LossKind.stolen,
            description: "gone",
          ),
        ],
      );
      final c = OwnershipLineageCatalog.withRecords([recA(), recB(), missing]);
      expect(c.missingCount, 1);
    });
  });
}
