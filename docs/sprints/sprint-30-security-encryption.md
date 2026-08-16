# Sprint 30 — Security + Encryption

> **Sumber judul kanonik**: uteke memory `90d845b9` ("S30 Security+Encryption") — hanya judul.
> Step dirancang oleh nephthys dari judul + audit repo nyata (`credential_store.dart`, dep
> `crypto` sudah ada, `sha256` dipakai untuk integrity file).

## Tujuan

Menambah lapisan **keamanan & enkripsi** pada fondasi yang sudah ada: key derivation,
enkripsi at-rest (AES-GCM), integrity HMAC, vault kredensial terenkripsi, redaction secret,
dan passphrase project lock — dengan batas jujur (enkripsi lokal; key management cloud & audit
eksternal tetap di luar).

## Batas lingkup (jujur)

- **IN**: PBKDF2 key derivation (murni `crypto` HMAC), AES-256-GCM (dep `cryptography`),
  HMAC-SHA256 integrity, `EncryptedBlob` envelope, `EncryptedCredentialStore` (wrapping),
  redaction/masking, passphrase lock/unlock, security settings screen.
- **OUT**: key escrow/cloud KMS, HSM, audit log terpusat, zero-knowledge sync server,
  enkripsi multi-user E2E (butuh backend nyata).

## Step

### Blok A — Key derivation (30.1–30.3)
- **30.1** `SecretKey` model (immutable bytes + zeroing).
- **30.2** `Pbkdf2KeyDeriver` (RFC 2898, HMAC-SHA256 via `crypto`).
- **30.3** `MasterKeyGenerator` (`Random.secure` 32 bytes).

### Blok B — Encryption cipher (30.4–30.6)
- **30.4** `EncryptionCipher` interface + `EncryptedBlob` (nonce + ciphertext + tag).
- **30.5** `AesGcmCipher` (dep `cryptography`, web-safe).
- **30.6** `HmacIntegrity` (HMAC-SHA256 signature + verify).

### Blok C — At-rest encryption service (30.7–30.9)
- **30.7** `EncryptionService` (encrypt/decrypt bytes + string).
- **30.8** `EncryptedFileService` (encrypt/decrypt file ke `.enc`).
- **30.9** Round-trip restart persistence test (file → disk → decrypt).

### Blok D — Secret vault (30.10–30.12)
- **30.10** `EncryptedCredentialStore` (wrap nilai credential dengan cipher sebelum simpan).
- **30.11** `SecretRedactor` (mask API key / redact dari log).
- **30.12** `SecretScanner` (deteksi pola secret untuk warning).

### Blok E — Passphrase project lock (30.13–30.15)
- **30.13** `ProjectLockService` (lock/unlock, verifikasi passphrase via PBKDF2+HMAC).
- **30.14** `ProjectLockState` + repository (schema v41→**v42**: `security_settings`).
- **30.15** Integrity manifest (daftar file + hash, verify).

### Blok F — UI (30.16–30.18)
- **30.16** `ProjectLockScreen` (passphrase entry, lock/unlock).
- **30.17** `SecuritySettingsScreen` (enable encryption, change passphrase).
- **30.18** `SecretVisibilityToggle` (mask/unmask field).

### Blok G — Wire + DoD (30.19–30.21)
- **30.19** Wire lock screen ke router (route `/security`).
- **30.20** Wire security settings ke shell/status.
- **30.21** DoD: full regression gates + commit + push + tandai DONE.

## Schema v42
- `security_settings` (projectId PK, encryptionEnabled, kdfIterations, passphraseSalt,
  passphraseHash, updatedAt).

## Risiko jujur
- Enkripsi lokal hanya sekuat passphrase pengguna; tanpa passphrase kuat, at-rest lemah.
- `cryptography` dep baru (murni Dart, web-safe) — harus lolos `flutter build web`.
- Tidak ada KMS/escrow; lupa passphrase = data tidak bisa dipulihkan.
