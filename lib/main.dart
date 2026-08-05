import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_scriptor/core/router.dart';
import 'package:void_scriptor/core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VoidScriptorApp());
}

class VoidScriptorApp extends StatelessWidget {
  const VoidScriptorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      theme: VoidTheme.light,
      darkTheme: VoidTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
      home: const VoidRoot(),
    );
  }
}

class VoidRoot extends StatelessWidget {
  const VoidRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const VoidRouter();
  }
}
