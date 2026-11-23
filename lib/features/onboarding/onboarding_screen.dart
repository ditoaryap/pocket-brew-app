import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../core/widgets/pocket_logo.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/models/enums.dart';

/// 1:1 FigCraft v7 Screen 01 · Onboarding Setup Awal:
/// - Circular wordmark header + Lewati dulu
/// - 3-segment smooth progress bar
/// - 3 elevated Soft Oat cards (Satuan Air & Suhu, Grinder + Preset Resmi ✓, Dripper Favorit)
/// - Crisp r=11 chip grids + inline centered offline trust note + wet-hand espresso CTA.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nameCtrl;
  late UnitMode _unit;
  late TempUnit _temp;
  late String _grinderId;
  late String _dripperId;
  int _activeStep = 1; // 1 initially (matches FigCraft), advances smoothly on taps

  static const _featuredGrinderPresets = <(String id, String label)>[
    ('comandante-c40-mk4', 'Comandante C40'),
    ('1zpresso-jx', '1Zpresso JX'),
    ('1zpresso-k-ultra', '1Zpresso K-Ultra'),
    ('timemore-c3s', 'Timemore C3S / S3'),
    ('kingrinder-k6', 'KINGrinder K6'),
  ];

  static const _featuredDripperPresets = <(String id, String label)>[
    ('hario-v60-02-plastic', 'Hario V60-02'),
    ('hario-switch-200', 'Hario Switch'),
    ('kalita-wave-185', 'Kalita 185'),
    ('origami-m', 'Origami M'),
  ];

  @override
  void initState() {
    super.initState();
    final store = ref.read(pocketStoreProvider);
    _nameCtrl = TextEditingController(text: store.prefs.userName);
    _unit = store.prefs.unitMode;
    _temp = store.prefs.tempUnit;
    _grinderId = store.activeProfile.grinderId;
    _dripperId = store.activeProfile.dripperId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAddCustomGear(String type) async {
    final beforeGrinder = ref.read(pocketStoreProvider).activeProfile.grinderId;
    final beforeDripper = ref.read(pocketStoreProvider).activeProfile.dripperId;
    await context.push('/gear/add-custom?type=$type');
    if (!mounted) return;
    final after = ref.read(pocketStoreProvider).activeProfile;
    setState(() {
      if (type == 'grinder' && after.grinderId != beforeGrinder) {
        _grinderId = after.grinderId;
        if (_activeStep < 2) _activeStep = 2;
      } else if (type == 'dripper' && after.dripperId != beforeDripper) {
        _dripperId = after.dripperId;
        _activeStep = 3;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final store = ref.watch(pocketStoreProvider);

    final customGrinders = store.grinders.where((g) => !g.isOfficial).toList();
    final customDrippers = store.drippers.where((d) => !d.isOfficial).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  // Top Bar: Pocket Brew Wordmark + Lewati dulu
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: PocketBrewWordmark(markSize: 30, fontSize: 19),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PocketTapScale(
                          onTap: () {
                            ref
                                .read(pocketStoreProvider.notifier)
                                .skipOnboarding();
                            context.go('/home');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Text(
                              'Lewati dulu',
                              maxLines: 1,
                              style: PocketTheme.ui(
                                size: 12.5,
                                weight: 600,
                                color: c.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),

                  // 3-Segment Progress Bar (exact FigCraft [2495]: h=5, gap=6, r=999)
                  Row(
                    children: List.generate(3, (index) {
                      final active = index < _activeStep;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: PocketCurves.normal,
                          curve: PocketCurves.smoothOut,
                          height: 5,
                          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: active ? c.brandTerracotta : c.surfaceSubtle,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 13),

                  // Headline
                  PocketEntrance(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siapkan meja seduhmu',
                          style: PocketTheme.ui(
                            size: 24,
                            weight: 700,
                            letterSpacing: -0.29,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cukup 1 menit agar hitungan klik grinder dan satuan air langsung cocok dengan alat di rumah.',
                          style: PocketTheme.ui(
                            size: 13,
                            weight: 400,
                            height: 1.46,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),

                  // Personal Name Card (Optional — zero hardcoded name!)
                  PocketEntrance(
                    delayMs: 25,
                    child: PocketCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                                  'Nama Panggilan',
                                  style: PocketTheme.ui(
                                    size: 13.5,
                                    weight: 700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PocketPill(
                                label: 'Opsional',
                                backgroundColor: c.surfaceElevated,
                                foregroundColor: c.textTertiary,
                                fontSize: 10,
                                fontWeight: 600,
                                height: 22,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          TextField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            maxLength: 24,
                            buildCounter: (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) =>
                                null,
                            onChanged: (_) => setState(() {}),
                            style: PocketTheme.ui(
                              size: 13.5,
                              weight: 600,
                              color: c.textPrimary,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: c.surfaceElevated,
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 19,
                                color: c.textTertiary,
                              ),
                              suffixIcon: _nameCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 17,
                                        color: c.textTertiary,
                                      ),
                                      onPressed: () {
                                        _nameCtrl.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              hintText: 'Contoh: Raka, Nadya, Dito...',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
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
                          const SizedBox(height: 7),
                          Text(
                            _nameCtrl.text.trim().isEmpty
                                ? 'Dipakai untuk sapaan di Beranda — bisa diubah kapan saja di Pengaturan.'
                                : 'Sapaan di Beranda: "Mau seduh apa, ${_nameCtrl.text.trim()}?"',
                            style: PocketTheme.ui(
                              size: 11.4,
                              weight: 500,
                              color: _nameCtrl.text.trim().isEmpty
                                  ? c.textTertiary
                                  : c.brandSage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  // Step 1 Card · Satuan Air & Suhu
                  PocketEntrance(
                    delayMs: 45,
                    child: PocketCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      radius: 20,
                      elevated: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. Satuan Air & Suhu',
                            style: PocketTheme.ui(
                              size: 13.5,
                              weight: 700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              UnitPillSelector(
                                value: _unit,
                                onChanged: (v) => setState(() => _unit = v),
                              ),
                              TempUnitPillSelector(
                                value: _temp,
                                onChanged: (v) => setState(() => _temp = v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Bisa ganti g / ml / oz kapan saja langsung di menu Brew.',
                            style: PocketTheme.ui(
                              size: 11.5,
                              weight: 400,
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  // Step 2 Card · Grinder yang Kamu Pakai
                  PocketEntrance(
                    delayMs: 90,
                    child: PocketCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  '2. Grinder yang Kamu Pakai',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PocketTheme.ui(
                                    size: 13.5,
                                    weight: 700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              PocketPill(
                                label: 'Preset Resmi ✓',
                                backgroundColor: c.tintSage,
                                foregroundColor: c.brandSage,
                                fontSize: 10,
                                fontWeight: 600,
                                height: 22,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 7,
                            children: [
                              ..._featuredGrinderPresets.map((item) {
                                final (id, label) = item;
                                return _OnboardingChip(
                                  label: label,
                                  height: 34,
                                  selected: _grinderId == id,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _grinderId = id;
                                      if (_activeStep < 2) _activeStep = 2;
                                    });
                                  },
                                );
                              }),
                              ...customGrinders.map(
                                (g) => _OnboardingChip(
                                  label: g.fullName,
                                  height: 34,
                                  selected: _grinderId == g.id,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _grinderId = g.id;
                                      if (_activeStep < 2) _activeStep = 2;
                                    });
                                  },
                                ),
                              ),
                              _OnboardingChip(
                                label: '+ Grinder Custom',
                                height: 34,
                                selected: false,
                                backgroundColor: c.tintTerracotta,
                                foregroundColor: c.brandTerracottaInk,
                                onTap: () => _openAddCustomGear('grinder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  // Step 3 Card · Dripper Favorit
                  PocketEntrance(
                    delayMs: 135,
                    child: PocketCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      radius: 20,
                      elevated: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '3. Dripper Favorit',
                            style: PocketTheme.ui(
                              size: 13.5,
                              weight: 700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 6,
                            runSpacing: 7,
                            children: [
                              ..._featuredDripperPresets.map((item) {
                                final (id, label) = item;
                                return _OnboardingChip(
                                  label: label,
                                  height: 33,
                                  selected: _dripperId == id,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _dripperId = id;
                                      _activeStep = 3;
                                    });
                                  },
                                );
                              }),
                              ...customDrippers.map(
                                (d) => _OnboardingChip(
                                  label: d.name,
                                  height: 33,
                                  selected: _dripperId == d.id,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _dripperId = d.id;
                                      _activeStep = 3;
                                    });
                                  },
                                ),
                              ),
                              _OnboardingChip(
                                label: '+ Custom',
                                height: 33,
                                selected: false,
                                onTap: () => _openAddCustomGear('dripper'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Inline Centered Offline Trust Note (exact FigCraft [2549], NO card box!)
                  PocketEntrance(
                    delayMs: 170,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PocketIcon(
                          PocketIconType.check,
                          size: 14,
                          color: c.brandSage,
                          strokeWidth: 2.1,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Aman dipakai tanpa internet & tanpa perlu akun',
                            textAlign: TextAlign.center,
                            style: PocketTheme.ui(
                              size: 11.5,
                              weight: 500,
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pinned Wet-Hand Primary CTA (`54dp` espresso pill with check icon)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: PocketButton(
                label: 'Selesai & Masuk Beranda',
                pocketIcon: PocketIconType.check,
                iconSize: 18,
                height: 54,
                fontSize: 14.5,
                fontWeight: 600,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                shadowColor: c.isDark
                    ? null
                    : const Color(0xFF1F1915).withValues(alpha: 0.14),
                onTap: () {
                  ref.read(pocketStoreProvider.notifier).completeOnboarding(
                        unit: _unit,
                        tempUnit: _temp,
                        grinderId: _grinderId,
                        dripperId: _dripperId,
                        userName: _nameCtrl.text,
                      );
                  context.go('/home');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingChip extends StatelessWidget {
  const _OnboardingChip({
    required this.label,
    required this.height,
    required this.selected,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final double height;
  final bool selected;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = selected
        ? c.brandEspresso
        : (backgroundColor ?? c.surfaceElevated);
    final fg = selected
        ? c.textOnAccent
        : (foregroundColor ?? c.textSecondary);

    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedContainer(
        duration: PocketCurves.fast,
        curve: PocketCurves.smoothOut,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              style: PocketTheme.ui(
                size: 11.2,
                weight: 600,
                color: fg,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
