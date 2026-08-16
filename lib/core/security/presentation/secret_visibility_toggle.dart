import 'package:flutter/material.dart';

/// Reusable secret visibility toggle (Step 30.18).
class SecretVisibilityToggle extends StatelessWidget {
  const SecretVisibilityToggle({
    super.key,
    required this.hidden,
    required this.onChanged,
  });

  final bool hidden;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
      tooltip: hidden ? 'Tampilkan' : 'Sembunyikan',
      onPressed: () => onChanged(!hidden),
    );
  }
}
