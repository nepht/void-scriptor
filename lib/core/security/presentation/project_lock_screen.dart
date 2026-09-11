import 'package:flutter/material.dart';

/// Passphrase entry screen to unlock an encrypted project (Step 30.16).
///
/// Wiring sprint Task 2 (bug-hunt run197 BUG-12) made this screen live for
/// the open-project flow: [onUnlock] returns whether the passphrase was
/// accepted, and [errorText] (set by the caller after a rejected attempt)
/// keeps the prompt open with an inline error instead of bouncing the user
/// back to a generic failure.
class ProjectLockScreen extends StatefulWidget {
  const ProjectLockScreen({
    super.key,
    required this.projectName,
    this.errorText,
    this.onUnlock,
  });

  final String projectName;

  /// Inline rejection message shown under the field; null hides it.
  final String? errorText;

  /// Called with the typed passphrase; resolves true when the project was
  /// unlocked (and opened by the caller), false when rejected.
  final Future<bool> Function(String passphrase)? onUnlock;

  @override
  State<ProjectLockScreen> createState() => _ProjectLockScreenState();
}

class _ProjectLockScreenState extends State<ProjectLockScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final onUnlock = widget.onUnlock;
    if (onUnlock == null || _busy) return;
    setState(() => _busy = true);
    bool accepted = false;
    try {
      accepted = await onUnlock(_controller.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    // A rejected attempt keeps the typed text so the user can fix a typo;
    // success unmounts this screen via the caller's state update.
    if (accepted && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyek Terkunci')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.projectName} terkunci',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Passphrase',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (widget.errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Memeriksa…' : 'Buka Proyek'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
