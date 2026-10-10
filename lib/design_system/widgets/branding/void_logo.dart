import 'package:flutter/material.dart';

import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class VoidLogo extends StatelessWidget {
  const VoidLogo({super.key, this.compact = false, this.textColor});

  final bool compact;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final labelColor = textColor ?? context.palette.textPrimary;
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
              Flexible(
                child: Text(
                  'VOID SCRIPTOR STUDIO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          );
  }
}
