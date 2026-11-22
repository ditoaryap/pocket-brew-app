# Changelog — Pocket Brew

Semua riwayat perubahan penting, penambahan fitur, penyempurnaan UX, dan perbaikan bug pada aplikasi **Pocket Brew** dicatat di dokumen ini.

Format mengacu pada [Keep a Changelog](https://keepachangelog.com/id-ID/1.0.0/) dengan skema penomoran versi `MAJOR.MINOR.PATCH+BUILD` di [`pubspec.yaml`](pubspec.yaml) dan [`lib/app/pocket_version.dart`](lib/app/pocket_version.dart).

---

## [Template Rilis Berikutnya — mis. 1.0.1+2] - YYYY-MM-DD
### Ditambahkan (Added)
- ...

### Diubah / Disempurnakan (Changed)
- ...

### Diperbaiki (Fixed)
- ...

---

## [1.0.0+1] - 2026-11-22
### Ditambahkan (Added)
- **Beranda Launchpad Interaktif (`HomeScreen`)**:
  - Header sapaan hangat (`Mau seduh apa, Dito?`) dengan chip alat aktif (`C40 MK4 · V60-02`) yang bisa diketuk langsung menuju halaman **Alat Seduh**.
  - Kartu utama **Siap Seduh** dengan *sliding toggle* **Hot V60** vs **Japanese Iced**, pemilih biji kopi aktif & status kesegaran, serta **Pilih Metode** horizontal langsung dari Beranda tanpa pindah halaman.
  - Strip ringkasan parameter *real-time* (**Dosis**, **Air/Es**, **Klik Grinder**, **Suhu Air**) dan tombol aksi langsung **Atur & Seduh**.
- **Kalkulator & Menu Seduh (`QuickBrewScreen`)**:
  - Kartu terpadu **Resep · Dosis, Rasio & Suhu** untuk mengatur dosis kopi, rasio air, dan **Suhu Air Seduh (`°C` / `°F`)** dalam satu tempat.
  - Dukungan penuh **2 Metode Japanese Iced**: **Es Duluan (Server)** vs **Seduh Dulu → Es** beserta kalkulasi proporsi air panas & es batu secara otomatis.
  - **Interactive Click Ruler (`CustomPainter`)** dengan mesin konversi lintas grinder berbasis **Delta-Micron (`Δμm`)** untuk 10+ grinder populer + grinder milik sendiri.
  - **Checklist Persiapan Barista (`Siap-siap Seduh`)** saat menekan tombol **Mulai Brew** (5 langkah berurutan: *Panaskan air*, *Timbang biji*, *Atur gilingan*, *Bilas filter / siapkan es*, *Ratakan bubuk & tare 0.0g*), dilengkapi tombol **Lewati** dan **Mulai Timer**.
- **Editor Tahapan Tuangan Independen (`PourStageEditorScreen`)**:
  - Kontrol rasio simetris (`−0.5` / `+0.5`) untuk mode Hot V60 maupun Japanese Iced.
  - Kontrol berat **Es Batu Custom** (`−5g` / `+5g`, ketuk input angka gram bebas, serta preset `30%`, `35%`, `40%` dalam rentang aman `15%–60%`).
  - Alokasi air per tahap yang **independen** (menambah tahap baru mulai dari `+0 ml` dan menghapus tahap tidak merusak takaran tahap lain), dilengkapi bar **Panduan Alokasi Air per Tahap**, chip **`+ Isi sisa target`**, dan tombol opsional **`Bagi Rata`**.
- **Timer Seduh Dual-Phase (`BrewTimerScreen`)**:
  - Hitung mundur persiapan `3–2–1`, cincin progres tuangan per tahap (*Menuang* ↔ *Tunggu & Swirl* ↔ *Langkah Akhir Japanese Iced*), panduan pola tuangan (*Spiral*, *Tengah*, *Swirl*), dan pengaman tombol keluar saat tangan basah.
- **Evaluasi Seduh & Roda Rasa SCA (`EvaluationScreen` & `ScaWheelScreen`)**:
  - Mesin diagnosis ekstraksi deterministik 100% lokal (tanpa AI/internet) yang memberikan rekomendasi perubahan klik grinder & suhu air untuk seduhan berikutnya.
  - Sinkronisasi 2 arah antara chip *Notes Rasa dari Biji* di Evaluasi dan layar **Roda Rasa SCA** (mudah dipilih maupun dibatalkan).
  - Switch praktis 1 baris **`Kurangi stok biji (−15.0g)`** saat menyimpan catatan seduh.
- **Katalog Biji Kopi & Masa Paling Enak (`BeansScreen`, `AddBeanScreen`, `BeanDetailScreen`)**:
  - Input **`Berat Biji Saat Ini`** yang ringkas dengan pilihan cepat (`100g`, `200g`, `250g`, `500g`, `1000g`), tombol `−10g` / `+10g`, dan input angka bebas.
  - Pengaturan **`Tanggal Sangrai & Masa Paling Enak`** (*Mulai Enak* & *Sampai Hari* setelah sangrai) yang bisa mengikuti standar level sangrai atau diatur sendiri per kantong biji, ditambah fitur **Simpan di Freezer** dan **Koreksi Stok Aktual**.
- **Koleksi Alat Seduh & Transisi 60fps (`GearScreen` & `AddCustomGearScreen`)**:
  - Tampilan fokus pada **Setup Aktif Saya** (dilengkapi tombol konfirmasi **`Simpan Setup Aktif`**) dan **Koleksi Alat Seduh** (Grinder, Dripper, Kertas Filter) dengan ikon vektor bersih tanpa foto dripper yang mengganggu.
  - Semua alat (baik bawaan maupun tambahan sendiri) kini bisa dihapus selama tersisa minimal 1 alat per kategori, lengkap dengan tombol **`Pulihkan Alat Bawaan yang Dihapus`**.
  - Transisi tab **Grinder / Dripper / Filter** 60fps menggunakan `PageView` + indikator geser mulus.
- **Animasi Entrance Barista Atelier (`_PocketEntranceCurtain`)**:
  - Animasi pembuka aplikasi bergaya *specialty coffee atelier* dengan dial cincin 36 klik grinder, busur *crema terracotta*, dan *reveal* bertahap ke Beranda.
- **Keamanan & Ketahanan Database Lokal (`PocketStorage` & `PocketStoreNotifier`)**:
  - **Dual-Slot Auto-Backup (`pocket_brew_state_v1` & `pocket_brew_state_v1_backup`)**: setiap penyimpanan otomatis mencadangkan state valid sebelumnya sehingga data tidak pernah rusak/hilang jika HP mati mendadak.
  - **Fault-Isolated Deserialization (`_parseListSafe`)**: pembaruan skema atau 1 entri yang tidak valid tidak akan pernah me-reset data biji kopi, resep, alat, atau riwayat seduhan pengguna.
  - Fitur **Salin Cadangan (JSON)** & **Pulihkan Data Cadangan** dengan validasi *dry-run* di halaman **Pengaturan**.
- **Otomasi GitHub Release & Konfigurasi Signing Tetap**:
  - Workflow GitHub Actions (`.github/workflows/release-apk.yml`) untuk otomatis menguji, mem-build `.apk`, dan mempublikasikan rilis ke **GitHub Releases** setiap ada pembaruan versi di branch `main`.
