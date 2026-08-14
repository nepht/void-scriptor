import '../../../core/commands/transaction_coordinator.dart';
import '../../../database/project/project_database.dart';

class DriftTransactionCoordinator implements TransactionCoordinator {
  const DriftTransactionCoordinator(this.database);

  final ProjectDatabase database;

  @override
  Future<T> run<T>(Future<T> Function() action) => database.transaction(action);
}
