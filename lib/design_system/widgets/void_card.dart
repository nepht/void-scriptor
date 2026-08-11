import 'package:flutter/material.dart';

import '../colors/void_colors.dart';
import '../radius/void_radius.dart';

class VoidCard extends StatelessWidget {
  const VoidCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VoidColors.surface,
      borderRadius: BorderRadius.circular(VoidRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VoidRadius.lg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VoidRadius.lg),
            border: Border.all(color: VoidColors.borderSoft),
          ),
          child: child,
        ),
      ),
    );
  }
}
