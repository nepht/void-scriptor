import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/async_mutex.dart';

void main() {
  test('runs immediately when idle and propagates the result', () async {
    final mutex = AsyncMutex();
    expect(mutex.isLocked, isFalse);
    final result = await mutex.run(() async => 42);
    expect(result, 42);
    expect(mutex.isLocked, isFalse);
  });

  test('serializes overlapping runs in FIFO order', () async {
    final mutex = AsyncMutex();
    final gate = Completer<void>();
    final order = <String>[];

    Future<void> record(String tag) async {
      order.add('enter:$tag');
      await gate.future;
      order.add('exit:$tag');
    }

    final first = mutex.run(() => record('a'));
    // The first run holds the mutex until the gate opens.
    expect(mutex.isLocked, isTrue);
    final second = mutex.run(() => record('b'));
    final third = mutex.run(() => record('c'));

    // Nothing else may enter while the first run is still in flight.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(order, ['enter:a']);

    gate.complete();
    await Future.wait([first, second, third]);
    expect(order, [
      'enter:a',
      'exit:a',
      'enter:b',
      'exit:b',
      'enter:c',
      'exit:c',
    ]);
    expect(mutex.isLocked, isFalse);
  });

  test('propagates errors and stays usable afterwards', () async {
    final mutex = AsyncMutex();
    await expectLater(
      mutex.run<void>(() async => throw StateError('boom')),
      throwsStateError,
    );
    expect(mutex.isLocked, isFalse);
    final result = await mutex.run(() async => 'recovered');
    expect(result, 'recovered');
  });
}
