import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';

/// core-hunt run197 BUG-16: the web platform seam opened a [ProjectDatabase]
/// and returned it without closing it when [ProjectDatabase.initialize]
/// threw, while the io seam already had the catch-close-rethrow guard.
/// A drift web initialize failure (e.g. IndexedDB open error mid-migration)
/// leaked the constructed wrapper.
///
/// The contract is extracted into the platform-agnostic
/// [initializeDatabaseOrClose] helper that both seams share. The helper is
/// compiled on every platform, so the failure path is exercised here through
/// a recording stub executor instead of the js-interop web file itself.
class _RecordingExecutor implements QueryExecutor {
  _RecordingExecutor({this.failEnsureOpen = false});

  final bool failEnsureOpen;

  int ensureOpenCalls = 0;
  int closeCalls = 0;
  bool get closed => closeCalls > 0;

  bool _opened = false;
  Future<bool> get isOpen => Future<bool>.value(_opened);

  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) {
    ensureOpenCalls++;
    if (failEnsureOpen) {
      return Future.error(StateError('simulated web initialize failure'));
    }
    _opened = true;
    return Future<bool>.value(true);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    String statement,
    List<Object?> args,
  ) async => const <Map<String, Object?>>[];

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  @override
  TransactionExecutor beginTransaction() =>
      throw UnsupportedError('not needed for this contract');

  @override
  QueryExecutor beginExclusive() =>
      throw UnsupportedError('not needed for this contract');

  @override
  Future<void> close() async {
    closeCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initializeDatabaseOrClose rethrows the initialize failure', () async {
    final executor = _RecordingExecutor(failEnsureOpen: true);
    final database = ProjectDatabase(executor);

    await expectLater(
      initializeDatabaseOrClose(database),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'initializeDatabaseOrClose closes the database when initialize throws',
    () async {
      final executor = _RecordingExecutor(failEnsureOpen: true);
      final database = ProjectDatabase(executor);

      await expectLater(initializeDatabaseOrClose(database), throwsA(anything));

      // BUG-16 failure-path contract: the wrapper must not outlive a failed
      // initialize. This is the assertion that failed before the helper
      // existed (RED) and passes once the close-on-failure guard runs.
      expect(await executor.isOpen, isFalse);
      expect(executor.closed, isTrue);
    },
  );

  test(
    'initializeDatabaseOrClose returns the open database on success',
    () async {
      final executor = _RecordingExecutor();
      final database = ProjectDatabase(executor);

      final returned = await initializeDatabaseOrClose(database);

      expect(identical(returned, database), isTrue);
      expect(await executor.isOpen, isTrue);
      expect(executor.closed, isFalse);
    },
  );
}
