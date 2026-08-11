import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VoidScriptorApp(),
    ),
  );
}

class VoidScriptorApp extends ConsumerWidget {
  const VoidScriptorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder GoRouter for initial setup
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PlaceholderHome(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Void Scriptor',
      theme: ThemeData.dark(), // Placeholder theme
      routerConfig: router,
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Void Scriptor (Multiplatform)')),
      body: const Center(
        child: Text(
          'Halo, Void Scriptor Multiplatform!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
