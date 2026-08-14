# Sprint 25 — Undo/Redo, Command System, History, and Versioning

**Status:** Complete — local gates passed; hosted CI remains blocked by GitHub billing.
**Current checkpoint:** 25.1 Mutation architecture foundation

## Goal

Route user-visible mutations through a command pipeline so undo/redo, transaction boundaries, persistent history, revisions, and downstream event consumers can be added without coupling editors directly to Drift repositories.

## Pipeline contract

```text
USER ACTION
    ↓
COMMAND
    ↓
VALIDATE
    ↓
TRANSACTION
    ↓
DATABASE
    ↓
HISTORY
    ↓
EVENT BUS
    ↓
UI UPDATE
```

## Implemented in checkpoint 25.1

- `AppCommand` mutation contract with stable `id`, `projectId`, and `label`.
- `BaseCommand` with explicit `execute`, `undo`, and default `redo` behavior.
- `CommandHistory` with:
  - undo and redo stacks;
  - redo invalidation after a new command;
  - bounded in-memory capacity, default 200;
  - failure-safe stack restoration;
  - labels for toolbar/tooltips;
  - session-scoped clear operation.
- `TransactionCoordinator` abstraction.
- `CommandBus` that executes a command inside a transaction, records history only after successful execution, and emits command events after commit.
- `CompositeCommand` with forward execution/redo and reverse-order undo.
- Existing command-palette entries migrated from the mutation name `AppCommand` to `PaletteCommand`, keeping palette behavior separate from persistent mutation commands.

## Tests completed

- Command history execute/undo/redo.
- Redo invalidation.
- History capacity.
- Transaction commit and rollback behavior.
- No history/event on command failure.
- Composite command reverse undo and forward redo.
- Existing command registry and global search regression.

## Sprint 25 completion slices

- Drift `CommandHistoryEntries` schema migration 34→35, project filtering, payload JSON, undo payload, status transitions, and stable command metadata.
- Real `DriftTransactionCoordinator` with rollback test.
- `ProjectMutationRuntime` attached to every writable/read-only project session, including durable mutation sequence and save point.
- Repository-backed `RenameCharacterCommand` with project ownership validation and atomic Character + Asset rename.
- CommandBus persistence callbacks for execute, undo, and redo plus event-driven history/status refresh.
- Desktop Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl/Cmd+Y, and Ctrl/Cmd+S shortcuts.
- Status bar indicators for dirty, undoable, and redoable state.
- Package-scoped snapshot/version service with create, list, compare, restore, and retention pruning.
- Full focused and regression tests for the above slices.

## Verification

The final local verification command is:

```text
dart run build_runner build
 dart format --set-exit-if-changed lib test
 flutter analyze
 flutter test
 flutter build web --release
 git diff --check
```

Hosted CI cannot currently be used as a code signal because GitHub refuses to start jobs while billing/spending-limit is blocked.

## Design boundaries

- Undo stack is per open project session and may be empty after reopen.
- Persistent command history is audit/revision input and is not the same thing as the RAM undo stack.
- Cache, export, login, migration internals, and permanent trash deletion are not automatically undoable.
- All project data mutation commands must remain project-scoped and pass through the active session.
