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
import '../../domain/models/models.dart';

/// Screen 16 · Alat Seduh (Sticky Workbench Redesign — Zero Confusion):
/// - Pinned compact "Setup Aktif Saya" 3-slot strip (Grinder | Dripper | Filter)
///   that ALWAYS stays visible at the top while scrolling the collection below.
/// - Auto-saves immediately on tap (ZERO confusing "Simpan Setup Aktif" button/checklist!).
/// - Tapping any top slot switches category smoothly & scrolls the collection to top.
class GearScreen extends ConsumerStatefulWidget {
  const GearScreen({super.key});

  @override
  ConsumerState<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends ConsumerState<GearScreen> {
  static const int _pageSize = 10;

  int _categoryTab = 0; // 0 = Grinder, 1 = Dripper, 2 = Filter
  bool _onlyCustom = false;
  String _query = '';
  int _visibleCount = _pageSize;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _categoryQueryParam => switch (_categoryTab) {
        1 => 'dripper',
        2 => 'filter',
        _ => 'grinder',
      };

  String get _categoryLabel => switch (_categoryTab) {
        1 => 'Dripper',
        2 => 'Filter',
        _ => 'Grinder',
      };

  void _selectCategory(int next) {
    if (next == _categoryTab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _categoryTab = next;
      _onlyCustom = false;
      _visibleCount = _pageSize;
    });
    if (_scrollCtrl.hasClients && _scrollCtrl.offset > 0) {
      _scrollCtrl.animateTo(
        0,
        duration: PocketCurves.normal,
        curve: PocketCurves.smoothOut,
      );
    }
  }

