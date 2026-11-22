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

## [1.0.4+5] - 2026-11-23
### Ditambahkan (Added)
- **Animasi Atmosfer & Mikro-Interaksi Khas Kopi (`coffee_atmosphere.dart`)**:
  - Menambahkan animasi *BrewAtmosphereBackdrop* di Beranda yang berubah mulus antara uap aroma kopi hangat (**Hot V60**) dan kristal es melayang (**Japanese Iced**), plus bar progres stok kopi beranimasi, indikator rasio Air Panas vs Es Batu, dan pengukur profil rasa beranimasi — seluruhnya ringan berbasis `CustomPainter` native tanpa membebani memori.
- **Upgrade Total Kurikulum Belajar Seduh (9 Materi Standar SCA & WBrC)**:
  - Memperbarui tampilan baca & memperluas materi menjadi **9 topik mendalam dan interaktif**: *Ensiklopedia Biji Kopi* (spesies, MASL, 5 proses pasca panen, simulator sangrai & resting, penyimpanan freezer), *Ilmu Ekstraksi & Rasio Emas SCA* (kurva interaktif 18–22%), *Teknik Tuang 5 Pola*, *Roda Rasa Kopi SCA*, *Diagnosa Rasa & Coffee Compass* (pemilih gejala interaktif), *Panduan Japanese Iced / Flash Brew* (simulator 70/30–60/40), *Kimia Air Seduh (TDS/Mg/Ca/KH)*, *Geometri Dripper & Kertas Filter*, serta *Grinder, Burr & RDT*.

### Diubah / Disempurnakan (Changed)
- **Redesign Beranda**:
  - Menyatukan alur visual dari sapaan & pita alat aktif di atas langsung ke kartu utama **Launchpad Seduh** hingga kartu **Stok Kopi**, **Eksplorasi & Panduan**, dan **Seduhan Terakhir** agar terasa satu kesatuan yang rapi.
- **Redesign Halaman Alat Seduh (Sticky Workbench — Bebas Bingung)**:
  - Menghapus tombol **Simpan Setup Aktif** dan checklist yang membingungkan; pilihan alat kini tersimpan otomatis dengan status `Dipakai` yang tegas dan pita **Setup Aktif Saya** 3-slot (`Grinder | Dripper | Filter`) yang selalu menempel di bagian atas saat menggulir koleksi.
- **Redesign Halaman Koleksi Kopi & Detail Kopi**:
  - Menghapus angka `klik` grinder yang tidak relevan dari kartu kopi, menambahkan garis aksen level sangrai, chip *Notes Rasa Kemasan*, umur sangrai, dan bar stok beranimasi.
- **Redesign Riwayat & Detail Seduhan (Pembeda Jelas Hot V60 vs Japanese Iced)**:
  - Membedakan identitas visual **Hot V60** (*Terracotta*) dan **Japanese Iced** (*Glacier Ice*), serta menampilkan visual **Proporsi Air Panas vs Es Batu** beserta teknik es (*Es Duluan* vs *Seduh Dulu → Es*) secara jelas di daftar riwayat maupun detail seduhan.
- **Perbaikan Tombol `Info Pola` & Konsistensi Istilah (`Kopi` / `Biji Kopi`)**:
  - Membangun ulang komponen tombol `PourInfoButton` agar seragam, proporsional, dan rapi di semua layar.
  - Menyeragamkan istilah navigasi & label menjadi **Kopi** / **Biji Kopi** (menghilangkan campur aduk `Beans` dan kata `Biji` yang ambigu).

---

## [1.0.3+4] - 2026-11-23
### Ditambahkan (Added)
- **Panduan Animasi 5 Teknik Tuangan (`Info Pola`)**:
  - Menambahkan tombol **Info Pola** di samping pemilih pola tuangan (pada layar Brew, Edit Tahapan, dan Timer Seduh) yang membuka panduan animasi interaktif untuk seluruh 5 teknik tuangan (**Spiral**, **Tengah**, **Pulse**, **Osmotic Flow**, dan **Swirl**) lengkap dengan langkah praktik, efek rasa, dan hal yang perlu dihindari.
  - Memperbarui materi **Teknik Tuang & Pola Air** di halaman **Belajar Seduh** agar mencakup kelima pola secara lengkap.
