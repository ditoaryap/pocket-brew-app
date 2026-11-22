# Pocket Brew — Session Handoff (Ready for New Chat)

> **Project Root (set as active workspace in new chat):** `/Users/ditoaryap/Documents/Project/pocket-brew-app`  
> **App Name:** **Pocket Brew** (Android & iOS manual brew companion — Hot V60 & Japanese Iced)  
> **Stack:** Flutter `3.50.1` · Dart `3.14.0` · Riverpod `2.6` · `go_router` `15.1` · Material 3 dual-theme (**Soft Oat** Light & **Espresso Dusk** Dark)  
> **Status:** `flutter analyze` **0 issues** · `flutter test` **9/9 passed** · `flutter build web` **passing**

---

## 1. Sumber Desain & Referensi Arsitektur (1:1 Source of Truth)
- **Master FigCraft v7 (25 Layar 5×5 + 6 Dark + 3 Responsive Proofs):**
  `/Users/ditoaryap/Documents/figcraft-designs/bloom-manual-brew/bloom-manual-brew.figcraft`
- **Design Tokens Export:**
  - `/Users/ditoaryap/Documents/figcraft-designs/bloom-manual-brew/bloom-tokens.json`
  - `/Users/ditoaryap/Documents/figcraft-designs/bloom-manual-brew/bloom-tokens.css`
- **Design Showcase (25 Screens Visual Reference):**
  `/Users/ditoaryap/.gemini/antigravity/brain/d387bf01-703b-4242-8a8b-a71a5c80b646/bloom_manual_brew_design_showcase.md`
- **Flutter Architecture Handoff:**
  `/Users/ditoaryap/.gemini/antigravity/brain/334ec68d-94bb-41f2-8f97-918c3e50f0c0/pocket_brew_flutter_architecture_handoff.md`

---

## 2. Aturan Produk Wajib (Jangan Diubah Tanpa Persetujuan User)
1. **100% Offline-First & ZERO LLM / ZERO AI**: Semua saran dial-in di *Evaluasi Seduh* murni rumus ekstraksi kopi deterministik lokal (drawdown delta + pilihan rasa natural + `μm/klik` grinder, maksimal 1 variabel per saran).
2. **NO E-Commerce & NO Promo Banner Photo di Beranda**: *Beranda — Morning Ritual* adalah alat seduh harian yang bersih & tipografis.
3. **Bahasa Manusiawi di Pengaturan**: Dilarang memunculkan jargon teknis (*SQLite, JSON, Cloudflare*) di UI Pengaturan — pakai copy ramah seperti *Data Tersimpan Aman di HP (Simpan / Pulihkan)*.
4. **Terminologi Konsisten**:
   - Selalu gunakan **`Japanese Iced`** / **`Japanese`** (JANGAN pernah `"Es Jepang"`).
   - Badge metode hanya **`Hot V60`**, **`Japanese`**, atau **`Custom`** (jangan pakai `Aktif / Es / Verified`).
5. **Japanese Iced 2 Opsi (`IcedMethod`)**:
   - **`Es Duluan (Server)`** (`ice_first`): ingatkan bilas filter di wastafel + swirl server 10 detik saat selesai.
   - **`Seduh Dulu → Es`** (`brew_first`): bilas filter di server seperti biasa + tuang konsentrat panas perlahan ke gelas/server es di akhir.
   - Proporsi es dikunci aman di **`30%–42%`** via draggable split bar (tanpa Material Slider default).
6. **Satuan Fleksibel**: Live toggle **`g` / `ml` / `oz`** dan **`°C` / `°F`**.
7. **Masa Resting Bisa Diatur User**: Default `Light 7–14h`, `Medium 5–10h`, `Dark 3–7h` bisa diubah di *Pengaturan* dan otomatis dipakai `BeanRestingCalculator` + *Tambah Biji*.
8. **Tambah Biji Kopi**: Mendukung **`Baru (Utuh)`** vs **`Sudah Terpakai`** (berat kemasan asli + sisa aktual di kantong).
9. **Evaluasi Seduh & Brew Log**:
   - *Evaluasi*: 4 kartu pilihan rasa natural → kartu *Saran Rumus* Non-AI → 2×2 bar kapsul tipis interaktif (*Asam / Manis / Pahit / Body*, tanpa Material Slider bulat) + Roda Rasa SCA sunburst + kurva suhu 60°C.
   - *Brew Log*: Kartu *Golden Hot V60* & *Golden Japanese* + daftar riwayat bersih (**tanpa** grafik Progres Dial-In).