  void _showActivatedToast(String category, String name) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1700),
        content: Text('$category aktif: $name ✓'),
      ),
    );
  }

  Future<void> _confirmDelete({
    required String name,
    required VoidCallback onConfirm,
  }) async {
    final ok = await showPocketDeleteDialog(
      context,
      title: 'Hapus Alat Ini?',
      message:
          'Hapus "$name" dari koleksi alatmu? Jika sedang dipakai, setup akan otomatis beralih ke alat lain yang tersisa.',
      confirmLabel: 'Hapus Alat',
    );
    if (ok) {
      onConfirm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name dihapus dari koleksi.')),
        );
      }
    }
  }

  String _shortGearLabel(String full) {
    final clean = full.trim();
    if (clean.length <= 18) return clean;
    final words = clean.split(' ');
    if (words.length >= 2) {
      final candidate = '${words[0]} ${words[1]}';
      return candidate.length <= 20 ? candidate : words[0];
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);

    final activeGrinder = state.activeGrinder;
    final activeDripper = state.activeDripper;
    final activeFilter = state.activeFilter;

    final customGrinderCount =
        state.grinders.where((g) => !g.isOfficial).length;
    final customDripperCount =
        state.drippers.where((d) => !d.isOfficial).length;
    final customFilterCount = state.filters.where((f) => !f.isOfficial).length;
    final activeCatCustomCount = switch (_categoryTab) {
      1 => customDripperCount,
      2 => customFilterCount,
      _ => customGrinderCount,
    };
    final activeCatTotalCount = switch (_categoryTab) {
      1 => state.drippers.length,
      2 => state.filters.length,
      _ => state.grinders.length,
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PINNED TOP WORKBENCH HEADER (Always visible — never lost on scroll!)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                color: c.surfaceCanvas,
                border: Border(
                  bottom: BorderSide(color: c.borderSubtle, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Title Row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Alat Seduh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PocketPill(
                        label: 'Tambah',
                        pocketIcon: PocketIconType.plus,
                        iconSize: 14,
                        height: 36,
                        fontSize: 12,
                        fontWeight: 700,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: c.tintTerracotta,
                        foregroundColor: c.brandTerracottaInk,
                        onTap: () => context
                            .push('/gear/add-custom?type=$_categoryQueryParam'),
                      ),
                      const SizedBox(width: 7),
                      PocketTapScale(
                        onTap: () => context.push('/settings'),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: c.surfaceCard,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.borderSubtle),
                          ),
                          alignment: Alignment.center,
                          child: PocketIcon(
                            PocketIconType.sliders,
                            size: 17,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  // 2. Compact Label + Auto-Save Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Setup Aktif Saya',
                          style: PocketTheme.ui(
                            size: 12.2,
                            weight: 800,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.brandSage,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Otomatis tersimpan',
                            style: PocketTheme.ui(
                              size: 11,
                              weight: 700,
                              color: c.brandSage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 3. Pinned 3-Slot Interactive Setup Selector (Acts as both live status & category tabs!)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PinnedGearSlot(
                          category: 'Grinder',
                          activeName: activeGrinder.model,
                          count: state.grinders.length,
                          icon: PocketIconType.burrGear,
                          accent: c.brandTerracotta,
                          accentInk: c.brandTerracottaInk,
                          tint: c.tintTerracotta,
                          selected: _categoryTab == 0,
                          onTap: () => _selectCategory(0),
                        ),
                        const SizedBox(width: 8),
                        _PinnedGearSlot(
                          category: 'Dripper',
                          activeName: _shortGearLabel(activeDripper.name),
                          count: state.drippers.length,
                          icon: PocketIconType.v60,
                          accent: c.brandSage,
                          accentInk: c.brandSage,
                          tint: c.tintSage,
                          selected: _categoryTab == 1,
                          onTap: () => _selectCategory(1),
                        ),
                        const SizedBox(width: 8),
                        _PinnedGearSlot(
                          category: 'Filter',
                          activeName: _shortGearLabel(activeFilter.name),
                          count: state.filters.length,
                          icon: PocketIconType.filterPaper,
                          accent: c.brandIce,
                          accentInk: c.brandIce,
                          tint: c.tintIce,
                          selected: _categoryTab == 2,
                          onTap: () => _selectCategory(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Compact Search + optional "Alat Saya" filter
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
                            size: 13,
                            weight: 500,
                            color: c.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: c.surfaceCard,
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 18,
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
                            hintText: 'Cari $_categoryLabel...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(color: c.borderSubtle),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: BorderSide(
                                color: c.brandTerracotta,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (activeCatCustomCount > 0) ...[
                        const SizedBox(width: 8),
                        PocketPill(
                          label: _onlyCustom
                              ? 'Alat Saya ($activeCatCustomCount) ✓'
                              : 'Alat Saya ($activeCatCustomCount)',
                          height: 40,
                          fontSize: 11.5,
                          fontWeight: 700,
                          padding: const EdgeInsets.symmetric(horizontal: 11),
                          backgroundColor:
                              _onlyCustom ? c.brandSage : c.surfaceCard,
                          foregroundColor:
                              _onlyCustom ? c.textOnAccent : c.textSecondary,
                          borderColor:
                              _onlyCustom ? Colors.transparent : c.borderSubtle,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _onlyCustom = !_onlyCustom;
                              _visibleCount = _pageSize;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // SCROLLABLE COLLECTION LIST BELOW PINNED WORKBENCH
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 112),
                children: [
                  PocketSectionHeader(
                    title: 'Koleksi Alat Seduh',
                    actionLabel: '$_categoryLabel ($activeCatTotalCount)',
                    onAction: () => context
                        .push('/gear/add-custom?type=$_categoryQueryParam'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ketuk salah satu $_categoryLabel di bawah untuk langsung memakainya.',
                    style: PocketTheme.ui(
                      size: 11.8,
                      weight: 500,
                      color: c.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: PocketCurves.smoothOut,
                    child: KeyedSubtree(
                      key: ValueKey(
                        'gear_list_${_categoryTab}_${_onlyCustom}_$_query',
                      ),
                      child: switch (_categoryTab) {
                        0 => _buildGrinderList(c, state, notifier),
                        1 => _buildDripperList(c, state, notifier),
                        _ => _buildFilterList(c, state, notifier),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrinderList(
    PocketColors c,
    PocketAppState state,
    PocketStoreNotifier notifier,
  ) {
    final q = _query.trim().toLowerCase();
    final sorted = [
      ...state.grinders.where((g) => !g.isOfficial),
      ...state.grinders.where((g) => g.isOfficial),
    ].where((g) {
      if (_onlyCustom && g.isOfficial) return false;
      if (q.isEmpty) return true;
      return g.fullName.toLowerCase().contains(q) ||
          g.burrSpec.toLowerCase().contains(q);
    }).toList();

    return _buildPaginatedList<GrinderSpec>(
      c: c,
      items: sorted,
      emptyText: _onlyCustom
          ? 'Belum ada grinder tambahan. Yuk tambahkan grinder milikmu sendiri!'
          : 'Grinder tidak ditemukan.',
      itemBuilder: (g) {
        final active = g.id == state.activeGrinder.id;
        return _GearCollectionCard(
          title: g.fullName,
          subtitle:
              '${g.umPerClick.round()} μm/klik · V60: ${g.v60HotMin}–${g.v60HotMax} klik',
          note: g.zeroPointNote,
          active: active,
          accentColor: c.brandTerracotta,
          accentInk: c.brandTerracottaInk,
          accentTint: c.tintTerracotta,
          isCustom: !g.isOfficial,
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.setActiveGrinder(g.id);
            if (!active) _showActivatedToast('Grinder', g.model);
          },
          onEdit: g.isOfficial
              ? null
              : () =>
                  context.push('/gear/add-custom?type=grinder&editId=${g.id}'),
          onDelete: state.grinders.length <= 1
              ? null
              : () => _confirmDelete(
                    name: g.fullName,
                    onConfirm: () => notifier.deleteCustomGrinder(g.id),
                  ),
        );
      },
    );
  }

  Widget _buildDripperList(
    PocketColors c,
    PocketAppState state,
    PocketStoreNotifier notifier,
  ) {
    final q = _query.trim().toLowerCase();
    final sorted = [
      ...state.drippers.where((d) => !d.isOfficial),
      ...state.drippers.where((d) => d.isOfficial),
    ].where((d) {
      if (_onlyCustom && d.isOfficial) return false;
      if (q.isEmpty) return true;
      return d.name.toLowerCase().contains(q) ||
          d.geometry.toLowerCase().contains(q) ||
          d.material.toLowerCase().contains(q);
    }).toList();

    return _buildPaginatedList<DripperSpec>(
      c: c,
      items: sorted,
      emptyText: _onlyCustom
          ? 'Belum ada dripper tambahan. Tambah dripper favoritmu di sini!'
          : 'Dripper tidak ditemukan.',
      itemBuilder: (d) {
        final active = d.id == state.activeDripper.id;
        return _GearCollectionCard(
          title: d.name,
          subtitle: '${d.geometry} · ${d.material} · ${d.capacityG}',
          note: d.flowNote,
          active: active,
          accentColor: c.brandSage,
          accentInk: c.brandSage,
          accentTint: c.tintSage,
          isCustom: !d.isOfficial,
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.setActiveDripper(d.id);
            if (!active) _showActivatedToast('Dripper', d.name);
          },
          onEdit: d.isOfficial
              ? null
              : () =>
                  context.push('/gear/add-custom?type=dripper&editId=${d.id}'),
          onDelete: state.drippers.length <= 1
              ? null
              : () => _confirmDelete(
                    name: d.name,
                    onConfirm: () => notifier.deleteCustomDripper(d.id),
                  ),
        );
      },
    );
  }

  Widget _buildFilterList(
    PocketColors c,
    PocketAppState state,
    PocketStoreNotifier notifier,
  ) {
    final q = _query.trim().toLowerCase();
    final sorted = [
      ...state.filters.where((f) => !f.isOfficial),
      ...state.filters.where((f) => f.isOfficial),
    ].where((f) {
      if (_onlyCustom && f.isOfficial) return false;
      if (q.isEmpty) return true;
      return f.name.toLowerCase().contains(q) ||
          f.speed.toLowerCase().contains(q) ||
          f.note.toLowerCase().contains(q);
    }).toList();

    return _buildPaginatedList<FilterSpec>(
      c: c,
      items: sorted,
      emptyText: _onlyCustom
          ? 'Belum ada kertas filter tambahan. Tambah kertas filter harianmu!'
          : 'Kertas filter tidak ditemukan.',
      itemBuilder: (f) {
        final active = f.id == state.activeFilter.id;
        return _GearCollectionCard(
          title: f.name,
          subtitle:
              'Aliran ${f.speed} · ${f.grindOffsetUm == 0 ? 'Standar' : '${f.grindOffsetUm > 0 ? '+' : ''}${f.grindOffsetUm.round()} μm'}',
          note: f.note,
          active: active,
          accentColor: c.brandIce,
          accentInk: c.brandIce,
          accentTint: c.tintIce,
          isCustom: !f.isOfficial,
          onTap: () {
            HapticFeedback.selectionClick();
            notifier.setActiveFilter(f.id);
            if (!active) _showActivatedToast('Filter', f.name);
          },
          onEdit: f.isOfficial
              ? null
              : () =>
                  context.push('/gear/add-custom?type=filter&editId=${f.id}'),
          onDelete: state.filters.length <= 1
              ? null
              : () => _confirmDelete(
                    name: f.name,
                    onConfirm: () => notifier.deleteCustomFilter(f.id),
                  ),
        );
      },
    );
  }

  Widget _buildPaginatedList<T>({
    required PocketColors c,
    required List<T> items,
    required String emptyText,
    required Widget Function(T item) itemBuilder,
  }) {
    if (items.isEmpty) {
      return PocketCard(
        padding: const EdgeInsets.all(20),
        radius: 18,
        elevated: false,
        child: Column(
          children: [
            Text(
              emptyText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: PocketButton(
                label: 'Tambah $_categoryLabel Sendiri',
                pocketIcon: PocketIconType.plus,
                height: 44,
                fontSize: 12.5,
                backgroundColor: c.brandTerracotta,
                foregroundColor: c.textOnAccent,
                onTap: () =>
                    context.push('/gear/add-custom?type=$_categoryQueryParam'),
              ),
            ),
          ],
        ),
      );
    }

    final visible = items.take(_visibleCount).toList();
    final hasMore = items.length > visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...visible.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: RepaintBoundary(child: itemBuilder(item)),
          ),
        ),
        if (hasMore || items.length > _pageSize)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Column(
              children: [
                Text(
                  'Menampilkan ${visible.length} dari ${items.length} $_categoryLabel',
                  style: PocketTheme.mono(size: 11, color: c.textTertiary),
                ),
                if (hasMore) ...[
                  const SizedBox(height: 8),
                  PocketButton(
                    label: 'Muat Lebih Banyak (+$_pageSize)',
                    height: 42,
                    fontSize: 12.5,
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
        const SizedBox(height: 4),
        PocketButton(
          label: 'Tambah $_categoryLabel Sendiri',
          pocketIcon: PocketIconType.plus,
          height: 46,
          fontSize: 13,
          backgroundColor: c.surfaceCard,
          foregroundColor: c.brandTerracottaInk,
          borderColor: c.brandTerracotta.withValues(alpha: 0.4),
          onTap: () =>
              context.push('/gear/add-custom?type=$_categoryQueryParam'),
        ),
      ],
    );
  }
}

/// Interactive pinned top slot showing live active tool + category selector.
class _PinnedGearSlot extends StatelessWidget {
  const _PinnedGearSlot({
    required this.category,
    required this.activeName,
    required this.count,
    required this.icon,
    required this.accent,
    required this.accentInk,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final String activeName;
  final int count;
  final PocketIconType icon;
  final Color accent;
  final Color accentInk;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: PocketTapScale(
        onTap: onTap,
        pressedScale: 0.96,
        child: AnimatedContainer(
          duration: PocketCurves.fast,
          curve: PocketCurves.smoothOut,
          padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
          decoration: BoxDecoration(
            color: selected ? tint : c.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : c.borderSubtle,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : (c.isDark ? c.surfaceElevated : c.surfaceCanvas),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: PocketIcon(
                      icon,
                      size: 13.5,
                      color: selected ? c.textOnAccent : accentInk,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: PocketTheme.mono(
                      size: 10.5,
                      weight: FontWeight.w700,
                      color: selected ? accentInk : c.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PocketTheme.ui(
                  size: 10.5,
                  weight: 700,
                  color: selected ? accentInk : c.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  key: ValueKey(activeName),
                  width: double.infinity,
                  child: Text(
                    activeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PocketTheme.ui(
                      size: 11.8,
                      weight: 800,
                      height: 1.2,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GearCollectionCard extends StatelessWidget {
  const _GearCollectionCard({
    required this.title,
    required this.subtitle,
    required this.note,
    required this.active,
    required this.accentColor,
    required this.accentInk,
    required this.accentTint,
    required this.isCustom,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final String note;
  final bool active;
  final Color accentColor;
  final Color accentInk;
  final Color accentTint;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketCard(
      backgroundColor: active ? accentTint : c.surfaceCard,
      borderColor: active ? accentColor : c.borderSubtle,
      borderWidth: active ? 1.45 : 1.0,
      elevated: false,
      radius: 18,
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: PocketTheme.ui(
                            size: 14,
                            weight: 800,
                            height: 1.25,
                            color: active ? accentInk : c.textPrimary,
                          ),
                        ),
                        if (isCustom)
                          PocketPill(
                            label: 'Alat Saya',
                            height: 21,
                            fontSize: 9.8,
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            backgroundColor: c.tintSage,
                            foregroundColor: c.brandSage,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: PocketTheme.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (active)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Dipakai',
                    style: PocketTheme.ui(
                      size: 10.8,
                      weight: 800,
                      color: c.textOnAccent,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Pakai',
                    style: PocketTheme.ui(
                      size: 10.8,
                      weight: 700,
                      color: c.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (note.isNotEmpty || onEdit != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: note.isNotEmpty
                      ? Text(
                          note,
                          style: PocketTheme.ui(
                            size: 11.4,
                            weight: 500,
                            height: 1.35,
                            color: c.textTertiary,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  PocketTapScale(
                    onTap: onEdit,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.borderSubtle),
                      ),
                      alignment: Alignment.center,
                      child: PocketIcon(
                        PocketIconType.edit,
                        size: 14,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  PocketTapScale(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c.statusError.withValues(alpha: 0.12),
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
              ],
            ),
          ],
        ],
      ),
    );
  }
}
