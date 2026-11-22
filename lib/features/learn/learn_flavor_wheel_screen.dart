import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/canvas/sca_flavor_wheel.dart';
import '../../core/widgets/pocket_card.dart';

/// Screen 21 · Belajar Roda Rasa Kopi (Complete 9-Category SCA Flavor Wheel Explorer):
/// Designed specifically for comfortable mobile reading in Soft Oat & Espresso Dusk:
/// - Instant flavor search across all 9 official SCA categories & 85+ sensory notes
/// - Interactive sunburst wheel + tactile category selector pills
/// - Clean subcategory breakdown with Indonesian cupping hints & beginner reading guide.
class LearnFlavorWheelScreen extends StatefulWidget {
  const LearnFlavorWheelScreen({super.key});

  @override
  State<LearnFlavorWheelScreen> createState() => _LearnFlavorWheelScreenState();
}

class _LearnFlavorWheelScreenState extends State<LearnFlavorWheelScreen> {
  int _selectedIdx = 0;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _totalNotesCount =>
      scaFlavorCategories.fold<int>(0, (sum, cat) => sum + cat.notes.length);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final activeCat = scaFlavorCategories[_selectedIdx];
    final q = _query.trim().toLowerCase();

    final searchMatches = q.isEmpty
        ? const <({
            FlavorCategoryData category,
            FlavorSubcategoryData sub,
            List<String> notes,
          })>[]
        : [
            for (final cat in scaFlavorCategories)
              for (final sub in cat.subcategories)
                () {
                  final catMatches = cat.label.toLowerCase().contains(q) ||
                      cat.indoLabel.toLowerCase().contains(q) ||
                      sub.name.toLowerCase().contains(q) ||
                      sub.indoHint.toLowerCase().contains(q);
                  final matchedNotes = catMatches
                      ? sub.notes
                      : sub.notes
                          .where((n) => n.toLowerCase().contains(q))
                          .toList();
                  return (category: cat, sub: sub, notes: matchedNotes);
                }(),
          ].where((e) => e.notes.isNotEmpty).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Roda Rasa Kopi',
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: '9 Kategori · $_totalNotesCount+ Rasa',
                backgroundColor: c.tintBerry,
                foregroundColor: c.brandBerry,
                fontSize: 10.5,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                children: [
                  // Intro & Live Search
                  Text(
                    'Standar SCA Coffee Taster’s Flavor Wheel untuk mengenali puluhan karakter rasa di dunia kopi — mulai dari buah, bunga, manis, hingga rempah.',
                    style: PocketTheme.ui(
                      size: 12.8,
                      weight: 500,
                      height: 1.45,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: PocketTheme.ui(
                      size: 13.5,
                      weight: 500,
                      color: c.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: c.surfaceCard,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 19,
                        color: c.textTertiary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: c.textTertiary,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      hintText: 'Cari rasa: Peach, Jasmine, Cokelat, Asam...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: c.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: c.brandTerracotta,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  if (q.isNotEmpty) ...[
                    // Search Results View
                    if (searchMatches.isEmpty)
                      PocketCard(
                        padding: const EdgeInsets.all(20),
                        radius: 20,
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 30,
                              color: c.textTertiary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rasa "$_query" belum ditemukan di katalog',
                              textAlign: TextAlign.center,
                              style: PocketTheme.ui(
                                size: 13.5,
                                weight: 700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba kata kunci umum seperti Berry, Citrus, Floral, Caramel, atau Chocolate.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        'Hasil Pencarian (${searchMatches.fold<int>(0, (s, e) => s + e.notes.length)} notes)',
                        style: PocketTheme.ui(
                          size: 13,
                          weight: 800,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...searchMatches.map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PocketCard(
                            padding: const EdgeInsets.all(14),
                            radius: 18,
                            elevated: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: m.category.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${m.category.label} · ${m.sub.name}',
                                        style: PocketTheme.ui(
                                          size: 13.5,
                                          weight: 800,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.sub.indoHint,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 9),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: m.notes.map((note) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: m.category.color
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        note,
                                        style: PocketTheme.ui(
                                          size: 12,
                                          weight: 700,
                                          color: c.isDark
                                              ? c.textPrimary
                                              : m.category.color,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ] else ...[
                    // 1. Interactive SCA Flavor Wheel Showcase Card
                    PocketCard(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                      radius: 22,
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wheelSize = (constraints.maxWidth - 20)
                                  .clamp(210.0, 268.0);
                              return Center(
                                child: ScaFlavorWheel(
                                  size: wheelSize,
                                  selectedCategoryIndex: _selectedIdx,
                                  selectedCount: activeCat.notes.length,
                                  onSelectCategory: (idx) =>
                                      setState(() => _selectedIdx = idx),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Ketuk bagian roda atau pilih kategori di bawah untuk melihat rincian rasa',
                            textAlign: TextAlign.center,
                            style: PocketTheme.ui(
                              size: 11.2,
                              weight: 600,
                              color: c.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // All 9 Category Selector Pills (clean Wrap, zero horizontal clipping!)
                          Wrap(
                            spacing: 6,
                            runSpacing: 7,
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              scaFlavorCategories.length,
                              (i) {
                                final cat = scaFlavorCategories[i];
                                final sel = i == _selectedIdx;
                                return PocketTapScale(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedIdx = i);
                                  },
                                  child: AnimatedContainer(
                                    duration: PocketCurves.fast,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? cat.color
                                          : c.surfaceElevated,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: sel
                                            ? cat.color
                                            : c.borderSubtle,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: sel
                                                ? Colors.white
                                                : cat.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat.label,
                                          style: PocketTheme.ui(
                                            size: 11.5,
                                            weight: 700,
                                            color: sel
                                                ? Colors.white
                                                : c.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Selected Category Deep-Dive Card
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: PocketCurves.smoothOut,
                      child: PocketCard(
                        key: ValueKey(activeCat.id),
                        padding: const EdgeInsets.all(16),
                        radius: 22,
                        borderColor: activeCat.color.withValues(alpha: 0.42),
                        borderWidth: 1.3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: activeCat.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${activeCat.label} · ${activeCat.indoLabel}',
                                        style: PocketTheme.ui(
                                          size: 16.5,
                                          weight: 800,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        activeCat.description,
                                        style: PocketTheme.ui(
                                          size: 12.6,
                                          weight: 500,
                                          height: 1.45,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Clean Subcategory Blocks
                            ...List.generate(activeCat.subcategories.length,
                                (si) {
                              final sub = activeCat.subcategories[si];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      si < activeCat.subcategories.length - 1
                                          ? 10
                                          : 0,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: c.isDark
                                        ? c.surfaceElevated
                                        : c.surfaceCanvas,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: c.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sub.name,
                                        style: PocketTheme.ui(
                                          size: 13.2,
                                          weight: 800,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sub.indoHint,
                                        style: PocketTheme.ui(
                                          size: 11.5,
                                          weight: 500,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: sub.notes.map((note) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: activeCat.color.withValues(
                                                alpha: c.isDark ? 0.24 : 0.13,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              note,
                                              style: PocketTheme.ui(
                                                size: 12,
                                                weight: 700,
                                                color: c.isDark
                                                    ? c.textPrimary
                                                    : activeCat.color,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. How to Read the SCA Wheel (Practical Beginner Guide)
                    PocketCard(
                      backgroundColor: c.tintSage,
                      elevated: false,
                      radius: 20,
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cara Membaca Roda Rasa Kopi',
                            style: PocketTheme.ui(
                              size: 14,
                              weight: 800,
                              color: c.brandSage,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ReadingTipRow(
                            step: '1',
                            text:
                                'Mulai dari lingkaran dalam (umum): apakah cangkirmu dominan Buah (Fruity), Manis (Sweet), atau Kacang/Cokelat?',
                          ),
                          const SizedBox(height: 7),
                          _ReadingTipRow(
                            step: '2',
                            text:
                                'Bergerak ke cincin tengah (sub-kategori): jika terasa buah, apakah arahnya ke Berry, Citrus, atau buah manis seperti Peach?',
                          ),
                          const SizedBox(height: 7),
                          _ReadingTipRow(
                            step: '3',
                            text:
                                'Cicipi lagi saat kopi mendingin ke 55–65°C — manis alami & notes buah biasanya baru keluar penuh saat tidak terlalu panas!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingTipRow extends StatelessWidget {
  const _ReadingTipRow({required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 21,
          height: 21,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: PocketTheme.mono(
              size: 11,
              weight: FontWeight.w800,
              color: c.brandSage,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: PocketTheme.ui(
              size: 12.4,
              weight: 500,
              height: 1.44,
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
