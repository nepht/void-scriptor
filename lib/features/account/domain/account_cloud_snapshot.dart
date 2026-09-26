import '../../../core/auth/auth_session.dart';
import '../../../core/auth/auth_status.dart';

enum AccountCloudConnectionState { connected, availableLocal, notConnected }

enum AccountCloudServiceGroup { signIn, localStorage, cloudStorage, sync }

class AccountCloudService {
  const AccountCloudService({
    required this.id,
    required this.label,
    required this.group,
    required this.state,
    required this.description,
    this.usageLabel,
  });

  final String id;
  final String label;
  final AccountCloudServiceGroup group;
  final AccountCloudConnectionState state;
  final String description;
  final String? usageLabel;
}

class AccountCloudSnapshot {
  AccountCloudSnapshot({
    required this.accountModeLabel,
    required this.accountDisplayName,
    required List<AccountCloudService> services,
    this.accountEmail,
  }) : services = List.unmodifiable(services);

  factory AccountCloudSnapshot.localOnly({required AuthSession? session}) {
    final authenticated = session?.status == AuthStatus.authenticated;
    final mode = switch (session?.status) {
      AuthStatus.authenticated => 'Connected account',
      AuthStatus.guest => 'Guest mode',
      AuthStatus.offline => 'Offline mode',
      _ => 'Not signed in',
    };
    return AccountCloudSnapshot(
      accountModeLabel: mode,
      accountDisplayName: session?.displayName ?? 'Local user',
      accountEmail: session?.email,
      services: [
        AccountCloudService(
          id: 'email-sign-in',
          label: 'Email sign-in',
          group: AccountCloudServiceGroup.signIn,
          state: authenticated
              ? AccountCloudConnectionState.connected
              : AccountCloudConnectionState.notConnected,
          description: authenticated
              ? 'Identity verified by the configured provider.'
              : 'An identity provider has not been configured.',
        ),
        const AccountCloudService(
          id: 'google-sign-in',
          label: 'Google',
          group: AccountCloudServiceGroup.signIn,
          state: AccountCloudConnectionState.notConnected,
          description: 'Google OAuth is not connected.',
        ),
        const AccountCloudService(
          id: 'microsoft-sign-in',
          label: 'Microsoft',
          group: AccountCloudServiceGroup.signIn,
          state: AccountCloudConnectionState.notConnected,
          description: 'Microsoft OAuth is not connected.',
        ),
        const AccountCloudService(
          id: 'github-sign-in',
          label: 'GitHub',
          group: AccountCloudServiceGroup.signIn,
          state: AccountCloudConnectionState.notConnected,
          description: 'GitHub OAuth is not connected.',
        ),
        const AccountCloudService(
          id: 'apple-sign-in',
          label: 'Apple ID',
          group: AccountCloudServiceGroup.signIn,
          state: AccountCloudConnectionState.notConnected,
          description: 'Apple ID is not connected.',
        ),
        const AccountCloudService(
          id: 'local-project-storage',
          label: 'Local project storage',
          group: AccountCloudServiceGroup.localStorage,
          state: AccountCloudConnectionState.availableLocal,
          description: 'Project packages can be stored on this device.',
        ),
        const AccountCloudService(
          id: 'folder-backup',
          label: 'Folder backup',
          group: AccountCloudServiceGroup.localStorage,
          state: AccountCloudConnectionState.availableLocal,
          description: 'Backups can be exported to a folder you choose.',
        ),
        const AccountCloudService(
          id: 'google-drive',
          label: 'Google Drive',
          group: AccountCloudServiceGroup.cloudStorage,
          state: AccountCloudConnectionState.notConnected,
          description: 'No Google Drive connection is configured.',
        ),
        const AccountCloudService(
          id: 'onedrive',
          label: 'OneDrive',
          group: AccountCloudServiceGroup.cloudStorage,
          state: AccountCloudConnectionState.notConnected,
          description: 'No OneDrive connection is configured.',
        ),
        const AccountCloudService(
          id: 'dropbox',
          label: 'Dropbox',
          group: AccountCloudServiceGroup.cloudStorage,
          state: AccountCloudConnectionState.notConnected,
          description: 'No Dropbox connection is configured.',
        ),
        const AccountCloudService(
          id: 'cloud-sync',
          label: 'Cloud sync',
          group: AccountCloudServiceGroup.sync,
          state: AccountCloudConnectionState.notConnected,
          description: 'Only local and folder-backed sync are available.',
        ),
      ],
    );
  }

  final String accountModeLabel;
  final String accountDisplayName;

  /// 115.36: email akun untuk kartu AUTHENTICATION. Null pada sesi lokal
  /// yang belum punya identitas terverifikasi.
  final String? accountEmail;
  final List<AccountCloudService> services;

  AccountCloudService service(String id) =>
      services.firstWhere((service) => service.id == id);
}
