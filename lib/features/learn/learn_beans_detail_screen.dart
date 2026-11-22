import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';

/// Complete Educational Topic Details for Belajar Seduh:
/// - `basics`: Ratio, Grind Size, Water Temp, Bloom & Agitation
/// - `troubleshoot`: Sour vs Bitter vs Stalled Drawdown Quick Fix Guide
/// - `beans`: Origin profiles & Post-harvest Processes
/// - `water`: Water Quality (~75–150 ppm) & Bean Storage / Resting
/// - `dripper`: Dripper Geometries & Materials
/// - `filter`: Paper Filter Flow Speeds & Rinse
class LearnTopicDetailScreen extends StatelessWidget {
  const LearnTopicDetailScreen({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (String title, String readTime, String ctaLabel, VoidCallback onCta) =
        switch (topic) {
      'basics' => (
          'Dasar Seduh Manual',
          '3 mnt',
          'Praktikkan di Brew',
          () => context.go('/brew'),
        ),
      'troubleshoot' => (
          'Perbaiki Rasa Kopi',
          '3 mnt',
          'Atur Ulang di Brew',
          () => context.go('/brew'),
        ),
      'water' => (
          'Air & Simpan Biji',
          '2 mnt',
          'Lihat Stok Biji di Rumah',
          () => context.go('/beans'),
        ),
      'dripper' => (
          'Jenis & Bahan Dripper',
          '3 mnt',
          'Pilih Alat di Profil Seduh',
          () => context.go('/gear'),
        ),
      'filter' => (
          'Jenis Kertas Filter',
          '2 mnt',
          'Pilih Filter di Profil Seduh',
          () => context.go('/gear'),
        ),
      _ => (
          'Biji & Daerah Asal',
          '3 mnt',
          'Tambah Biji ke Library',
          () => context.push('/beans/add'),
        ),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: title,
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: readTime,
                backgroundColor: c.tintSage,
                foregroundColor: c.brandSage,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: switch (topic) {
                  'basics' => _buildBasicsContent(context, c),
                  'troubleshoot' => _buildTroubleshootContent(context, c),
                  'water' => _buildWaterContent(context, c),
                  'dripper' => _buildDripperContent(context, c),
                  'filter' => _buildFilterContent(context, c),
                  _ => _buildBeansContent(context, c),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: ctaLabel,
                pocketIcon: topic == 'beans'
                    ? PocketIconType.plus
                    : (topic == 'dripper' || topic == 'filter'
                        ? PocketIconType.sliders
                        : PocketIconType.v60),
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 52,
                onTap: onCta,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBasicsContent(BuildContext context, PocketColors c) {
    return [
      PocketEntrance(
        delayMs: 0,
        child: PocketCard(
          backgroundColor: c.tintHoney,
          elevated: false,
          padding: const EdgeInsets.all(14),
          child: Text(
            'Seduh manual (pour-over) intinya hanya menyeimbangkan 4 hal: Rasio air, Ukuran gilingan, Suhu air, dan Cara tuang (Bloom). Kalau 4 ini pas, kopimu bakal manis dan jernih.',
            style: PocketTheme.ui(
              size: 12.5,
              weight: 600,
              height: 1.45,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      const PocketSectionHeader(title: '1. Rasio Kopi : Air'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: '1:15 (Lebih Pekat & Manis)',
              badge: '15g → 225 ml',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Rasa lebih tebal dan intens. Cocok untuk Japanese Iced (sebagian air diganti es batu) atau kopi medium roast.',
            ),
            const Divider(),
            _InfoRow(
              title: '1:16 – 1:17 (Standar Harian)',
              badge: '15g → 240–255 ml',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Titik manis paling seimbang (standar SCA & James Hoffmann). Aroma floral dan buah keluar jelas tanpa terasa encer.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const PocketSectionHeader(title: '2. Ukuran Gilingan & Suhu Air'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Ukuran Gilingan V60',
              badge: 'Medium-Fine',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Kira-kira sehalus garam dapur. Lebih halus = air turun lebih lambat & rasa makin kuat; lebih kasar = air cepat turun & rasa makin ringan.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Light Roast (Cerah / Floral)',
              badge: '93°C – 96°C',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Biji light roast lebih padat sehingga butuh air lebih panas agar rasa manis dan buahnya keluar maksimal.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Medium & Dark Roast',
              badge: '88°C – 92°C',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Biji yang disangrai lebih gelap lebih mudah terekstrak — suhu sedikit lebih rendah mencegah rasa pahit/gosong.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const PocketSectionHeader(title: '3. Kenapa Harus Bloom (0:00 – 0:45)?'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Saat air panas pertama menyentuh kopi (2–3× berat kopi, misal 45–50 ml untuk 15g), gas CO₂ dari proses sangrai akan keluar membentuk gelembung. Tunggu 30–45 detik dan goyang ringan (swirl) supaya semua bubuk basah merata sebelum tuangan berikutnya.',
          style: PocketTheme.ui(
            size: 12.5,
            weight: 500,
            height: 1.48,
            color: c.textSecondary,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTroubleshootContent(
    BuildContext context,
    PocketColors c,
  ) {
    return [
      PocketEntrance(
        delayMs: 0,
        child: PocketCard(
          backgroundColor: c.tintSage,
          elevated: false,
          padding: const EdgeInsets.all(14),
          child: Text(
            'Aturan Emas Seduh Manual: jika rasa belum pas, ubah SATU variabel saja di seduhan berikutnya (mulai dari klik grinder dulu) supaya kamu tahu pasti penyebab perubahannya.',
            style: PocketTheme.ui(
              size: 12.5,
              weight: 700,
              height: 1.45,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      const PocketSectionHeader(title: 'Diagnosa Cepat dari Rasa di Lidah'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Asam Tajam, Kecut, atau Encer',
              badge: 'Kurang Terekstrak',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Biasanya air turun terlalu cepat (<2:20). Solusi: haluskan gilingan 1–2 klik, atau naikkan suhu air +2°C, atau pastikan bloom dibasahi rata.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Pahit, Sepat, atau Kering di Lidah',
              badge: 'Terlalu Terekstrak',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Biasanya air turun terlalu lama (>3:45). Solusi: kasarkan gilingan 1–2 klik, turunkan suhu −2°C, dan tuang lebih tenang tanpa terlalu sering diaduk.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Air Mampet / Menetes Lama (>4 mnt)',
              badge: 'Filter Tersumbat',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Bubuk sangat halus (fines) turun menutup pori kertas filter. Solusi: tuang dari ketinggian lebih rendah, kurangi goyangan keras, atau gunakan kertas filter aliran cepat (Cafec Abaca).',
            ),
            const Divider(),
            _InfoRow(
              title: 'Rasa Hambar / Kurang Beraroma',
              badge: 'Cek Rasio & Umur Biji',
              bg: c.tintBerry,
              fg: c.brandBerry,
              desc:
                  'Coba perkecil rasio ke 1:15 (air lebih sedikit), cek apakah biji sudah terlalu lama lewat masa peak (>6 minggu), atau cek kualitas air seduhmu.',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildWaterContent(BuildContext context, PocketColors c) {
    return [
      PocketEntrance(
        delayMs: 0,
        child: PocketCard(
          backgroundColor: c.tintIce,
          elevated: false,
          padding: const EdgeInsets.all(14),
          child: Text(
            'Lebih dari 98% isi secangkir V60 adalah air! Air yang tepat bikin manis dan aroma kopi jauh lebih terasa meski resepnya sama persis.',
            style: PocketTheme.ui(
              size: 12.5,
              weight: 600,
              height: 1.45,
              color: c.textPrimary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      const PocketSectionHeader(title: 'Memilih Air Seduh Harian'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Air Mineral Ringan / Filtered',
              badge: 'Ideal (75–150 ppm)',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Kandungan mineral ringan (kalsium & magnesium seimbang) membantu mengikat rasa manis dan buah dari kopi secara optimal.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Air Demineral / RO Murni (~0 ppm)',
              badge: 'Terlalu Kosong',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Tanpa mineral, rasa kopi sering terasa datar, tipis, atau asamnya menusuk tajam.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Air Keran / Mineral Sangat Tinggi',
              badge: 'Terlalu Berat',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Mineral kapur berlebih meredam keasaman cerah kopi sehingga rasanya jadi tumpul dan berat.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const PocketSectionHeader(title: 'Menyimpan & Merawat Biji Kopi'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Beri Waktu Resting Setelah Sangrai',
              badge: '4–14 Hari',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Biji yang baru disangrai masih penuh gas CO₂. Light roast paling enak di hari ke 7–14, medium di 4–7 hari, dark di 2–4 hari.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Wadah Kedap & Jauh dari Cahaya',
              badge: 'Suhu Ruang Sejuk',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Simpan di kantong asli ber-valve atau toples kedap udara, jauh dari kompor & sinar matahari. Giling biji tepat sebelum diseduh.',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildBeansContent(BuildContext context, PocketColors c) {
    final origins = [
      (
        'Ethiopia',
        'Floral · Peach · Tea',
        'Aroma bunga melati kuat, rasa ringan & sangat bersih.',
        c.tintBerry,
        c.brandBerry,
      ),
      (
        'Kenya',
        'Blackcurrant · Juicy',
        'Asam buah beri yang cerah, segar, dan berlapis.',
        c.tintTerracotta,
        c.brandTerracottaInk,
      ),
      (
        'Colombia',
        'Caramel · Balanced',
        'Manis seimbang, cocok diminum setiap hari tanpa bikin bosan.',
        c.tintHoney,
        c.brandHoney,
      ),
      (
        'Indonesia / Gayo',
        'Spice · Herbal · Sweet',
        'Body lebih tebal, hangat, dengan sentuhan rempah manis.',
        c.tintSage,
        c.brandSage,
      ),
    ];

    return [
      const PocketSectionHeader(title: 'Karakter Daerah Populer'),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.18,
        children: origins.map((o) {
          return PocketCard(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PocketPill(
                    label: o.$2,
                    backgroundColor: o.$4,
                    foregroundColor: o.$5,
                    fontSize: 9.5,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    o.$3,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
      const PocketSectionHeader(title: 'Beda Proses Pasca-Panen'),
      const SizedBox(height: 10),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Washed (Cuci Bersih)',
              badge: 'Jernih & Cerah',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Daging buah dicuci sebelum dijemur → rasa paling bersih, asam segar, karakter asli daerah sangat terasa.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Natural (Jemur Utuh)',
              badge: 'Manis & Tebal',
              bg: c.tintBerry,
              fg: c.brandBerry,
              desc:
                  'Ceri kopi dijemur utuh bersama kulit → rasa manis buah matang (beri/tropis) dan body jauh lebih tebal.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Honey (Semi-Washed)',
              badge: 'Seimbang',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Sebagian lendir manis ditinggal saat dijemur → perpaduan manis sirup dengan akhir yang tetap bersih.',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildDripperContent(BuildContext context, PocketColors c) {
    return [
      const PocketSectionHeader(title: 'Bentuk Dripper & Karakter Rasa'),
      const SizedBox(height: 10),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Hario V60 (Cone 60°)',
              badge: 'Cerah & Kompleks',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Lubang besar & ulir spiral membuat aliran cepat. Menonjolkan aroma floral & asam buah yang jernih.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Kalita Wave (Flat-Bottom)',
              badge: 'Manis & Konsisten',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Dasar datar dengan 3 lubang kecil membuat ekstraksi lebih rata dan body bulat — sangat ramah pemula.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Hario Switch (Hybrid)',
              badge: 'Perkulasi + Rendam',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Punya katup tutup/buka: bisa jadi V60 biasa atau direndam dulu untuk rasa manis pekat tanpa repot.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      PocketCard(
        backgroundColor: c.tintSage,
        borderColor: Colors.transparent,
        padding: const EdgeInsets.all(14),
        child: Text(
          'Bahan Plastik vs Keramik: Dripper plastik (AS Resin) justru menjaga suhu air paling stabil karena tidak menyerap panas dari seduhan!',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildFilterContent(BuildContext context, PocketColors c) {
    return [
      const PocketSectionHeader(title: 'Pengaruh Kertas Filter ke Aliran Air'),
      const SizedBox(height: 10),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          children: [
            _InfoRow(
              title: 'Hario VCF-02W Japan',
              badge: 'Standar Harian',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Aliran sedang dan seimbang. Titik acuan terbaik untuk belajar V60 harian.',
            ),
            const Divider(),
            _InfoRow(
              title: 'Cafec Abaca & T-90',
              badge: 'Aliran Cepat',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Serat abaca jarang mampet walau biji Ethiopia/Kenya menghasilkan banyak bubuk halus (fines).',
            ),
            const Divider(),
            _InfoRow(
              title: 'Cafec T-92 & Hario Holland',
              badge: 'Aliran Lambat',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Kertas lebih rapat dan tebal — kasarkan gilingan 1–2 klik agar drawdown tidak terlalu lama.',
            ),
          ],
        ),
      ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.badge,
    required this.bg,
    required this.fg,
    required this.desc,
  });

  final String title;
  final String badge;
  final Color bg;
  final Color fg;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PocketPill(
                label: badge,
                backgroundColor: bg,
                foregroundColor: fg,
                fontSize: 10.5,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(desc, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
