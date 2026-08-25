# 108.22 — Security & Privacy Feasibility

> Sprint 108 · disusun 2026-08-25 · kanonik required_outputs:
> threat_notes, data_classification, permission_needs, privacy_risk,
> mitigations — dinilai SEJAK DISCOVERY, bukan sesudah jadi.

## threat_notes

1. **Eksfiltrasi konten novel via AI remote** (OPP-06): ancaman privasi
   terbesar dari seluruh daftar — naskah belum terbit keluar mesin.
2. **Jurnal pemakaian bocor konten** (OPP-05): risiko kalau jurnal tak sengaja
   menampung judul/teks; desain harus metadata-only.
3. **Paket distribusi dipalsukan** (OPP-04): sudah termitigasi KI-01
   (RSA-3072 detached + pub key + VERIFY-SIGNATURE.sh).
4. Permukaan plugin/sandbox TIDAK berubah oleh peluang mana pun.

## data_classification

| kelas | contoh | perlakuan |
|---|---|---|
| sensitif-pribadi | teks/judul novel, struktur cerita | tidak pernah keluar mesin tanpa persetujuan eksplisit per-aksi |
| operasional | jumlah sesi, durasi, fitur disentuh, versi | boleh masuk jurnal lokal (OPP-05), tetap di mesin |
| kredensial | API key provider remote | env/config milik pengguna; TIDAK PERNAH di repo/db/summary ([REDACTED]) |

## permission_needs

- OPP-06: izin EKSPLISIT Choirudin per eksperimen (konten apa, provider apa,
  biaya berapa) — gerbang sebelum prompt pertama.
- OPP-05: opt-in di settings, default OFF, mudah dihapus.
- Tidak ada permintaan permission OS baru (tanpa installer, tanpa service).

## privacy_risk

Keseluruhan: **RENDAH-SEDANG**, terkonsentrasi di OPP-06. OPP-05 berisiko
rendah BILA skema jurnal ketat metadata-only (divalidasi test).

## mitigations

a. Gerbang persetujuan per-konten sebelum request AI remote keluar (prompt
   yang dikirim ditampilkan dulu); opsi redaksi nama entitas.
b. Jurnal OPP-05: whitelist field, test anti-kebocoran-konten, rotasi/hapus
   mudah, tanpa network egress.
c. Verifikasi signature wajib di alur distribusi eksternal (sudah ada).
d. Kunci signing tetap di luar repo (`~/codesign/`), publik hanya .pub.
