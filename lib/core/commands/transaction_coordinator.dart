abstract interface class TransactionCoordinator {
  Future<T> run<T>(Future<T> Function() action);
}
