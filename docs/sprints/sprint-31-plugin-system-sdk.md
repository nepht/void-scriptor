# Sprint 31 — Plugin System + SDK

> **STATUS: DONE** — 31.1–31.21 GREEN, 587 PASS, analyze 0 issues, build web ✓.

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S31 Plugin System+SDK") — hanya judul.
> Step dirancang oleh nephthys dari judul + audit repo nyata: pola registry mapan
> (`CommandTypeRegistry`, `AiProviderRegistry`), flag `PlatformCapabilities.supportsDesktopPlugins`,
> `MarketplaceCard` menyebut "plugins", `ProjectPackage` untuk direktori proyek.

## Tujuan

Membangun fondasi **sistem plugin + SDK**: model plugin, manifest, kontrak API, lifecycle host,
registry, sandbox/permission, persistence, dan UI manager — dengan batas jujur (plugin contoh
in-memory, bukan dynamic code loading dari file arbitrary yang butuh sandbox OS-level).

## Batas lingkup (jujur)

- **IN**: `PluginManifest` (JSON metadata + apiVersion + capabilities + permissions),
  `PluginDescriptor` (validated), `PluginContext` (logger/storage/eventBus/settings),
  `Plugin` interface (activate/deactivate/dispose), `PluginHost` lifecycle,
  `PluginRegistry` (register/enable/disable/list), `PluginPermission` + `PluginSandbox`
  (enforce permission), persistence (schema v42→v43: `plugins`, `plugin_settings`),
  UI `PluginManagerScreen` + install dialog + permission grant, wire route `/plugins`.
- **OUT**: dynamic code loading (isolate/.so dari file arbitrary), plugin marketplace server,
  hot-reload plugin, distribusi plugin terenkripsi, interop lintas-bahasa.

## Step

### Blok A — Model + manifest (31.1–31.3)
- **31.1** `PluginApiVersion` (major.minor + compatibility check).
- **31.2** `PluginManifest` (parse/validate JSON: id, name, version, author, apiVersion, capabilities, permissions, entrypoint).
- **31.3** `PluginDescriptor` (validated manifest + status enum).

### Blok B — SDK surface (31.4–31.6)
- **31.4** `PluginLogger` (scoped logging ke konsol/ring buffer).
- **31.5** `PluginSettingsStore` (key-value per-plugin).
- **31.6** `PluginContext` (bundle logger + settings + storage + eventBus ke plugin).

### Blok C — Plugin API + host (31.7–31.9)
- **31.7** `Plugin` interface (id, manifest, activate/deactivate/dispose).
- **31.8** `PluginHost` (lifecycle: load → validate → activate → deactivate).
- **31.9** `PluginRegistry` (register + enable/disable + list active).

### Blok D — Sandbox + permission (31.10–31.12)
- **31.10** `PluginPermission` enum (storage, network, ui, commands, projectData).
- **31.11** `PluginSandbox` (guard: check permission sebelum akses).
- **31.12** Permission set validation (invalid permission → reject).

### Blok E — Persistence (31.13–31.15)
- **31.13** Table `plugins` + `plugin_settings` (schema v42→**v43**).
- **31.14** `PluginRepository` (persist plugin state + settings).
- **31.15** Restart persistence test.

### Blok F — UI (31.16–31.18)
- **31.16** `PluginManagerScreen` (list + enable/disable + detail).
- **31.17** `PluginInstallDialog` (input manifest/URL + validate).
- **31.18** `PluginPermissionGrant` (grant/revoke per plugin).

### Blok G — Wire + DoD (31.19–31.21)
- **31.19** Wire route `/plugins` + menu.
- **31.20** Register demo plugin (built-in) di composition root.
- **31.21** DoD: full regression gates + commit + push + tandai DONE.

## Schema v43
- `plugins` (id PK, name, version, author, apiVersion, manifestJson, enabled, installedAt, updatedAt).
- `plugin_settings` (pluginId FK, key, value; PK composite).

## Risiko jujur
- Plugin in-memory = SDK & lifecycle teruji; eksekusi kode plugin asli butuh sandbox OS/isolate
  (di luar sprint ini).
- API surface SDK bisa berubah saat plugin asli dimuat (breaking change ditangani `PluginApiVersion`).
