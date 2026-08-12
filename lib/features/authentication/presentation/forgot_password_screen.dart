import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/void_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: VoidColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VoidColors.borderSoft),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Reset password',
                    style: VoidTypography.headingLarge,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter your email and we will send a password reset link.',
                    style: VoidTypography.body,
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),

                  const SizedBox(height: 20),

                  VoidButton(label: 'Send Reset Link', onPressed: () {}),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
