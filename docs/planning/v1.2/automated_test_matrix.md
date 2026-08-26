# 109.45 — Automated Test Matrix

**Required suites:** unit, integration, contract, migration, UI, end-to-end,
regression.

## Matrix

| Suite | Discovery/coverage evidence |
|---|---|
| unit | Domain tests under `test/**/domain/`, including export/subplot contracts. |
| integration | Persistence/repository and `*_integration_test.dart` suites. |
| contract | `*_contract_test.dart` plus `test/sprint_109_test_matrix_test.dart`. |
| migration | Workspace/database migration and rollback tests. |
| UI | Presentation/widget tests, including workspace projections and dialogs. |
| end-to-end | `test/e2e/sprint_109_export_workspace_e2e_test.dart` composes quest → board → alert → clean export → preflight manifest. |
| regression | Existing release/hotfix regression suites plus explicit 109.39–109.44 regression path assertions. |

## Executable contract

`test/sprint_109_test_matrix_test.dart` discovers non-empty `*_test.dart` files
and asserts every required category has executable coverage. It also names the
109.39–109.44 regression slices explicitly. The E2E test validates the real
cross-module flow using production domain APIs rather than mocks.

## Evidence

- Initial RED: matrix correctly detected missing end-to-end coverage.
- E2E initial RED: test used stale guessed APIs; corrected to live
  `ExportProfile.plainText()`, `ExportPreflightRequest`, and
  `CleanExportResult.text`.
- Matrix + E2E focused suite: **4/4 passed**.
- Scoped analyzer: **No issues found**.
- Full gate is required before commit.

This step adds test coverage and discovery only; it does not weaken existing
acceptance criteria or claim production E2E/browser coverage beyond the tested
in-process contract path.

## Limitations

The E2E category here is a deterministic in-process end-to-end domain flow, not
native desktop automation. Native GUI/E2E coverage remains separately governed
by the existing widget/integration suites.

No secrets, credentials, or external services are used.
