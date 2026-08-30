// Sprint 110.49 - Alpha 2 Acceptance Gate (test slice).
//
// Verifier-style slice for the 110.49 acceptance gate. The gate aggregates the
// alpha-2 canonical 8 evidence items from `sprint_110.json` step 110.49, verifies
// that any blocked item forces a `NO-GO` decision, and confirms the canonical
// order of the eight kinds. Domain-only, deterministic, no persistence, UI, wall
// clock, locale, random, or network.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/alpha2_acceptance_gate.dart";

Alpha2AcceptanceReport _buildReport({
  int verifiedSteps = 10,
  int totalSteps = 10,
  bool determinismGreen = true,
  bool testResultsGreen = true,
  bool benchReportWithinBudget = true,
  String threatReviewFixStatus = "acceptable",
  String a11yFixStatus = "acceptable",
  bool rollbackRecorded = true,
}) {
  final evidences = Alpha2AcceptanceGate.buildCanonicalEvidence(
    verifiedSteps: verifiedSteps,
    totalSteps: totalSteps,
    determinismGreen: determinismGreen,
    testResultsGreen: testResultsGreen,
    benchReportWithinBudget: benchReportWithinBudget,
    threatReviewFixStatus: threatReviewFixStatus,
    a11yFixStatus: a11yFixStatus,
    rollbackRecorded: rollbackRecorded,
  );
  return Alpha2AcceptanceReport.from(
    scope: Alpha2FeatureScope(
      totalSteps: totalSteps,
      verifiedSteps: verifiedSteps,
      capabilities: Alpha2AcceptanceGate.canonicalCapabilities,
    ),
    evidences: evidences,
  );
}

