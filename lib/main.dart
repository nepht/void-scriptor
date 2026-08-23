import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_diagnostics.dart';
import 'app/void_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sprint 101.3/101.9: install crash capture + startup failure tracking
  // before anything else can fail.
  final handle = await prepareBootstrap();

  runApp(const ProviderScope(child: VoidScriptorApp()));

  // Startup succeeded once the first frame renders: clear the failure
  // streak so the next launch boots normally (healthy-shutdown semantics).
  // A crash before the first frame leaves the streak intact, so repeated
  // startup failures escalate normal -> safe -> recovery on next boots.
  WidgetsBinding.instance.endOfFrame.then((_) {
    handle.store.recordHealthyShutdown();
  });
}
