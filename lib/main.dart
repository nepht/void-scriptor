import 'dart:io' show exit;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_diagnostics.dart';
import 'app/bootstrap/bootstrap_gate.dart';
import 'app/void_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sprint 101.3/101.9: install crash capture + startup failure tracking
  // before anything else can fail.
  final handle = await prepareBootstrap();

  // Sprint 101.9: honor the persisted decision — an escalated mode boots
  // into the dependency-free recovery surface instead of the full app.
  // The streak still clears once a frame renders: a degraded shell that
  // renders IS a healthy boot of the recovery path.
  runApp(
    ProviderScope(
      child: BootstrapGate(
        outcome: handle.lastOutcome,
        onResetConfig: () {
          // configuration_reset (101.9): wipe the persisted streak and
          // exit cleanly so the next launch boots normally.
          handle.store.reset();
          exit(0);
        },
        child: const VoidScriptorApp(),
      ),
    ),
  );

  // Startup succeeded once the first frame renders: clear the failure
  // streak so the next launch boots normally (healthy-shutdown semantics).
  // A crash before the first frame leaves the streak intact, so repeated
  // startup failures escalate normal -> safe -> recovery on next boots.
  WidgetsBinding.instance.endOfFrame.then((_) {
    handle.store.recordHealthyShutdown();
  });
}
