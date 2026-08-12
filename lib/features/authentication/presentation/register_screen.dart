import 'package:flutter/material.dart';

import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../design_system/widgets/void_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoidColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: VoidColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VoidColors.borderSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: VoidLogo()),

                  const SizedBox(height: 30),

                  const Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: VoidTypography.headingLarge,
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                  ),

                  const SizedBox(height: 24),

                  VoidButton(
                    label: 'Create Account',
                    icon: Icons.person_add_outlined,
                    onPressed: () {},
                  ),

                  const SizedBox(height: 18),

                  TextButton(
                    onPressed: widget.onBackToLogin,
                    child: const Text('Already have an account? Sign in'),
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
