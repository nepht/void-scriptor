# Sprint 115.2 — Reference Design Audit

Status: **VERIFIED-LOCAL** (documentation/evidence audit only)

Tanggal run: 2026-09-25

## Objective and evidence boundary

- Canonical step `115.2` requires mapping every panel in the reference image to a real capability, data source, state, and owner.
- Binding product source: `C:/Users/nepht/Documents/Codex/2026-08-22/referenced-chatgpt-conversation-this-is-an-2/outputs/account_cloud_center_spec.json`; canonical step source: `C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json`.
- Reference image: `D:/AI/design/8753e3b4-4116-4875-9b1b-f44cd0754a44.png`. The path does not exist, and bounded searches of `build/`, `docs/release/`, and the configured release root did not find a copy. The product spec records a 1536 x 1024 canvas, but no pixel-level panel mapping is claimed.
- This audit inventories the current live Account & Cloud Center implementation and records missing/unverified capabilities. It does not claim connector certification, live quotas, public billing, or production UI parity.

## Component inventory and ownership matrix

| Panel / surface | Current production surface | Real data source | State boundary | Owner | Source evidence |
|---|---|---|---|---|---|
| Header / account shell | `AccountCloudCenterScreen` + `_AccountCloudCenterScreenState` | global route + injected auth/snapshot | connected / local / not connected | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:27,54,69` |
| Authentication | `_AccountSummary` | `AuthController` / `AuthSession`; local-only snapshot | connected / available local / not connected; sign-in callback | account domain + core/auth | `lib/features/account/domain/account_cloud_snapshot.dart:33,55`; `lib/core/auth/auth_controller.dart:10,79` |
| Quick Connect | `_ServiceRow` list from cloud-storage services | `AccountCloudSnapshot.services`; no connector manifest read | service state; first four cloud services | account domain + presentation | `lib/features/account/domain/account_cloud_snapshot.dart:84,110`; `lib/features/account/presentation/account_cloud_center_screen.dart:227,243` |
| Cloud Storage Usage | `_OverviewCapabilityCard` | static unavailable text; no remote quota adapter | remote unavailable | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:250,257` |
| Connected Services Overview | `_OverviewCapabilityCard` | static post-verification message; no live service repository | no connected service in the current local snapshot | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:266,272` |
| AI Providers | `_DestinationActionCard` | route to `AiProviderWorkspaceScreen`; no account-specific provider state | route available; connection state not claimed | account presentation + app/routing | `lib/features/account/presentation/account_cloud_center_screen.dart:928,940,1041,1050`; `lib/app/routing/app_router.dart:439,442` |
| AI Usage This Month | `_AiUsageMetricsCard` | `AiUsageLogRepository.forProject`; current UTC calendar month; cost sum | loading / no open project / metrics available; estimate labeled | account application + AI application | `lib/features/account/application/account_operational_metrics.dart:25,64`; `lib/features/ai/application/ai_usage_log_repository.dart:34,54` |
| Developer Tools | `_OverviewCapabilityCard` | static no-connection message; no developer manifest | unavailable | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:280,284,944,949` |
| Creative Tools | `_OverviewCapabilityCard` | static no-connection message; no creative manifest | unavailable | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:286,290,950,955` |
| Payment Methods | `_OverviewCapabilityCard` | static no-method message; no payment repository | unavailable | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:292,296,984,991` |
| API Keys Manager / API Keys | `_OverviewCapabilityCard` + `EncryptedCredentialStore` | vault primitive exists; no account API-key inventory or reveal action in this screen | no key values exposed; manager not implemented | core/security + account presentation | `lib/core/security/application/encrypted_credential_store.dart:8,51`; `lib/features/account/presentation/account_cloud_center_screen.dart:298,302,942,961` |
| Team & Collaboration | `_OverviewCapabilityCard` | no team/member/invitation source in the inspected account source | not configured / unavailable | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:304,308,962,969` |
| Activity Log | `_OverviewCapabilityCard` | no account activity source in the inspected account source | no activity recorded / unavailable | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:310,314,970,983` |
| Backup & Sync | `_ServiceCard` / `_QuickActionsCard` | local folder backup and project backup routes; cloud sync remains not connected | local available; remote unavailable | account domain + project-resilience application | `lib/features/account/domain/account_cloud_snapshot.dart:77,82,105,110`; `lib/features/project_resilience/application/project_backup_restore_flow.dart:23,55` |
| Security Center | `_DestinationActionCard` + `SecuritySettingsScreen` route | local project security tools; no account telemetry source | local route available; telemetry unavailable | core/security + app/routing | `lib/features/account/presentation/account_cloud_center_screen.dart:321,325,1052,1062`; `lib/app/routing/app_router.dart:411,414` |
| Plan | `_PlanSummaryCard` | account mode/display name only; no subscription provider | local auth mode; subscription unavailable | account domain + presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:690,732` |
| Credits & Tokens | `_CreditsCard` | static unavailable/local-only metric tiles; no balance provider | unavailable / local only | account presentation | `lib/features/account/presentation/account_cloud_center_screen.dart:733,778` |
| Storage Distribution | `_StorageDistributionCard` | `ProjectStorageAnalyzer` scans the active local package by category | loading / no open project / metrics available; local only | account application + project-resilience application | `lib/features/account/application/account_operational_metrics.dart:48,63`; `lib/features/project_resilience/application/project_storage_analyzer.dart:42,95` |
| Quick Actions | `_QuickActionsCard` | injected callback seams; defaults route to AI Providers and Project Backups | local actions available; sync disabled without provider | account presentation + routing callbacks | `lib/features/account/presentation/account_cloud_center_screen.dart:779,817` |

## Data-source and state rules observed

- `AccountCloudSnapshot.localOnly` is the only current account snapshot factory. It derives identity state from `AuthSession.status` and creates local/not-connected service records; it does not read a connector manifest or provider API.
- AI usage and local storage metrics are the only live operational data sources: `AiUsageLogRepository` and `ProjectStorageAnalyzer` operate on the active project, not remote account telemetry.
- `EncryptedCredentialStore` provides an encrypted credential-store primitive; no account API-key inventory/reveal flow is present in the inspected screen.
- `AuthIdentityProvider` defaults to `UnavailableAuthIdentityProvider`; OAuth/PKCE, live identity connections, and external health remain unverified.
- The screen preserves extension-point callbacks for future sync/backup/provider actions; the default sync action is disabled when no provider is connected.
- Local and remote storage are not merged in the current metrics implementation; remote quota is explicitly unavailable.

## Canonical reference areas vs current live status

| Canonical reference area | Current local evidence | Classification |
|---|---|---|
| Authentication / Connected Accounts | Implemented local auth summary; connected, guest, offline, and not-signed-in states; Google/GitHub rows remain not connected. | PARTIAL — local identity only |
| Quick Connect / Connected Services | Cloud-service rows are visible, but availability is a local snapshot default rather than a connector manifest/API. | PARTIAL |
| Cloud Storage Usage | Local storage distribution exists; remote quota/provider usage is static unavailable text. | PARTIAL |
| AI Providers / AI Usage | Route and local monthly usage/cost summary exist; live provider inventory/health/quotas not present. | PARTIAL |
| API Keys | Encrypted credential primitive exists; no account manager UI in current source. | PARTIAL / MISSING |
| Team & Collaboration | Placeholder only; no source or owner for members/seats/invitations. | MISSING |
| Activity & Audit | Placeholder only; no account activity source. | MISSING |
| Security Center | Local security route exists; account session/device/telemetry summary absent. | PARTIAL |
| Backup & Sync | Local backup destination/services and route exist; cloud sync unavailable. | PARTIAL |
| Billing / Plan / Credits / Team seats | Unavailable labels and no payment/plan/balance owner; product spec says planned/not verified. | MISSING / DEFERRED-EXTERNAL |

## Route and workspace boundary

- Global route constant: `lib/app/routing/app_routes.dart:21` (`/account-cloud`).
- Global navigation destination: `lib/app/navigation/app_navigation_registry.dart:168-174`.
- Desktop and mobile shell entries point to the same global route (`void_desktop_shell.dart:160`, `void_mobile_shell.dart:140-143`).
- The account screen is mounted in `app_router.dart:90-92` and `391-394`; the bounded source scan found no nested Novel/Character workspace route owning it.
- The product-spec route target is `/account/cloud-center`; the live application currently exposes `/account-cloud`. This route-contract mismatch is recorded for canonical step 115.3 and is not silently rewritten in this audit.

## Mock data register

| Mock/reference datum | Current production path | Register decision |
|---|---|---|
| Reference quota examples (`420 GB / 1 TB`, Drive/OneDrive/Dropbox/Mega values) | `account_cloud_center_spec.json` only; product spec marks `production_use_allowed: false` | EXCLUDED; do not copy into state |
| `Connected account` / `Guest mode` / `Offline mode` | Derived from `AuthSession.status` in `AccountCloudSnapshot.localOnly` | Live-derived label, not a fabricated account |
| Cloud-service `notConnected` entries | Explicit local-only snapshot defaults | Honest unavailable state, not provider certification |
| `AI Credits: Unavailable`, `Render Credits: Unavailable`, `Team Seats: Unavailable` | Static UI labels with no balance source | Explicit unavailable, not mock values |

## Gaps carried to later canonical steps

1. The canonical reference image is unavailable at its specified path, so this is a source/spec/current-implementation audit rather than a pixel-complete image audit.
2. Connector manifest, provider/API-backed quota, API-key inventory, team/collaboration, activity/audit, billing, and device/session sources are absent or placeholder in the inspected local scope.
3. Responsive visual, accessibility, localization, native interaction, and external certification remain separate steps/gates.
4. The live route `/account-cloud` differs from the product-spec primary route `/account/cloud-center`; canonical 115.3 owns the information-architecture decision and route contract.

## Verification

Commands are serialized in this order; no Flutter/native command ran concurrently.

- `tasklist.exe | grep -Ei 'flutter|dart|dartvm|msbuild|cmake|ninja|gen_snapshot'` — exit 0; no matching process.
- `D:\DevTools\Flutter SDK\flutter\bin\dart.bat run tool/roadmap_guard.dart` — exit 0; `ROADMAP_GUARD: PASS`, canonical sprint 115, recommended step 115.2, last resolved step 115.1, SHA-256 `c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba`.
- `D:\DevTools\Flutter SDK\flutter\bin\flutter.bat test --no-pub test/features/account -j 1` — exit 0; 9 tests passed.
- `D:\DevTools\Flutter SDK\flutter\bin\flutter.bat analyze --no-pub lib/features/account test/features/account` — exit 0; `No issues found!`.
- `D:\DevTools\Flutter SDK\flutter\bin\dart.bat format --output=none --set-exit-if-changed lib/features/account test/features/account` — exit 0; 0 files changed.
- `git diff --check` — exit 0.
- `D:\DevTools\Flutter SDK\flutter\bin\flutter.bat build windows --debug --no-pub` — exit 0; built `build/windows/x64/runner/Debug/void_scriptor.exe`.
- Pre-slice HEAD: `521298f4cea74063514c1c8db9e11d8abb3aa8f7`; no production/test file was changed by this documentation-only audit.

## Verdict

**VERIFIED-LOCAL** for the bounded 115.2 audit artifact: current panels, data sources, states, owners, route boundary, mock-data exclusions, and the explicit route mismatch are recorded from live source and fresh executable evidence. The product is **not** complete for the full Account & Cloud Center; the listed missing capabilities and all external gates remain pending or deferred to their canonical later steps.

## Next canonical step

`115.3 Global Information Architecture`.
