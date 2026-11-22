import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/canvas/coffee_atmosphere.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';

/// Complete Pro-Standard Educational Detail Screen for Belajar Seduh:
/// Grounded in SCA standards, World Brewers Cup insights, and modern extraction research
/// (J. Gagné, S. Rao, Colonna-Dashwood & Hendon), presented in calm, readable, interactive Indonesian.
/// Topics: `beans`, `basics`, `troubleshoot`, `iced`, `water`, `dripper` (incl. `filter`), `grinder`.
class LearnTopicDetailScreen extends StatefulWidget {
  const LearnTopicDetailScreen({super.key, required this.topic});

  final String topic;

  @override
  State<LearnTopicDetailScreen> createState() => _LearnTopicDetailScreenState();
}

class _LearnTopicDetailScreenState extends State<LearnTopicDetailScreen> {
  // Interactive lab state indices (lightweight, local to current article)
  int _roastTab = 0; // 0=Light, 1=Medium, 2=Dark
  int _extractTab = 1; // 0=Under, 1=SweetSpot, 2=Over
  int _symptomTab = 0; // 0=Sour, 1=Bitter, 2=Weak, 3=Stalled
  int _icedTab = 1; // 0=70/30, 1=65/35, 2=60/40
  int _dripperTab = 0; // 0=Cone, 1=Flat, 2=Hybrid
  int _burrTab = 0; // 0=Conical, 1=Flat

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final topic = widget.topic == 'filter' ? 'dripper' : widget.topic;

