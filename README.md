# Pocket Brew — Manual Pour-Over Companion (Hot V60 & Japanese Iced)

**Pocket Brew** adalah aplikasi pendamping seduh kopi manual rumahan (**Hot V60 & Japanese Iced**) yang **100% Offline-First**, menggunakan **rumus ekstraksi kopi deterministik lokal (tanpa AI/LLM & tanpa server eksternal)**, dengan desain Material 3 **Soft Oat (Terang)** & **Espresso Dusk (Gelap)**.

- **Versi Saat Ini:** `v1.0.0+1` ([Lihat CHANGELOG.md](CHANGELOG.md))
- **Penyimpanan:** 100% Lokal di perangkat (`Dual-Slot Auto-Backup` + Ekspor/Impor JSON)

---

## Fitur Utama

1. **Beranda Launchpad Interaktif (`HomeScreen`)**
   - Pilih mode **Hot V60** atau **Japanese Iced**, ganti **Biji Kopi Aktif**, dan ganti **Metode Seduh** (*James Hoffmann 1-Cup*, *Tetsu Kasuya 4:6*, *Cafec Osmotic Flow*, dll.) langsung dari Beranda.
   - Ringkasan parameter *real-time* (**Dosis**, **Air/Es**, **Klik Grinder**, **Suhu Air**) + pintasan cepat ke **Alat Seduh**.
2. **Menu Seduh & Checklist Persiapan Barista (`QuickBrewScreen`)**
   - Kartu terpadu **Resep · Dosis, Rasio & Suhu** (`g` / `ml` / `oz` dan `°C` / `°F`).
   - **2 Opsi Japanese Iced**: **Es Duluan (Server)** vs **Seduh Dulu → Es**.
   - **Interactive Click Ruler (`CustomPainter`)** dengan konversi lintas grinder berbasis **Delta-Micron (`Δμm`)**.
   - **Sheet Checklist `"Siap-siap Seduh"`** saat menekan **Mulai Brew** (urutan persiapan barista dari panaskan air hingga tare `0.0g` sebelum timer berjalan).
3. **Editor Tahapan Tuangan Independen (`PourStageEditorScreen`)**
   - Rasio simetris (`−0.5` / `+0.5`), berat **Es Batu Custom** (gram & persen), serta alokasi air per tahap yang independen dengan bar **Panduan Alokasi Air per Tahap** dan chip **`+ Isi sisa target`**.
4. **Live Brew Timer Dual-Phase & Evaluasi Seduh SCA (`BrewTimerScreen` & `EvaluationScreen`)**
   - Hitung mundur `3–2–1`, panduan tuang & swirl per tahap, roda rasa SCA 2 arah, diagnosis ekstraksi lokal untuk saran klik besok, dan pengurangan stok biji otomatis (`Kurangi stok biji`).
5. **Katalog Biji Kopi & Koleksi Alat Seduh (`BeansScreen` & `GearScreen`)**
   - Pencatatan **Berat Biji Saat Ini**, **Tanggal Sangrai & Masa Paling Enak** (*Mulai Enak* & *Sampai Hari*), mode **Simpan di Freezer**, serta manajemen **Setup Aktif Saya** & **Koleksi Alat Seduh** dengan transisi tab 60fps.

---

## Keamanan & Ketahanan Database Lokal (Anti-Rusak & Anti-Bocor)

1. **100% Offline & Tanpa Kebocoran Data:** Seluruh data pengguna disimpan secara lokal di HP dan tidak pernah dikirim ke server mana pun. File sensitif (`.jks`, `.keystore`, `android/key.properties`, `.pem`, `.env`) sudah dikunci di [`.gitignore`](.gitignore) agar tidak pernah bocor ke GitHub.
2. **Dual-Slot Auto-Backup (`PocketStorage`):** Setiap kali ada perubahan data, sistem otomatis menyimpan salinan valid sebelumnya ke slot cadangan (`pocket_brew_state_v1_backup`). Jika aplikasi tertutup paksa saat menyimpan, database otomatis pulih dari slot cadangan.
3. **Fault-Isolated Parsing (`PocketStoreNotifier`):** Setiap daftar (*biji kopi*, *riwayat seduhan*, *resep custom*, *alat seduh*) dibaca per item secara terisolasi sehingga pembaruan versi aplikasi tidak akan pernah menghapus atau me-reset database pengguna.
4. **Salin & Pulihkan Cadangan JSON:** Tersedia di menu **Pengaturan → Data Tersimpan Aman di HP** untuk pindah perangkat kapan saja.

---

## Cara Update & Rilis Versi Baru ke GitHub (Untuk Personal & Teman)

Repository ini sudah dilengkapi **GitHub Actions** ([`.github/workflows/release-apk.yml`](.github/workflows/release-apk.yml)). Setiap kali kamu menaikkan versi lalu `push` ke branch `main`, GitHub otomatis menjalankan test, merakit file `.apk`, dan menerbitkannya di halaman **GitHub Releases**.

### 1. Setup Awal Repository ke GitHub (Hanya Sekali)
```bash
git add .
git commit -m "chore: initial release Pocket Brew v1.0.0"
git remote add origin https://github.com/USERNAME_KAMU/pocket-brew-app.git
git push -u origin main
```

### 2. Setup Kunci Tanda Tangan APK Tetap (Agar Teman Bisa Update Tanpa Uninstall)
Supaya `.apk` baru selalu bisa ** langsung ditimpa (Update)** di atas aplikasi lama tanpa menghapus data lokal di HP teman:

1. Buat 1 file keystore tetap di laptopmu (cukup sekali seumur hidup):
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias pocketbrew
   ```
2. Salin [`android/key.properties.example`](android/key.properties.example) menjadi `android/key.properties` dan isi password yang kamu buat tadi (file ini otomatis diabaikan oleh `.gitignore` sehingga **tidak akan bocor ke GitHub**).
3. *(Opsional jika ingin build otomatis dari GitHub Actions memakai kunci yang sama)*: Masukkan base64 keystore & password ke menu **Settings → Secrets and variables → Actions** di GitHub:
   - `POCKET_BREW_KEYSTORE_BASE64` (hasil `base64 -i android/app/upload-keystore.jks | pbcopy`)
   - `POCKET_BREW_KEYSTORE_PASSWORD`
   - `POCKET_BREW_KEY_ALIAS` (`pocketbrew`)
   - `POCKET_BREW_KEY_PASSWORD`

### 3. Setiap Kali Mau Rilis Update Baru (Misal `v1.0.1`)
1. Naikkan nomor versi di [`pubspec.yaml`](pubspec.yaml) (contoh: `version: 1.0.1+2`) dan samakan di [`lib/app/pocket_version.dart`](lib/app/pocket_version.dart).
2. Catat perubahan singkat di [`CHANGELOG.md`](CHANGELOG.md).
3. Commit & push ke `main`:
   ```bash
   git add .
   git commit -m "release: v1.0.1"
   git push origin main
   ```
4. **Selesai!** GitHub Actions akan otomatis mem-build `pocket-brew-v1.0.1.apk` dan memunculkannya di tab **Releases** GitHub kamu. Kamu atau temanmu tinggal unduh `.apk` tersebut lalu tekan **Update**.

---

## Perintah Pengembangan Lokal

```bash
# Jalankan seluruh unit, database & widget tests
flutter test

# Analisis kode statis (0 issues)
flutter analyze

# Build Android APK secara lokal di laptop
flutter build apk --release
```
