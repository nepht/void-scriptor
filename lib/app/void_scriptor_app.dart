import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_router.dart';

class VoidScriptorApp extends StatefulWidget {
  const VoidScriptorApp({super.key, this.routerConfig});

  final GoRouter? routerConfig;

  @override
  State<VoidScriptorApp> createState() => _VoidScriptorAppState();
}

class _VoidScriptorAppState extends State<VoidScriptorApp> {
  late GoRouter _router = widget.routerConfig ?? createAppRouter();
  late bool _ownsRouter = widget.routerConfig == null;

  @override
  void didUpdateWidget(covariant VoidScriptorApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.routerConfig, oldWidget.routerConfig)) return;

    if (_ownsRouter) _router.dispose();
    _router = widget.routerConfig ?? createAppRouter();
    _ownsRouter = widget.routerConfig == null;
  }

  @override
  void dispose() {
    if (_ownsRouter) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Void Scriptor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: _router,
    );
  }
}
