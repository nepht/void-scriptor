# Sprint 25 — Undo/Redo, Command System, History, and Versioning

**Status:** In progress  
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

## Next vertical slices

1. Replace the no-op transaction abstraction in project sessions with Drift `database.transaction`. **Coordinator implemented and rollback-tested; session wiring remains pending.**
2. Add project-scoped `CommandHistoryEntries` with schema migration 34→35, repository serialization, and stable command type registry. **Completed in current checkpoint.**
3. Add mutation sequence and dirty state derived from current/saved sequence. **Domain state completed; session persistence pending.**
4. Add real Character rename command as the first repository-backed mutation tracer.
5. Wire command bus to undo/redo shortcuts and toolbar state.
6. Add composite/bulk command failure rollback against a real project database.
7. Add revisions, snapshots, compare, restore, and asset versions only after command persistence is proven.

## Design boundaries

- Undo stack is per open project session and may be empty after reopen.
- Persistent command history is audit/revision input and is not the same thing as the RAM undo stack.
- Cache, export, login, migration internals, and permanent trash deletion are not automatically undoable.
- All project data mutation commands must remain project-scoped and pass through the active session.
