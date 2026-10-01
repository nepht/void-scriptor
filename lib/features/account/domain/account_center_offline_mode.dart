/// Sprint 115.44 — Offline Account Center.
///
/// Local, dependency-free metadata contract for the offline state. It describes
/// what a cached reading is, how old it is, which actions a network connection
/// still needs, and which device-scoped data keeps working without one. It
/// performs no provider request, no local scan, and no cache write, and it never
/// turns an absent reading into a zero.
library;

/// Cached-record freshness, transcribed from the 115.40/115.41 vocabulary so one
/// freshness idea does not drift into three shapes.
enum AccountCenterOfflineFreshness {
  live,
  stale,
  expired,

  /// `measuredAt` is later than the reference clock. A record that claims to
  /// have been measured in the future is a data defect, not a fresh reading.
  futureTimestamped,
}

/// Remote actions the Account Center would otherwise perform. While offline
/// every one of them is refused; the enum exists so the refusal can name the
/// action instead of reporting a generic failure.
enum AccountCenterRemoteAction {
  refreshQuota('Refresh quota'),
  fetchUsage('Fetch usage'),
  startTransfer('Start transfer'),
  listBackups('List backups'),
  readInvoices('Read invoices'),
  manageBilling('Manage billing'),
  rotateToken('Rotate token');

  const AccountCenterRemoteAction(this.label);

  final String label;
}

/// Age window used to classify a cached reading.
///
/// Validated through a factory so a nonsensical window is refused in every build
/// mode; a const constructor's `assert` disappears in release.
final class AccountCenterOfflineFreshnessPolicy {
  factory AccountCenterOfflineFreshnessPolicy({
    Duration staleAfter = const Duration(hours: 24),
    Duration expiresAfter = const Duration(days: 7),
  }) {
    if (staleAfter <= Duration.zero) {
      throw ArgumentError.value(staleAfter, 'staleAfter', 'must be positive');
    }
    if (expiresAfter <= staleAfter) {
      throw ArgumentError.value(
        expiresAfter,
        'expiresAfter',
        'must be later than staleAfter (${staleAfter.inMinutes} minutes)',
      );
    }
    return AccountCenterOfflineFreshnessPolicy._(staleAfter, expiresAfter);
  }

  const AccountCenterOfflineFreshnessPolicy._(
    this.staleAfter,
    this.expiresAfter,
  );

  final Duration staleAfter;
  final Duration expiresAfter;

  AccountCenterOfflineFreshness classify({
    required DateTime measuredAt,
    required DateTime now,
  }) {
    final age = now.toUtc().difference(measuredAt.toUtc());
    if (age.isNegative) return AccountCenterOfflineFreshness.futureTimestamped;
    if (age > expiresAfter) return AccountCenterOfflineFreshness.expired;
    if (age > staleAfter) return AccountCenterOfflineFreshness.stale;
    return AccountCenterOfflineFreshness.live;
  }
}

/// One cached provider reading as it was stored, before any age judgement.
final class AccountCenterCachedEntry {
  AccountCenterCachedEntry({
    required String providerId,
    required String label,
    required DateTime measuredAt,
    required String detail,
  }) : providerId = _text(providerId, 'providerId'),
       label = _text(label, 'label'),
       detail = _text(detail, 'detail'),
       measuredAt = measuredAt.toUtc();

  final String providerId;
  final String label;
  final DateTime measuredAt;
  final String detail;
}

/// A cached reading with its freshness verdict attached.
final class AccountCenterCachedEntryView {
  const AccountCenterCachedEntryView({
    required this.providerId,
    required this.label,
    required this.measuredAt,
    required this.detail,
    required this.freshness,
    required this.staleLabel,
  });

  final String providerId;
  final String label;
  final DateTime measuredAt;
  final String detail;
  final AccountCenterOfflineFreshness freshness;
  final String? staleLabel;

  /// Whether this reading may be presented as a value rather than as a caveat.
  bool get isUsable =>
      freshness == AccountCenterOfflineFreshness.live ||
      freshness == AccountCenterOfflineFreshness.stale;
}

