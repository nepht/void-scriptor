import 'package:flutter/material.dart';

import '../../colors/void_colors.dart';

class VoidLogo extends StatelessWidget {
  const VoidLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return compact
        ? Image.asset(
            'assets/logos/void_scriptor_logo.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logos/void_scriptor_logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text(
                'VOID SCRIPTOR',
                style: TextStyle(
                  color: VoidColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          );
  }
}
