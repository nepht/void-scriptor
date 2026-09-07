import 'package:flutter/material.dart';

import '../../../database/project/project_database.dart';
import '../application/project_lock_service.dart';
import '../crypto/encryption_cipher.dart';
import '../crypto/key_derivation.dart';

/// Security settings with encryption enable + passphrase change (Step 30.17).
///
/// core-hunt-20260906 BUG-44: the "Enkripsi Proyek" switch used to mutate
/// only local widget state. It now reflects the persisted
/// `securitySettings.encryptionEnabled` flag and drives it through
/// [ProjectLockService.setEncryptionEnabled]; enabling without a passphrase
/// (the key source) is refused with a visible message instead of silently
/// flipping state. Without a backing database the switch renders disabled —
/// never a fake toggle.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({
    super.key,
    this.onChangePassphrase,
    this.projectId,
    this.database,
  });

  final VoidCallback? onChangePassphrase;
  final String? projectId;
  final ProjectDatabase? database;

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _encryptionEnabled = false;
  bool _busy = true;

  bool get _hasStore => widget.database != null && widget.projectId != null;

  ProjectLockService _service() => ProjectLockService(
    database: widget.database!,
    deriver: const Pbkdf2KeyDeriver(),
    integrity: const HmacIntegrity(),
  );

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (!_hasStore) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final enabled = await _service().isEncryptionEnabled(widget.projectId!);
    if (mounted) {
      setState(() {
        _encryptionEnabled = enabled;
        _busy = false;
      });
    }
  }

  Future<void> _onToggle(bool value) async {
    try {
      await _service().setEncryptionEnabled(widget.projectId!, value);
      if (mounted) setState(() => _encryptionEnabled = value);
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan & Enkripsi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enkripsi Proyek'),
            subtitle: const Text('Enkripsi data proyek saat disimpan'),
            value: _encryptionEnabled,
            onChanged: (_hasStore && !_busy) ? _onToggle : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Ubah Passphrase'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onChangePassphrase,
          ),
        ],
      ),
    );
  }
}
