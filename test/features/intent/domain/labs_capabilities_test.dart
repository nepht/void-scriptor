import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/labs_capabilities.dart';

void main() {
  test('experimental capability is disabled by default', () {
    const labs = LabsCapabilities();

    expect(labs.version, '0.51-experimental');
    expect(labs.isEnabled(LabsFeature.gaze), isFalse);
    expect(labs.fallbackFor(LabsFeature.gaze), LabsFallback.standardInput);
  });

  test('feature flag enables an opted-in capability', () {
    const labs = LabsCapabilities(enabled: {LabsFeature.gesture});

    expect(labs.isEnabled(LabsFeature.gesture), isTrue);
    expect(labs.fallbackFor(LabsFeature.gesture), LabsFallback.none);
  });

  test('unsupported capability always falls back safely', () {
    const labs = LabsCapabilities(
      enabled: {LabsFeature.bci},
      available: {LabsFeature.gesture},
    );

    expect(labs.isEnabled(LabsFeature.bci), isFalse);
    expect(labs.fallbackFor(LabsFeature.bci), LabsFallback.standardInput);
  });
}
