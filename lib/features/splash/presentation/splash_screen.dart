import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/widgets/branding/void_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: VoidColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoidLogo(),
            SizedBox(height: 28),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: VoidColors.primary,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Initializing Void Scriptor...',
              style: TextStyle(
                color: VoidColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
