import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/engines/brew_recipe_scaler.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screens 11 & 12 · Riwayat Seduhan (Complete Redesign):
/// - Clean search bar + clear tactile `Filter` button opening a Bottom Sheet modal!
/// - Active filter summary tags with 1-tap Reset (zero cluttered chip rows)
/// - Crisp modern brew history cards (Bean, Mode badge, ★ Rating, metrics strip, notes & memo)
/// - Lazy pagination (`Muat Lebih Banyak` per 15 items) with RepaintBoundary per card.
class BrewLogScreen extends ConsumerStatefulWidget {
  const BrewLogScreen({super.key});

  @override
  ConsumerState<BrewLogScreen> createState() => _BrewLogScreenState();
}

class _BrewLogScreenState extends ConsumerState<BrewLogScreen> {
  static const int _pageSize = 15;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _modeFilter = 'all'; // all | hot | iced
  String? _beanFilter;
  double _minRating = 0.0; // 0 | 4.0 | 4.5 | 5.0
  bool _sortByHighestRating = false;
  int _visibleCount = _pageSize;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int n = 0;
    if (_modeFilter != 'all') n++;
    if (_beanFilter != null) n++;
    if (_minRating > 0) n++;
    if (_sortByHighestRating) n++;
    return n;
  }

  bool get _hasAnyFilter => _activeFilterCount > 0 || _query.trim().isNotEmpty;

  void _resetFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _searchCtrl.clear();
      _query = '';
      _modeFilter = 'all';
      _beanFilter = null;
      _minRating = 0.0;
      _sortByHighestRating = false;
      _visibleCount = _pageSize;
    });
  }

  String _formatDateShort(DateTime dt) {
    final now = DateTime.now();
    final diffDays = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diffDays == 0) return 'Hari ini';
    if (diffDays == 1) return 'Kemarin';
    if (diffDays < 7) return '$diffDays hr lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  List<BrewLog> _applyFilters(
    List<BrewLog> allLogs, {
    required String query,
    required String modeFilter,
    required String? beanFilter,
    required double minRating,
    required bool sortByHighest,
  }) {
    final q = query.trim().toLowerCase();
    final list = allLogs.where((l) {
      final matchMode = switch (modeFilter) {
        'hot' => l.mode == BrewMode.hot,
        'iced' => l.mode == BrewMode.iced,
        _ => true,
      };
      if (!matchMode) return false;
      if (beanFilter != null && l.beanName != beanFilter) return false;
      if (minRating > 0 && l.rating < minRating) return false;
      if (q.isNotEmpty) {
        final inBean = l.beanName.toLowerCase().contains(q);
        final inRecipe = l.recipeName.toLowerCase().contains(q);
        final inNotes = l.notes.toLowerCase().contains(q);
        final inTags = l.tastingTags.any((t) => t.toLowerCase().contains(q));
        if (!inBean && !inRecipe && !inNotes && !inTags) return false;
      }
      return true;
    }).toList();

    if (sortByHighest) {
      list.sort((a, b) {
        final cmp = b.rating.compareTo(a.rating);
        return cmp != 0 ? cmp : b.brewedAt.compareTo(a.brewedAt);
      });
    } else {
      list.sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
    }
    return list;
  }

  void _openFilterSheet(
    BuildContext context,
    List<BrewLog> allLogs,
    List<String> beanNames,
  ) {
    HapticFeedback.selectionClick();
    String draftMode = _modeFilter;
    String? draftBean = _beanFilter;
    double draftRating = _minRating;
    bool draftSort = _sortByHighestRating;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final c = ctx.colors;
            final previewCount = _applyFilters(
              allLogs,
              query: _query,
              modeFilter: draftMode,
              beanFilter: draftBean,
              minRating: draftRating,
              sortByHighest: draftSort,
            ).length;

            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.82,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: c.borderStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Filter Riwayat Seduhan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PocketTheme.ui(
                              size: 16.5,
                              weight: 800,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PocketTapScale(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModal(() {
                              draftMode = 'all';
                              draftBean = null;
                              draftRating = 0.0;
                              draftSort = false;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: PocketTheme.ui(
                              size: 12.5,
                              weight: 700,
                              color: c.brandTerracottaInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Metode Seduh
                            _SheetLabel('Metode Seduh'),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                ('all', 'Semua', c.brandEspresso),
                                ('hot', 'Hot V60', c.brandTerracotta),
                                ('iced', 'Japanese Iced', c.brandIce),
                              ].map((m) {
                                final (id, label, activeColor) = m;
                                final sel = draftMode == id;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: id == 'iced' ? 0 : 7,
                                    ),
                                    child: PocketPill(
                                      label: label,
                                      height: 36,
                                      fontSize: 12,
                                      backgroundColor: sel
                                          ? activeColor
                                          : c.surfaceElevated,
                                      foregroundColor: sel
                                          ? c.textOnAccent
                                          : c.textPrimary,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setModal(() => draftMode = id);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 15),

                            // 2. Biji Kopi
                            if (beanNames.isNotEmpty) ...[
                              _SheetLabel('Biji Kopi'),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  PocketPill(
                                    label: 'Semua Biji',
                                    height: 32,
                                    fontSize: 11.5,
                                    backgroundColor: draftBean == null
                                        ? c.brandEspresso
                                        : c.surfaceElevated,
                                    foregroundColor: draftBean == null
                                        ? c.textOnAccent
                                        : c.textPrimary,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModal(() => draftBean = null);
                                    },
                                  ),
                                  ...beanNames.map((bn) {
                                    final sel = draftBean == bn;
                                    return PocketPill(
                                      label: bn,
                                      height: 32,
                                      fontSize: 11.5,
                                      backgroundColor: sel
                                          ? c.brandSage
                                          : c.surfaceElevated,
                                      foregroundColor: sel
                                          ? c.textOnAccent
                                          : c.textPrimary,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setModal(() => draftBean = bn);
                                      },
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 15),
                            ],

                            // 3. Rating Minimum
                            _SheetLabel('Rating Minimum'),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                (0.0, 'Semua'),
                                (4.0, '★ 4.0+'),
                                (4.5, '★ 4.5+'),
                                (5.0, '★ 5.0'),
                              ].map((r) {
                                final (val, lbl) = r;
                                final sel = (draftRating - val).abs() < 0.05;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: val == 5.0 ? 0 : 6,
                                    ),
                                    child: PocketPill(
                                      label: lbl,
                                      height: 34,
                                      fontSize: 11.5,
                                      isMono: val > 0,
                                      backgroundColor: sel
                                          ? c.brandHoney
                                          : c.surfaceElevated,
                                      foregroundColor: sel
                                          ? c.textOnAccent
                                          : c.textPrimary,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setModal(() => draftRating = val);
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 15),

                            // 4. Urutkan
                            _SheetLabel('Urutkan'),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child: PocketPill(
                                    label: 'Terbaru',
                                    height: 36,
                                    fontSize: 12,
                                    backgroundColor: !draftSort
                                        ? c.brandEspresso
                                        : c.surfaceElevated,
                                    foregroundColor: !draftSort
                                        ? c.textOnAccent
                                        : c.textPrimary,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModal(() => draftSort = false);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: PocketPill(
                                    label: 'Rating Tertinggi',
                                    height: 36,
                                    fontSize: 12,
                                    backgroundColor: draftSort
                                        ? c.brandEspresso
                                        : c.surfaceElevated,
                                    foregroundColor: draftSort
                                        ? c.textOnAccent
                                        : c.textPrimary,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setModal(() => draftSort = true);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    PocketButton(
                      label: 'Terapkan · Lihat $previewCount Seduhan',
                      pocketIcon: PocketIconType.check,
                      height: 48,
                      backgroundColor: c.brandEspresso,
                      foregroundColor: c.textOnAccent,
                      onTap: () {
                        setState(() {
                          _modeFilter = draftMode;
                          _beanFilter = draftBean;
                          _minRating = draftRating;
                          _sortByHighestRating = draftSort;
                          _visibleCount = _pageSize;
                        });
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final unit = state.prefs.unitMode;

    final beanNames = <String>[];
    for (final l in state.logs) {
      if (!beanNames.contains(l.beanName)) {
        beanNames.add(l.beanName);
      }
    }

    final filtered = _applyFilters(
      state.logs,
      query: _query,
      modeFilter: _modeFilter,
      beanFilter: _beanFilter,
      minRating: _minRating,
      sortByHighest: _sortByHighestRating,
    );

    final visibleLogs = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > visibleLogs.length;
    final filterCount = _activeFilterCount;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
          children: [
            // Clean Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Riwayat Seduhan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                PocketPill(
                  label: '${state.logs.length} seduhan',
                  backgroundColor: c.surfaceElevated,
                  foregroundColor: c.textSecondary,
                  isMono: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Unified Search + Prominent `Filter` Modal Trigger Button!
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {
                      _query = v;
                      _visibleCount = _pageSize;
                    }),
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
                                setState(() {
                                  _query = '';
                                  _visibleCount = _pageSize;
                                });
                              },
                            )
                          : null,
                      hintText: 'Cari biji, resep, notes...',
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
                ),
                const SizedBox(width: 9),
                PocketTapScale(
                  onTap: () => _openFilterSheet(context, state.logs, beanNames),
                  child: AnimatedContainer(
                    duration: PocketCurves.fast,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color:
                          filterCount > 0 ? c.brandTerracotta : c.brandEspresso,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PocketIcon(
                          PocketIconType.sliders,
                          size: 15,
                          color: c.textOnAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filterCount > 0 ? 'Filter ($filterCount)' : 'Filter',
                          style: PocketTheme.ui(
                            size: 12.5,
                            weight: 700,
                            color: c.textOnAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Active Filter Summary Strip (Only visible when user applied a filter!)
            AnimatedSize(
              duration: PocketCurves.normal,
              curve: PocketCurves.smoothOut,
              child: _hasAnyFilter
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_modeFilter != 'all')
                                    _ActiveTag(
                                      label: _modeFilter == 'hot'
                                          ? 'Hot V60'
                                          : 'Japanese Iced',
                                      color: _modeFilter == 'hot'
                                          ? c.brandTerracottaInk
                                          : c.brandIce,
                                      bg: _modeFilter == 'hot'
                                          ? c.tintTerracotta
                                          : c.tintIce,
                                    ),
                                  if (_beanFilter != null)
                                    _ActiveTag(
                                      label: _beanFilter!,
                                      color: c.brandSage,
                                      bg: c.tintSage,
                                    ),
                                  if (_minRating > 0)
                                    _ActiveTag(
                                      label:
                                          '★ ${_minRating.toStringAsFixed(1)}+',
                                      color: c.brandHoney,
                                      bg: c.tintHoney,
                                    ),
                                  if (_sortByHighestRating)
                                    _ActiveTag(
                                      label: '★ Tertinggi',
                                      color: c.textPrimary,
                                      bg: c.surfaceElevated,
                                    ),
                                  if (_activeFilterCount == 0 &&
                                      _query.trim().isNotEmpty)
                                    Text(
                                      'Ditemukan ${filtered.length} seduhan',
                                      style: PocketTheme.mono(
                                        size: 11,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PocketTapScale(
                            onTap: _resetFilters,
                            child: Text(
                              'Reset',
                              style: PocketTheme.ui(
                                size: 12,
                                weight: 700,
                                color: c.brandTerracottaInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 13),

            // Empty State or Modern Brew Cards
            if (filtered.isEmpty)
              PocketCard(
                padding: const EdgeInsets.all(24),
                radius: 22,
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: c.tintTerracotta,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: PocketIcon(
                        PocketIconType.v60,
                        size: 24,
                        color: c.brandTerracottaInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hasAnyFilter
                          ? 'Tidak ada seduhan yang cocok'
                          : 'Belum ada riwayat seduhan',
                      style: PocketTheme.ui(
                        size: 15.5,
                        weight: 800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hasAnyFilter
                          ? 'Coba ubah pilihan di modal Filter atau hapus pencarian.'
                          : 'Mulai seduh lewat menu Brew agar klik, waktu turun, dan catatan rasamu tersimpan otomatis.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 200,
                      child: PocketButton(
                        label: _hasAnyFilter ? 'Reset Filter' : 'Buka Brew',
                        height: 44,
                        backgroundColor: c.brandTerracotta,
                        foregroundColor: c.textOnAccent,
                        onTap: _hasAnyFilter
                            ? _resetFilters
                            : () => context.go('/brew'),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              ...visibleLogs.map((log) {
                final isIced = log.mode == BrewMode.iced;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: RepaintBoundary(
                    child: PocketCard(
                      padding: const EdgeInsets.all(14),
                      radius: 20,
                      onTap: () => context.push('/log/${log.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: Bean Name + Mode badge + ★ Rating + Delete
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log.beanName,
                                      style: PocketTheme.ui(
                                        size: 14.5,
                                        weight: 800,
                                        height: 1.25,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isIced
                                                ? c.tintIce
                                                : c.tintTerracotta,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            log.mode.shortBadge,
                                            style: PocketTheme.ui(
                                              size: 10,
                                              weight: 700,
                                              color: isIced
                                                  ? c.brandIce
                                                  : c.brandTerracottaInk,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${_formatDateShort(log.brewedAt)} · ${log.recipeName.split('·').last.trim()}',
                                          style: PocketTheme.ui(
                                            size: 11,
                                            weight: 500,
                                            color: c.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.tintHoney,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PocketIcon(
                                          PocketIconType.starFilled,
                                          size: 12,
                                          color: c.brandHoney,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          log.rating.toStringAsFixed(1),
                                          style: PocketTheme.mono(
                                            size: 12.5,
                                            weight: FontWeight.w800,
                                            color: c.brandHoney,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  PocketTapScale(
                                    onTap: () async {
                                      final ok = await showPocketDeleteDialog(
                                        context,
                                        title: 'Hapus Riwayat Seduhan?',
                                        message:
                                            'Catatan seduhan "${log.beanName}" ini akan dihapus permanen.',
                                        confirmLabel: 'Hapus',
                                      );
                                      if (!ok) return;
                                      ref
                                          .read(pocketStoreProvider.notifier)
                                          .deleteLog(log.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Catatan seduhan dihapus.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: c.statusError
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 15,
                                        color: c.statusError,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Clean 4-column compact metrics strip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: c.isDark
                                  ? c.surfaceElevated
                                  : c.surfaceCanvas,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _MiniMetric('${log.clickSetting} klik'),
                                _MiniMetric(
                                  BrewRecipeScaler.formatTemp(
                                    log.tempC,
                                    state.prefs.tempUnit,
                                  ),
                                ),
                                _MiniMetric(
                                  BrewRecipeScaler.formatShortDuration(
                                    log.actualDrawdownSec,
                                  ),
                                ),
                                _MiniMetric(
                                  BrewRecipeScaler.formatLiquidCompact(
                                    log.totalLiquidG,
                                    unit,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tasting notes pills + optional short memo
                          if (log.tastingTags.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 5,
                              runSpacing: 5,
                              children: log.tastingTags.take(4).map((tag) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.tintBerry,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: PocketTheme.ui(
                                      size: 10.5,
                                      weight: 600,
                                      color: c.brandBerry,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (log.notes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '"${log.notes}"',
                              style: PocketTheme.ui(
                                size: 11.8,
                                weight: 500,
                                height: 1.38,
                                color: c.textSecondary,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Pagination footer
              if (hasMore || filtered.length > _pageSize)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: [
                      Text(
                        'Menampilkan ${visibleLogs.length} dari ${filtered.length} seduhan',
                        style: PocketTheme.mono(
                          size: 11,
                          color: c.textTertiary,
                        ),
                      ),
                      if (hasMore) ...[
                        const SizedBox(height: 8),
                        PocketButton(
                          label: 'Muat Lebih Banyak (+$_pageSize)',
                          height: 44,
                          fontSize: 13,
                          backgroundColor: c.surfaceElevated,
                          foregroundColor: c.textPrimary,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _visibleCount += _pageSize);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: PocketTheme.ui(
        size: 12,
        weight: 800,
        color: context.colors.textSecondary,
      ),
    );
  }
}

class _ActiveTag extends StatelessWidget {
  const _ActiveTag({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: PocketTheme.ui(size: 11, weight: 700, color: color),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: PocketTheme.mono(
            size: 11.5,
            weight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
