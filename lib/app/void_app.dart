import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/theme/void_theme.dart';
import 'routing/app_router.dart';

class VoidScriptorApp extends ConsumerWidget {
  const VoidScriptorApp({super.key, this.routerConfig});

  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = routerConfig ?? ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: VoidTheme.dark,
      routerConfig: router,
    );
  }
}