- **Materi Roda Rasa Kopi (SCA Flavor Wheel) di Belajar Seduh**:
  - Menambahkan panduan **Roda Rasa Kopi (SCA)** di menu **Belajar Seduh** (total kini 8 materi) dengan roda interaktif 9 kategori, pencarian catatan rasa cepat, kartu sub-kategori, dan panduan 3 langkah cara membaca rasa kopi untuk pemula.
- **Pemulihan Preset Bawaan Terpusat di Pengaturan**:
  - Menambahkan bagian **Pulihkan Preset Bawaan Aplikasi** di halaman **Pengaturan** dengan rincian jelas jumlah Grinder, Dripper, Filter, dan Metode Resep bawaan yang akan dikembalikan tanpa menghapus data pribadi pengguna.

### Diubah / Disempurnakan (Changed)
- **Redesign Welcome Screen Minimalis**:
  - Menghapus teks pembuka yang berlebihan pada layar masuk dan menampilkan animasi logo **Pocket Brew** yang bersih, tenang, dan konsisten di mode Terang maupun Gelap.
- **Alur Setup Awal Pengguna Baru (`Onboarding`)**:
  - Pengguna yang baru pertama kali memasang aplikasi (atau setelah melakukan **Hapus Data**) kini diarahkan melewati **Setup Awal** untuk memilih satuan, grinder, dan dripper sebelum masuk ke Beranda.
- **Redesign Timer Seduh (`LiveTimerScreen` & `DualPhaseTimerRing`)**:
  - Memperbesar ukuran angka timer, target timbangan, kartu instruksi aktif, ringkasan setup 2×2, dan daftar tahapan agar mudah terbaca dari jarak meja seduh saat tangan memegang kettle, termasuk pintasan **Lihat Teknik** pola tuangan.
- **Pembersihan Metode & Resep serta Struktur Repository**:
  - Menghapus preset demo `V60 Pagi Custom` & `Japanese Iced Sore` serta strip bawah pada tab Resep Profesional agar daftar resep lebih bersih.
  - Memindahkan tombol pulihkan bawaan dari halaman Alat & Metode ke Pengaturan, membersihkan aset tidak terpakai, memperbarui `.gitignore`, dan merapikan `README.md`.

---

## [1.0.2+3] - 2026-11-22
### Ditambahkan (Added)
- **Sintesis Audio Native Android (`AudioTrack` PCM Chime)**:
  - Menambahkan mesin sintesis suara *bell chime* 100% offline langsung di `MainActivity.kt` (`AudioAttributes.USAGE_MEDIA`) agar bunyi hitung mundur `3–2–1`, mulai tuang, tunggu/swirl, dan selesai seduh terdengar jernih di HP Android (tidak lagi bergantung pada `SystemSound` bawaan yang bisu di Android), dilengkapi tombol **Tes Suara** di halaman **Pengaturan**.
- **Hapus Semua Data Lokal di Pengaturan**:
  - Menambahkan tombol **Hapus Data** (dengan modal konfirmasi keamanan) untuk membersihkan seluruh biji kopi, riwayat seduhan, resep & alat custom secara menyeluruh.
- **Edit / Tambah / Hapus Tahap Tuangan Langsung di Halaman Brew (Sesi Ini)**:
  - Barista kini bisa menambah tahap baru (`+ Tambah Tahap (Sesi Ini)`), mengubah judul/air/durasi/pola per tahap, atau menghapus tahap langsung dari halaman **Brew** khusus untuk sesi seduh tersebut tanpa merusak preset resep aslinya, lengkap dengan tombol **Reset preset**.
