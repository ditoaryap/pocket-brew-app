import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/pocket_version.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/audio/brew_audio_cue.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_confirm_dialog.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/models/enums.dart';

/// Screen 18 · Pengaturan & Preferensi:
/// Human-friendly Indonesian (ZERO technical jargon), live Unit & Temp toggle,
/// customizable Bean Resting Days, Timer cues, Theme switcher, local Backup/Restore,
/// and an explicit sticky "Simpan Pengaturan" CTA button for clear save confirmation.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasChanges = false;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: ref.read(pocketStoreProvider).prefs.userName,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  String _buildDeletedSummaryText(PocketAppState state) {
    final parts = <String>[];
    if (state.deletedGrinderIds.isNotEmpty) {
      parts.add('${state.deletedGrinderIds.length} Grinder');
    }
    if (state.deletedDripperIds.isNotEmpty) {
      parts.add('${state.deletedDripperIds.length} Dripper');
    }
    if (state.deletedFilterIds.isNotEmpty) {
      parts.add('${state.deletedFilterIds.length} Filter');
    }
    if (state.deletedRecipeIds.isNotEmpty) {
      parts.add('${state.deletedRecipeIds.length} Resep bawaan');
    }
    return 'Akan dipulihkan: ${parts.join(' · ')}. Data custom & catatanmu tetap aman.';
  }

  String _buildDeletedDetailBulletList(PocketAppState state) {
    final lines = <String>[];
    if (state.deletedGrinderIds.isNotEmpty) {
      lines.add(
        '• ${state.deletedGrinderIds.length} Grinder bawaan yang sebelumnya dihapus',
      );
    }
    if (state.deletedDripperIds.isNotEmpty) {
      lines.add(
        '• ${state.deletedDripperIds.length} Dripper bawaan yang sebelumnya dihapus',
      );
    }
    if (state.deletedFilterIds.isNotEmpty) {
      lines.add(
        '• ${state.deletedFilterIds.length} Kertas Filter bawaan yang sebelumnya dihapus',
      );
    }
    if (state.deletedRecipeIds.isNotEmpty) {
      lines.add(
        '• ${state.deletedRecipeIds.length} Resep Profesional bawaan yang sebelumnya dihapus',
      );
    }
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = ref.watch(pocketStoreProvider);
    final notifier = ref.read(pocketStoreProvider.notifier);
    final prefs = state.prefs;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: 'Pengaturan',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                children: [
                  // 0. Profil & Nama Panggilan
                  const PocketSectionHeader(title: 'Profil & Nama Panggilan'),
                  const SizedBox(height: 8),
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          onChanged: (v) {
                            notifier.setUserName(v);
                            _markDirty();
                            setState(() {});
                          },
                          style: PocketTheme.ui(
                            size: 13.8,
                            weight: 700,
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
                                      notifier.setUserName('');
                                      _markDirty();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            hintText: 'Tulis nama panggilanmu (opsional)...',
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
                              ? 'Sapaan di Beranda: "Mau seduh apa hari ini?"'
                              : 'Sapaan di Beranda: "Mau seduh apa, ${_nameCtrl.text.trim()}?"',
                          style: PocketTheme.ui(
                            size: 11.5,
                            weight: 600,
                            color: c.brandSage,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Satuan & Pengukuran
                  const PocketSectionHeader(title: 'Satuan & Pengukuran'),
                  const SizedBox(height: 8),
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Satuan Air & Cairan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            UnitPillSelector(
                              value: prefs.unitMode,
                              onChanged: (u) {
                                notifier.setUnitMode(u);
                                _markDirty();
                              },
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Satuan Suhu Air',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: TempUnit.values.map((t) {
                                final sel = prefs.tempUnit == t;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: PocketPill(
                                    label: t.symbol,
                                    backgroundColor: sel
                                        ? c.brandEspresso
                                        : c.surfaceElevated,
                                    foregroundColor: sel
                                        ? c.textOnAccent
                                        : c.textSecondary,
                                    onTap: () {
                                      notifier.setTempUnit(t);
                                      _markDirty();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Default Masa Paling Enak Biji Baru — User Configurable Global Default!
                  PocketSectionHeader(
                    title: 'Default Masa Paling Enak Kopi',
                    actionLabel: 'Atur →',
                    onAction: () => _openRestingDialog(context, ref),
                  ),
                  const SizedBox(height: 8),
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => _openRestingDialog(context, ref),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patokan hari terbaik setelah sangrai saat menambah biji baru. Tetap bisa diubah per kantong di halaman Biji Kopi.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _RestBadge(
                              label: 'Light',
                              range:
                                  '${prefs.restLightMinD}–${prefs.restLightMaxD} Hari',
                            ),
                            const SizedBox(width: 8),
                            _RestBadge(
                              label: 'Medium',
                              range:
                                  '${prefs.restMedMinD}–${prefs.restMedMaxD} Hari',
                            ),
                            const SizedBox(width: 8),
                            _RestBadge(
                              label: 'Dark',
                              range:
                                  '${prefs.restDarkMinD}–${prefs.restDarkMaxD} Hari',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Timer & Kenyamanan Seduh
                  const PocketSectionHeader(title: 'Timer & Kenyamanan Seduh'),
                  const SizedBox(height: 8),
                  PocketCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Column(
                      children: [
                        _ToggleRow(
                          title: 'Layar Tetap Menyala',
                          subtitle: 'Layar tidak mati otomatis saat menyeduh',
                          value: prefs.keepScreenOn,
                          onChanged: (v) {
                            notifier.updatePrefs(prefs.copyWith(keepScreenOn: v));
                            _markDirty();
                          },
                        ),
                        const Divider(),
                        _ToggleRow(
                          title: 'Suara Hitung Mundur 3–2–1',
                          subtitle: 'Bip halus 3 detik sebelum tuang berikutnya',
                          value: prefs.soundCue,
                          onChanged: (v) {
                            notifier.updatePrefs(prefs.copyWith(soundCue: v));
                            if (v) BrewAudioCue.playTestTone();
                            _markDirty();
                          },
                          extraAction: PocketPill(
                            label: 'Tes Suara',
                            height: 28,
                            fontSize: 11,
                            fontWeight: 700,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            backgroundColor: c.tintTerracotta,
                            foregroundColor: c.brandTerracottaInk,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              BrewAudioCue.playTestTone();
                            },
                          ),
                        ),
                        const Divider(),
                        _ToggleRow(
                          title: 'Getaran Tangan Basah',
                          subtitle:
                              'Getar lembut saat pindah tahap atau ganti klik',
                          value: prefs.hapticCue,
                          onChanged: (v) {
                            notifier.updatePrefs(prefs.copyWith(hapticCue: v));
                            _markDirty();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Tampilan & Salinan Data (100% Human-Friendly Copy!)
                  const PocketSectionHeader(title: 'Tampilan & Salinan Data'),
                  const SizedBox(height: 8),
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: AppThemePref.values.map((t) {
                            final sel = prefs.themePref == t;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: t != AppThemePref.system ? 7 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    notifier.setThemePref(t);
                                    _markDirty();
                                  },
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? c.brandEspresso
                                          : c.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      t.label,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: sel
                                            ? c.textOnAccent
                                            : c.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Data Tersimpan Aman di HP',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Buat cadangan catatan jika ganti HP',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            PocketPill(
                              label: 'Simpan',
                              backgroundColor: c.tintSage,
                              foregroundColor: c.brandSage,
                              onTap: () async {
                                final data = notifier.exportBackupJson();
                                await Clipboard.setData(
                                  ClipboardData(text: data),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Salinan cadangan berhasil disalin! Simpan di catatan amanmu.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            PocketPill(
                              label: 'Pulihkan',
                              backgroundColor: c.surfaceElevated,
                              foregroundColor: c.textPrimary,
                              onTap: () => _openRestoreDialog(context, ref),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 5. Versi Aplikasi & Integritas Database Lokal
                  const PocketSectionHeader(title: 'Versi & Database Lokal'),
                  const SizedBox(height: 8),
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Pocket Brew',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: PocketPill(
                                label: PocketVersion.fullLabel,
                                backgroundColor: c.surfaceElevated,
                                foregroundColor: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Database Lokal Schema v${PocketVersion.dbSchemaVersion} (Dual-Slot Auto-Backup) · '
                          '${state.beans.length} kopi · ${state.logs.length} seduhan · '
                          '${state.recipes.where((r) => !r.isOfficial).length} resep custom',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pulihkan Preset Bawaan Aplikasi',
                                    style: PocketTheme.ui(
                                      size: 13.5,
                                      weight: 800,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.hasAnyDeletedOfficialItems
                                        ? _buildDeletedSummaryText(state)
                                        : 'Semua alat & resep bawaan aplikasi sudah lengkap. Data biji, riwayat, & custom milikmu tidak akan terhapus.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            PocketPill(
                              label: state.hasAnyDeletedOfficialItems
                                  ? 'Pulihkan (${state.totalDeletedOfficialCount})'
                                  : 'Lengkap ✓',
                              height: 34,
                              fontSize: 11.5,
                              fontWeight: 700,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: state.hasAnyDeletedOfficialItems
                                  ? c.tintSage
                                  : c.surfaceElevated,
                              foregroundColor: state.hasAnyDeletedOfficialItems
                                  ? c.brandSage
                                  : c.textTertiary,
                              onTap: state.hasAnyDeletedOfficialItems
                                  ? () async {
                                      final details =
                                          _buildDeletedDetailBulletList(state);
                                      final ok = await showPocketDeleteDialog(
                                        context,
                                        title: 'Pulihkan Preset Bawaan?',
                                        message:
                                            'Item bawaan aplikasi berikut akan dikembalikan:\n$details\n\nCatatan: Biji kopi, riwayat seduhan, alat custom, dan resep custom milikmu TIDAK akan terhapus.',
                                        confirmLabel: 'Pulihkan',
                                        isDestructive: false,
                                      );
                                      if (!ok) return;
                                      await notifier
                                          .restoreAllDeletedOfficialCatalog();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Semua alat & resep bawaan berhasil dipulihkan ✓',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hapus Semua Data',
                                    style: PocketTheme.ui(
                                      size: 13.5,
                                      weight: 800,
                                      color: c.statusError,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Bersihkan seluruh stok biji, riwayat seduhan, resep & alat custom agar mulai bersih.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            PocketPill(
                              label: 'Hapus Data',
                              height: 34,
                              fontSize: 11.5,
                              fontWeight: 700,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor:
                                  c.statusError.withValues(alpha: 0.14),
                              foregroundColor: c.statusError,
                              borderColor:
                                  c.statusError.withValues(alpha: 0.35),
                              onTap: () async {
                                final ok = await showPocketDeleteDialog(
                                  context,
                                  title: 'Hapus Semua Data Lokal?',
                                  message:
                                      'Seluruh stok biji kopi, catatan riwayat seduhan, resep custom, dan alat tambahan akan dihapus permanen dari HP ini. Aplikasi akan kembali ke Setup Awal.',
                                  confirmLabel: 'Ya, Hapus Semua',
                                );
                                if (!ok) return;
                                await notifier.clearAllLocalData();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Semua data lokal berhasil dibersihkan ✓',
                                      ),
                                    ),
                                  );
                                  context.go('/onboarding');
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/onboarding'),
                      child: Text(
                        'Buka Ulang Setup Meja Awal',
                        style: TextStyle(
                          color: c.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: _hasChanges ? 'Simpan Pengaturan' : 'Simpan & Kembali',
                pocketIcon: PocketIconType.check,
                backgroundColor:
                    _hasChanges ? c.brandTerracotta : c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 52,
                onTap: () {
                  notifier.updatePrefs(
                    ref
                        .read(pocketStoreProvider)
                        .prefs
                        .copyWith(userName: _nameCtrl.text.trim()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan berhasil disimpan ✓'),
                    ),
                  );
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRestingDialog(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(pocketStoreProvider).prefs;
    int lightMin = prefs.restLightMinD;
    int medMin = prefs.restMedMinD;
    int darkMin = prefs.restDarkMinD;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              backgroundColor: ctx.colors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Atur Masa Resting Minimal',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RestSlider(
                    label: 'Light Roast',
                    days: lightMin,
                    min: 3,
                    max: 21,
                    onChanged: (v) => setModal(() => lightMin = v),
                  ),
                  _RestSlider(
                    label: 'Medium Roast',
                    days: medMin,
                    min: 2,
                    max: 14,
                    onChanged: (v) => setModal(() => medMin = v),
                  ),
                  _RestSlider(
                    label: 'Dark Roast',
                    days: darkMin,
                    min: 1,
                    max: 10,
                    onChanged: (v) => setModal(() => darkMin = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ctx.colors.brandEspresso,
                    foregroundColor: ctx.colors.textOnAccent,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () {
                    ref.read(pocketStoreProvider.notifier).updatePrefs(
                          prefs.copyWith(
                            restLightMinD: lightMin,
                            restLightMaxD: lightMin + 7,
                            restMedMinD: medMin,
                            restMedMaxD: medMin + 5,
                            restDarkMinD: darkMin,
                            restDarkMaxD: darkMin + 4,
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openRestoreDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Pulihkan Data Cadangan',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Tempel teks cadangan yang sebelumnya disimpan di sini...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colors.brandSage,
              foregroundColor: ctx.colors.textOnAccent,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () async {
              final ok = await ref
                  .read(pocketStoreProvider.notifier)
                  .importBackupJson(ctrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Data berhasil dipulihkan!'
                          : 'Teks cadangan belum sesuai, coba cek ulang ya.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );
  }
}

class _RestBadge extends StatelessWidget {
  const _RestBadge({required this.label, required this.range});
  final String label;
  final String range;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                range,
                style: PocketTheme.mono(
                  size: 12,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.extraAction,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? extraAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
          if (extraAction != null) ...[
            const SizedBox(height: 6),
            extraAction!,
          ],
        ],
      ),
    );
  }
}

class _RestSlider extends StatelessWidget {
  const _RestSlider({
    required this.label,
    required this.days,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int days;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              'Min $days hari',
              style: PocketTheme.mono(
                size: 12,
                weight: FontWeight.w800,
                color: context.colors.brandTerracottaInk,
              ),
            ),
          ],
        ),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: days.toDouble(),
          activeColor: context.colors.brandTerracotta,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
