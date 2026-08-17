/// Sprint 50 — Step 50.36–50.40 Accessibility.
class AccessibilityState {
  const AccessibilityState({
    required this.reduceMotion,
    required this.highContrast,
    this.textScaleFactor = 1.0,
    this.screenReaderEnabled = false,
  });

  final bool reduceMotion;
  final bool highContrast;
  final double textScaleFactor;
  final bool screenReaderEnabled;
}
