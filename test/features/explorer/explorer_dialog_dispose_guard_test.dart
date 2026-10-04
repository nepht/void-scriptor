// hunt-run171 BUG-14: `ref.read` setelah await dialog tanpa mounted guard
// melempar StateError('Cannot use "ref" after the widget was disposed.')
// bila panel di-dispose selagi dialog-nya sendiri masih terbuka pada
// navigator yang lebih awet (stack replacement under an open dialog,
// mis. forced logout/navigasi).
//
// Simulasi setia ke produksi: ref milik ConsumerWidget PANEL; dialog
// dibuka lewat root navigator; panel di-dispose selagi dialog terbuka;
// lalu dialog di-pop `true` sehingga helper melanjutkan ke ref.read pada
// ref yang sudah disposed. Guard yang benar (arah Referee): periksa
// context.mounted SEBELUM ref.read pasca-await, lalu bail out lebih awal.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _probeProvider = Provider<int>((ref) => 7);

/// BUGGY: pola lama explorer_panel.dart (tanpa guard mounted pasca-await).
Future<void> unguardedReadAfterDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('ok'),
        ),
      ],
    ),
  );
  if (result != true) return;
  ref.read(_probeProvider);
}

/// FIXED: pola yang diminta Referee — mounted guard sebelum ref.read.
Future<void> guardedReadAfterDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('ok'),
        ),
      ],
    ),
  );
  if (result != true) return;
  if (!context.mounted) return;
  ref.read(_probeProvider);
}

/// Host stabil (tidak pernah di-dispose selama test) — pemilik visibility.
class _Host extends StatefulWidget {
  const _Host({super.key, required this.run, required this.errorSink});
  final Future<void> Function(BuildContext, WidgetRef) run;
  final ValueNotifier<Object?> errorSink;

  @override
  State<_Host> createState() => HostState();
}

class HostState extends State<_Host> {
  bool panelVisible = true;

  void hidePanel() => setState(() => panelVisible = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: panelVisible
            // Panel = ConsumerWidget pemilik ref; dispose panel = dispose ref.
            ? _Panel(run: widget.run, errorSink: widget.errorSink)
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Panel extends ConsumerWidget {
  const _Panel({required this.run, required this.errorSink});
  final Future<void> Function(BuildContext, WidgetRef) run;
  final ValueNotifier<Object?> errorSink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (innerContext) => TextButton(
        onPressed: () {
          run(innerContext, ref).catchError((Object error) {
            errorSink.value = error;
          });
        },
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  Future<(ValueNotifier<Object?>, HostState)> pumpHost(
    WidgetTester tester,
    Future<void> Function(BuildContext, WidgetRef) run,
  ) async {
    final errorSink = ValueNotifier<Object?>(null);
    final key = GlobalKey<HostState>();
    await tester.pumpWidget(
      ProviderScope(
        child: _Host(key: key, run: run, errorSink: errorSink),
      ),
    );
    return (errorSink, key.currentState!);
  }

  Future<void> disposePanelThenPopDialog(
    WidgetTester tester,
    HostState state,
  ) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget, reason: 'dialog harus terbuka');
    // Dispose panel (dengan ref miliknya); dialog di root navigator tetap.
    state.hidePanel();
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget, reason: 'dialog harus tetap ada');
    await tester.tap(find.text('ok'));
    await tester.pumpAndSettle();
  }

  testWidgets('RED: unguarded post-await ref.read throws when panel disposes '
      'under an open dialog', (tester) async {
    final (errorSink, state) = await pumpHost(tester, unguardedReadAfterDialog);
    await disposePanelThenPopDialog(tester, state);
    expect(
      errorSink.value,
      isA<StateError>(),
      reason: 'bug hidup: read() pada disposed ref harus melempar tanpa guard',
    );
    // Riverpod 3 replaced the Riverpod 2 wording ('...ref used after being
    // disposed'). The contract under test is that reading a ref whose widget
    // is unmounted still throws a StateError — assert on that, not on the
    // library's exact sentence, so a Riverpod message change cannot silently
    // pass this regression guard.
    expect('${errorSink.value}', contains('unmounted'));
  });

  testWidgets(
    'GREEN pattern: mounted guard before ref.read prevents the throw',
    (tester) async {
      final (errorSink, state) = await pumpHost(tester, guardedReadAfterDialog);
      await disposePanelThenPopDialog(tester, state);
      expect(
        errorSink.value,
        isNull,
        reason: 'guard harus membuat jalur ini no-op',
      );
    },
  );
}
