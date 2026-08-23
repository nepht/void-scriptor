import 'package:flutter/material.dart';

import 'startup_recovery_policy.dart';

/// Sprint 101.9 — the UI half of startup recovery.
///
/// [RecoveryShell] is the degraded boot surface shown when
/// [StartupRecoveryPolicy] escalates past normal mode. It is intentionally
/// dependency-free: no repositories, no database, no platform channels —
/// only what a broken boot can still guarantee.
class RecoveryShell extends StatelessWidget {
  final StartupMode mode;
  final int failureCount;
  final bool suggestDiagnostics;
  final VoidCallback? onRetry;
  final VoidCallback? onResetConfig;

  const RecoveryShell({
    super.key,
    required this.mode,
    this.failureCount = 0,
    this.suggestDiagnostics = false,
    this.onRetry,
    this.onResetConfig,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                mode == StartupMode.recovery
                    ? Icons.build_circle_outlined
                    : Icons.shield_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                mode == StartupMode.recovery ? 'Recovery Mode' : 'Safe Mode',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'VOID SCRIPTOR failed to start cleanly $failureCount'
                '${failureCount == 1 ? ' time' : ' times'} in a row.',
                textAlign: TextAlign.center,
              ),
              if (suggestDiagnostics) ...[
                const SizedBox(height: 8),
                Text(
                  'Crash diagnostics were written to the application support '
                  'directory and can be attached to a bug report.',
                  key: const Key('recovery-diagnostics-hint'),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
              if (mode == StartupMode.recovery && onResetConfig != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onResetConfig,
                  child: const Text('Reset configuration'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sprint 101.9 — swaps the real app for [RecoveryShell] whenever the
/// persisted failure streak escalated past [StartupMode.normal]. A healthy
/// decision renders [child] untouched.
class BootstrapGate extends StatelessWidget {
  final StartupRecoveryOutcome outcome;
  final Widget child;

  /// Wired by the composition root (see `main.dart`): wipes the persisted
  /// startup state (the configuration_reset mode of 101.9) and exits so
  /// the next launch boots normally. Null keeps the button hidden.
  final VoidCallback? onResetConfig;

  const BootstrapGate({
    super.key,
    required this.outcome,
    required this.child,
    this.onResetConfig,
  });

  @override
  Widget build(BuildContext context) {
    if (outcome.mode == StartupMode.normal) {
      return child;
    }
    return RecoveryShell(
      mode: outcome.mode,
      failureCount: outcome.failureCountAfterDecision,
      suggestDiagnostics: outcome.suggestDiagnostics,
      onResetConfig: onResetConfig,
    );
  }
}
