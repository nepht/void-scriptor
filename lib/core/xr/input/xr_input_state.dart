enum XrHand { left, right }

enum PassthroughMode { off, grayscale, color }

/// Hand pose (Step 41.10).
class XrHandPose {
  const XrHandPose({required this.hand, required this.pinch});

  final XrHand hand;
  final bool pinch;
}

/// Aggregated XR input state (Step 41.11–41.12).
class XrInputState {
  const XrInputState({
    required this.left,
    required this.right,
    this.passthrough = PassthroughMode.off,
  });

  final XrHandPose left;
  final XrHandPose right;
  final PassthroughMode passthrough;
}
