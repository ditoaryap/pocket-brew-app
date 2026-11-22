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

/// Screen 16 · Alat Seduh (Complete Redesign):
/// - Clean Setup Aktif Saya hero card (Grinder, Dripper, Filter — vector icons only, no distracting photos)
/// - Explicit "Simpan Setup Aktif" confirmation button inside Setup Aktif Saya
/// - Scalable 3-tab Koleksi Alat (`Grinder` | `Dripper` | `Filter`) where built-in & custom items can be deleted (min 1 kept).
class GearScreen extends ConsumerStatefulWidget {
  const GearScreen({super.key});

  @override
  ConsumerState<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends ConsumerState<GearScreen> {
  static const int _pageSize = 10;

  int _categoryTab = 0; // 0 = Grinder, 1 = Dripper, 2 = Filter
  bool _onlyCustom = false;
  bool _hasSetupChanges = false;
  String _query = '';
  int _visibleCount = _pageSize;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 108),
          children: [
            // Top Header
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
                  onTap: () =>
                      context.push('/gear/add-custom?type=$_categoryQueryParam'),
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
            const SizedBox(height: 14),

            // 1. HERO CARD: Setup Aktif Saya (Clean single active setup — NO confusing Meja Rumah/Kantor/Travel!)
            PocketCard(
              padding: const EdgeInsets.all(15),
              radius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Setup Aktif Saya',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PocketTheme.ui(
                            size: 13.5,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PocketPill(
                        label: 'Dipakai saat Brew',
                        height: 22,
                        fontSize: 10,
                        backgroundColor: c.tintSage,
                        foregroundColor: c.brandSage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  _ActiveSetupSlot(
                    label: 'Grinder',
                    title: activeGrinder.fullName,
                    spec:
                        '${activeGrinder.umPerClick.round()} μm/klik · V60: ${activeGrinder.v60HotMin}–${activeGrinder.v60HotMax} klik',
                    isCustom: !activeGrinder.isOfficial,
                    highlighted: _categoryTab == 0,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c.tintTerracotta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: PocketIcon(
                        PocketIconType.burrGear,
                        size: 20,
                        color: c.brandTerracottaInk,
                      ),
                    ),
                    onTap: () => _selectCategory(0),
                  ),
                  const SizedBox(height: 8),
                  _ActiveSetupSlot(
                    label: 'Dripper',
                    title: activeDripper.name,
                    spec:
                        '${activeDripper.geometry} · ${activeDripper.material}',
                    isCustom: !activeDripper.isOfficial,
                    highlighted: _categoryTab == 1,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: PocketIcon(
                        PocketIconType.v60,
                        size: 20,
                        color: c.textPrimary,
                      ),
                    ),
                    onTap: () => _selectCategory(1),
                  ),
                  const SizedBox(height: 8),
                  _ActiveSetupSlot(
                    label: 'Kertas Filter',
                    title: activeFilter.name,
                    spec:
                        'Aliran ${activeFilter.speed} · ${activeFilter.grindOffsetUm == 0 ? 'Standar' : '${activeFilter.grindOffsetUm > 0 ? '+' : ''}${activeFilter.grindOffsetUm.round()} μm'}',
                    isCustom: !activeFilter.isOfficial,
                    highlighted: _categoryTab == 2,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c.tintIce,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: PocketIcon(
                        PocketIconType.filterPaper,
                        size: 20,
                        color: c.brandIce,
                      ),
                    ),
                    onTap: () => _selectCategory(2),
                  ),
                  const SizedBox(height: 12),
                  PocketButton(
                    label: _hasSetupChanges
                        ? 'Simpan Setup Aktif'
                        : 'Simpan Setup Aktif ✓',
                    pocketIcon: PocketIconType.check,
                    iconSize: 16,
                    height: 44,
                    fontSize: 12.8,
                    backgroundColor:
                        _hasSetupChanges ? c.brandTerracotta : c.brandEspresso,
                    foregroundColor: c.textOnAccent,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _hasSetupChanges = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Setup aktif disimpan: ${activeGrinder.model} · ${activeDripper.name} · ${activeFilter.name} ✓',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. KOLEKSI ALAT (Natural merged official + personal gear browser!)
            PocketSectionHeader(
              title: 'Koleksi Alat Seduh',
              actionLabel: '+ Tambah $_categoryLabel Sendiri',
              onAction: () =>
                  context.push('/gear/add-custom?type=$_categoryQueryParam'),
            ),
            const SizedBox(height: 9),

            // Smooth Sliding 3-Tab Category Selector
            _GearCategoryTabs(
              selected: _categoryTab,
              grinderCount: state.grinders.length,
              dripperCount: state.drippers.length,
              filterCount: state.filters.length,
              onSelect: _selectCategory,
            ),
            const SizedBox(height: 10),

            // Search + optional "Alat Saya" quick filter when user has added own tools
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
                    backgroundColor: _onlyCustom ? c.brandSage : c.surfaceCard,
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
            const SizedBox(height: 10),

            // Animated Category List Body
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: PocketCurves.smoothOut,
              child: KeyedSubtree(
                key: ValueKey('gear_list_${_categoryTab}_${_onlyCustom}_$_query'),
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
    );
  }

