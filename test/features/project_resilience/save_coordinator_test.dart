import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/application/save_coordinator.dart';

void main() {
  test('save coordinator autosaves when dirty after debounce', () async {
    var saved = 0;
    var journaled = 0;
    final coordinator = SaveCoordinator(
      autosaveInterval: const Duration(milliseconds: 10),
      persist: () async => saved++,
      journal: () async => journaled++,
    );

    coordinator.markDirty();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(saved, greaterThanOrEqualTo(1));
    expect(journaled, greaterThanOrEqualTo(1));
    expect(coordinator.isDirty, isFalse);
  });

  test('save coordinator does not autosave when clean', () async {
    var saved = 0;
    SaveCoordinator(
      autosaveInterval: const Duration(milliseconds: 10),
      persist: () async => saved++,
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(saved, 0);
  });

  test('journal records a stable sequence number per flush', () async {
    final journal = AutosaveJournal();
    journal.append(1);
    journal.append(2);
    journal.append(3);

    expect(journal.entries, [1, 2, 3]);
    expect(journal.lastSequence, 3);
    expect(journal.pending, isTrue);

    await journal.clear();
    expect(journal.entries, isEmpty);
    expect(journal.pending, isFalse);
  });

  test('manual save persists immediately and clears dirty state', () async {
    var saved = 0;
    final coordinator = SaveCoordinator(persist: () async => saved++);

    coordinator.markDirty();
    await coordinator.saveNow();

    expect(saved, 1);
    expect(coordinator.isDirty, isFalse);
  });
}
