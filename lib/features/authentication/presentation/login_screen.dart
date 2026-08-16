import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../app/routing/app_routes.dart';
import '../../../design_system/colors/void_colors.dart';
import '../../../design_system/typography/void_typography.dart';
import '../../../design_system/widgets/branding/void_logo.dart';
import '../../../design_system/widgets/void_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    required this.onRegister,
    required this.onForgotPassword,
  });

  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    final loading = authState.isLoading;

    return Scaffold(
      backgroundColor: VoidColors.background,
      body: Stack(
        children: [
          // Full-bleed background with dark overlay for readability
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/auth_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    VoidColors.background.withValues(alpha: 0.55),
                    VoidColors.background.withValues(alpha: 0.75),
                    VoidColors.background.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
          ),
          // Akses pengaturan tampilan langsung dari layar login
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              tooltip: 'Appearance',
              onPressed: () => context.go(AppRoutes.appearance),
              icon: const Icon(Icons.palette_outlined, size: 20),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: VoidColors.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: VoidColors.borderSoft),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: VoidLogo()),

                      const SizedBox(height: 34),

                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: VoidTypography.headingLarge,
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Sign in to continue to Void Scriptor.',
                        textAlign: TextAlign.center,
                        style: VoidTypography.body,
                      ),

                      const SizedBox(height: 30),

                      const Text('Email', style: VoidTypography.label),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          hintText: 'creator@example.com',
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text('Password', style: VoidTypography.label),

                      const SizedBox(height: 8),

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 4,
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Remember me',
                            style: VoidTypography.caption,
                          ),
                          TextButton(
                            onPressed: widget.onForgotPassword,
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: VoidButton(
                          label: loading ? 'Signing In...' : 'Sign In',
                          icon: Icons.login_rounded,
                          onPressed: loading ? null : _login,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: VoidTypography.caption),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 18),

                      OutlinedButton.icon(
                        onPressed: loading
                            ? null
                            : () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .continueAsGuest();
                              },
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Continue as Guest'),
                      ),

                      const SizedBox(height: 10),

                      OutlinedButton.icon(
                        onPressed: loading
                            ? null
                            : () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .continueOffline();
                              },
                        icon: const Icon(Icons.wifi_off_outlined),
                        label: const Text('Work Offline'),
                      ),

                      const SizedBox(height: 24),

                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'No account?',
                            style: VoidTypography.caption,
                          ),
                          TextButton(
                            onPressed: widget.onRegister,
                            child: const Text('Create account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
