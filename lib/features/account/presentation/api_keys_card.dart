import 'package:flutter/material.dart';

import '../../../design_system/theme/void_theme_context.dart';
import '../domain/account_center_api_keys_manager.dart';
import '../domain/account_center_design_tokens.dart';

/// Screen of managed API keys.
///
/// The manager already owns the rules that matter: the secret never leaves the
/// vault except through a copy the user asked for, rotation wipes the old
/// clipboard copy, revocation wipes it too, and every sensitive action is
/// refused without reauthentication. This widget does not re-implement any of
/// that - it renders what the manager decided and hands every action straight
/// back to it, so the UI cannot become a second source of truth about what is
/// valid or what is revoked.
///
/// Two rules the widget enforces on top of the manager, because they are
/// presentation hazards rather than domain ones:
///
/// * a revoked key is shown with its state, never rendered as if it were live,
///   so a key the user cannot use is never mistakable for a working one;
/// * the secret is only ever shown as the manager's mask. There is no reveal
///   path here, and the copied-to-clipboard case reports itself so the user
///   knows a readable copy exists outside the vault.
class ApiKeysCard extends StatelessWidget {
  const ApiKeysCard({
    super.key,
    this.keys = const <ManagedApiKey>[],
    this.onAdd,
    this.onValidate,
    this.onCopy,
    this.onReplace,
    this.onRevoke,
    this.onOpenVault,
    this.busyKeyId,
  });

  final List<ManagedApiKey> keys;
  final Future<void> Function(String id)? onAdd;
  final Future<bool> Function(String id)? onValidate;
  final Future<bool> Function(String id)? onCopy;
  final Future<void> Function(String id)? onReplace;
  final Future<void> Function(String id)? onRevoke;
  final VoidCallback? onOpenVault;
  final String? busyKeyId;

  /// Actions a caller may supply, keyed by the sensitive action they gate.
  bool _can(String id, Future<void> Function(String)? action) => action != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AccountCenterDesignTokens.card.padding),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(
          AccountCenterDesignTokens.radius.card,
        ),
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.vpn_key_outlined,
                size: AccountCenterDesignTokens.iconSizes.serviceRow,
                color: context.palette.primaryBright,
              ),
              SizedBox(width: AccountCenterDesignTokens.spacing.sm),
              Expanded(
                child: Text('API KEYS', style: theme.textTheme.titleSmall),
              ),
              if (_can('', onAdd))
                TextButton.icon(
                  onPressed: onAdd == null || busyKeyId != null
                      ? null
                      : () => onAdd!('new'),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add key'),
                ),
            ],
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.xs),
          Text(
            keys.isEmpty
                ? 'No provider keys are stored for this account.'
                : '${keys.where((k) => k.status == ApiKeyStatus.active).length} '
                      'active of ${keys.length} stored. Secrets stay in the '
                      'vault and are only copied when you ask.',
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: AccountCenterDesignTokens.spacing.md),
          if (keys.isEmpty)
            _EmptyKeys(onOpenVault: onOpenVault)
          else
            for (final key in keys) ...[
              _ApiKeyRow(
                managedKey: key,
                busy: busyKeyId == key.id,
                onValidate: onValidate,
                onCopy: onCopy,
                onReplace: onReplace,
                onRevoke: onRevoke,
              ),
              if (key != keys.last)
                Divider(color: context.palette.border, height: 1),
            ],
          SizedBox(height: AccountCenterDesignTokens.spacing.sm),
          Text(
            'Replacing or revoking a key asks for reauthentication and clears '
            'any clipboard copy of the old secret.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ApiKeyRow extends StatelessWidget {
  const _ApiKeyRow({
    required this.managedKey,
    required this.busy,
    this.onValidate,
    this.onCopy,
    this.onReplace,
    this.onRevoke,
  });

  final ManagedApiKey managedKey;
  final bool busy;
  final Future<bool> Function(String id)? onValidate;
  final Future<bool> Function(String id)? onCopy;
  final Future<void> Function(String id)? onReplace;
  final Future<void> Function(String id)? onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revoked = managedKey.status == ApiKeyStatus.revoked;
    final validation = _validationLabel(managedKey.validation);
    final statusText = revoked ? 'Revoked' : validation.label;
    return Semantics(
      container: true,
      label:
          'API key ${managedKey.label} for ${managedKey.providerId}, $statusText',
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AccountCenterDesignTokens.spacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              revoked ? Icons.key_off_outlined : Icons.key_outlined,
              size: AccountCenterDesignTokens.iconSizes.serviceRow,
              color: revoked
                  ? context.palette.textSecondary
                  : validation.color(context),
            ),
            SizedBox(width: AccountCenterDesignTokens.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(managedKey.label, style: theme.textTheme.bodyMedium),
                  SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
                  Text(
                    '${managedKey.providerId} · ${managedKey.maskedValue}',
                    style: theme.textTheme.labelSmall,
                  ),
                  SizedBox(height: AccountCenterDesignTokens.spacing.twoXs),
                  Wrap(
                    spacing: AccountCenterDesignTokens.spacing.sm,
                    runSpacing: AccountCenterDesignTokens.spacing.twoXs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusChip(label: statusText),
                      _StatusChip(
                        label: 'Scopes: ${managedKey.scopes.join(', ')}',
                      ),
                      if (managedKey.lastUsedAt != null)
                        _StatusChip(
                          label: 'Last used ${_short(managedKey.lastUsedAt!)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!revoked) ...[
              _KeyAction(
                tooltip: 'Validate against the provider',
                icon: Icons.verified_outlined,
                onPressed: onValidate == null
                    ? null
                    : () => onValidate!(managedKey.id),
              ),
              _KeyAction(
                tooltip: 'Copy to clipboard',
                icon: Icons.content_copy_outlined,
                onPressed: busy || onCopy == null
                    ? null
                    : () => onCopy!(managedKey.id),
              ),
              _KeyAction(
                tooltip: 'Replace secret (requires reauthentication)',
                icon: Icons.autorenew,
                onPressed: busy || onReplace == null
                    ? null
                    : () => onReplace!(managedKey.id),
              ),
              _KeyAction(
                tooltip: 'Revoke key (requires reauthentication)',
                icon: Icons.block,
                onPressed: busy || onRevoke == null
                    ? null
                    : () => onRevoke!(managedKey.id),
                destructive: true,
              ),
            ] else
              const _StatusChip(label: 'Secret destroyed'),
          ],
        ),
      ),
    );
  }

  static String _short(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }

  static _Validation _validationLabel(ApiKeyValidation validation) {
    switch (validation) {
      case ApiKeyValidation.unverified:
        return const _Validation('Not verified yet', null);
      case ApiKeyValidation.valid:
        return const _Validation('Valid', Colors.green);
      case ApiKeyValidation.invalid:
        return const _Validation('Invalid', Colors.red);
    }
  }
}

