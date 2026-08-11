import 'package:flutter/material.dart';

import '../design_system/theme/void_theme.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

class VoidScriptorApp extends StatelessWidget {
  const VoidScriptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: VoidTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
