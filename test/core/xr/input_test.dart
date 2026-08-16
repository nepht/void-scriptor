import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/xr/input/xr_input_state.dart';

void main() {
  test('XrHandPose holds hand state', () {
    const left = XrHandPose(hand: XrHand.left, pinch: true);
    const right = XrHandPose(hand: XrHand.right, pinch: false);
    expect(left.hand, XrHand.left);
    expect(left.pinch, isTrue);
    expect(right.pinch, isFalse);
  });

  test('PassthroughMode values', () {
    expect(PassthroughMode.values, hasLength(3));
    expect(PassthroughMode.color.name, 'color');
  });

  test('XrInputState aggregates hands and passthrough', () {
    const state = XrInputState(
      left: XrHandPose(hand: XrHand.left, pinch: true),
      right: XrHandPose(hand: XrHand.right, pinch: false),
      passthrough: PassthroughMode.grayscale,
    );
    expect(state.left.pinch, isTrue);
    expect(state.passthrough, PassthroughMode.grayscale);
  });
}
