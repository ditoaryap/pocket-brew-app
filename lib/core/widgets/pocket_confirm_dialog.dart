import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';

/// Universal confirmation modal for all destructive & sensitive actions across Pocket Brew.
/// Consistent in both Soft Oat (Light) and Espresso Dusk (Dark) themes, and responsive on narrow devices.
Future<bool> showPocketDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
  String cancelLabel = 'Batal',
  bool isDestructive = true,
}) async {
  HapticFeedback.mediumImpact();
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final c = ctx.colors;
      final accent = isDestructive ? c.statusError : c.brandTerracotta;
      final confirmTextColor = isDestructive ? Colors.white : c.textOnAccent;

      return AlertDialog(
        backgroundColor: c.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.borderSubtle),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 8),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: Icon(
                isDestructive
                    ? Icons.delete_outline_rounded
                    : Icons.warning_amber_rounded,
                size: 19,
                color: accent,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: PocketTheme.ui(
                  size: 16.5,
                  weight: 800,
                  height: 1.25,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: PocketTheme.ui(
            size: 13.2,
            weight: 500,
            height: 1.48,
            color: c.textSecondary,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.borderStrong),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    cancelLabel,
                    style: PocketTheme.ui(
                      size: 13,
                      weight: 700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    backgroundColor: accent,
                    foregroundColor: confirmTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(ctx).pop(true);
                  },
                  child: Text(
                    confirmLabel,
                    style: PocketTheme.ui(
                      size: 13,
                      weight: 700,
                      color: confirmTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
  return result ?? false;
}