/// A device-scoped setting. It is stored and read on this device, so an offline
/// session neither loses it nor needs a network connection for it.
final class AccountCenterLocalSetting {
  const AccountCenterLocalSetting({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final String value;
}

/// Local disk accounting, deliberately separate from cloud quota readings. An
/// absent summary stays `null`; it is never reported as zero bytes.
final class AccountCenterLocalStorageDetails {
  const AccountCenterLocalStorageDetails({
    required this.totalBytes,
    required this.largestCategory,
  });

  final int totalBytes;
  final String largestCategory;
}

/// Outcome of asking for a remote action while offline.
final class AccountCenterRemoteActionResult {
  const AccountCenterRemoteActionResult({
    required this.action,
    required this.allowed,
    required this.completed,
    this.reason,
  });

  final AccountCenterRemoteAction action;
  final bool allowed;
  final bool completed;
  final String? reason;
}

/// What a reconnect would do, stated before it happens.
final class AccountCenterReconnectPlan {
  const AccountCenterReconnectPlan({
    required this.label,
    required this.affectedProviders,
    required this.preservesLocalSettings,
    required this.preservesLocalStorage,
    required this.carriedSettings,
    required this.carriedStorage,
    required this.carriedPolicy,
  });

  final String label;
  final List<String> affectedProviders;
  final bool preservesLocalSettings;
  final bool preservesLocalStorage;

  /// The device-scoped data the plan carries across, so applying it cannot
  /// silently drop the settings or the local storage summary.
  final List<AccountCenterLocalSetting> carriedSettings;
  final AccountCenterLocalStorageDetails? carriedStorage;
  final AccountCenterOfflineFreshnessPolicy carriedPolicy;

  bool get requiresNetworkConnection => true;
  bool get replacesCache => true;
  bool get discardsLocalData => false;

  /// Applies the plan to a fresh set of readings. This is the only path out of
  /// the offline state, and it is explicit: the caller supplies the readings a
  /// network connection produced.
  AccountCenterOfflineMode apply({
    required List<AccountCenterCachedEntry> freshEntries,
    required DateTime now,
  }) => AccountCenterOfflineMode.cached(
    entries: freshEntries,
    now: now,
    policy: carriedPolicy,
    isOffline: false,
    localSettings: carriedSettings,
    localStorage: carriedStorage,
  );
}

/// The offline surface of the Account Center.
final class AccountCenterOfflineMode {
  AccountCenterOfflineMode._({
    required this.isOffline,
    required this.entries,
    required this.localSettings,
    required this.localStorage,
    required this.policy,
    required this.referenceNow,
  });

  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  static const List<String> canonicalAcceptance = <String>[
    'cached_metadata',
    'stale_label',
    'remote_actions_disabled',
    'local_settings_available',
    'local_storage_available',
    'reconnect_refresh',
  ];

  final bool isOffline;
  final List<AccountCenterCachedEntryView> entries;
  final List<AccountCenterLocalSetting> localSettings;
  final AccountCenterLocalStorageDetails? localStorage;
  final AccountCenterOfflineFreshnessPolicy policy;
  final DateTime referenceNow;

  static AccountCenterOfflineMode cached({
    required List<AccountCenterCachedEntry> entries,
    required DateTime now,
    AccountCenterOfflineFreshnessPolicy policy =
        const AccountCenterOfflineFreshnessPolicy._(
          Duration(hours: 24),
          Duration(days: 7),
        ),
    bool isOffline = true,
    List<AccountCenterLocalSetting> localSettings =
        const <AccountCenterLocalSetting>[],
    AccountCenterLocalStorageDetails? localStorage,
  }) {
    _rejectDuplicateProviders(entries);
    _rejectNonsensicalLocalDetail(localSettings, localStorage);
    final reference = now.toUtc();
    final views = <AccountCenterCachedEntryView>[
      for (final entry in entries)
        AccountCenterCachedEntryView(
          providerId: entry.providerId,
          label: entry.label,
          measuredAt: entry.measuredAt,
          detail: entry.detail,
          freshness: policy.classify(
            measuredAt: entry.measuredAt,
            now: reference,
          ),
          staleLabel: _staleLabel(
            policy.classify(measuredAt: entry.measuredAt, now: reference),
          ),
        ),
    ];
    return AccountCenterOfflineMode._(
      isOffline: isOffline,
      entries: List.unmodifiable(views),
      localSettings: List.unmodifiable(localSettings),
      localStorage: localStorage,
      policy: policy,
      referenceNow: reference,
    );
  }

  int get cachedEntryCount => entries.length;

  /// A cache is fully fresh only when every reading is current; one stale entry
  /// makes the whole surface caveated rather than partly trusted.
  bool get isFullyFresh =>
      entries.isNotEmpty &&
      entries.every(
        (view) => view.freshness == AccountCenterOfflineFreshness.live,
      );

  int get staleEntryCount => entries
      .where((view) => view.freshness != AccountCenterOfflineFreshness.live)
      .length;

  bool get localSettingsAvailable => localSettings.isNotEmpty;
  int get localSettingsCount => localSettings.length;
  bool get localStorageAvailable => localStorage != null;

  /// No remote action may be enabled while offline, including for a provider
  /// whose cached reading is still fresh.
  bool get remoteActionsEnabled => !isOffline;

  AccountCenterRemoteActionResult performRemoteAction(
    AccountCenterRemoteAction action,
  ) {
    if (!remoteActionsEnabled) {
      return AccountCenterRemoteActionResult(
        action: action,
        allowed: false,
        completed: false,
        reason: 'Offline mode. ${action.label} needs a network connection.',
      );
    }
    return AccountCenterRemoteActionResult(
      action: action,
      allowed: true,
      completed: false,
      reason: 'Request handed to the online transport.',
    );
  }

  String get notice {
    final buffer = StringBuffer(
      isOffline
          ? 'Offline. Showing cached metadata for $cachedEntryCount connection(s).'
          : 'Connected. Showing $cachedEntryCount live reading(s).',
    );
    final stale = staleEntryCount;
    if (stale > 0) {
      buffer.write(
        ' $stale of $cachedEntryCount cached reading(s) are not current.',
      );
    }
    if (!localSettingsAvailable) {
      buffer.write(' Local settings are unavailable on this device.');
    }
    if (!localStorageAvailable) {
      buffer.write(' Local storage details are unavailable.');
    }
    // 117.27: kalimat ini hanya boleh muncul saat aksi remote memang mati.
    // Sebelumnya ditulis tanpa syarat, jadi SESUDAH reconnect berhasil — saat
    // [remoteActionsEnabled] sudah `true` — notice tetap memberitahu pengguna
    // bahwa aksi remote dimatikan sampai ia me-reconnect, padahal ia baru
    // saja selesai reconnect. Notifikasi yang mengada-ada membuat pengguna
    // mencari penyebab yang tidak ada, dan yang lebih buruk: [isFullyFresh]
    // bernilai `true` sementara notice menyatakan ada bacaan yang tidak
    // current.
    if (!remoteActionsEnabled) {
      buffer.write(
        ' Remote actions are disabled until you reconnect and refresh.',
      );
    } else if (!isFullyFresh) {
      buffer.write(' Some readings are not current.');
    }
    return buffer.toString();
  }

  /// The only way out of the offline state, stated before it happens.
  AccountCenterReconnectPlan reconnectPlan() {
    final providers = <String>[for (final view in entries) view.providerId];
    return AccountCenterReconnectPlan(
      label: 'Reconnect and refresh',
      affectedProviders: List.unmodifiable(providers),
      preservesLocalSettings: localSettingsAvailable,
      preservesLocalStorage: localStorageAvailable,
      carriedSettings: localSettings,
      carriedStorage: localStorage,
      carriedPolicy: policy,
    );
  }

  static void _rejectDuplicateProviders(
    List<AccountCenterCachedEntry> entries,
  ) {
    final seen = <String>{};
    for (final entry in entries) {
      if (!seen.add(entry.providerId)) {
        throw ArgumentError.value(
          entry.providerId,
          'entries',
          'must not list a provider twice',
        );
      }
    }
  }

  /// Menolak detail lokal yang tidak bisa jadi hasil pengukuran apa pun.
  ///
  /// Entri cache sudah menolak identitas kosong lewat [_text], tetapi
  /// [AccountCenterLocalSetting] dan [AccountCenterLocalStorageDetails] punya
  /// constructor `const` sehingga tidak bisa melempar tanpa merusak setiap
  /// call site `const`. Hasilnya: `label: '   '`, `value: ''`, dan
  /// `totalBytes: -1` diterima lalu dilaporkan sebagai
  /// `localSettingsAvailable == true` / `localStorageAvailable == true` —
  /// membalik doktrin file ini sendiri ("an absent summary stays `null`; it is
  /// never reported as zero bytes"). Penolakan diletakkan di boundary yang
  /// sama dengan [_rejectDuplicateProviders] supaya tidak ada jalur yang
  /// melewati validasi.
  static void _rejectNonsensicalLocalDetail(
    List<AccountCenterLocalSetting> settings,
    AccountCenterLocalStorageDetails? storage,
  ) {
    for (final setting in settings) {
      _text(setting.id, 'localSettings.id');
      _text(setting.label, 'localSettings.label');
      _text(setting.value, 'localSettings.value');
    }
    if (storage == null) return;
    if (storage.totalBytes < 0) {
      throw ArgumentError.value(
        storage.totalBytes,
        'localStorage.totalBytes',
        'must not be negative (absent storage is null, never a fabricated count)',
      );
    }
    _text(storage.largestCategory, 'localStorage.largestCategory');
  }
}

String _text(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}

String? _staleLabel(AccountCenterOfflineFreshness freshness) =>
    switch (freshness) {
      AccountCenterOfflineFreshness.live => null,
      AccountCenterOfflineFreshness.stale => 'Stale',
      AccountCenterOfflineFreshness.expired => 'Expired',
      AccountCenterOfflineFreshness.futureTimestamped =>
        'Timestamped in the future',
    };
