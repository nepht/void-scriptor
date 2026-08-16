import 'package:flutter/material.dart';

import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/void_button.dart';
import 'package:void_scriptor/design_system/theme/void_theme_context.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.palette.borderSoft),
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

                  VoidButton(
                    label: 'Send Reset Link',
                    onPressed: _sendResetLink,
                  ),

                  if (_feedback != null) ...[
                    const SizedBox(height: 12),
                    Text(_feedback!, textAlign: TextAlign.center),
                  ],

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

  void _sendResetLink() {
    final email = _emailController.text.trim();
    setState(() {
      _feedback = email.isEmpty
          ? 'Enter an email address.'
          : 'Reset link request recorded in local mode.';
    });
  }
}
