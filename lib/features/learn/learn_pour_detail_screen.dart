import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/widgets/canvas/spiral_pour_diagram.dart';
import '../../core/widgets/pocket_card.dart';

/// Screen 20 · Detail Teknik Penuangan (Interactive Animated Canvas Diagram + 3 Pour Techniques).
class LearnPourDetailScreen extends StatefulWidget {
  const LearnPourDetailScreen({super.key});

  @override
  State<LearnPourDetailScreen> createState() => _LearnPourDetailScreenState();
}

class _LearnPourDetailScreenState extends State<LearnPourDetailScreen> {
  PourDemoType _selected = PourDemoType.spiral;
  bool _playing = true;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Teknik Penuangan',
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: 'Animasi',
                icon: Icons.play_circle_outline_rounded,
                backgroundColor: c.tintTerracotta,
                foregroundColor: c.brandTerracottaInk,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: [
                  // Dark Animated Visual Stage Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1915),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        SpiralPourDiagram(
                          type: _selected,
                          isPlaying: _playing,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selected.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFFDF9),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _selected.caption,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: Color(0xFFBFB3A6),
                                ),
                              ),
                              const SizedBox(height: 10),
                              PocketPill(
                                label: _playing
                                    ? 'Jeda Animasi'
                                    : 'Putar Animasi',
                                icon: _playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                backgroundColor: c.brandTerracotta,
                                foregroundColor: const Color(0xFFFFFDF9),
                                onTap: () =>
                                    setState(() => _playing = !_playing),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3 Interactive Technique Cards
                  _TechniqueCard(
                    title: '1. Spiral Pelan (Merata)',
                    badge: 'Sedang · ~60 ml/10 dtk',
                    badgeBg: c.tintTerracotta,
                    badgeFg: c.brandTerracottaInk,
                    desc:
                        'Jaga aliran tetap stabil (~60 ml tiap 10 detik) dan tidak terlalu tinggi supaya ekstraksi paling rata dan jernih.',
                    selected: _selected == PourDemoType.spiral,
                    onTap: () => setState(() {
                      _selected = PourDemoType.spiral;
                      _playing = true;
                    }),
                  ),
                  const SizedBox(height: 10),
                  _TechniqueCard(
                    title: '2. Center / Osmotic Flow',
                    badge: 'Pelan · ~30 ml/10 dtk',
                    badgeBg: c.tintHoney,
                    badgeFg: c.brandHoney,
                    desc:
                        'Tuang tipis & pelan (~30 ml tiap 10 detik) tepat di pusat gundukan kopi, menjaga kubah tetap utuh untuk rasa manis & body penuh.',
                    selected: _selected == PourDemoType.centerOsmotic,
                    onTap: () => setState(() {
                      _selected = PourDemoType.centerOsmotic;
                      _playing = true;
                    }),
                  ),
                  const SizedBox(height: 10),
                  _TechniqueCard(
                    title: '3. Rao Spin (Goyang Ringan)',
                    badge: '1x putaran pelan',
                    badgeBg: c.tintSage,
                    badgeFg: c.brandSage,
                    desc:
                        'Putar dripper lembut 1x setelah tuangan terakhir agar ampas kopi datar sempurna tanpa jalur bocor (channeling).',
                    selected: _selected == PourDemoType.raoSpin,
                    onTap: () => setState(() {
                      _selected = PourDemoType.raoSpin;
                      _playing = true;
                    }),
                  ),
                  const SizedBox(height: 12),

                  PocketCard(
                    backgroundColor: c.tintHoney,
                    borderColor: Colors.transparent,
                    padding: const EdgeInsets.all(13),
                    child: Text(
                      'Tip penting: hindari menyiram langsung dinding kertas filter — air bisa lolos ke server tanpa mengekstrak kopi (bypass), bikin rasa jadi encer.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: c.brandTerracotta,
                    foregroundColor: c.textOnAccent,
                  ),
                  onPressed: () => context.go('/brew'),
                  icon: const Icon(Icons.local_cafe_rounded, size: 19),
                  label: const Text('Praktikkan di Brew'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechniqueCard extends StatelessWidget {
  const _TechniqueCard({
    required this.title,
    required this.badge,
    required this.badgeBg,
    required this.badgeFg,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String badge;
  final Color badgeBg;
  final Color badgeFg;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketCard(
      borderColor: selected ? badgeFg : c.borderSubtle,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PocketPill(
                label: badge,
                backgroundColor: badgeBg,
                foregroundColor: badgeFg,
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
