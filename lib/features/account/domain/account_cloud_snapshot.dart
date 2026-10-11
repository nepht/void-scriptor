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
    final linkedProviders = {
      ...?session?.linkedIdentityProviders,
      ?session?.identityProvider,
    };
    final connectedSignInId = switch (session?.identityProvider) {
      'google' => 'google-sign-in',
      'github' => 'github-sign-in',
      // Older injected/test sessions did not carry provider metadata. Keep
      // their established honest fallback rather than claiming a provider we
      // cannot identify.
      _ when authenticated => 'email-sign-in',
      _ => null,
    };

    AccountCloudService signInService({
      required String id,
      required String label,
      required String providerDescription,
    }) {
      final providerId = id.endsWith('-sign-in')
          ? id.substring(0, id.length - '-sign-in'.length)
          : null;
      final connected =
          id == connectedSignInId ||
          (providerId != null && linkedProviders.contains(providerId));
      return AccountCloudService(
        id: id,
        label: label,
        group: AccountCloudServiceGroup.signIn,
        state: connected
            ? AccountCloudConnectionState.connected
            : AccountCloudConnectionState.notConnected,
        description: connected
            ? 'Identity verified by $providerDescription.'
            : '$label sign-in is not connected.',
      );
    }

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
        signInService(
          id: 'email-sign-in',
          label: 'Email sign-in',
          providerDescription: 'the configured email identity',
        ),
        signInService(
          id: 'google-sign-in',
          label: 'Google',
          providerDescription: 'Google',
        ),
        signInService(
          id: 'microsoft-sign-in',
          label: 'Microsoft',
          providerDescription: 'Microsoft',
        ),
        signInService(
          id: 'github-sign-in',
          label: 'GitHub',
          providerDescription: 'GitHub',
        ),
        signInService(
          id: 'apple-sign-in',
          label: 'Apple ID',
          providerDescription: 'Apple ID',
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

  /// 115.52: lookup yang tidak melempar untuk entri yang memang absen.
  ///
  /// Chrome menanyakan `email-sign-in` di tiga tempat (kartu AUTHENTICATION,
  /// kartu rail, dan penentu plan). Semula semuanya memakai [service] yang
  /// `firstWhere` tanpa `orElse`, jadi snapshot yang tidak memuat entri itu
  /// melempar `StateError: Bad state: No element` dan SELURUH halaman hilang
  /// — bukan hanya badge yang salah. Ketiadaan entri berarti "belum
  /// terhubung", jadi getter ini mengembalikan null dan [connectionStateOf]
  /// meremapkannya ke state yang jujur.
  AccountCloudService? serviceOrNull(String id) {
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }

  /// State koneksi untuk [id], atau `notConnected` bila entri tidak ada.
  AccountCloudConnectionState connectionStateOf(String id) =>
      serviceOrNull(id)?.state ?? AccountCloudConnectionState.notConnected;

  /// The one sign-in identity that was verified for this snapshot, if known.
  /// A local authenticated test/session without provider metadata may still
  /// use the legacy `email-sign-in` fallback above, so this getter remains
  /// useful for both old and new session shapes.
  String? get connectedSignInServiceId {
    for (final service in services) {
      if (service.group == AccountCloudServiceGroup.signIn &&
          service.state == AccountCloudConnectionState.connected) {
        return service.id;
      }
    }
    return null;
  }
}
