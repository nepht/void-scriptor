import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    // Riverpod 3 auto-retries failed providers; Void Scriptor surfaces load
    // failures itself through manual error rows with a Retry action. See the
    // matching note on the root scope in lib/main.dart.
    return const ProviderScope(retry: _noAutoRetry, child: VoidScriptorApp());
  }
}

/// Disables Riverpod 3's automatic provider retry, restoring the Riverpod 2
/// runtime contract (no auto-retry) that this app's error surfaces assume.
Duration? _noAutoRetry(int retryCount, Object error) => null;
