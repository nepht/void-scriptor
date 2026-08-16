import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/xr/session/xr_session.dart';

void main() {
  test('XrSessionState values', () {
    expect(XrSessionState.values, hasLength(5));
    expect(XrSessionState.idle.name, 'idle');
  });

  test('XrSession start-pause-resume-end transitions', () {
    final session = XrSession();
    expect(session.state, XrSessionState.idle);
    session.start();
    expect(session.state, XrSessionState.running);
    session.pause();
    expect(session.state, XrSessionState.paused);
    session.resume();
    expect(session.state, XrSessionState.running);
    session.end();
    expect(session.state, XrSessionState.ended);
  });

  test('invalid transition throws', () {
    final session = XrSession();
    expect(() => session.pause(), throwsStateError);
  });
}