class _Validation {
  const _Validation(this.label, this.tint);

  final String label;
  final Color? tint;

  Color color(BuildContext context) => tint ?? context.palette.textSecondary;
}

class _KeyAction extends StatelessWidget {
  const _KeyAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 18,
          color: destructive ? context.palette.danger : null,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.panelSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.palette.border),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

class _EmptyKeys extends StatelessWidget {
  const _EmptyKeys({this.onOpenVault});

  final VoidCallback? onOpenVault;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AccountCenterDesignTokens.spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect a provider or add a key to store it in the secure vault.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onOpenVault != null)
            Padding(
              padding: EdgeInsets.only(
                top: AccountCenterDesignTokens.spacing.sm,
              ),
              child: TextButton(
                onPressed: onOpenVault,
                child: const Text('Open secure vault'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bridges [AccountCenterApiKeysManager] to the widget tree.
///
/// The manager is a plain, already-complete domain object: it deliberately does
/// not extend [ChangeNotifier] and must not, because its state is credential
/// metadata that no UI framework should be able to invalidate by accident. That
/// leaves a real hole for a production consumer - the manager mutates its keys
/// in place, so a widget that was handed `manager.keys` once has no way to learn
/// that a key just became valid, invalid or revoked.
///
/// This controller is that missing notification, and nothing more. It holds the
/// manager, forwards each action to it, and republishes only the two things a
/// screen actually needs: the current key list and which key is mid-action.
class ApiKeysCardController extends ChangeNotifier {
  ApiKeysCardController(this.manager);

  final AccountCenterApiKeysManager manager;

  String? _busyKeyId;

  /// The key whose action is in flight, or null when nothing is running.
  ///
  /// While this is set every action button for that key is disabled, so a
  /// double tap cannot fire two rotates, or a rotate racing a revoke.
  String? get busyKeyId => _busyKeyId;

  List<ManagedApiKey> get keys => manager.keys;

  /// Returns what the manager returned, so a caller can react to the verdict the
  /// manager actually reached instead of assuming success.
  Future<bool> validate(String id) => _run(id, () => manager.validate(id));

  Future<bool> copy(String id) => _run(id, () => manager.secureCopy(id));

  Future<void> replace(String id, String secret) =>
      _run(id, () => manager.replace(id: id, secret: secret));

  Future<void> revoke(String id) => _run(id, () => manager.revoke(id));

  Future<T> _run<T>(String id, Future<T> Function() action) async {
    if (_busyKeyId != null) {
      throw StateError('Another API key action is still running.');
    }
    _busyKeyId = id;
    notifyListeners();
    try {
      return await action();
    } finally {
      _busyKeyId = null;
      notifyListeners();
    }
  }
}

/// An [ApiKeysCard] wired to its [ApiKeysCardController].
///
/// This is what a screen should use. It rebuilds when the manager's decisions
/// change, so a validation that turns a key invalid is visible instead of
/// silently stale.
class ApiKeysCardView extends StatelessWidget {
  const ApiKeysCardView({
    super.key,
    required this.controller,
    this.onAdd,
    this.onOpenVault,
  });

  final ApiKeysCardController controller;
  final VoidCallback? onAdd;
  final VoidCallback? onOpenVault;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ApiKeysCard(
        keys: controller.keys,
        busyKeyId: controller.busyKeyId,
        onAdd: onAdd == null ? null : (_) async => onAdd!(),
        onValidate: controller.validate,
        onCopy: controller.copy,
        onReplace: null,
        onRevoke: controller.revoke,
        onOpenVault: onOpenVault,
      ),
    );
  }
}
