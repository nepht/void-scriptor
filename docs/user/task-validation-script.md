# Skrip Validasi Task-Based Peserta Pilot (input 145.46)

**Status:** DRAFT — instrumen observasi untuk sesi pilot; menunggu keputusan
Choi sebelum dipakai. Dokumen ini TIDAK mengubah kontrak sprint/pointer.

## Prinsip

- Observasi **tanpa memandu (without leading)**: fasilitator memberi tujuan
  tugas, bukan langkah. Jawaban atas pertanyaan peserta dicatat sebagai data
  friksi, bukan dijawab dengan instruksi UI.
- Satu peserta per sesi; proyek salinan yang disediakan; naskah pribadi tidak
  digunakan.
- Semua temuan dicatat per tugas: friksi, error, confidence, terminology,
  context.

## Persiapan sesi (per peserta)

1. Bangun proyek salinan dari template uji (bukan naskah pengguna nyata).
2. Catat versi build (git SHA) dan spesifikasi perangkat di lembar sesi.
3. Set rekaman layar hanya setelah persetujuan eksplisit peserta.
4. Siapkan lembar skor confidence 1 (sangat tidak yakin) - 5 (sangat yakin).

## Kelompok tugas (sesuai objective 145.46)

### T1 - Create novel
- Perintah ke peserta: "Mulai sebuah novel baru untuk cerita yang ingin kamu
  tulis."
- Observasi: friksi navigasi, istilah yang membingungkan, waktu sampai
  naskah pertama bisa diketik.

### T2 - Create character
- Perintah: "Buat satu karakter utama untuk novel tadi."
- Observasi: friksi form/profil, terminology field, kesalahan yang pulih
  sendiri vs buntu.

### T3 - Write dan reopen
- Perintah: "Tulis paragraf pembuka, lalu tutup aplikasinya, dan buka lagi
  untuk melanjutkan tulisanmu."
- Observasi: kepercayaan diri bahwa teks aman (confidence), reaksi pada
  indikator status simpan, error/salah paham saat reopen.

### T4 - Lore finding
- Perintah: "Cari kembali catatan lore tentang [subjek dari proyek salinan]."
- Observasi: jalur pencarian yang dipilih, friksi filter/istilah, context
  yang hilang dari hasil.

### T5 - Export
- Perintah: "Ekspor novel tadi ke satu berkas yang bisa kamu kirim ke orang
  lain."
- Observasi: pilihan format, kebingungan opsi, error saat ekspor.

### T6 - Backup dan restore
- Perintah: "Buat cadangan proyek ini, lalu pulihkan cadangan itu."
- Observasi: pemahaman istilah backup/restore, reaksi pada peringatan,
  error dan pemulihannya.

## Lembar pencatatan per tugas

| Field | Catatan |
|---|---|
| Tugas | T1-T6 |
| Durasi | mm:ss |
| Friksi | deskripsi + kutipan peserta |
| Error | apa yang muncul + pemulihan (sendiri/bantuan/buntu) |
| Confidence | 1-5 + alasan singkat |
| Terminology | istilah yang disalahpahami |
| Context | situasi (kelelahan, distraksi, gangguan teknis) |

## Penutup sesi

1. Tanyakan kesan umum tanpa memandu ("Apa yang paling mengganjal?").
2. Minta skor confidence keseluruhan dan alasannya.
3. Debrief: ringkasan non-rahasia, terima kasih, tanpa tekanan tindak lanjut.
4. Arsipkan lembar sesi dengan ID peserta (P01-P20) tanpa nama asli.