void main() {
  group("110.49 canonical evidence kinds", () {
    test("migration_results is recorded rather than blocked", () {
      // D-SCHEMA-01 is OPEN; Wave-2 is additive-only with documented
      // rollback. The migration item thus is always covered by default.
      final report = _buildReport();
      expect(
        report.evidenceFor(Alpha2EvidenceKind.migrationResults).status,
        equals(Alpha2EvidenceStatus.recorded),
      );
    });

    test("eight kinds in canonical order", () {
      final report = _buildReport();
      expect(
        report.evidences.map((e) => e.kind),
        equals(Alpha2EvidenceKind.values),
      );
    });

    test("each kind slug matches sprint_110.json required_evidence", () {
      final slugs = Alpha2EvidenceKind.values.map((k) => k.slug);
      expect(
        slugs,
        containsAll(<String>[
          "feature_acceptance",
          "determinism_results",
          "test_results",
          "migration_results",
          "performance_results",
          "security_review",
          "accessibility_review",
          "rollback_readiness",
        ]),
      );
    });
  });

  group("110.49 status mapping - blocked item forces NO-GO", () {
    test("determinism failed forces NO-GO", () {
      final report = _buildReport(determinismGreen: false);
      expect(report.isBlocked, isTrue);
      expect(report.summary, contains("decision=NO-GO"));
    });

    test("test results failed forces NO-GO", () {
      final report = _buildReport(testResultsGreen: false);
      expect(report.isBlocked, isTrue);
    });

    test("performance out of budget forces NO-GO", () {
      final report = _buildReport(benchReportWithinBudget: false);
      expect(report.isBlocked, isTrue);
    });

    test("security actionRequired forces NO-GO", () {
      final report = _buildReport(threatReviewFixStatus: "actionRequired");
      expect(report.isBlocked, isTrue);
    });

    test("accessibility actionRequired forces NO-GO", () {
      final report = _buildReport(a11yFixStatus: "actionRequired");
      expect(report.isBlocked, isTrue);
    });

    test("rollback not recorded forces NO-GO", () {
      final report = _buildReport(rollbackRecorded: false);
      expect(report.isBlocked, isTrue);
    });
  });

  group("110.49 status mapping - pass items are covered", () {
    test("security clean raises to pass status", () {
      final evidence = Alpha2AcceptanceGate.buildCanonicalEvidence(
        verifiedSteps: 10,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "clean",
        a11yFixStatus: "acceptable",
        rollbackRecorded: true,
      );
      final securityEvidence = evidence.firstWhere(
        (e) => e.kind == Alpha2EvidenceKind.securityReview,
      );
      expect(securityEvidence.status, equals(Alpha2EvidenceStatus.pass));
      expect(securityEvidence.isCovered, isTrue);
    });

    test("accessibility clean raises to pass status", () {
      final evidence = Alpha2AcceptanceGate.buildCanonicalEvidence(
        verifiedSteps: 10,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "acceptable",
        a11yFixStatus: "clean",
        rollbackRecorded: true,
      ).firstWhere((e) => e.kind == Alpha2EvidenceKind.accessibilityReview);
      expect(evidence.status, equals(Alpha2EvidenceStatus.pass));
    });

    test("performance within budget is passLocal", () {
      final evidence = Alpha2AcceptanceGate.buildCanonicalEvidence(
        verifiedSteps: 10,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "acceptable",
        a11yFixStatus: "acceptable",
        rollbackRecorded: true,
      ).firstWhere((e) => e.kind == Alpha2EvidenceKind.performanceResults);
      expect(evidence.status, equals(Alpha2EvidenceStatus.passLocal));
    });

    test("feature_acceptance reflects verified steps", () {
      final evidence = Alpha2AcceptanceGate.buildCanonicalEvidence(
        verifiedSteps: 7,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "acceptable",
        a11yFixStatus: "acceptable",
        rollbackRecorded: true,
      ).firstWhere((e) => e.kind == Alpha2EvidenceKind.featureAcceptance);
      expect(evidence.status, equals(Alpha2EvidenceStatus.passLocal));
      expect(evidence.notes, contains("7/10"));
    });

    test("migration is recorded", () {
      final evidence = Alpha2AcceptanceGate.buildCanonicalEvidence(
        verifiedSteps: 10,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "acceptable",
        a11yFixStatus: "acceptable",
        rollbackRecorded: true,
      ).firstWhere((e) => e.kind == Alpha2EvidenceKind.migrationResults);
      expect(evidence.status, equals(Alpha2EvidenceStatus.recorded));
    });
  });

  group("110.49 decision summary - GO vs GO_WITH_DOCUMENTED_RISK vs NO-GO", () {
    test("full pass scenario yields GO decision", () {
      final report = _buildReport(
        verifiedSteps: 10,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "clean",
        a11yFixStatus: "clean",
        rollbackRecorded: true,
      );
      expect(report.isBlocked, isFalse);
      expect(report.allEvidenceCovered, isTrue);
      expect(report.summary, contains("decision=GO"));
    });

    test("partial governance yields GO_WITH_DOCUMENTED_RISK (passLocal)", () {
      final report = _buildReport(
        verifiedSteps: 8,
        determinismGreen: true,
        testResultsGreen: true,
        benchReportWithinBudget: true,
        threatReviewFixStatus: "acceptable",
        a11yFixStatus: "acceptable",
        rollbackRecorded: true,
      );
      expect(report.isBlocked, isFalse);
      expect(report.scope.allStepsVerified, isFalse);
      expect(report.summary, contains("decision=GO_WITH_DOCUMENTED_RISK"));
    });

    test("summary includes steps fround and total", () {
      final report = _buildReport(verifiedSteps: 7);
      expect(report.summary, contains("steps=7/10"));
    });

    test("summary includes covered evidence count", () {
      final report = _buildReport();
      expect(report.summary, contains("evidence_count=8/8"));
    });
  });

  group("110.49 assertions and contract guards", () {
    test("totalSteps: 0 raises AssertionError", () {
      expect(
        () => Alpha2AcceptanceGate.buildCanonicalEvidence(
          verifiedSteps: 1,
          totalSteps: 0,
          determinismGreen: true,
          testResultsGreen: true,
          benchReportWithinBudget: true,
          threatReviewFixStatus: "acceptable",
          a11yFixStatus: "acceptable",
          rollbackRecorded: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test("verifiedSteps above totalSteps raises AssertionError", () {
      expect(
        () => Alpha2AcceptanceGate.buildCanonicalEvidence(
          verifiedSteps: 12,
          totalSteps: 10,
          determinismGreen: true,
          testResultsGreen: true,
          benchReportWithinBudget: true,
          threatReviewFixStatus: "acceptable",
          a11yFixStatus: "acceptable",
          rollbackRecorded: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test("canonical capabilities lists ten entries", () {
      expect(Alpha2AcceptanceGate.canonicalCapabilities.length, 10);
      expect(
        Alpha2AcceptanceGate.canonicalCapabilities,
        contains("world_time_state_authority"),
      );
      expect(
        Alpha2AcceptanceGate.canonicalCapabilities,
        contains("communication_rumor"),
      );
    });
  });
}
