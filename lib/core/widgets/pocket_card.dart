import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../domain/models/enums.dart';
import '../motion/pocket_motion.dart';
import 'pocket_icons.dart';

/// Soft Oat / Espresso Dusk M3 ceramic card matching FigCraft v7:
/// Clean elevated `#FFFDF9` surface with subtle warm shadow and optional accent border.
class PocketCard extends StatelessWidget {
  const PocketCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.25,
    this.radius = 20,
    this.onTap,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final VoidCallback? onTap;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasExplicitBorder =
        borderColor != null && borderColor != Colors.transparent;
    final bg = backgroundColor ?? c.surfaceCard;
    final isSurfaceCard = bg == c.surfaceCard;

    final card = AnimatedContainer(
      duration: PocketCurves.normal,
      curve: PocketCurves.smoothOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: hasExplicitBorder
            ? Border.all(color: borderColor!, width: borderWidth)
            : (c.isDark && isSurfaceCard
                ? Border.all(color: c.borderSubtle, width: 1)
                : null),
        boxShadow: elevated && !c.isDark && isSurfaceCard
            ? [
                BoxShadow(
                  color: const Color(0xFF1F1915).withValues(alpha: 0.055),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return PocketTapScale(onTap: onTap, child: card);
  }
}

class PocketPill extends StatelessWidget {
  const PocketPill({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.icon,
    this.pocketIcon,
    this.iconSize,
    this.fontSize = 11.5,
    this.fontWeight = 600,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.height,
    this.radius = 999,
    this.onTap,
    this.isMono = false,
    this.elevated = false,
  });

  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final IconData? icon;
  final PocketIconType? pocketIcon;
  final double? iconSize;
  final double fontSize;
  final double fontWeight;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double radius;
  final VoidCallback? onTap;
  final bool isMono;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = backgroundColor ?? c.surfaceElevated;
    final fg = foregroundColor ?? c.textPrimary;
    final resolvedIconSize = iconSize ?? (fontSize + 2.5);

    final inner = AnimatedContainer(
      duration: PocketCurves.fast,
      curve: PocketCurves.smoothOut,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: elevated && !c.isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF1F1915).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (pocketIcon != null) ...[
            PocketIcon(pocketIcon!, size: resolvedIconSize, color: fg),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: resolvedIconSize, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: isMono
                    ? PocketTheme.mono(
                        size: fontSize,
                        weight: fontWeight >= 700
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: fg,
                        height: 1.15,
                      )
                    : PocketTheme.ui(
                        size: fontSize,
                        weight: fontWeight,
                        color: fg,
                        height: 1.15,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return inner;
    return PocketTapScale(onTap: onTap, pressedScale: 0.94, child: inner);
  }
}

class PocketSectionHeader extends StatelessWidget {
  const PocketSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PocketTheme.ui(
                size: 15.5,
                weight: 700,
                letterSpacing: -0.05,
                color: c.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            PocketTapScale(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
                child: Text(
                  actionLabel!,
                  style: PocketTheme.ui(
                    size: 12.5,
                    weight: 600,
                    color: c.brandTerracottaInk,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live g | ml | oz selector pill with smooth sliding white capsule thumb
/// matching FigCraft `M3/UnitPill` (`h=34`, `pad=3`, `r=999`).
class UnitPillSelector extends StatelessWidget {
  const UnitPillSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UnitMode value;
  final ValueChanged<UnitMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final idx = UnitMode.values.indexOf(value);
    final alignX = idx == 0 ? -1.0 : (idx == 1 ? 0.0 : 1.0);

    return Container(
      width: 108,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
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
                            color: const Color(0xFF1F1915)
                                .withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Row(
            children: UnitMode.values.map((u) {
              final active = u == value;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!active) {
                      HapticFeedback.selectionClick();
                      onChanged(u);
                    }
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: PocketCurves.fast,
                      style: PocketTheme.mono(
                        size: 11.5,
                        weight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? c.textPrimary : c.textTertiary,
                      ),
                      child: Text(u.label),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Live °C | °F selector pill with smooth sliding white capsule thumb
/// matching FigCraft `Temp Unit` (`80x34`, `pad=3`, `r=999`).
class TempUnitPillSelector extends StatelessWidget {
  const TempUnitPillSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TempUnit value;
  final ValueChanged<TempUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isRight = value == TempUnit.fahrenheit;

    return Container(
      width: 82,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: PocketCurves.gentleSpring,
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: c.surfaceCard,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: c.isDark
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF1F1915)
                                .withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            ),
          ),
          Row(
            children: TempUnit.values.map((t) {
              final active = t == value;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!active) {
                      HapticFeedback.selectionClick();
                      onChanged(t);
                    }
                  },
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: PocketCurves.fast,
                      style: PocketTheme.mono(
                        size: 11.5,
                        weight: active ? FontWeight.w700 : FontWeight.w600,
                        color: active ? c.textPrimary : c.textSecondary,
                      ),
                      child: Text(t.symbol),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Native Android ArrowLeft TopBar matching FigCraft v7 (`h=46`, back 22px, title 20px Bold).
class PocketTopBar extends StatelessWidget {
  const PocketTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 20, 6),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            if (onBack != null)
              PocketTapScale(
                onTap: onBack,
                pressedScale: 0.9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
                  child: PocketIcon(
                    PocketIconType.backArrow,
                    size: 22,
                    color: c.textPrimary,
                  ),
                ),
              )
            else
              const SizedBox(width: 8),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PocketTheme.ui(
                  size: 20,
                  weight: 700,
                  letterSpacing: -0.16,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Tactile pill CTA matching FigCraft v7's soft rounded pill buttons.
class PocketButton extends StatelessWidget {
  const PocketButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.pocketIcon,
    this.icon,
    this.iconSize = 16,
    this.height = 52,
    this.fontSize = 14.5,
    this.fontWeight = 600,
    this.shadowColor,
    this.borderColor,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final PocketIconType? pocketIcon;
  final IconData? icon;
  final double iconSize;
  final double height;
  final double fontSize;
  final double fontWeight;
  final Color? shadowColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return PocketTapScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      pressedScale: 0.972,
      child: AnimatedContainer(
        duration: PocketCurves.normal,
        curve: PocketCurves.smoothOut,
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1.2)
              : null,
          boxShadow: shadowColor != null
              ? [
                  BoxShadow(
                    color: shadowColor!,
                    blurRadius: 20,
                    spreadRadius: -2,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (pocketIcon != null) ...[
              PocketIcon(pocketIcon!, size: iconSize, color: foregroundColor),
              const SizedBox(width: 7),
            ] else if (icon != null) ...[
              Icon(icon, size: iconSize + 1, color: foregroundColor),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: PocketTheme.ui(
                    size: fontSize,
                    weight: fontWeight,
                    color: foregroundColor,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
