# Sprint 20 — Reference Library & Identity Consistency

## Status

Implemented as project-level SQLite/Drift architecture. Current schema: **v17**.

## Data flow

```text
Universal Asset owner
  → global References
  → Primary per owner + type
  → Reference Sets
  → Character Mode referenceSetId
  → Story Scene referenceSetId
  → Effective Reference Bundle
  → AI Context / Generation
  → Consistency Review
```

## Persistence

- `References`: canonical project-relative path, source, type, priority, primary, enabled, SHA-256.
- `ReferenceSets` / `ReferenceSetItems`: reusable bundles.
- `ReferenceVersions`: immutable file snapshots created before replacement. Restore copies snapshot bytes back to the stable current path and refreshes the hash.
- `PreservationLocks`: machine-readable AI preservation instructions.
- `ConsistencyRules`, `ConsistencyReviews`, `ConsistencyReviewItems`: post-generation review data.
- `CharacterModes.referenceSetId`: mode override layer.
- `StoryScenes.referenceSetId`: scene override layer (schema v17).

## Resolution precedence

```text
Character/default references
  < Character Mode reference set
  < Scene reference set
  < explicit generation-call overrides
```

Only enabled references participate. Selection then sorts primary first, preferred type, and priority, bounded by provider reference budget.

## Filesystem

Imported/generated references are copied under:

```text
assets/references/<owner-or-unowned>/<type>/
```

External source paths are never canonical. Duplicate content is rejected by SHA-256 unless explicitly permitted. Health scanning distinguishes:

- healthy;
- modified;
- missing;
- moved (relocated file found by matching basename and hash);
- incomplete;
- broken.

## UI boundaries

- `/references`: project-backed Reference Library, search/type filter, import dialog, set-primary action, missing-file fallback.
- `/references/compare`: side-by-side, overlay, and swipe comparison.
- `ReferenceManagementScreen`: Reference Sets, Identity Locks, Consistency Rules, and Reports tabs.
- `/ai/gallery`: project generation output gallery with Use as Reference and Compare with Primary actions.

Widgets do not query Drift directly. Project wrappers use Riverpod session providers and application services/repositories.

## Verification contract

Required gates after Reference schema/application changes:

```text
dart format --set-exit-if-changed lib test
dart run build_runner build
flutter analyze
flutter test
flutter build web --release
flutter build linux --debug
git diff --check
```

Linux requires `libsecret-1-dev`; GitHub Actions installs it explicitly.
