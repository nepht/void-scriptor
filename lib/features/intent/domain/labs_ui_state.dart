class LabsUiState {
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void toggle() => _isVisible = !_isVisible;
}
