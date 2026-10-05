import 'dart:io' show exit;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/bootstrap/app_diagnostics.dart';
import 'app/bootstrap/bootstrap_gate.dart';
import 'app/void_app.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_session.dart';
import 'core/auth/auth_session_platform.dart'
    if (dart.library.io) 'core/auth/auth_session_platform_io.dart'
    if (dart.library.js_interop) 'core/auth/auth_session_platform_web.dart';
import 'core/auth/auth_session_store.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sprint 101.3/101.9: install crash capture + startup failure tracking
  // before anything else can fail.
  final handle = await prepareBootstrap();

  // Sprint 145.20: install the disk-backed session store at the composition
  // root so Guest/Offline sessions survive restarts on desktop. Web keeps
  // the in-memory provider default; a store failure must never block boot.
  AuthSessionStore? sessionStore;
  AuthSession? initialSession;
  if (!kIsWeb) {
    try {
      sessionStore = await createDiskAuthSessionStore();
      initialSession = await loadLocalFirstAuthSession(sessionStore);
    } on Object {
      sessionStore = null;
      initialSession = const AuthSession.offline();
    }
  }

  // Sprint 101.9: honor the persisted decision — an escalated mode boots
  // into the dependency-free recovery surface instead of the full app.
  // The streak still clears once a frame renders: a degraded shell that
  // renders IS a healthy boot of the recovery path.
  runApp(
    ProviderScope(
      // Riverpod 3 auto-retries a failed provider (exponential backoff, up
      // to 10 attempts). This app already surfaces load failures itself:
      // panels render a manual error row with a Retry action (BUG-8 catalog,
      // BUG-20 sidebar module preferences), plus SectionErrorBoundary. Silent
      // auto-retry makes those rows flash and vanish, which reinstates the
      // silent-masking bug they exist to prevent and makes the manual Retry
      // button useless. Riverpod 2 had no auto-retry, so disabling it restores
      // the exact pre-upgrade runtime contract instead of re-inventing one.
      retry: (_, _) => null,
      overrides: [
        if (sessionStore != null)
          authSessionStoreProvider.overrideWithValue(sessionStore),
        if (initialSession != null)
          initialAuthSessionProvider.overrideWithValue(initialSession),
      ],
      // BootstrapGate must always have the minimum Material environment.
      // RecoveryShell can be the first rendered surface, before the full
      // VoidScriptorApp (and its own app shell) is safe to construct.
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BootstrapGate(
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
