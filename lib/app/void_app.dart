import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_controller.dart';
import '../design_system/theme/void_theme.dart';
import 'routing/app_router.dart';

class VoidScriptorApp extends ConsumerWidget {
  const VoidScriptorApp({super.key, this.routerConfig});

  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = routerConfig ?? ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider).value;

    return MaterialApp.router(
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode?.themeMode ?? ThemeMode.system,
      theme: VoidTheme.light,
      darkTheme: VoidTheme.dark,
      routerConfig: router,
    );
  }
}