- **Rename Judul Tahap Tuangan di Editor Metode Resep**:
  - Menambahkan input **Judul Tahap** di setiap kartu tahap pada layar **Edit Tahapan** sehingga `Tuangan 4`, `Tuangan 5`, dst. bisa diganti namanya secara bebas.
- **Fitur Hapus Menyeluruh + Modal Konfirmasi Universal (`showPocketDeleteDialog`)**:
  - Semua entitas (Biji Kopi, Metode Resep bawaan & custom, Alat Seduh bawaan & custom, Riwayat Seduhan, Tahap Tuangan, dan Reset Data) kini bisa dihapus dan selalu dilindungi dialog konfirmasi **Batal / Hapus**, lengkap dengan tombol **Pulihkan Resep/Alat Bawaan**.

### Diubah / Disempurnakan (Changed)
- **Redesign Welcome / Entrance Screen (`_PocketEntranceCurtain`)**:
  - Desain ulang layar pembuka agar lebih tenang, elegan, dan adaptif mengikuti tema **Soft Oat (Terang)** & **Espresso Dusk (Gelap)** dengan durasi animasi lebih nyaman (`2.35 dtk`), cincin riak tuangan, busur *crema*, dan tipografi bertahap.
- **Redesign Header Beranda**:
  - Header Beranda dibuat lebih ringkas, proporsional, dan rapi dalam 1 kartu kompak sehingga area **Launchpad Seduh** langsung terlihat nyaman tanpa terlalu tinggi.
- **Input Notes Rasa Kemasan Per-Item (`Notes 1`, `Notes 2`, dst.)**:
  - Mengganti input teks pisah koma di **Tambah / Edit Biji Kopi** menjadi kolom terpisah (`Notes 1`, `Notes 2`, `+ Tambah Note`) ditambah chip pilihan cepat sekali ketuk.
- **Redesign Detail Biji & Koreksi Sisa Stok Fleksibel**:
  - Tampilan **Detail Biji** disempurnakan dengan strip 3-KPI (*Sisa Stok*, *Estimasi*, *Klik Andalan*) dan input **Koreksi Sisa Stok Aktual** yang bebas diketik langsung (mendukung desimal seperti `18.5g`) plus tombol `±1g`, `±5g`, `±10g`, dan `0g (Habis)`.
- **Penghapusan Fitur Arsip Biji Kopi (Backward-Compatible)**:
  - Menghapus tab dan tombol **Arsip** secara bersih dari UI, store, dan model (tetap aman membaca database/cadangan versi lama tanpa kehilangan data saat update APK).
- **Audit Keterbacaan Teks Panjang & Responsivitas Light/Dark Mode**:
  - Menghilangkan pemotongan teks `...` (`TextOverflow.ellipsis`) yang menyulitkan baca pada nama biji, spesifikasi resep, catatan seduhan, nama alat, dan tahapan tuangan di seluruh layar.

---

## [1.0.1+2] - 2026-11-22
### Ditambahkan (Added)
- **Logo & Adaptive Icon Resmi Pocket Brew**:
  - Mengganti seluruh ikon bawaan Flutter di Android (`mipmap-mdpi` s/d `xxxhdpi`, `ic_launcher_round`, dan Vector Adaptive Icon `mipmap-anydpi-v26`), iOS (`AppIcon.appiconset`), dan Web (`favicon.png`, `Icon-192`, `Icon-512`) dengan logo resmi **Pocket Brew** (*V60 Cone + Diagonal Rib + Pocket Cradle + Crema Droplet*).
- **Production Release Keystore & Android V1/V2 Signature**:
  - Menandatangani `.apk` rilis dengan sertifikat produksi resmi **Pocket Brew (`RSA-2048`)** via GitHub Actions Secrets (bukan lagi *Android Debug Key*), serta merapikan `AndroidManifest.xml` (`allowBackup="false"`, `roundIcon`) dan `launch_background.xml` (`#17120F` bebas kilatan putih).

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
