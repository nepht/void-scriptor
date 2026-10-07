import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routing/app_router.dart';
import 'oauth_callback_arguments.dart';
import 'oauth_callback_bootstrap.dart';

/// Runs the native process-start callback exactly once after the app tree is
/// mounted. Invalid or stale callbacks are ignored without logging secrets.
final class OAuthCallbackBootstrapGate extends ConsumerStatefulWidget {
  const OAuthCallbackBootstrapGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<OAuthCallbackBootstrapGate> createState() =>
      _OAuthCallbackBootstrapGateState();
}

final class _OAuthCallbackBootstrapGateState
    extends ConsumerState<OAuthCallbackBootstrapGate> {
  bool _processed = false;
  static const MethodChannel _channel = MethodChannel('void_scriptor/oauth');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _processed) return;
      _processed = true;
      final wiring = ref.read(oauthWiringProvider);
      final bootstrap = OAuthCallbackBootstrap(
        complete: (callback) =>
            wiring.completeAuthorization(callback: callback),
      );
      bootstrap.process(getOAuthCallbackArguments());
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'callback' || call.arguments is! String) {
          return null;
        }
        await bootstrap.process(<String>['--oauth-callback=${call.arguments}']);
        return null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
