import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/context_stack.dart';

void main() {
  test('returns the newest active context first', () {
    final stack = IntentContextStack(clock: () => DateTime.utc(2026, 1, 1, 12));
    stack.push(const IntentContext(id: 'project', value: 'Void Scriptor'));
    stack.push(
      const IntentContext(
        id: 'selection',
        value: 'Scene One',
        ttl: Duration(minutes: 5),
      ),
    );

    expect(stack.active.map((context) => context.id), ['selection', 'project']);
    expect(stack.current?.value, 'Scene One');
  });

  test('expires contexts without affecting persistent context', () {
    var now = DateTime.utc(2026, 1, 1, 12);
    final stack = IntentContextStack(clock: () => now);
    stack.push(const IntentContext(id: 'project', value: 'Void Scriptor'));
    stack.push(
      const IntentContext(
        id: 'selection',
        value: 'Scene One',
        ttl: Duration(seconds: 10),
      ),
    );

    now = now.add(const Duration(seconds: 11));
    expect(stack.expire(), 1);
    expect(stack.active.map((context) => context.id), ['project']);
  });
}
