import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../app/theme/pocket_theme.dart';
import '../../app/theme/pocket_tokens.dart';
import '../../core/motion/pocket_motion.dart';
import '../../core/widgets/pocket_card.dart';
import '../../core/widgets/pocket_icons.dart';
import '../../data/repositories/pocket_store.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/models.dart';

/// Screen 15 · Tambah / Edit Biji Kopi:
/// - Cleanly separates Metode Pasca Panen (Processing) & Tingkat Sangrai (Roast Level)
/// - Rich specialty coffee processing methods (+ custom "Lainnya")
/// - Clean metric gram (g) bag weights (NO confusing g/oz pill)
/// - Editable per-bean Peak Resting window (Follow Settings Default OR Custom days)
/// - Clear status: Aktif Dipakai vs Stok Cadangan (NO confusing "Disimpan (Jeda)")
class AddBeanScreen extends ConsumerStatefulWidget {
  const AddBeanScreen({super.key, this.editBeanId});

  final String? editBeanId;

  @override
  ConsumerState<AddBeanScreen> createState() => _AddBeanScreenState();
}

class _AddBeanScreenState extends ConsumerState<AddBeanScreen> {
  static const List<String> _processOptions = [
    'Washed',
    'Natural',
    'Honey',
    'Anaerobic Natural',
    'Anaerobic Washed',
    'Carbonic Maceration',
    'Wet-Hulled (Giling Basah)',
    'Experimental',
    'Lainnya',
  ];

  final _nameCtrl = TextEditingController();
  final _roasteryCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _customProcessCtrl = TextEditingController();
  final _weightCtrl = TextEditingController(text: '250');
  final List<TextEditingController> _noteCtrls = [];

  static const List<String> _noteHints = [
    'Contoh: White Peach',
    'Contoh: Jasmine',
    'Contoh: Bergamot',
    'Contoh: Caramel',
    'Contoh: Chocolate',
    'Contoh: Berry',
  ];

  static const List<String> _quickNoteSuggestions = [
    'White Peach',
    'Jasmine',
    'Citrus',
    'Berry',
    'Honey',
    'Caramel',
    'Chocolate',
    'Floral',
  ];

  String _process = 'Washed';
  RoastLevel _roast = RoastLevel.light;
  double _weightG = 250;
  DateTime _roastDate = DateTime.now().subtract(const Duration(days: 5));
  bool _isReserveStock = false;

  bool _useCustomRest = false;
  int _customRestMinD = 7;
  int _customRestMaxD = 14;
  CoffeeBean? _editingBean;

  bool get _isEditing => _editingBean != null;