  Widget _buildGrinderList(
    PocketColors c,
    PocketAppState state,
    PocketStoreNotifier notifier,
  ) {
    final q = _query.trim().toLowerCase();
    // Put Custom grinders first so user immediately sees their custom gear!
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
          isCustom: !g.isOfficial,
          onTap: () {
            HapticFeedback.selectionClick();
            if (!active) {
              setState(() => _hasSetupChanges = true);
            }
            notifier.setActiveGrinder(g.id);
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
          isCustom: !d.isOfficial,
          onTap: () {
            HapticFeedback.selectionClick();
            if (!active) {
              setState(() => _hasSetupChanges = true);
            }
            notifier.setActiveDripper(d.id);
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
          isCustom: !f.isOfficial,
          onTap: () {
            HapticFeedback.selectionClick();
            if (!active) {
              setState(() => _hasSetupChanges = true);
            }
            notifier.setActiveFilter(f.id);
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

class _ActiveSetupSlot extends StatelessWidget {
  const _ActiveSetupSlot({
    required this.label,
    required this.title,
    required this.spec,
    required this.leading,
    required this.isCustom,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final String title;
  final String spec;
  final Widget leading;
  final bool isCustom;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: PocketCurves.fast,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlighted
              ? (c.isDark ? c.surfaceElevated : c.surfaceCanvas)
              : (c.isDark ? c.surfaceCanvas : c.surfaceElevated),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: highlighted
                ? c.brandTerracotta.withValues(alpha: 0.5)
                : c.borderSubtle,
            width: highlighted ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: PocketTheme.ui(
                          size: 10.5,
                          weight: 700,
                          color: c.textTertiary,
                        ),
                      ),
                      if (isCustom) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: c.tintSage,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Alat Saya',
                            style: PocketTheme.ui(
                              size: 9,
                              weight: 700,
                              color: c.brandSage,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    title,
                    style: PocketTheme.ui(
                      size: 13.5,
                      weight: 800,
                      height: 1.25,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    spec,
                    style: PocketTheme.mono(
                      size: 10.5,
                      weight: FontWeight.w500,
                      height: 1.3,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Ganti',
              style: PocketTheme.ui(
                size: 11.5,
                weight: 700,
                color: c.brandTerracottaInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GearCategoryTabs extends StatelessWidget {
  const _GearCategoryTabs({
    required this.selected,
    required this.grinderCount,
    required this.dripperCount,
    required this.filterCount,
    required this.onSelect,
  });

  final int selected;
  final int grinderCount;
  final int dripperCount;
  final int filterCount;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final alignX = selected == 0 ? -1.0 : (selected == 1 ? 0.0 : 1.0);
    final items = [
      'Grinder ($grinderCount)',
      'Dripper ($dripperCount)',
      'Filter ($filterCount)',
    ];

    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: PocketCurves.gentleSpring,
            alignment: Alignment(alignX, 0),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: c.isDark
                      ? null
                      : [
                          BoxShadow(
                            color:
                                const Color(0xFF1F1915).withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(items.length, (i) {
              final act = i == selected;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(i),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          items[i],
                          maxLines: 1,
                          style: PocketTheme.ui(
                            size: 12,
                            weight: act ? 700 : 600,
                            color: act ? c.textPrimary : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
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
    required this.isCustom,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final String note;
  final bool active;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketCard(
      backgroundColor: active ? c.tintTerracotta : c.surfaceCard,
      borderColor: active ? c.brandTerracotta : c.borderSubtle,
      borderWidth: active ? 1.4 : 1.0,
      elevated: false,
      radius: 17,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: PocketTheme.ui(
                          size: 13.5,
                          weight: 800,
                          height: 1.25,
                          color:
                              active ? c.brandTerracottaInk : c.textPrimary,
                        ),
                      ),
                    ),
                    if (isCustom) ...[
                      const SizedBox(width: 6),
                      PocketPill(
                        label: 'Alat Saya',
                        height: 20,
                        fontSize: 9.5,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        backgroundColor: c.tintSage,
                        foregroundColor: c.brandSage,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: PocketTheme.mono(
                    size: 10.8,
                    weight: FontWeight.w600,
                    height: 1.3,
                    color: c.textSecondary,
                  ),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: PocketTheme.ui(
                      size: 11,
                      weight: 500,
                      height: 1.3,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onEdit != null || onDelete != null) ...[
            if (onEdit != null)
              PocketTapScale(
                onTap: onEdit,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: PocketIcon(
                    PocketIconType.edit,
                    size: 14,
                    color: c.textPrimary,
                  ),
                ),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 5),
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
            const SizedBox(width: 6),
          ],
          AnimatedContainer(
            duration: PocketCurves.fast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: active ? c.brandTerracotta : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? c.brandTerracotta : c.borderStrong,
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: active
                ? PocketIcon(
                    PocketIconType.check,
                    size: 13,
                    color: c.textOnAccent,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