    final (
      String title,
      String readTime,
      String ctaLabel,
      PocketIconType ctaIcon,
      VoidCallback onCta,
    ) = switch (topic) {
      'basics' => (
          'Ilmu Ekstraksi (SCA)',
          '4 mnt',
          'Praktikkan di Brew',
          PocketIconType.v60,
          () => context.go('/brew'),
        ),
      'troubleshoot' => (
          'Diagnosa Rasa',
          '4 mnt',
          'Sesuaikan di Brew',
          PocketIconType.v60,
          () => context.go('/brew'),
        ),
      'iced' => (
          'Japanese Iced Pro',
          '4 mnt',
          'Coba Japanese Iced',
          PocketIconType.snowflake,
          () => context.go('/brew'),
        ),
      'water' => (
          'Kimia Air Seduh',
          '3 mnt',
          'Praktikkan di Brew',
          PocketIconType.v60,
          () => context.go('/brew'),
        ),
      'dripper' => (
          'Dripper & Filter',
          '4 mnt',
          'Pilih di Alat Seduh',
          PocketIconType.burrGear,
          () => context.go('/gear'),
        ),
      'grinder' => (
          'Grinder & Burr',
          '3 mnt',
          'Atur di Alat Seduh',
          PocketIconType.burrGear,
          () => context.go('/gear'),
        ),
      _ => (
          'Ensiklopedia Biji Kopi',
          '5 mnt',
          'Tambah Kopi ke Koleksi',
          PocketIconType.plus,
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
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                children: switch (topic) {
                  'basics' => _buildBasicsContent(c),
                  'troubleshoot' => _buildTroubleshootContent(c),
                  'iced' => _buildIcedContent(c),
                  'water' => _buildWaterContent(c),
                  'dripper' => _buildDripperContent(c),
                  'grinder' => _buildGrinderContent(c),
                  _ => _buildBeansContent(c),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: ctaLabel,
                pocketIcon: ctaIcon,
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

  // ===========================================================================
  // 1. ENSIKLOPEDIA BIJI KOPI (Spesies, Ketinggian, 5 Proses, Sangrai, Resting)
  // ===========================================================================
  List<Widget> _buildBeansContent(PocketColors c) {
    final roastProfiles = [
      (
        label: 'Light Roast',
        dotColor: const Color(0xFFA86A3D),
        temp: '93°C – 96°C',
        rest: '7 – 14 hari',
        density: 'Padat & keras',
        taste:
            'Aroma bunga (floral), keasaman buah cerah (citrus, berry, peach), dan body ringan seperti teh. Butuh air lebih panas agar ekstraksi tembus sampai inti biji.',
      ),
      (
        label: 'Medium Roast',
        dotColor: const Color(0xFF6F4229),
        temp: '90°C – 93°C',
        rest: '5 – 10 hari',
        density: 'Seimbang',
        taste:
            'Keseimbangan manis karamel/cokelat dengan sentuhan buah lembut. Paling fleksibel untuk V60 harian maupun Japanese Iced.',
      ),
      (
        label: 'Dark Roast',
        dotColor: const Color(0xFF3A2218),
        temp: '84°C – 89°C',
        rest: '2 – 6 hari',
        density: 'Berpori & rapuh',
        taste:
            'Dominan cokelat pekat, rempah, dan body tebal. Karena sangat mudah larut, gunakan suhu lebih rendah & giling sedikit lebih kasar agar tidak pahit gosong.',
      ),
    ];
    final rp = roastProfiles[_roastTab];

    return [
      _TopicHeroCard(
        reference: 'Standar SCA · World Coffee Research',
        headline: 'Rasa di cangkir 70% ditentukan sebelum air menyentuh kopi',
        summary:
            'Genetik spesies, ketinggian kebun, proses pasca panen, level sangrai, dan umur resting adalah kunci memahami kenapa tiap kantong biji kopi perlu perlakuan seduh berbeda.',
        tint: c.tintTerracotta,
        accent: c.brandTerracottaInk,
      ),
      const SizedBox(height: 16),

      // Interactive Roast & Resting Lab
      const PocketSectionHeader(title: '1. Profil Sangrai, Suhu & Masa Resting'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SegmentRow(
              labels: const ['Light', 'Medium', 'Dark'],
              selected: _roastTab,
              accent: c.brandTerracotta,
              onSelect: (i) => setState(() => _roastTab = i),
            ),
            const SizedBox(height: 13),
            AnimatedSwitcher(
              duration: PocketCurves.normal,
              child: Column(
                key: ValueKey('roast_$_roastTab'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: rp.dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.borderStrong, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${rp.label} · ${rp.density}',
                          style: PocketTheme.ui(
                            size: 14.5,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MiniStatBox(label: 'Suhu Ideal', value: rp.temp),
                      const SizedBox(width: 8),
                      _MiniStatBox(label: 'Masa Resting', value: rp.rest),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rp.taste,
                    style: PocketTheme.ui(
                      size: 13.2,
                      weight: 500,
                      height: 1.52,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Species & Altitude
      const PocketSectionHeader(title: '2. Spesies & Ketinggian Kebun (MASL)'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Arabica (Coffea arabica)',
              badge: '1.200–2.200 mdpl',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Standar utama pour-over specialty. Kadar gula & lipid lebih tinggi, kafein lebih rendah (~1,2%), sehingga menghasilkan aroma floral, buah, dan manis bersih.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Robusta (Coffea canephora)',
              badge: '200–900 mdpl',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Kafein hampir 2× lipat (~2,2%), body sangat tebal, catatan cokelat gelap/kacang. Jarang dipakai untuk V60 murni, lebih umum di espresso/kopi susu.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Liberica & Excelsa',
              badge: 'Langka · Tropis',
              bg: c.tintBerry,
              fg: c.brandBerry,
              desc:
                  'Biji berukuran besar khas Asia Tenggara (seperti Jambi/Meranti). Aroma unik nangka matang, asap kayu lembut, dan buah tropis eksotis.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Hukum Ketinggian (MASL)',
              badge: 'Makin Tinggi = Padat',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Di dataran tinggi bersuhu sejuk, ceri kopi matang lebih lambat sehingga menumpuk lebih banyak gula & asam organik kompleks. Biji sangat padat → butuh suhu air lebih panas.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 5 Complete Post-Harvest Processes
      const PocketSectionHeader(title: '3. 5 Proses Pasca Panen Utama'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Washed (Cuci Bersih)',
              badge: 'Jernih & Floral',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Kulit dan lendir manis (mucilage) dibersihkan penuh sebelum dijemur. Hasil paling bersih (high clarity), menonjolkan karakter asli tanah & varietas.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Natural (Jemur Utuh)',
              badge: 'Manis Buah Matang',
              bg: c.tintBerry,
              fg: c.brandBerry,
              desc:
                  'Ceri kopi dijemur utuh bersama kulitnya 2–4 minggu. Gula buah meresap ke biji → rasa beri, buah tropis, body lebih tebal, namun hati-hati suhu terlalu tinggi bisa mudah over-extract.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Honey (Yellow / Red / Black)',
              badge: 'Manis Sirup Seimbang',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Kulit dikupas tapi sebagian lendir manis dibiarkan menempel saat dijemur. Makin gelap warna honey (Black Honey), makin intens rasa manis & buahnya.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Anaerobic / Carbonic Maceration',
              badge: 'Aromatik & Eksotis',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Fermentasi terkontrol dalam tangki kedap oksigen (populer di panggung World Brewers Cup). Aroma sangat mencolok (winey, kayu manis, buah tropis). Tip: turunkan suhu 2–3°C (88–91°C) agar rasa tidak terlalu "fermenty".',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Wet-Hulled (Giling Basah · Nusantara)',
              badge: 'Khas Gayo / Mandheling',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Proses khas Indonesia di mana kulit tanduk dikupas saat kadar air biji masih ~30–35%. Memberi body kental, keasaman rendah, dan aroma rempah/herbal hangat.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // World & Indonesian Origins
      const PocketSectionHeader(title: '4. Peta Karakter Origin Populer'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Ethiopia (Guji / Yirgacheffe)',
              badge: 'Jasmine · Peach · Tea',
              bg: c.tintBerry,
              fg: c.brandBerry,
              desc:
                  'Tempat lahir kopi Arabica. Ciri khas aroma bunga melati, bergamot, persik, dan tekstur ringan elegan. Catatan: cenderung menghasilkan lebih banyak bubuk halus (fines).',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Kenya (Nyeri / Kirinyaga)',
              badge: 'Blackcurrant · Juicy',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Varietas SL28 & SL34 terkenal dengan keasaman asam fosfat/malat yang "sparkling" seperti jus beri hitam dan jeruk bali.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Colombia & Panama',
              badge: 'Caramel · Geisha Floral',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Colombia unggul di rasa seimbang manis karamel hingga eksperimen fermentasi modern. Panama terkenal dengan varietas Geisha beraroma melati & jeruk mandarin.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Indonesia (Gayo · Flores · Bali · Toraja)',
              badge: 'Manis · Rempah · Tropis',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Gayo & Flores modern (Washed/Natural) punya manis gula aren, jeruk, & cokelat lembut; Bali Kintamani segar citrus; Toraja & Mandheling hangat berempah.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Storage & Freezer Science
      const PocketSectionHeader(title: '5. Penyimpanan & Rahasia Freezer'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BulletStep(
              num: '1',
              text:
                  'Tunggu fase degassing (resting): biji baru sangrai (hari 1–3) masih membuang gas CO₂ deras yang menolak air saat diseduh, membuat rasa terasa tipis & bersoda.',
            ),
            const SizedBox(height: 9),
            const _BulletStep(
              num: '2',
              text:
                  'Musuh utama kopi: Oksigen, Cahaya, Panas, dan Kelembapan. Simpan di kantong asli ber-valve satu arah atau toples kedap di lemari sejuk gelap.',
            ),
            const SizedBox(height: 9),
            const _BulletStep(
              num: '3',
              text:
                  'Cara benar simpan di Freezer (teknik WBrC): bekukan saat biji sudah masuk masa puncak (hari ke 7–14), tutup rapat katup udaranya pakai selotip atau bagi per-dosis 15g di tabung vakum. Jangan pernah buka-tutup kantong beku berulang kali agar uap air tidak mengembun!',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MythFactCard(
        myth: 'Kopi paling segar (baru disangrai 1 hari) pasti paling enak.',
        fact:
            'Faktanya, kopi light roast butuh 7–14 hari resting agar CO₂ mereda sehingga air bisa mengekstrak rasa manis dan aroma buah secara maksimal.',
      ),
    ];
  }

  // ===========================================================================
  // 2. ILMU EKSTRAKSI & RASIO EMAS (Standar SCA)
  // ===========================================================================
  List<Widget> _buildBasicsContent(PocketColors c) {
    final zones = [
      (
        title: 'Kurang Terekstrak (< 18%)',
        pointer: 0.16,
        color: c.brandHoney,
        taste: 'Asam tajam/kecut, asin tipis, cepat hilang di akhir (hollow).',
        why:
            'Senyawa asam & garam larut paling awal saat air menyentuh kopi; gula manis & senyawa penyeimbang belum sempat keluar.',
        fix: 'Haluskan gilingan 1–2 klik atau naikkan suhu air +2°C.',
      ),
      (
        title: 'Titik Manis SCA (18% – 22%)',
        pointer: 0.50,
        color: c.brandSage,
        taste: 'Manis alami, asam buah cerah terstruktur, bersih & seimbang.',
        why:
            'Menurut SCA Brewing Control Chart, rentang 18–22% Extraction Yield (dengan TDS ~1,25–1,45% untuk filter) menghasilkan keseimbangan rasa terbaik.',
        fix: 'Catat klik, suhu, dan waktunya sebagai resep andalan!',
      ),
      (
        title: 'Terlalu Terekstrak (> 22%)',
        pointer: 0.84,
        color: c.brandTerracotta,
        taste: 'Pahit pekat, sepat, kering di lidah (astringent), aroma tertutup.',
        why:
            'Air menarik senyawa pahit berat & polifenol kayu yang larut paling akhir karena kontak terlalu lama atau gilingan terlalu halus.',
        fix: 'Kasarkan gilingan 1–2 klik, turunkan suhu −2°C, kurangi agitasi.',
      ),
    ];
    final z = zones[_extractTab];

    return [
      _TopicHeroCard(
        reference: 'Acuan: SCA Brewing Control Chart',
        headline: 'Ekstraksi adalah seni melarutkan 18–22% bagian terbaik kopi',
        summary:
            'Hanya sekitar 30% massa bubuk kopi yang bisa larut dalam air. Tugas kita adalah mengambil 18–22% bagian manis & aromatiknya, lalu berhenti sebelum senyawa pahit berat ikut terekstrak.',
        tint: c.tintHoney,
        accent: c.brandHoney,
      ),
      const SizedBox(height: 16),

      // Interactive Extraction Balance Visual
      const PocketSectionHeader(title: '1. Peta Keseimbangan Ekstraksi'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SegmentRow(
              labels: const ['Kurang', 'Titik Manis', 'Berlebih'],
              selected: _extractTab,
              accent: z.color,
              onSelect: (i) => setState(() => _extractTab = i),
            ),
            const SizedBox(height: 14),
            // Animated Spectrum Pointer Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return SizedBox(
                  height: 22,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 8,
                                color: c.brandHoney.withValues(alpha: 0.55),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 8,
                                color: c.brandSage,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 8,
                                color: c.brandTerracotta.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedPositioned(
                        duration: PocketCurves.normal,
                        curve: PocketCurves.gentleSpring,
                        left: (w * z.pointer - 10).clamp(0.0, w - 20),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: z.color, width: 3.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: PocketCurves.fast,
              child: Column(
                key: ValueKey('ext_$_extractTab'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    z.title,
                    style: PocketTheme.ui(
                      size: 14.5,
                      weight: 800,
                      color: z.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Rasa: ${z.taste}',
                    style: PocketTheme.ui(
                      size: 13.2,
                      weight: 700,
                      height: 1.45,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    z.why,
                    style: PocketTheme.ui(
                      size: 12.8,
                      weight: 500,
                      height: 1.48,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceElevated,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'Langkah: ${z.fix}',
                      style: PocketTheme.ui(
                        size: 12.4,
                        weight: 700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Ratio Table
      const PocketSectionHeader(title: '2. Panduan Rasio Kopi : Air'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: '1:15 (Lebih Pekat & Body Tebal)',
              badge: '15g → 225 ml',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Menghasilkan cangkir lebih kental (strength tinggi) dan manis intens. Sangat cocok untuk Japanese Iced atau biji medium/natural.',
            ),
            const Divider(),
            _ProDetailRow(
              title: '1:16 – 1:16.7 (Golden Ratio SCA)',
              badge: '15g → 240–250 ml',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Titik acuan utama James Hoffmann & kompetisi filter. Keseimbangan terbaik antara kejelasan rasa (clarity) dan manis.',
            ),
            const Divider(),
            _ProDetailRow(
              title: '1:17 – 1:18 (Ringan & Tea-Like)',
              badge: '15g → 255–270 ml',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Ekstraksi lebih tinggi tapi tubuh kopi lebih ringan seperti teh. Cocok untuk Ethiopia Washed atau Geisha beraroma halus.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Bloom Science
      const PocketSectionHeader(title: '3. Fisika Bloom (0:00 – 0:45)'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BulletStep(
              num: '1',
              text:
                  'Tuang air sebanyak 2× sampai 3× berat kopi (misal 45–50 ml untuk 15g) dalam 10–15 detik pertama.',
            ),
            const SizedBox(height: 9),
            const _BulletStep(
              num: '2',
              text:
                  'Gelembung yang mengembang adalah gas CO₂. Selama gas masih terdorong keluar, air tidak bisa menempel sempurna ke partikel kopi.',
            ),
            const SizedBox(height: 9),
            const _BulletStep(
              num: '3',
              text:
                  'Lakukan 1–2 goyangan halus (swirl) segera setelah tuang bloom agar tidak ada kantong bubuk kering, lalu tunggu hingga detik 0:45.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MythFactCard(
        myth: 'Air mendidih 96–100°C bikin biji kopi gosong.',
        fact:
            'Kopi disangrai di suhu >200°C, jadi air 96°C mustahil membakar kopi! Suhu tinggi justru diperlukan untuk light roast padat agar ekstraksi optimal.',
      ),
    ];
  }

  // ===========================================================================
  // 3. DIAGNOSA RASA & COFFEE COMPASS
  // ===========================================================================
  List<Widget> _buildTroubleshootContent(PocketColors c) {
    final symptoms = [
      (
        label: 'Asam Tajam',
        status: 'Under-Extracted (Kurang Terekstrak)',
        color: c.brandHoney,
        sign: 'Rasa kecut menggigit, agak asin, selesai terlalu cepat (<2:15).',
        steps: const [
          'Prioritas 1: Haluskan gilingan 1–2 klik (−30 s/d −60 μm) supaya air lebih lama mengekstrak.',
          'Prioritas 2: Naikkan suhu air +2°C (misal 92°C → 94°C) terutama untuk light roast.',
          'Prioritas 3: Pastikan saat bloom seluruh bubuk basah rata dan tidak membentuk kantong kering.',
        ],
      ),
      (
        label: 'Pahit / Sepat',
        status: 'Over-Extracted / Astringent',
        color: c.brandTerracotta,
        sign: 'Pahit tajam, kesat/kering di lidah, atau waktu turun >3:45.',
        steps: const [
          'Prioritas 1: Kasarkan gilingan 1–2 klik (+30 s/d +60 μm) untuk memperlancar aliran.',
          'Prioritas 2: Turunkan suhu air −2°C hingga −3°C (terutama biji natural/anaerobic/medium-dark).',
          'Prioritas 3: Kurangi agitasi — tuang lebih tenang & cukup swirl ringan 1× saja.',
        ],
      ),
      (
        label: 'Encer / Hambar',
        status: 'Low Strength atau Biji Stale',
        color: c.brandIce,
        sign: 'Aroma redup, terasa seperti air teh tipis tanpa karakter.',
        steps: const [
          'Prioritas 1: Perkecil rasio air dari 1:17 ke 1:15 (lebih sedikit air untuk dosis kopi sama).',
          'Prioritas 2: Cek umur sangrai — biji di atas 6–8 minggu umumnya sudah kehilangan banyak aroma volatil.',
          'Prioritas 3: Cek air seduh — air dengan mineral terlalu rendah (RO 0 ppm) atau kapur terlalu tinggi bikin rasa tumpul.',
        ],
      ),
      (
        label: 'Air Mampet',
        status: 'Fines Migration (Pori Tersumbat)',
        color: c.brandBerry,
        sign: 'Air berhenti mengalir lancar, menetes lambat sekali (>4 menit).',
        steps: const [
          'Prioritas 1: Turunkan ketinggian tuangan kettle (cukup 3–5 cm dari permukaan air) agar bubuk halus (fines) tidak turun menyumbat kertas.',
          'Prioritas 2: Hindari swirl keras atau terlalu banyak tuangan kecil berulang pada biji Ethiopia/Kenya.',
          'Prioritas 3: Gunakan kertas filter aliran cepat seperti Cafec Abaca / T-90.',
        ],
      ),
    ];
    final sym = symptoms[_symptomTab];

    return [
      _TopicHeroCard(
        reference: 'Acuan: Coffee Compass · Single-Variable Dial-In',
        headline: 'Ubah SATU variabel saja tiap kali memperbaiki rasa',
        summary:
            'Kesalahan paling umum pemula adalah mengubah gilingan, suhu, dan rasio sekaligus. Dengan mengubah 1 variabel (dimulai dari klik grinder), kamu langsung tahu pasti apa yang bikin kopimu membaik.',
        tint: c.tintSage,
        accent: c.brandSage,
      ),
      const SizedBox(height: 16),

      // Interactive Symptom Fixer
      const PocketSectionHeader(title: '1. Pilih Gejala Rasa di Cangkirmu'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: List.generate(symptoms.length, (i) {
                final sel = i == _symptomTab;
                return PocketPill(
                  label: symptoms[i].label,
                  height: 34,
                  fontSize: 12,
                  fontWeight: 700,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: sel ? symptoms[i].color : c.surfaceElevated,
                  foregroundColor: sel ? c.textOnAccent : c.textPrimary,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _symptomTab = i);
                  },
                );
              }),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: PocketCurves.fast,
              child: Column(
                key: ValueKey('sym_$_symptomTab'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sym.status,
                    style: PocketTheme.ui(
                      size: 14.5,
                      weight: 800,
                      color: sym.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sym.sign,
                    style: PocketTheme.ui(
                      size: 12.6,
                      weight: 600,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(sym.steps.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i < sym.steps.length - 1 ? 9 : 0,
                      ),
                      child: _BulletStep(
                        num: '${i + 1}',
                        text: sym.steps[i],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Reading the Coffee Bed
      const PocketSectionHeader(title: '2. Membaca Ampas (Coffee Bed) & Channeling'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Bed Rata & Halus (Ideal)',
              badge: 'Ekstraksi Seragam',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Permukaan ampas rata seperti pasir pantai menandakan air melewati seluruh bubuk dengan ketebalan merata.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Kawah Dalam / Lubang di Tengah',
              badge: 'Channeling',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Air membuat jalur pintas (channeling), hasilnya aneh: terasa ASAM sekaligus PAHIT di tegukan yang sama! Solusi: ratakan bubuk sebelum bloom & tuang lebih tenang.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Banyak Bubuk Menempel di Dinding Atas',
              badge: 'High & Dry',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Bubuk yang tersangkut di dinding atas tidak ikut terekstrak. Lakukan 1× swirl ringan di akhir tuangan untuk menurunkannya.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MythFactCard(
        myth: 'Kalau kopinya asam + pahit bersamaan, berarti suhunya salah.',
        fact:
            'Asam dan pahit yang muncul bersamaan adalah tanda klasik CHANNELING (aliran air tidak merata) atau gilingan tidak seragam, bukan semata-mata suhu.',
      ),
    ];
  }

  // ===========================================================================
  // 4. PANDUAN JAPANESE ICED / FLASH BREW
  // ===========================================================================
  List<Widget> _buildIcedContent(PocketColors c) {
    final splits = [
      (
        label: '70/30 · Bold',
        hotFrac: 0.70,
        hot: '175 ml',
        ice: '75g',
        desc:
            'Air panas lebih dominan sehingga ekstraksi maksimal, rasa lebih pekat & aromatik. Cocok jika es batu akan ditambah lagi di gelas saji.',
      ),
      (
        label: '65/35 · Seimbang',
        hotFrac: 0.65,
        hot: '162 ml',
        ice: '88g',
        desc:
            'Standar emas Japanese Iced (rekomendasi James Hoffmann & Tetsu Kasuya). Semua es meleleh pas saat seduh selesai, langsung dingin segar tanpa encer.',
      ),
      (
        label: '60/40 · Segar',
        hotFrac: 0.60,
        hot: '150 ml',
        ice: '100g',
        desc:
            'Paling dingin dan super menyegarkan untuk siang terik. Wajib giling sedikit lebih halus (−3 klik) supaya rasa buah tetap keluar penuh.',
      ),
    ];
    final sp = splits[_icedTab];

    return [
      _TopicHeroCard(
        reference: 'Acuan: Flash Brew Method (Jepang · Hoffmann · Kasuya)',
        headline: 'Mengunci aroma kopi panas seketika di atas es batu',
        summary:
            'Berbeda dari Cold Brew yang direndam dingin berjam-jam (aroma floral hilang), Japanese Iced menyeduh panas dengan sebagian air diganti es batu sehingga aroma buah & bunga langsung terkunci.',
        tint: c.tintIce,
        accent: c.brandIce,
      ),
      const SizedBox(height: 16),

      // Interactive Ice Split Simulator
      const PocketSectionHeader(title: '1. Simulator Proporsi Air Panas vs Es (250 ml)'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SegmentRow(
              labels: const ['70/30 Bold', '65/35 Pas', '60/40 Segar'],
              selected: _icedTab,
              accent: c.brandIce,
              onSelect: (i) => setState(() => _icedTab = i),
            ),
            const SizedBox(height: 13),
            AnimatedWaterIceSplitBar(
              hotWaterLabel: sp.hot,
              iceLabel: sp.ice,
              hotFraction: sp.hotFrac,
              totalLabel: '250 ml (15–16g kopi)',
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: PocketCurves.fast,
              child: Text(
                sp.desc,
                key: ValueKey('iced_$_icedTab'),
                style: PocketTheme.ui(
                  size: 13,
                  weight: 500,
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Why Finer Grind + 2 Techniques
      const PocketSectionHeader(title: '2. 3 Kunci Wajib Agar Tidak Encer'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Giling Lebih Halus (−2 s/d −4 klik)',
              badge: 'Kunci #1',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Karena air panas yang melewati kopi hanya ~60–70% dari biasanya, kita wajib memperhalus gilingan agar ekstraksi tetap mencapai 19–21% sebelum air habis.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Rasio Total Lebih Ketat (1:14 – 1:16)',
              badge: 'Kunci #2',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Indera perasa manusia kurang peka terhadap manis saat minuman dingin. Rasio 1:15 menjaga rasa buah & manis tetap tebal walau disajikan dingin.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Es Duluan vs Seduh Dulu → Es',
              badge: '2 Teknik',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Es Duluan di server mendinginkan tiap tetes seketika (aroma paling segar). Seduh Dulu lalu tuang ke gelas es cocok kalau ingin mengontrol suhu & tampilan tetesan dulu baru didinginkan serentak.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MythFactCard(
        myth: 'Pakai es serut atau es kecil-kecil lebih bagus karena cepat dingin.',
        fact:
            'Es batu kristal padat ukuran sedang justru lebih baik: meleleh seimbang saat diseduh dan tidak meninggalkan genangan air encer di gelas saji.',
      ),
    ];
  }

  // ===========================================================================
  // 5. KIMIA AIR SEDUH (Standar SCA)
  // ===========================================================================
  List<Widget> _buildWaterContent(PocketColors c) {
    return [
      _TopicHeroCard(
        reference: 'Acuan: SCA Water Quality Handbook · Water for Coffee',
        headline: '98,5% isi cangkir pour-over kamu adalah air',
        summary:
            'Biji kopi mahal dengan resep juara sekalipun akan terasa datar atau asam tajam jika mineral airnya tidak seimbang. Air bukan sekadar pelarut — mineralnya ikut "menarik" rasa dari bubuk kopi.',
        tint: c.tintIce,
        accent: c.brandIce,
      ),
      const SizedBox(height: 16),

      // Visual TDS Spectrum Card
      const PocketSectionHeader(title: '1. Spektrum Mineral Air (TDS ppm)'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Row(
                children: [
                  Expanded(
                    flex: 25,
                    child: Container(
                      height: 11,
                      color: c.brandHoney.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    flex: 40,
                    child: Container(height: 11, color: c.brandSage),
                  ),
                  Expanded(
                    flex: 35,
                    child: Container(
                      height: 11,
                      color: c.brandTerracotta.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  flex: 25,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '0 ppm (RO)',
                      style: PocketTheme.mono(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: c.brandHoney,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 50,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      '75–150 ppm (Ideal SCA)',
                      style: PocketTheme.mono(
                        size: 11,
                        weight: FontWeight.w800,
                        color: c.brandSage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 25,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '250+ ppm',
                      style: PocketTheme.mono(
                        size: 10.5,
                        weight: FontWeight.w700,
                        color: c.brandTerracottaInk,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rentang ideal SCA berada di kisaran 75–150 ppm (dengan pH netral 6,8–7,5, bebas bau klorin). Di bawah 40 ppm kopi terasa tajam/kosong; di atas 200 ppm keasaman buah meredup jadi tumpul.',
              style: PocketTheme.ui(
                size: 13,
                weight: 500,
                height: 1.5,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // 3 Key Minerals
      const PocketSectionHeader(title: '2. Peran 3 Mineral Utama dalam Rasa'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Magnesium (Mg²⁺) · Penarik Aroma Buah',
              badge: 'Clarity & Fruity',
              bg: c.tintBerry,
              fg: c.brandBerry,
              desc:
                  'Ion magnesium punya ikatan kuat terhadap senyawa aromatik buah & bunga di kopi, bikin notes berry/peach keluar lebih terang.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Kalsium (Ca²⁺) · Pembentuk Body',
              badge: 'Sweet & Creamy',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Membantu ekstraksi rasa manis berat dan sensasi tekstur lembut (creamy body) di mulut.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Bikarbonat / KH · Penyangga Asam',
              badge: 'Ideal ~30–50 ppm',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Menetralkan kelebihan asam supaya halus. Tapi jika KH terlalu tinggi (>80 ppm), semua keasaman cerah kopi specialty bakal hilang jadi seperti air kapur!',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Practical Indonesia Guide
      const PocketSectionHeader(title: '3. Tips Praktis Memilih Air di Rumah'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _BulletStep(
              num: '1',
              text:
                  'Pilih air mineral kemasan ringan (TDS ~50–120 ppm, pH ~7) dibanding air demineral/RO murni (~0–15 ppm) yang bikin rasa tipis.',
            ),
            SizedBox(height: 9),
            _BulletStep(
              num: '2',
              text:
                  'Hindari air mineral ber-pH basa ekstrem (pH 8,5–9,5+) karena alkalinitasnya terlalu tinggi dan mematikan karakter asam buah kopi.',
            ),
            SizedBox(height: 9),
            _BulletStep(
              num: '3',
              text:
                  'Jangan merebus ulang air sisa berkali-kali — kadar mineralnya makin pekat akibat penguapan.',
            ),
          ],
        ),
      ),
    ];
  }

  // ===========================================================================
  // 6. GEOMETRI DRIPPER & KERTAS FILTER
  // ===========================================================================
  List<Widget> _buildDripperContent(PocketColors c) {
    final drippers = [
      (
        name: 'Kerucut 60° (V60 / Origami)',
        flow: 'Cepat · Aliran bebas',
        profile: 'Clarity tinggi, floral, asam buah tajam & berlapis',
        desc:
            'Lubang besar di dasar membuat ketebalan bubuk kopi paling dalam di tengah. Sangat responsif terhadap teknik tuangan — favorit kompetisi untuk biji washed & floral.',
      ),
      (
        name: 'Dasar Datar (Kalita Wave / Orea)',
        flow: 'Sedang · Terkontrol',
        profile: 'Manis bulat, body seimbang, super konsisten',
        desc:
            'Ketebalan bed kopi seragam dari pinggir ke tengah dengan 3 lubang kecil yang menahan aliran. Jauh lebih pemaaf terhadap ketidakstabilan tuangan, cocok untuk hasil manis konsisten tiap pagi.',
      ),
      (
        name: 'Hybrid Katup (Hario Switch / Clever)',
        flow: 'Bisa Perkulasi + Rendam',
        profile: 'Manis tebal, minim asam tajam, praktis',
        desc:
            'Tutup katup untuk merendam kopi (immersion) lalu buka katup untuk mengalirkan lewat kertas filter. Menggabungkan kemudahan French Press dengan kejernihan V60.',
      ),
    ];
    final dr = drippers[_dripperTab];

    return [
      _TopicHeroCard(
        reference: 'Acuan: Riset Perkolasi & Bypass (J. Gagné)',
        headline: 'Bentuk dripper & serat kertas mengatur kecepatan aliran air',
        summary:
            'Geometri menentukan seberapa rata air menembus bed kopi, sementara kertas filter menjadi "rem alami" yang menentukan waktu kontak dan seberapa bersih cangkir dari minyak kopi.',
        tint: c.tintSage,
        accent: c.brandSage,
      ),
      const SizedBox(height: 16),

      // Interactive Dripper Geometry Comparator
      const PocketSectionHeader(title: '1. Bandingkan 3 Geometri Dripper'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SegmentRow(
              labels: const ['Kerucut 60°', 'Dasar Datar', 'Hybrid'],
              selected: _dripperTab,
              accent: c.brandSage,
              onSelect: (i) => setState(() => _dripperTab = i),
            ),
            const SizedBox(height: 13),
            AnimatedSwitcher(
              duration: PocketCurves.fast,
              child: Column(
                key: ValueKey('dr_$_dripperTab'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dr.name,
                    style: PocketTheme.ui(
                      size: 14.5,
                      weight: 800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniStatBox(label: 'Aliran', value: dr.flow),
                      const SizedBox(width: 8),
                      _MiniStatBox(label: 'Karakter', value: dr.profile),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    dr.desc,
                    style: PocketTheme.ui(
                      size: 13,
                      weight: 500,
                      height: 1.5,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Filter Paper Guide
      const PocketSectionHeader(title: '2. Jenis Kertas Filter & Laju Alir'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
        radius: 20,
        child: Column(
          children: [
            _ProDetailRow(
              title: 'Hario VCF-02W Japan (Tabbed/Untabbed)',
              badge: 'Standar · 0 μm',
              bg: c.tintTerracotta,
              fg: c.brandTerracottaInk,
              desc:
                  'Tolok ukur utama resep V60. Aliran seimbang dengan kejernihan rasa yang bersih.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Cafec Abaca & T-90 (Medium-Dark)',
              badge: 'Cepat · Anti Mampet',
              bg: c.tintSage,
              fg: c.brandSage,
              desc:
                  'Serat pisang abaca kuat & berpori lega — jarang tersumbat meski menyeduh biji Ethiopia/Kenya yang banyak fines. Boleh giling 1 klik lebih halus.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Cafec T-92 & Hario Holland',
              badge: 'Lambat · +1–2 klik',
              bg: c.tintIce,
              fg: c.brandIce,
              desc:
                  'Serat kertas lebih rapat sehingga air turun lebih pelan dan body sedikit lebih penuh. Kasarkan gilingan 1–2 klik supaya tidak over-extract.',
            ),
            const Divider(),
            _ProDetailRow(
              title: 'Pentingnya Bilas Filter (Pre-Wet)',
              badge: 'Wajib 100 ml Panas',
              bg: c.tintHoney,
              fg: c.brandHoney,
              desc:
                  'Bilas menyeluruh menghilangkan bau kertas (terutama kertas cokelat unbleached), menempelkan kertas ke rusuk dripper, sekaligus menghangatkan server.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MythFactCard(
        myth: 'Dripper keramik/kaca jauh lebih menjaga panas daripada plastik.',
        fact:
            'Riset termal membuktikan dripper plastik (AS Resin/Tritan) justru menjaga suhu seduhan paling stabil karena kapasitas panasnya rendah — tidak menyedot panas dari air seduh!',
      ),
    ];
  }

  // ===========================================================================
  // 7. GRINDER, BURR & PERAWATAN KONSISTENSI
  // ===========================================================================
  List<Widget> _buildGrinderContent(PocketColors c) {
    final burrs = [
      (
        title: 'Conical Burr (Kerucut)',
        dist: 'Bimodal (sedikit fines)',
        flavor: 'Manis bulat, body lebih kaya, tekstur lembut',
        examples: 'Comandante C40, 1Zpresso K-Ultra / J-Max, Timemore C2/C3',
        desc:
            'Paling populer untuk hand grinder rumahan. Menghasilkan distribusi partikel utama ditambah sedikit fines alami yang memberi manis & ketebalan nyaman di lidah.',
      ),
      (
        title: 'Flat Burr (Datar)',
        dist: 'Unimodal (super seragam)',
        flavor: 'Clarity super bersih, manis cerah, pemisahan notes tajam',
        examples: 'Fellow Ode Gen 2 (SSP MP), DF64, Timemore Sculptor 078',
        desc:
            'Banyak dipakai barista kompetisi untuk memisahkan notes floral & buah secara presisi. Karena super seragam, air turun lebih cepat sehingga bisa digiling lebih halus tanpa pahit.',
      ),
    ];
    final b = burrs[_burrTab];

    return [
      _TopicHeroCard(
        reference: 'Acuan: Particle Distribution & RDT Research (Univ. Oregon)',
        headline: 'Grinder adalah investasi #1 penentu enaknya pour-over',
        summary:
            'Sekeren apa pun dripper atau kettle-mu, jika hasil gilingan tidak seragam (ada bongkahan kasar + debu halus sekaligus), mustahil mendapatkan ekstraksi bersih tanpa rasa pahit-asam bercampur.',
        tint: c.tintHoney,
        accent: c.brandHoney,
      ),
      const SizedBox(height: 16),

      // Interactive Burr Comparison
      const PocketSectionHeader(title: '1. Conical Burr vs Flat Burr'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SegmentRow(
              labels: const ['Conical Burr', 'Flat Burr'],
              selected: _burrTab,
              accent: c.brandHoney,
              onSelect: (i) => setState(() => _burrTab = i),
            ),
            const SizedBox(height: 13),
            AnimatedSwitcher(
              duration: PocketCurves.fast,
              child: Column(
                key: ValueKey('burr_$_burrTab'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    style: PocketTheme.ui(
                      size: 14.5,
                      weight: 800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MiniStatBox(label: 'Distribusi', value: b.dist),
                      const SizedBox(width: 8),
                      _MiniStatBox(label: 'Karakter', value: b.flavor),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    b.desc,
                    style: PocketTheme.ui(
                      size: 13,
                      weight: 500,
                      height: 1.5,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contoh: ${b.examples}',
                    style: PocketTheme.mono(
                      size: 11.2,
                      weight: FontWeight.w700,
                      color: c.brandTerracottaInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Practical Routine: RDT, Zero Point & Care
      const PocketSectionHeader(title: '2. Kebiasaan Pro: RDT, Zero Point & Perawatan'),
      const SizedBox(height: 8),
      PocketCard(
        padding: const EdgeInsets.all(15),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _BulletStep(
              num: '1',
              text:
                  'Teknik RDT (Ross Droplet Technique): semprot 1× kabut air sangat tipis (atau basahi ujung sendok lalu aduk ke biji) sebelum menggiling. Riset 2023 membuktikan ini memangkas listrik statis & debu menempel secara drastis!',
            ),
            SizedBox(height: 9),
            _BulletStep(
              num: '2',
              text:
                  'Pahami Zero Point (Titik Nol): selalu hitung klik dari posisi "burr tepat terkunci/tidak jatuh oleh gravitasi" — jangan memutar paksa melebihi batas agar mata burr tidak tumpul.',
            ),
            SizedBox(height: 9),
            _BulletStep(
              num: '3',
              text:
                  'Bersihkan rutin tiap 1–2 minggu memakai kuas halus kering & blower udara. JANGAN PERNAH mencuci burr baja dengan air agar tidak berkarat!',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MythFactCard(
        myth: 'Semua grinder dengan angka "20 klik" punya ukuran gilingan yang sama.',
        fact:
            'Tiap grinder punya jarak geser mikron per klik (Δμm) berbeda! 21 klik di Comandante C40 (±30 μm/klik) jauh berbeda dengan 21 klik di 1Zpresso K-Ultra (±20 μm/klik). Pocket Brew otomatis mengonversinya untukmu.',
      ),
    ];
  }
}

// =============================================================================
// REUSABLE LEARNING UI BUILDING BLOCKS
// =============================================================================

class _TopicHeroCard extends StatelessWidget {
  const _TopicHeroCard({
    required this.reference,
    required this.headline,
    required this.summary,
    required this.tint,
    required this.accent,
  });

  final String reference;
  final String headline;
  final String summary;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketEntrance(
      delayMs: 0,
      child: PocketCard(
        backgroundColor: tint,
        borderColor: accent.withValues(alpha: 0.28),
        elevated: false,
        radius: 22,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: c.surfaceCard.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                reference,
                style: PocketTheme.ui(
                  size: 10.5,
                  weight: 800,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              headline,
              style: PocketTheme.ui(
                size: 16.5,
                weight: 800,
                height: 1.25,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summary,
              style: PocketTheme.ui(
                size: 13.2,
                weight: 500,
                height: 1.5,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.labels,
    required this.selected,
    required this.accent,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: List.generate(labels.length, (i) {
        final sel = i == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 6 : 0),
            child: PocketTapScale(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(i);
              },
              child: AnimatedContainer(
                duration: PocketCurves.fast,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: sel ? accent : c.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    style: PocketTheme.ui(
                      size: 12,
                      weight: sel ? 800 : 600,
                      color: sel ? c.textOnAccent : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MiniStatBox extends StatelessWidget {
  const _MiniStatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: PocketTheme.ui(
                size: 10.5,
                weight: 700,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: PocketTheme.ui(
                size: 12.2,
                weight: 800,
                height: 1.25,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProDetailRow extends StatelessWidget {
  const _ProDetailRow({
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: PocketTheme.ui(
                  size: 14,
                  weight: 800,
                  color: c.textPrimary,
                ),
              ),
              PocketPill(
                label: badge,
                backgroundColor: bg,
                foregroundColor: fg,
                fontSize: 10.5,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: PocketTheme.ui(
              size: 13,
              weight: 500,
              height: 1.5,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletStep extends StatelessWidget {
  const _BulletStep({required this.num, required this.text});
  final String num;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          height: 23,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: c.tintTerracotta,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            num,
            style: PocketTheme.mono(
              size: 11,
              weight: FontWeight.w800,
              color: c.brandTerracottaInk,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: PocketTheme.ui(
              size: 13.2,
              weight: 500,
              height: 1.5,
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MythFactCard extends StatelessWidget {
  const _MythFactCard({required this.myth, required this.fact});
  final String myth;
  final String fact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketCard(
      backgroundColor: c.tintHoney,
      borderColor: c.brandHoney.withValues(alpha: 0.3),
      elevated: false,
      radius: 20,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mitos vs Fakta',
            style: PocketTheme.ui(
              size: 12.2,
              weight: 800,
              color: c.brandHoney,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Mitos: "$myth"',
            style: PocketTheme.ui(
              size: 12.8,
              weight: 700,
              height: 1.4,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            fact,
            style: PocketTheme.ui(
              size: 13,
              weight: 500,
              height: 1.48,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