  @override
  void initState() {
    super.initState();
    final state = ref.read(pocketStoreProvider);
    final prefs = state.prefs;
    final (defMin, defMax) = prefs.restingRange(_roast);
    _customRestMinD = defMin;
    _customRestMaxD = defMax;

    if (widget.editBeanId != null) {
      final existing =
          state.beans.where((b) => b.id == widget.editBeanId).firstOrNull;
      if (existing != null) {
        _editingBean = existing;
        _nameCtrl.text = existing.name;
        _roasteryCtrl.text = existing.roastery;
        _varietyCtrl.text = existing.variety;
        if (existing.tastingNotes.isNotEmpty) {
          for (final note in existing.tastingNotes) {
            _noteCtrls.add(TextEditingController(text: note));
          }
        }
        if (_processOptions.contains(existing.process)) {
          _process = existing.process;
        } else {
          _process = 'Lainnya';
          _customProcessCtrl.text = existing.process;
        }
        _roast = existing.roastLevel;
        _weightG = existing.remainingG > 0
            ? existing.remainingG
            : existing.bagWeightG;
        _weightCtrl.text = _weightG.round().toString();
        _roastDate = existing.roastDate;
        _isReserveStock = existing.isFrozen;
        if (existing.hasCustomResting) {
          _useCustomRest = true;
          _customRestMinD = existing.customRestMinD!;
          _customRestMaxD = existing.customRestMaxD!;
        } else {
          final (rMin, rMax) = prefs.restingRange(existing.roastLevel);
          _customRestMinD = rMin;
          _customRestMaxD = rMax;
        }
      }
    }
    while (_noteCtrls.length < 2) {
      _noteCtrls.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roasteryCtrl.dispose();
    _varietyCtrl.dispose();
    _customProcessCtrl.dispose();
    _weightCtrl.dispose();
    for (final ctrl in _noteCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _addNoteField([String initial = '']) {
    if (_noteCtrls.length >= 8) return;
    HapticFeedback.selectionClick();
    setState(() {
      _noteCtrls.add(TextEditingController(text: initial));
    });
  }

  void _removeNoteField(int index) {
    if (_noteCtrls.length <= 1) return;
    HapticFeedback.selectionClick();
    setState(() {
      final removed = _noteCtrls.removeAt(index);
      removed.dispose();
    });
  }

  void _applyQuickNote(String note) {
    HapticFeedback.selectionClick();
    // Avoid duplicates
    final exists = _noteCtrls.any(
      (ctrl) => ctrl.text.trim().toLowerCase() == note.toLowerCase(),
    );
    if (exists) return;
    // Fill first empty slot if available, otherwise add a new slot
    for (final ctrl in _noteCtrls) {
      if (ctrl.text.trim().isEmpty) {
        setState(() => ctrl.text = note);
        return;
      }
    }
    if (_noteCtrls.length < 8) {
      setState(() => _noteCtrls.add(TextEditingController(text: note)));
    }
  }

  void _setWeightG(double next) {
    final clamped = next.clamp(5.0, 5000.0);
    setState(() {
      _weightG = clamped;
      _weightCtrl.text = clamped.round().toString();
      _weightCtrl.selection =
          TextSelection.collapsed(offset: _weightCtrl.text.length);
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama biji kopi terlebih dahulu ya!')),
      );
      return;
    }
    final parsedW =
        double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ??
            _weightG;
    final finalWeight = parsedW.clamp(5.0, 5000.0);
    final notesList = _noteCtrls
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final resolvedProcess = _process == 'Lainnya' &&
            _customProcessCtrl.text.trim().isNotEmpty
        ? _customProcessCtrl.text.trim()
        : (_process == 'Lainnya' ? 'Custom Process' : _process);

    final notifier = ref.read(pocketStoreProvider.notifier);

    if (_editingBean != null) {
      final bagCap = finalWeight > _editingBean!.bagWeightG
          ? finalWeight
          : _editingBean!.bagWeightG;
      final updated = _editingBean!.copyWith(
        name: name,
        roastery: _roasteryCtrl.text.trim().isEmpty
            ? 'Roastery Pilihan'
            : _roasteryCtrl.text.trim(),
        variety: _varietyCtrl.text.trim(),
        process: resolvedProcess,
        roastLevel: _roast,
        bagWeightG: bagCap,
        remainingG: finalWeight,
        condition: BeanCondition.openedUsed,
        roastDate: _roastDate,
        tastingNotes:
            notesList.isEmpty ? const ['Balanced', 'Sweet'] : notesList,
        isFrozen: _isReserveStock,
        clearCustomRest: !_useCustomRest,
        customRestMinD: _useCustomRest ? _customRestMinD : null,
        customRestMaxD: _useCustomRest ? _customRestMaxD : null,
      );
      notifier.updateBean(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perubahan pada ${updated.name} disimpan ✓')),
      );
      context.pop();
      return;
    }

    final bean = CoffeeBean(
      id: 'bean-${const Uuid().v4().substring(0, 8)}',
      name: name,
      roastery: _roasteryCtrl.text.trim().isEmpty
          ? 'Roastery Pilihan'
          : _roasteryCtrl.text.trim(),
      origin: name,
      variety: _varietyCtrl.text.trim(),
      process: resolvedProcess,
      roastLevel: _roast,
      bagWeightG: finalWeight,
      remainingG: finalWeight,
      condition: BeanCondition.sealedNew,
      roastDate: _roastDate,
      tastingNotes: notesList.isEmpty ? const ['Balanced', 'Sweet'] : notesList,
      isFrozen: _isReserveStock,
      customRestMinD: _useCustomRest ? _customRestMinD : null,
      customRestMaxD: _useCustomRest ? _customRestMaxD : null,
    );

    notifier.addBean(bean);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${bean.name} (${finalWeight.round()}g) ditambahkan ke Biji Kopi ✓',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final prefs = ref.watch(pocketStoreProvider).prefs;
    final (defaultMin, defaultMax) = prefs.restingRange(_roast);
    final activeRestMin = _useCustomRest ? _customRestMinD : defaultMin;
    final activeRestMax = _useCustomRest ? _customRestMaxD : defaultMax;

    final optimalStart = _roastDate.add(Duration(days: activeRestMin));
    final optimalEnd = _roastDate.add(Duration(days: activeRestMax));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: _isEditing ? 'Edit Biji Kopi' : 'Tambah Biji Kopi',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
                children: [
                  // 1. Identitas Biji Kopi
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identitas Biji Kopi',
                          style: PocketTheme.ui(
                            size: 13.5,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Kopi / Origin',
                            hintText: 'Contoh: Ethiopia Guji Uraga / Gayo Pantan',
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _roasteryCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Roastery',
                                  hintText: 'Fuglen / Space',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _varietyCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Varietas',
                                  hintText: 'Bourbon / Geisha',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // 2. Metode Pasca Panen (SEPARATED clearly from Roast Level!)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pasca Panen (Proses)',
                          style: PocketTheme.ui(
                            size: 13.5,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Proses biji memengaruhi karakter rasa & kecepatan ekstraksi.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 7,
                          children: _processOptions.map((p) {
                            final sel = _process == p;
                            return PocketPill(
                              label: p,
                              height: 30,
                              fontSize: 11.5,
                              backgroundColor:
                                  sel ? c.brandEspresso : c.surfaceElevated,
                              foregroundColor:
                                  sel ? c.textOnAccent : c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _process = p);
                              },
                            );
                          }).toList(),
                        ),
                        AnimatedSize(
                          duration: PocketCurves.normal,
                          curve: PocketCurves.smoothOut,
                          child: _process == 'Lainnya'
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: TextField(
                                    controller: _customProcessCtrl,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText:
                                          'Tulis proses lain, mis. Thermal Shock / Koji...',
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // 3. Tingkat Sangrai (Roast Level — SEPARATE card!)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Tingkat Sangrai (Roast)',
                                style: PocketTheme.ui(
                                  size: 13.5,
                                  weight: 800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            PocketPill(
                              label: 'Default $defaultMin–$defaultMax hr',
                              isMono: true,
                              fontSize: 10.5,
                              backgroundColor: c.tintSage,
                              foregroundColor: c.brandSage,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 7,
                          children: RoastLevel.values.map((r) {
                            final sel = _roast == r;
                            return PocketPill(
                              label: r.shortLabel,
                              height: 32,
                              fontSize: 12,
                              backgroundColor:
                                  sel ? c.tintTerracotta : c.surfaceElevated,
                              foregroundColor:
                                  sel ? c.brandTerracottaInk : c.textPrimary,
                              borderColor: sel
                                  ? c.brandTerracotta.withValues(alpha: 0.45)
                                  : Colors.transparent,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _roast = r;
                                  if (!_useCustomRest) {
                                    final (rMin, rMax) = prefs.restingRange(r);
                                    _customRestMinD = rMin;
                                    _customRestMaxD = rMax;
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // 4. Berat Biji Saat Ini (1 input bersih + tombol cepat & ketik bebas, TANPA Baru/Terpakai & TANPA estimasi cup!)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Berat Kopi Saat Ini',
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
                              label: 'gram (g)',
                              backgroundColor: c.surfaceElevated,
                              foregroundColor: c.textSecondary,
                              fontSize: 10.5,
                              isMono: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Pilih ukuran cepat atau ketik langsung berat biji yang kamu punya.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              [100.0, 150.0, 200.0, 250.0, 500.0, 1000.0]
                                  .map((w) {
                            final sel = (_weightG - w).abs() < 0.5;
                            return PocketPill(
                              label: w >= 1000 ? '1 kg' : '${w.round()}g',
                              isMono: true,
                              height: 32,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              backgroundColor:
                                  sel ? c.brandEspresso : c.surfaceElevated,
                              foregroundColor:
                                  sel ? c.textOnAccent : c.textPrimary,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _setWeightG(w);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            PocketTapScale(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _setWeightG(_weightG - 10);
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: c.surfaceElevated,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: PocketIcon(
                                  PocketIconType.minus,
                                  size: 17,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (val) {
                                  final parsed = double.tryParse(val.trim());
                                  if (parsed != null && parsed >= 5) {
                                    setState(
                                      () => _weightG = parsed.clamp(5, 5000),
                                    );
                                  }
                                },
                                style: PocketTheme.mono(
                                  size: 19,
                                  weight: FontWeight.w800,
                                  color: c.brandTerracottaInk,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: c.isDark
                                      ? c.surfaceElevated
                                      : c.surfaceCanvas,
                                  suffixText: 'g',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide:
                                        BorderSide(color: c.borderSubtle),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: c.brandTerracotta,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            PocketTapScale(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _setWeightG(_weightG + 10);
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: c.brandEspresso,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: PocketIcon(
                                  PocketIconType.plus,
                                  size: 17,
                                  color: c.textOnAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // 5. Tanggal Sangrai, Masa Paling Enak Diseduh & Status Penyimpanan
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Sangrai & Masa Paling Enak',
                          style: PocketTheme.ui(
                            size: 13.5,
                            weight: 800,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Masa paling enak adalah rentang hari setelah sangrai saat gas kopi stabil dan rasa seduhan sedang maksimal (umumnya 7–21 hari).',
                          style: PocketTheme.ui(
                            size: 11,
                            weight: 500,
                            height: 1.38,
                            color: c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PocketTapScale(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _roastDate,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 180)),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _roastDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: c.surfaceElevated,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tanggal Sangrai',
                                        style: PocketTheme.ui(
                                          size: 10,
                                          weight: 600,
                                          color: c.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_roastDate.day}/${_roastDate.month}/${_roastDate.year}',
                                        style: PocketTheme.mono(
                                          size: 12.5,
                                          weight: FontWeight.w800,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PocketTapScale(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                    () => _useCustomRest = !_useCustomRest,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: c.tintSage,
                                    borderRadius: BorderRadius.circular(13),
                                    border: Border.all(
                                      color: _useCustomRest
                                          ? c.brandSage
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Paling Enak ($activeRestMin–$activeRestMax hr)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: PocketTheme.ui(
                                                size: 10,
                                                weight: 700,
                                                color: c.brandSage,
                                              ),
                                            ),
                                          ),
                                          PocketIcon(
                                            PocketIconType.edit,
                                            size: 11,
                                            color: c.brandSage,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${optimalStart.day}/${optimalStart.month} – ${optimalEnd.day}/${optimalEnd.month}',
                                        style: PocketTheme.mono(
                                          size: 12,
                                          weight: FontWeight.w800,
                                          color: c.brandSage,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),

                        // Masa Paling Enak Mode Switch: Default vs Atur Sendiri
                        Row(
                          children: [
                            Expanded(
                              child: PocketPill(
                                label: 'Default ($defaultMin–$defaultMax hr)',
                                height: 32,
                                fontSize: 11,
                                backgroundColor: !_useCustomRest
                                    ? c.brandEspresso
                                    : c.surfaceElevated,
                                foregroundColor: !_useCustomRest
                                    ? c.textOnAccent
                                    : c.textSecondary,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _useCustomRest = false);
                                },
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: PocketPill(
                                label: 'Atur Sendiri',
                                pocketIcon: PocketIconType.edit,
                                iconSize: 12,
                                height: 32,
                                fontSize: 11,
                                backgroundColor: _useCustomRest
                                    ? c.brandSage
                                    : c.surfaceElevated,
                                foregroundColor: _useCustomRest
                                    ? c.textOnAccent
                                    : c.textSecondary,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _useCustomRest = true);
                                },
                              ),
                            ),
                          ],
                        ),

                        // Inline Custom Resting Steppers
                        AnimatedSize(
                          duration: PocketCurves.normal,
                          curve: PocketCurves.smoothOut,
                          child: _useCustomRest
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(11),
                                    decoration: BoxDecoration(
                                      color: c.surfaceElevated,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sesuaikan rentang hari paling enak diseduh (mis. anjuran roastery 10–21 hari setelah sangrai)',
                                          style: PocketTheme.ui(
                                            size: 10.8,
                                            weight: 500,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _RestDayStepper(
                                                label: 'Mulai Enak',
                                                days: _customRestMinD,
                                                onMinus: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(() {
                                                    _customRestMinD =
                                                        (_customRestMinD - 1)
                                                            .clamp(1, 45);
                                                    if (_customRestMaxD <=
                                                        _customRestMinD) {
                                                      _customRestMaxD =
                                                          _customRestMinD + 1;
                                                    }
                                                  });
                                                },
                                                onPlus: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(() {
                                                    _customRestMinD =
                                                        (_customRestMinD + 1)
                                                            .clamp(1, 45);
                                                    if (_customRestMaxD <=
                                                        _customRestMinD) {
                                                      _customRestMaxD =
                                                          _customRestMinD + 1;
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _RestDayStepper(
                                                label: 'Sampai Hari',
                                                days: _customRestMaxD,
                                                onMinus: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(() {
                                                    _customRestMaxD =
                                                        (_customRestMaxD - 1)
                                                            .clamp(
                                                      _customRestMinD + 1,
                                                      60,
                                                    );
                                                  });
                                                },
                                                onPlus: () {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(() {
                                                    _customRestMaxD =
                                                        (_customRestMaxD + 1)
                                                            .clamp(
                                                      _customRestMinD + 1,
                                                      60,
                                                    );
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 11),

                        // Status Pemakaian: Aktif Dipakai vs Stok Cadangan (NO "Disimpan (Jeda)")
                        Text(
                          'Status Pemakaian',
                          style: PocketTheme.ui(
                            size: 11.5,
                            weight: 700,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: PocketPill(
                                label: 'Aktif Dipakai',
                                height: 38,
                                backgroundColor: !_isReserveStock
                                    ? c.brandEspresso
                                    : c.surfaceElevated,
                                foregroundColor: !_isReserveStock
                                    ? c.textOnAccent
                                    : c.textPrimary,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isReserveStock = false);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PocketPill(
                                label: 'Stok Cadangan',
                                height: 38,
                                backgroundColor: _isReserveStock
                                    ? c.brandSage
                                    : c.surfaceElevated,
                                foregroundColor: _isReserveStock
                                    ? c.textOnAccent
                                    : c.textPrimary,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isReserveStock = true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _isReserveStock
                              ? 'Biji masuk tab Cadangan sampai kamu siap membukanya untuk seduh.'
                              : 'Biji langsung muncul di daftar aktif & siap dipilih saat Brew.',
                          style: PocketTheme.ui(
                            size: 10.8,
                            weight: 500,
                            height: 1.35,
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),

                  // 6. Notes Rasa Kemasan — Individual structured inputs (Notes 1, Notes 2, ...)
                  PocketCard(
                    padding: const EdgeInsets.all(14),
                    radius: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Notes Rasa Kemasan',
                                style: PocketTheme.ui(
                                  size: 13.5,
                                  weight: 800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            if (_noteCtrls.length < 8)
                              PocketPill(
                                label: '+ Tambah Note',
                                height: 28,
                                fontSize: 11,
                                fontWeight: 700,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                backgroundColor: c.tintBerry,
                                foregroundColor: c.brandBerry,
                                onTap: () => _addNoteField(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Isi satu rasa per kolom (Notes 1, Notes 2, dst.) atau ketuk pilihan cepat di bawah.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_noteCtrls.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i < _noteCtrls.length - 1 ? 8 : 0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: c.tintBerry,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: PocketTheme.mono(
                                      size: 11,
                                      weight: FontWeight.w800,
                                      color: c.brandBerry,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: TextField(
                                    controller: _noteCtrls[i],
                                    onChanged: (_) => setState(() {}),
                                    textInputAction: i < _noteCtrls.length - 1
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    style: PocketTheme.ui(
                                      size: 13.5,
                                      weight: 600,
                                      color: c.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'Notes ${i + 1}',
                                      hintText: _noteHints[
                                          i % _noteHints.length],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_noteCtrls.length > 1) ...[
                                  const SizedBox(width: 6),
                                  PocketTapScale(
                                    onTap: () => _removeNoteField(i),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: c.surfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 16,
                                        color: c.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Text(
                          'Pilihan Cepat:',
                          style: PocketTheme.ui(
                            size: 10.8,
                            weight: 700,
                            color: c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _quickNoteSuggestions.map((s) {
                            final alreadyAdded = _noteCtrls.any(
                              (ctrl) =>
                                  ctrl.text.trim().toLowerCase() ==
                                  s.toLowerCase(),
                            );
                            return PocketPill(
                              label: alreadyAdded ? '$s ✓' : '+ $s',
                              height: 28,
                              fontSize: 11,
                              fontWeight: 600,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              backgroundColor: alreadyAdded
                                  ? c.tintBerry
                                  : c.surfaceElevated,
                              foregroundColor: alreadyAdded
                                  ? c.brandBerry
                                  : c.textSecondary,
                              onTap: () => _applyQuickNote(s),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: PocketButton(
                label: _isEditing
                    ? 'Simpan Perubahan Kopi'
                    : 'Simpan Kopi (${_weightG.round()}g)',
                pocketIcon: PocketIconType.check,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                height: 52,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestDayStepper extends StatelessWidget {
  const _RestDayStepper({
    required this.label,
    required this.days,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final int days;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: PocketTheme.ui(
              size: 10,
              weight: 600,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PocketTapScale(
                onTap: onMinus,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: PocketIcon(
                    PocketIconType.minus,
                    size: 13,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                'Hari $days',
                style: PocketTheme.mono(
                  size: 12,
                  weight: FontWeight.w800,
                  color: c.brandSage,
                ),
              ),
              PocketTapScale(
                onTap: onPlus,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: PocketIcon(
                    PocketIconType.plus,
                    size: 13,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
