import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../motion/pocket_motion.dart';
import 'pocket_icons.dart';

class PocketDockItem {
  const PocketDockItem({
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final PocketIconType icon;
  final Color Function(PocketColors c) accentColor;
}

/// Pocket Brew v7 signature Expanding-Pill Floating Bottom Dock (`M3/BottomDock`):
/// Exact 64dp capsule, subtle `#E4DBCF` border in both light & dark, terracotta glow on Seduh,
/// smooth pixel-interpolated width expansion with custom FigCraft 19px stroke icons.
class PocketFloatingDock extends StatelessWidget {
  const PocketFloatingDock({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static final List<PocketDockItem> items = [
    PocketDockItem(
      label: 'Beranda',
      icon: PocketIconType.home,
      accentColor: (c) => c.brandEspresso,
    ),
    PocketDockItem(
      label: 'Beans',
      icon: PocketIconType.bean,
      accentColor: (c) => c.brandEspresso,
    ),
    PocketDockItem(
      label: 'Brew',
      icon: PocketIconType.v60,
      accentColor: (c) => c.brandTerracotta,
    ),
    PocketDockItem(
      label: 'Log',
      icon: PocketIconType.log,
      accentColor: (c) => c.brandEspresso,
    ),
    PocketDockItem(
      label: 'Alat',
      icon: PocketIconType.burrGear,
      accentColor: (c) => c.brandEspresso,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: c.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F1915)
                    .withValues(alpha: c.isDark ? 0.45 : 0.10),
                blurRadius: 28,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final activeFactor = currentIndex == 0 ? 0.30 : 0.275;
              final activeW = (totalW * activeFactor).clamp(92.0, 118.0);
              final idleW = (totalW - activeW) / (items.length - 1);

              return Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;
                  final isSeduh = i == 2;
                  final activeBg = item.accentColor(c);
                  final activeFg = c.textOnAccent;
                  final inactiveColor = isSeduh && !selected
                      ? c.brandTerracottaInk
                      : c.textTertiary;

                  return PocketTapScale(
                    pressedScale: 0.94,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: PocketCurves.gentleSpring,
                      width: selected ? activeW : idleW,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: selected ? activeBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: selected && isSeduh && !c.isDark
                            ? [
                                BoxShadow(
                                  color: c.brandTerracotta
                                      .withValues(alpha: 0.24),
                                  blurRadius: 16,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 190),
                        switchInCurve: PocketCurves.smoothOut,
                        switchOutCurve: Curves.easeIn,
                        child: selected
                            ? Padding(
                                key: ValueKey('sel_$i'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PocketIcon(
                                      item.icon,
                                      size: 19,
                                      color: activeFg,
                                      strokeWidth: 1.95,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.fade,
                                        softWrap: false,
                                        style: PocketTheme.ui(
                                          size: 12.5,
                                          weight: 700,
                                          height: 1.2,
                                          color: activeFg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                key: ValueKey('idle_$i'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PocketIcon(
                                    item.icon,
                                    size: 19,
                                    color: inactiveColor,
                                    strokeWidth: 1.75,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    softWrap: false,
                                    style: PocketTheme.ui(
                                      size: 9.5,
                                      weight: isSeduh ? 600 : 500,
                                      height: 1.2,
                                      color: inactiveColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