10. **Belajar Seduh (4 Topik)**: *Karakter Biji & Daerah*, *Teknik Penuangan (Diagram Canvas Animasi Spiral / Center-Osmotic / Rao Spin)*, *Jenis & Bahan Dripper*, *Jenis Kertas Filter*.

---

## 3. Struktur Kode Flutter Saat Ini
- **Theme & Variable Fonts (`FontVariation('wght')`):**
  - `lib/app/theme/pocket_tokens.dart` (38 exact Soft Oat & Espresso Dusk tokens)
  - `lib/app/theme/pocket_theme.dart` (`PlusJakartaSans-Variable.ttf` & `JetBrainsMono-Variable.ttf` di `assets/fonts/`)
- **Motion & Navigation:**
  - `lib/core/motion/pocket_motion.dart` (`PocketCurves`, `PocketTapScale`, `pocketSlidePage`, `pocketModalPage`, `PocketScrollBehavior`)
  - `lib/app/router.dart` (5-tab `StatefulShellRoute` + smooth crossfade/scale + push/modal routes)
  - `lib/app/app.dart` (full-screen mobile native saat `width <= 520dp`; 412dp phone frame di desktop web)
- **Bespoke UI & 5 CustomPainters:**
  - `lib/core/widgets/pocket_icons.dart` (custom `1.85px` vector stroke icons ala FigCraft)
  - `lib/core/widgets/pocket_logo.dart` (V60 Cone + Pocket Cradle + Coffee Drop mark)
  - `lib/core/widgets/floating_dock.dart` (Expanding-Pill Floating Bottom Dock 5 tab)
  - `lib/core/widgets/canvas/`: `click_ruler_widget.dart`, `dual_phase_timer_ring.dart`, `sca_flavor_wheel.dart`, `cooling_curve_chart.dart`, `spiral_pour_diagram.dart`
- **5 Pure Dart Coffee Engines (+ Unit Tests di `test/domain/coffee_engines_test.dart`):**
  - `delta_micron_grinder_engine.dart`, `brew_recipe_scaler.dart`, `coffee_compass_engine.dart`, `bean_resting_calculator.dart`, `brew_timer_engine.dart`
- **Data & State:**
  - `assets/catalog/catalog_seed_v1.json` (10 grinder resmi, 5 dripper, 5 filter, 6 resep pro, 4 panduan)
  - `lib/data/repositories/pocket_store.dart` (Riverpod `Notifier` + `SharedPreferences` local persistence + backup/restore)
- **Screens (25 FigCraft v7 flows implemented):**
  `lib/features/` → `onboarding`, `home`, `methods`, `quick_brew`, `timer`, `evaluation`, `brew_log`, `beans`, `gear`, `settings`, `learn`.

---

## 4. Menjalankan Preview & Testing
```bash
export PATH="/opt/homebrew/bin:$PATH"
cd /Users/ditoaryap/Documents/Project/pocket-brew-app

# Analisis & Tests
flutter analyze
flutter test

# Build Web + Jalankan Server LAN Dual HTTP+HTTPS (bisa dibuka dari HP di WiFi lokal!)
# Pakai Node Volta yang sudah diizinkan di macOS Firewall & support TLS 1.3 + gzip
flutter build web
/Users/ditoaryap/.volta/tools/image/node/24.18.0/bin/node tool/preview_server.mjs --port 8085
```
- **Akses di Mac:** `http://localhost:8085`
- **Akses di HP (WiFi sama):** `http://<IP-Mac>:8085` atau `https://<IP-Mac>:8085` (cek IP dengan `ipconfig getifaddr en0`; bila browser HP auto-upgrade ke HTTPS, cukup klik *Lanjutan / Advanced → Lanjutkan ke IP*).

---

## 5. Rencana Tahap Berikutnya (Opsional Sesuai Permintaan User)
- [ ] Review & poles ulang UI/animasi dari hasil tes langsung user di HP
- [ ] Upgrade persistence native ke **Drift SQLite** (tetap menjaga kompatibilitas preview web) + **WakelockPlus** & **Audio 3-2-1 cue** native Android/iOS
- [ ] Setup **Android SDK / APK Build** (atau koneksi USB HP Android untuk test APK asli)
- [ ] Setup **Cloudflare Pages/R2 OTA Catalog JSON** (`catalog_seed` update ringan tanpa rilis ulang toko aplikasi) & **Shorebird** code push
