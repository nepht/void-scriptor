import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/enterprise/audit/audit_log.dart';

void main() {
  test('AuditLog appends and queries by actor', () {
    final log = AuditLog(capacity: 10);
    log.append(actor: 'u1', action: 'create', target: 'shot-1');
    log.append(actor: 'u2', action: 'edit', target: 'shot-2');
    log.append(actor: 'u1', action: 'delete', target: 'shot-3');

    expect(log.byActor('u1'), hasLength(2));
    expect(log.byActor('u2'), hasLength(1));
  });

  test('AuditLog queries by action', () {
    final log = AuditLog(capacity: 10);
    log.append(actor: 'u1', action: 'create', target: 'a');
    log.append(actor: 'u1', action: 'edit', target: 'b');
    expect(log.byAction('edit'), hasLength(1));
  });

  test('AuditLog caps at capacity (ring buffer)', () {
    final log = AuditLog(capacity: 3);
    for (var i = 0; i < 5; i++) {
      log.append(actor: 'u1', action: 'create', target: 't$i');
    }
    expect(log.events, hasLength(3));
    // oldest two dropped, newest kept
    expect(log.events.first.target, 't2');
    expect(log.events.last.target, 't4');
  });
}
