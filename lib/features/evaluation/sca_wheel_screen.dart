import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/canvas/cooling_curve_chart.dart';
import '../../core/widgets/canvas/sca_flavor_wheel.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';

/// Screen 10 · Panduan & Roda Rasa SCA (Complete 9-Category WCR Sensory Lexicon):
/// - Searchable across all 9 official SCA categories & Tier-2/Tier-3 notes
/// - Interactive 9-wedge blooming SCA Wheel + selected notes summary tray
/// - Grouped Tier-2 Subcategories with plain-Indonesian tasting hints
/// - Cooling Curve sweet-spot reference (55–65°C).
class ScaWheelScreen extends ConsumerStatefulWidget {
  const ScaWheelScreen({super.key, this.initialTags});

  final List<String>? initialTags;

  @override
  ConsumerState<ScaWheelScreen> createState() => _ScaWheelScreenState();
}

class _ScaWheelScreenState extends ConsumerState<ScaWheelScreen> {
  int _selectedCategory = 0;
  final Set<String> _picked = {};
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    final existing = widget.initialTags ??
        ref.read(pocketStoreProvider).pendingEval?.selectedTags;
    if (existing != null && existing.isNotEmpty) {
      _picked.addAll(existing);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleNote(String note) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_picked.contains(note)) {
        _picked.remove(note);
      } else {
        _picked.add(note);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final activeCat = scaFlavorCategories[_selectedCategory];
    final q = _query.trim().toLowerCase();

    // Cross-category live search results across all 9 official SCA categories!
    final searchMatches = q.isEmpty
        ? const <(String note, FlavorCategoryData cat, String subName)>[]
        : [
            for (final cat in scaFlavorCategories)
              for (final sub in cat.subcategories)
                for (final note in sub.notes)
                  if (note.toLowerCase().contains(q) ||
                      sub.name.toLowerCase().contains(q) ||
                      sub.indoHint.toLowerCase().contains(q) ||
                      cat.indoLabel.toLowerCase().contains(q))
                    (note, cat, sub.name),
          ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Roda Rasa SCA',
              onBack: () => context.pop(),
              trailing: PocketPill(
                label: '9 Kategori SCA',
                height: 26,
                fontSize: 10.5,
                backgroundColor: c.tintSage,
                foregroundColor: c.brandSage,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                children: [
                  // 1. Instant Search across all ~90 official SCA flavor notes
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
                      hintText: 'Cari rasa: peach, jasmine, cokelat, winey...',
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

                  // Selected Notes Summary Bar (removable chips)
                  AnimatedSize(
                    duration: PocketCurves.normal,
                    curve: PocketCurves.smoothOut,
                    child: _picked.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: PocketCard(
                              padding: const EdgeInsets.all(11),
                              radius: 16,
                              elevated: false,
                              backgroundColor: c.tintBerry,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Dipilih (${_picked.length} notes)',
                                        style: PocketTheme.ui(
                                          size: 11.5,
                                          weight: 800,
                                          color: c.brandBerry,
                                        ),
                                      ),
                                      PocketTapScale(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _picked.clear());
                                        },
                                        child: Text(
                                          'Bersihkan',
                                          style: PocketTheme.ui(
                                            size: 11,
                                            weight: 700,
                                            color: c.brandBerry,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: _picked.map((note) {
                                      return PocketPill(
                                        label: '$note ×',
                                        height: 28,
                                        fontSize: 11,
                                        backgroundColor: c.brandBerry,
                                        foregroundColor: c.textOnAccent,
                                        onTap: () => _toggleNote(note),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 11),

                  // Search Mode vs Full 9-Category Interactive Wheel Mode
                  if (q.isNotEmpty)
                    PocketCard(
                      padding: const EdgeInsets.all(15),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hasil Pencarian (${searchMatches.length})',
                            style: PocketTheme.ui(
                              size: 13,
                              weight: 800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (searchMatches.isEmpty)
                            Text(
                              'Tidak ditemukan di daftar SCA. Kamu tetap bisa tulis rasa bebas di catatan evaluasi.',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: searchMatches.map((m) {
                                final (note, cat, subName) = m;
                                final chosen = _picked.contains(note);
                                return PocketPill(
                                  label: chosen
                                      ? '$note ✓'
                                      : '$note · ${cat.label.split('/').first}',
                                  height: 32,
                                  fontSize: 11.5,
                                  backgroundColor: chosen
                                      ? cat.color
                                      : cat.color.withValues(alpha: 0.13),
                                  foregroundColor:
                                      chosen ? Colors.white : cat.color,
                                  onTap: () => _toggleNote(note),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    )
                  else ...[
                    // 2. All 9 Official SCA Category Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            List.generate(scaFlavorCategories.length, (i) {
                          final cat = scaFlavorCategories[i];
                          final active = i == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: PocketPill(
                              label: cat.label,
                              height: 32,
                              fontSize: 11.5,
                              backgroundColor:
                                  active ? cat.color : c.surfaceCard,
                              foregroundColor:
                                  active ? Colors.white : c.textSecondary,
                              borderColor:
                                  active ? Colors.transparent : c.borderSubtle,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = i);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. Interactive 9-Category SCA Sunburst Wheel + Grouped Tier-2 Subcategories
                    PocketCard(
                      padding: const EdgeInsets.all(15),
                      radius: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Ketuk bagian roda untuk eksplor 9 kategori rasa resmi SCA',
                              textAlign: TextAlign.center,
                              style: PocketTheme.ui(
                                size: 11,
                                weight: 500,
                                color: c.textTertiary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: ScaFlavorWheel(
                              selectedCategoryIndex: _selectedCategory,
                              selectedCount: _picked.length,
                              onSelectCategory: (idx) =>
                                  setState(() => _selectedCategory = idx),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Active Category Banner + Tier-2 Grouped Subcategories
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: PocketCurves.smoothOut,
                            child: Column(
                              key: ValueKey(activeCat.id),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color:
                                        activeCat.color.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: activeCat.color
                                          .withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${activeCat.label} · ${activeCat.indoLabel}',
                                        style: PocketTheme.ui(
                                          size: 13.5,
                                          weight: 800,
                                          color: activeCat.color,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        activeCat.description,
                                        style: PocketTheme.ui(
                                          size: 11.5,
                                          weight: 500,
                                          height: 1.4,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Tier-2 Subcategories & Tier-3 Specific Notes
                                ...activeCat.subcategories.map((sub) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: activeCat.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Expanded(
                                              child: Text(
                                                '${sub.name} — ${sub.indoHint}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: PocketTheme.ui(
                                                  size: 11.5,
                                                  weight: 700,
                                                  color: c.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 7),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: sub.notes.map((note) {
                                            final chosen =
                                                _picked.contains(note);
                                            return PocketPill(
                                              label: chosen ? '$note ✓' : note,
                                              height: 31,
                                              fontSize: 11.5,
                                              backgroundColor: chosen
                                                  ? activeCat.color
                                                  : c.surfaceElevated,
                                              foregroundColor: chosen
                                                  ? Colors.white
                                                  : c.textPrimary,
                                              borderColor: chosen
                                                  ? Colors.transparent
                                                  : c.borderSubtle,
                                              onTap: () => _toggleNote(note),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // 4. Cooling Curve Reference (Sweet Spot 55–65°C)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    elevated: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Kapan Enaknya Dicicipi?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PocketTheme.ui(
                                  size: 13,
                                  weight: 800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PocketPill(
                              label: 'Sweet Spot 55–65°C',
                              backgroundColor: c.tintSage,
                              foregroundColor: c.brandSage,
                              fontSize: 10.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const RepaintBoundary(child: CoolingCurveChart()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: PocketButton(
                label: _picked.isEmpty
                    ? 'Kembali ke Evaluasi'
                    : 'Terapkan ${_picked.length} Notes ke Evaluasi',
                pocketIcon: PocketIconType.check,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 52,
                onTap: () {
                  final list = _picked.toList();
                  ref
                      .read(pocketStoreProvider.notifier)
                      .setPendingEvaluationTags(list);
                  context.pop(list);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
