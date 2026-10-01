import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/theme_mode_menu.dart';
import '../../../design_system/theme/void_theme_context.dart';
import '../../../design_system/widgets/branding/void_logo.dart';

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
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  Offset _pointer = Offset.zero;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (ref.read(authControllerProvider).isLoading ||
        !_form.currentState!.validate()) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .login(email: _email.text.trim(), password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final base = dark ? context.palette.background : context.palette.surface;
    final ink = dark
        ? context.palette.textPrimary
        : context.palette.textPrimary;
    final muted = dark ? context.palette.textMuted : context.palette.textMuted;
    final accent = dark
        ? context.palette.primaryBright
        : context.palette.primary;
    final edge = dark ? context.palette.border : context.palette.border;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: edge),
    );
    final theme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? context.palette.surfaceElevated
            : context.palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: muted),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: dark
              ? context.palette.primaryBright
              : context.palette.primary,
          foregroundColor: dark ? context.palette.background : Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: edge),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(0, 48),
        ),
      ),
    );
    final form = Form(
      key: _form,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A place for your next chapter.',
              style: TextStyle(fontSize: 16, height: 1.5, color: muted),
            ),
            const SizedBox(height: 32),
            Text(
              'Email',
              style: TextStyle(color: ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              autocorrect: false,
              decoration: const InputDecoration(hintText: 'you@example.com'),
              validator: (value) =>
                  RegExp(
                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                  ).hasMatch(value?.trim() ?? '')
                  ? null
                  : 'Enter a valid email address.',
            ),
            const SizedBox(height: 22),
            Text(
              'Password',
              style: TextStyle(color: ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              focusNode: _passwordFocus,
              enabled: !auth.isLoading,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                hintText: 'Your password',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter your password.'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: auth.isLoading ? null : widget.onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: auth.isLoading ? null : _login,
              child: Text(auth.isLoading ? 'Signing in…' : 'Sign In'),
            ),
            if (auth.hasError) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Sign-in could not be completed. Try again or use Guest or Offline mode.',
                  style: TextStyle(color: theme.colorScheme.error, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Google and GitHub sign-in are not available yet.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            Divider(color: edge.withValues(alpha: .3)),
            const SizedBox(height: 16),
            Text(
              'Start without an account',
              style: TextStyle(color: ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep writing with local access.',
              style: TextStyle(color: muted, height: 1.5),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: auth.isLoading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .continueOffline(),
              icon: const Icon(Icons.folder_open_outlined, size: 20),
              label: const Text('Work Offline'),
            ),
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => ref
                        .read(authControllerProvider.notifier)
                        .continueAsGuest(),
              child: const Text('Continue as Guest'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('New here?', style: TextStyle(color: muted)),
                TextButton(
                  onPressed: auth.isLoading ? null : widget.onRegister,
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: base,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 1050 &&
                MediaQuery.textScalerOf(context).scale(16) <= 24;
            return Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/backgrounds/auth_background.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.centerLeft,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  base.withValues(
                                    alpha: dark && wide ? .5 : .92,
                                  ),
                                  base.withValues(alpha: .96),
                                  base,
                                ],
                                stops: const [0, .62, 1],
                              ),
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  base.withValues(alpha: .2),
                                  Colors.transparent,
                                  base,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 64 : 24,
                      28,
                      wide ? 64 : 24,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child:
                                        MediaQuery.textScalerOf(
                                              context,
                                            ).scale(13) >
                                            20
                                        ? const VoidLogo(compact: true)
                                        : VoidLogo(textColor: ink),
                                  ),
                                ),
                                const ThemeModeMenu(iconSize: 20),
                              ],
                            ),
                            SizedBox(height: wide ? 68 : 36),
                            if (wide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: MouseRegion(
                                      onHover: reduced
                                          ? null
                                          : (event) => setState(
                                              () => _pointer = Offset(
                                                (event.localPosition.dx / 600 -
                                                            .5)
                                                        .clamp(-.5, .5) *
                                                    12,
                                                (event.localPosition.dy / 600 -
                                                            .5)
                                                        .clamp(-.5, .5) *
                                                    12,
                                              ),
                                            ),
                                      onExit: (_) => setState(
                                        () => _pointer = Offset.zero,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 60,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ExcludeSemantics(
                                              child: TweenAnimationBuilder<Offset>(
                                                tween: Tween(
                                                  end: reduced
                                                      ? Offset.zero
                                                      : _pointer,
                                                ),
                                                duration: reduced
                                                    ? Duration.zero
                                                    : const Duration(
                                                        milliseconds: 260,
                                                      ),
                                                builder:
                                                    (context, offset, child) =>
                                                        Transform.translate(
                                                          offset: offset,
                                                          child: child,
                                                        ),
                                                child: Image.asset(
                                                  'assets/logos/void_scriptor_logo.png',
                                                  width: 110,
                                                  height: 140,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 40),
                                            Text(
                                              'Give your stories\na world to live in.',
                                              style: TextStyle(
                                                color: ink,
                                                fontSize: 48,
                                                height: 1.15,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: -1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              'Write the novel. Know your characters.\nBuild the world that connects them.',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 18,
                                                height: 1.7,
                                              ),
                                            ),
                                            const SizedBox(height: 54),
                                            Text(
                                              'NOVELS  /  CHARACTERS  /  WORLDS',
                                              style: TextStyle(
                                                color: muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 408, child: form),
                                ],
                              )
                            else
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 440,
                                  ),
                                  child: form,
                                ),
                              ),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
