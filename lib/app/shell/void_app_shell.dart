import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../adaptive/void_breakpoints.dart';
import '../routing/app_routes.dart';
import '../../core/security/presentation/project_lock_screen.dart';
import '../../features/project_resilience/application/project_session_manager.dart';
import '../../features/projects/presentation/project_persistence_providers.dart';
import '../../database/project/project_database_service.dart';
import 'desktop/void_desktop_shell.dart';
import 'mobile/void_mobile_shell.dart';

class VoidAppShell extends ConsumerStatefulWidget {
  const VoidAppShell({super.key, this.content, this.onLogout, this.projectId});

  final Widget? content;
  final VoidCallback? onLogout;
  final String? projectId;

  @override
  ConsumerState<VoidAppShell> createState() => _VoidAppShellState();
}

/// vs-hunt-20260911 BUG-10: human display name for the locked-project
/// prompt. Resolved from the project list (registry-backed); a fresh or
/// unlisted project falls back to its id, so the prompt is never blank.
final projectNameProvider = FutureProvider.family<String, String>((
  ref,
  projectId,
) async {
  try {
    final entries = await ref.watch(projectRegistryServiceProvider).load();
    for (final entry in entries) {
      if (entry.id == projectId && entry.name.isNotEmpty) return entry.name;
    }
  } catch (_) {
    // Registry unavailable: the caller falls back to the id.
  }
  return projectId;
});

/// Sprint 145.42: pesan pemulihan spesifik untuk keadaan database bertipe
/// hasil klasifikasi [classifyProjectDatabaseOpenError]. Selain keempat
/// klasifikasi ini, pesan generik dipertahankan untuk error tak terduga
/// agar tidak pernah mengarang diagnosis.
String _openFailureMessage(Object? error) {
  if (error is ProjectDatabaseWriteFailedException) {
    return 'Penyimpanan proyek menolak penulisan. Bebaskan ruang disk atau '
        'pulihkan izin tulis folder proyek, lalu coba lagi.';
  }
  if (error is ProjectDatabaseUnavailableException) {
    return 'Lokasi penyimpanan proyek tidak dapat diakses. Pastikan drive '
        'atau lokasi kustom terpasang, lalu coba lagi.';
  }
  if (error is ProjectDatabaseLockedException) {
    return 'Proyek sedang dibuka aplikasi lain. Tutup aplikasi yang memakai '
        'proyek ini, lalu coba lagi.';
  }
  if (error is ProjectDatabaseUnreadableException) {
    return 'Basis data proyek tidak dapat dibaca. Cadangkan folder proyek '
        'sebelum mencoba pemulihan backup.';
  }
  // vs-hunt-20260911 BUG-5 defensive tail: a healthy-but-locked project that
  // reaches the generic screen (unlock-probe failure path) must not be told
  // to check its folder — the real problem is the passphrase lock.
  if (error is ProjectLockedException) {
    return 'Proyek terkunci passphrase. Masukkan passphrase yang benar '
        'untuk membuka proyek ini.';
  }
  return 'Periksa lokasi folder, izin akses, dan kondisi berkas proyek, '
      'lalu coba lagi.';
}

class _VoidAppShellState extends ConsumerState<VoidAppShell> {
  bool _opening = false;
  Object? _openError;
  String? _unlockError;
  bool _unlocking = false;

  /// Wiring sprint Task 2 (BUG-12): the passphrase prompt-and-retry flow for
  /// [ProjectLockedException]. True on success; false keeps the prompt up
  /// with an inline rejection message.
  ///
  /// vs-hunt-20260911 BUG-4: the open-request token is captured and
  /// re-checked after every await — an unlock that settles after a
  /// navigation must not write state into (or reopen a session for) the
  /// project the shell has since moved away from.
  Future<bool> _unlockProject(String passphrase) async {
    final projectId = widget.projectId;
    if (projectId == null || _unlocking) return false;
    _unlocking = true;
    final request = _openRequest;
    try {
      final opened = await ref
          .read(projectSessionProvider.notifier)
          .unlockAndOpen(projectId, passphrase);
      final current =
          mounted && request == _openRequest && widget.projectId == projectId;
      if (opened && current) {
        setState(() {
          _openError = null;
          _unlockError = null;
        });
      } else if (current) {
        setState(() => _unlockError = 'Passphrase salah. Coba lagi.');
      }
      return opened;
    } catch (error) {
      // Unlock probe failures (typed database classification etc.) surface
      // through the generic open-error screen, not as a rejected passphrase.
      if (mounted && request == _openRequest) {
        setState(() {
          _openError = error;
          _unlockError = null;
        });
      }
      return false;
    } finally {
      _unlocking = false;
    }
  }

  int _openRequest = 0;
  @override
  void initState() {
    super.initState();
    _openProject(widget.projectId);
  }

  @override
  void didUpdateWidget(covariant VoidAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _openProject(widget.projectId);
    }
  }

  void _openProject(String? projectId) {
    final request = ++_openRequest;
    if (projectId == null) {
      _opening = false;
      _openError = null;
      _unlockError = null;
      return;
    }
    Future<void>.microtask(() async {
      if (!mounted || request != _openRequest) return;
      setState(() {
        _opening = true;
        _openError = null;
        _unlockError = null;
      });
      try {
        await ref.read(projectSessionProvider.notifier).openProject(projectId);
      } catch (error) {
        if (mounted && request == _openRequest) {
          setState(() {
            _openError = error;
          });
        }
      } finally {
        if (mounted && request == _openRequest) {
          setState(() {
            _opening = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_opening || _openError != null) {
      final error = _openError;
      if (error is ProjectLockedException) {
        // BUG-12 prompt-and-retry contract: passphrase prompt replaces the
        // generic failure screen; a rejected attempt keeps it up inline.
        // vs-hunt-20260911 BUG-5: no `_unlocking` render gate — that flag
        // flipped without setState, so any unrelated rebuild mid-unlock
        // bounced the user to the generic screen. The busy state (disabled
        // 'Memeriksa…' button) is owned by ProjectLockScreen itself.
        final resolved = ref.watch(projectNameProvider(error.projectId));
        return ProjectLockScreen(
          projectName: resolved.value ?? error.projectId,
          errorText: _unlockError,
          onUnlock: _unlockProject,
        );
      }
      final locked =
          error is StateError &&
          error.message == 'Project has an active or stale session';
      return Scaffold(
        appBar: AppBar(title: const Text('Buka proyek')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _opening ? 'Memuat proyek…' : 'Proyek tidak dapat dibuka',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_opening)
                    const CircularProgressIndicator()
                  else ...[
                    Text(
                      locked
                          ? 'Proyek memiliki sesi aktif atau penanda sesi lama. Tutup aplikasi lain yang memakai proyek ini. Jika masih terkunci, pulihkan penanda sesi setelah mencadangkan proyek.'
                          : _openFailureMessage(error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _openProject(widget.projectId),
                      child: const Text('Coba lagi'),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.projects),
                      child: const Text('Kembali ke Projects'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < VoidBreakpoints.tablet) {
          return VoidMobileShell(
            content: widget.content,
            onLogout: widget.onLogout,
            projectId: widget.projectId,
          );
        }

        return VoidDesktopShell(
          content: widget.content,
          onLogout: widget.onLogout,
          projectId: widget.projectId,
        );
      },
    );
  }
}
