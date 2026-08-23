import 'package:flutter/material.dart';

import '../../../design_system/widgets/branding/void_logo.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VoidLogo(),
            const SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.palette.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Initializing Void Scriptor...',
              style: TextStyle(color: context.palette.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
