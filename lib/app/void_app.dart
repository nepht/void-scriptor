import 'package:flutter/material.dart';

import '../design_system/theme/void_theme.dart';
import 'shell/void_app_shell.dart';

class VoidScriptorApp extends StatelessWidget {
  const VoidScriptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: VoidTheme.dark,
      home: const VoidAppShell(),
    );
  }
}
