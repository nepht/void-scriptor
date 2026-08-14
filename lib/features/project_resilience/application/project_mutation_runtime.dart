import 'package:flutter/foundation.dart';

import '../../../core/commands/app_command.dart';
import '../../../core/commands/command_bus.dart';
import '../../../core/commands/command_event_bus.dart';
import '../../../core/commands/command_history.dart';
import '../../../core/commands/command_type_registry.dart';
import '../../../core/commands/project_mutation_state.dart';
import '../../../database/project/project_database.dart';
import 'command_history_repository.dart';
import 'drift_transaction_coordinator.dart';

class ProjectMutationRuntime {
  ProjectMutationRuntime._({
    required this.database,
    required this.projectId,
    required this.historyRepository,
    required this.state,
    required this.stateNotifier,
    required this.readOnly,
  }) : history = CommandHistory(),
       eventBus = CommandEventBus();

  final ProjectDatabase database;
  final String projectId;
  final CommandHistoryRepository historyRepository;
  final CommandHistory history;
  final CommandEventBus eventBus;
  ProjectMutationState state;
  final ValueNotifier<ProjectMutationState> stateNotifier;
  final bool readOnly;

  static Future<ProjectMutationRuntime> open({
    required ProjectDatabase database,
    required String projectId,
    bool readOnly = false,
    CommandTypeRegistry? registry,
  }) async {
    final currentRow = await (database.select(
      database.projectMetadata,
    )..where((item) => item.key.equals('mutationSequence'))).getSingleOrNull();
    final savedRow =
        await (database.select(database.projectMetadata)
              ..where((item) => item.key.equals('savedMutationSequence')))
            .getSingleOrNull();
    final sequence = int.tryParse(currentRow?.value ?? '') ?? 0;
    final savedSequence = int.tryParse(savedRow?.value ?? '') ?? sequence;
    final runtime = ProjectMutationRuntime._(
      database: database,
      projectId: projectId,
      historyRepository: CommandHistoryRepository(database),
      state: ProjectMutationState(
        currentSequence: sequence,
        savedSequence: savedSequence,
      ),
      stateNotifier: ValueNotifier(
        ProjectMutationState(
          currentSequence: sequence,
          savedSequence: savedSequence,
        ),
      ),
      readOnly: readOnly,
    );
    runtime._replaceBus();
    if (registry != null) {
      final records = await runtime.historyRepository.list(projectId);
      runtime.history.restoreApplied(
        records
            .where((record) => record.status == CommandHistoryStatus.applied)
            .map(registry.tryCreate)
            .whereType<AppCommand>(),
      );
      runtime.history.restoreUndone(
        records
            .where((record) => record.status == CommandHistoryStatus.undone)
            .toList()
            .reversed
            .map(registry.tryCreate)
            .whereType<AppCommand>(),
      );
    }
    return runtime;
  }

  Future<void> _persist(AppCommand command) async {
    if (readOnly) {
      throw StateError('Read-only project sessions cannot execute mutations');
    }
    if (command.projectId != projectId) {
      throw StateError('Command project does not match active project');
    }
    final next = state.mutated();
    for (final redoCommand in history.redoCommands) {
      await historyRepository.markAbandoned(redoCommand.id);
    }
    await database
        .into(database.projectMetadata)
        .insertOnConflictUpdate(
          ProjectMetadataCompanion.insert(
            key: 'mutationSequence',
            value: next.currentSequence.toString(),
          ),
        );
    await historyRepository.record(
      CommandHistoryRecordInput(
        id: command.id,
        projectId: command.projectId,
        commandType: command.commandType,
        label: command.label,
        payload: command.payload,
        undoPayload: command.undoPayload,
        sequence: next.currentSequence,
        source: command.source,
      ),
    );
    _setState(next);
  }

  Future<void> _transition(
    AppCommand command,
    CommandHistoryStatus status,
  ) async {
    final next = state.mutated();
    await database
        .into(database.projectMetadata)
        .insertOnConflictUpdate(
          ProjectMetadataCompanion.insert(
            key: 'mutationSequence',
            value: next.currentSequence.toString(),
          ),
        );
    if (status == CommandHistoryStatus.undone) {
      await historyRepository.markUndone(command.id);
    } else {
      await historyRepository.markApplied(command.id);
    }
    _setState(next);
  }

  void _replaceBus() {
    // CommandBus is immutable, so the runtime creates the configured facade.
    _configuredBus = CommandBus(
      history: history,
      transactionCoordinator: DriftTransactionCoordinator(database),
      onPersist: _persist,
      onUndoPersist: (command) =>
          _transition(command, CommandHistoryStatus.undone),
      onRedoPersist: (command) =>
          _transition(command, CommandHistoryStatus.applied),
      onEvent: _publishEvent,
    );
  }

  void _publishEvent(CommandEvent event) {
    eventBus.publish(
      ProjectMutationEvent(
        projectId: event.command.projectId,
        commandType: event.command.commandType,
        sequence: state.currentSequence,
        type: event.type,
        source: event.command.source,
      ),
    );
    stateNotifier.value = state;
  }

  late CommandBus _configuredBus;

  CommandBus get bus => _configuredBus;

  void _setState(ProjectMutationState next) {
    state = next;
    stateNotifier.value = next;
  }

  Future<void> dispose() async {
    await eventBus.close();
    stateNotifier.dispose();
  }

  Future<void> markSaved() async {
    await database
        .into(database.projectMetadata)
        .insertOnConflictUpdate(
          ProjectMetadataCompanion.insert(
            key: 'savedMutationSequence',
            value: state.currentSequence.toString(),
          ),
        );
    _setState(state.saved());
  }
}
