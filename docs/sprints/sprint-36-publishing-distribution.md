# Sprint 36 — Publishing + Distribution

> **STATUS: PROPOSAL**
> **Sumber judul kanonik**: uteke memory `90d845b9` ("S36 Publishing+Distribution") — hanya judul.
> Fondasi audit: `PortableProjectExporter` (zip `.voidproject`), `ArchiveManifest`,
> `ProjectPackage`, `ProjectManifest` (schemaVersion/version/tags).

## Tujuan

Membangun **publishing + distribution pipeline** deterministic: build target, release
channel (alpha/beta/stable), publish manifest (versi/changelog/checksum), dan distribution
pipeline (build → package → publish record). Bukan CDN upload real.

## Batas lingkup (jujur)

- **IN**: `BuildTarget` (web/desktop/mobile/package), `ReleaseChannel` (alpha/beta/stable),
  `PublishManifest` (version/semver/changelog/checksum/artifacts), `PublishRecord`
  (state machine draft/review/published/rejected), `PublishingPipeline`
  (build → package → publish), `DistributionManager` (channel registry + latest release),
  UI `PublishingPanel` + route `/publishing`.
- **OUT**: real CDN upload, store submission (App Store/Play), signing/notarization,
  network distribution server. Ini **manifest + pipeline model** CPU.

## Step

### Blok A — Build target + release channel (36.1–36.3)
- **36.1** `BuildTarget` enum (web, desktop, mobile, package).
- **36.2** `ReleaseChannel` enum (alpha, beta, stable).
- **36.3** `SemVer` (major.minor.patch + parse + compare).

### Blok B — Publish manifest (36.4–36.6)
- **36.4** `PublishManifest` (version, changelog, checksum, artifacts).
- **36.5** Manifest JSON serialize/deserialize.
- **36.6** Manifest validation (version required, changelog non-empty).

### Blok C — Publish record (36.7–36.9)
- **36.7** `PublishRecord` (id, manifest, channel, state, publishedAt).
- **36.8** `PublishState` (draft/review/published/rejected).
- **36.9** `DistributionManager` (publish + latest per channel).

### Blok D — Pipeline (36.10–36.12)
- **36.10** `PublishingPipeline` (build → package → publish).
- **36.11** Pipeline stage reporting (build/package/publish status).
- **36.12** Failure propagation (stage error → pipeline fails).

### Blok E — Persistence (36.13–36.15)
- **36.13** Table `publish_records` (schema v46→**v47**).
- **36.14** `PublishRepository` (persist record).
- **36.15** Restart persistence test (file-backed).

### Blok F — UI (36.16–36.18)
- **36.16** `PublishingPanel` (channels + latest release).
- **36.17** `PublishManifestView` (version + changelog).
- **36.18** `ReleaseChannelSelector`.

### Blok G — Demo + wire (36.19–36.21)
- **36.19** Wire route `/publishing`.
- **36.20** `DemoPublishing` built-in.
- **36.21** DoD: full regression gates + commit + tandai DONE.

## Schema v47
- `publish_records` (id PK, channel, version, state, checksum, publishedAt, changelog).

## Risiko jujur
- Manifest + pipeline model CPU; bukan CDN/store upload / signing.
