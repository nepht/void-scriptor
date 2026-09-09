import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme_mode.dart';
import '../core/theme/theme_controller.dart';
import '../design_system/theme/void_theme.dart';
import '../design_system/theme/void_theme_variant.dart';
import '../l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'project_exit_guard.dart';

class VoidScriptorApp extends ConsumerWidget {
  const VoidScriptorApp({super.key, this.routerConfig});

  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = routerConfig ?? ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider).value;
    final accent =
        ref.watch(themeAccentControllerProvider).value ??
        VoidThemeAccent.voidPurple;
    final variant = accent.variant;

    return MaterialApp.router(
      builder: (context, child) =>
          ProjectExitGuard(child: child ?? const SizedBox.shrink()),
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode?.themeMode ?? ThemeMode.system,
      theme: variant == VoidThemeVariant.voidPurple
          ? VoidTheme.light
          : variant.lightTheme,
      darkTheme: variant == VoidThemeVariant.voidPurple
          ? VoidTheme.dark
          : variant.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
