# Runbook Fasilitator Sesi Pilot (siap-tempel) — operasional 145.46

**Status:** DRAFT siap-tempel — menerapkan `task-validation-script.md` (d5524e3)
jadi prosedur hari-H. Cetak/buka berdampingan saat sesi berlangsung.

---

## H-1: Persiapan (checklist)

- [ ] Proyek salinan uji dibuat dari template (`[P01]` dst. sebagai nama), bukan naskah nyata.
- [ ] Catat di lembar sesi: git SHA build, spesifikasi laptop peserta, tanggal, ID peserta.
- [ ] Buka aplikasi sekali untuk memastikan build jalan; tutup dengan tombol Close (jangan force-kill — sisakan `session.lock` yatim yang menghambat peserta).
- [ ] Siapkan lembar skor confidence 1-5 dan lembar pencatatan (format di bawah).
- [ ] Cek kamera/mic layar meeting; rekaman layar disiapkan TAPI baru aktif setelah persetujuan eksplisit.

## Menit 0-10: Pembukaan (bacakan, jangan parafrase — jaga konsisten antar peserta)

> "Terima kasih sudah mau ikut. Hari ini kamu akan mencoba aplikasi menulis
> novel bernama Void Scriptor — versi awal, berjalan di laptopmu secara lokal,
> tanpa akun dan tanpa internet. Aku akan memberi tujuan tugas satu per satu;
> **tidak ada cara yang benar atau salah** — bagaimana kamu menyelesaikannya
> justru yang ingin kita pelajari. Kalau bingung atau macet, itu data berharga,
> bukan kesalahanmu; boleh bertanya kapan saja dan aku mungkin tidak selalu
> bisa menjawab. Sesi ini 60-90 menit dan boleh berhenti kapan saja tanpa
> alasan. Layar akan direkam hanya jika kamu setuju — setuju direkam?
> … Baik, mulai."

Catat waktu mulai, status persetujuan rekaman, suasana awal (context).

## T1-T6: Eksekusi tugas (aturan fasilitator)

- Berikan **hanya kalimat perintah** dari skrip (T1 Create novel → T6 Backup/restore).
- **Jangan menyebut nama menu/tombol.** Jika peserta bertanya "ini yang dimaksud?",
  balas: "Apa yang kamu lihat?" — catat pertanyaannya sebagai data friksi.
- Setiap tugas: catat durasi (mm:ss), friksi + kutipan, error + pemulihan
  (sendiri / butuh bantuan / buntu), lalu minta skor confidence 1-5 + alasan.
- Jika sesi terhenti teknis >5 menit: bantu, catat sebagai friksi, lanjut.
- Istilah yang disalahpahami peserta dicatat verbatim di kolom Terminology.

## Penutup (menit terakhir)

1. "Apa yang paling mengganjal dari aplikasi ini?" (jangan beri pilihan).
2. Skor confidence keseluruhan 1-5 + alasan.
3. "Ada yang ingin kamu tanyakan?" — jawab tanpa menjanjikan fitur/tanggal.
4. Terima kasih; sampaikan ringkasan non-rahasia menyusul bila diminta.
5. Arsip: lembar sesi P01 dst., rekaman sesuai persetujuan.

## Lembar sesi (satu per peserta, duplikasi per tugas)

| Field | Isi |
|---|---|
| Peserta / tanggal / build SHA | |
| Persetujuan rekaman | ya / tidak |
| Tugas | T1-T6 |
| Durasi | mm:ss |
| Friksi + kutipan | |
| Error + pemulihan | sendiri / bantuan / buntu |
| Confidence | 1-5 + alasan |
| Terminology salah paham | |
| Context | kelelahan / distraksi / gangguan teknis |

## Konteks (kondisi peserta saat sesi — dicatat di penutup)

- Catat kelelahan, distraksi, gangguan teknis, atau kejadian lain yang memengaruhi sesi.
- Bukan penilaian peserta; ini membantu 145.47 membedakan friksi konsisten vs situasional.
- Keputusan apresiasi Choi 2026-09-06: **Pro lifetime untuk SEMUA peserta** saat rilis, **jalur A terkunci** (tanpa tambahan cash, tanpa kontes pemenang).
