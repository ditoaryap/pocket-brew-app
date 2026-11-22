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
import '../../domain/models/models.dart';

/// Screen 17 · Tambah / Edit Alat Sendiri (Grinder / Dripper / Filter):
/// - Silky sliding capsule switcher + 60fps horizontal PageView transitions (zero choppiness)
/// - Disciplined visual hierarchy & clear contrast in Light + Dark mode
/// - Beginner-friendly Grinder inputs (technical micron/zero-point collapsed cleanly)
/// - Clean text-only Dripper shape cards (no distracting photos)
/// - Plain-language Filter flow cards + full multiline unclipped notes.
class AddCustomGearScreen extends ConsumerStatefulWidget {
  const AddCustomGearScreen({
    super.key,
    this.initialType = 0,
    this.editId,
  });

  final int initialType;
  final String? editId;

  @override
  ConsumerState<AddCustomGearScreen> createState() =>
      _AddCustomGearScreenState();
}

class _AddCustomGearScreenState extends ConsumerState<AddCustomGearScreen> {
  late int _type; // 0 = Grinder, 1 = Dripper, 2 = Filter
  late final PageController _pageCtrl;

  // Separate controllers per equipment type so notes never bleed across tabs.
  final _grinderNameCtrl = TextEditingController();
  final _umCtrl = TextEditingController(text: '25');
  final _v60HotCtrl = TextEditingController(text: '22');
  final _grinderZeroCtrl = TextEditingController();
  bool _showGrinderAdvanced = false;
  int _selectedUmPreset = 25;

  final _dripperNameCtrl = TextEditingController();
  String _dripperGeometry = 'Cone 60°';
  String _dripperMaterial = 'Plastik';
  final _dripperNoteCtrl = TextEditingController();

  final _filterNameCtrl = TextEditingController();
  String _filterSpeedChoice = 'Sedang'; // Cepat | Sedang | Lambat | Tidak Yakin
  final _filterNoteCtrl = TextEditingController();

  bool get _isEditing => widget.editId != null && widget.editId!.isNotEmpty;

  static const _dripperGeometries = [
    (
      id: 'Cone 60°',
      title: 'Kerucut 60° (Conical)',
      examples: 'Hario V60, Origami, Kono',
      taste: 'Rasa lebih cerah, jernih & aromatik',
    ),
    (
      id: 'Flat-Bottom',
      title: 'Dasar Datar (Flat-Bottom)',
      examples: 'Kalita Wave, April, Timemore B75',
      taste: 'Rasa lebih manis, seimbang & konsisten',
    ),
    (
      id: 'Hybrid Valve',
      title: 'Katup / Rendam (Hybrid)',
      examples: 'Hario Switch, Clever Dripper',
      taste: 'Bisa direndam, body lebih tebal & stabil',
    ),
  ];

  static const _filterChoices = [
    (
      id: 'Cepat',
      title: 'Cepat · Aliran Lancar',
      desc: 'Air turun cepat · Contoh: Sibarist, Cafec Abaca / T-90',
    ),
    (
      id: 'Sedang',
      title: 'Normal · Seimbang',
      desc: 'Standar harian · Contoh: Hario Putih buatan Jepang',
    ),
    (
      id: 'Lambat',
      title: 'Lambat · Kertas Tebal',
      desc: 'Air turun pelan · Contoh: Hario Coklat / Belanda, Kalita tebal',
    ),
    (
      id: 'Tidak Yakin',
      title: 'Tidak Yakin (Pakai Normal)',
      desc: 'Pilihan aman buat mulai — pakai setelan standar dulu',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType.clamp(0, 2);
    _pageCtrl = PageController(initialPage: _type);

    if (_isEditing) {
      final store = ref.read(pocketStoreProvider);
      if (_type == 0) {
        final g =
            store.grinders.where((x) => x.id == widget.editId).firstOrNull;
        if (g != null) {
          _grinderNameCtrl.text = g.fullName;
          _umCtrl.text = g.umPerClick.round().toString();
          _selectedUmPreset = g.umPerClick.round();
          _v60HotCtrl.text = g.v60HotDefault.toString();
          _grinderZeroCtrl.text = g.zeroPointNote;
        }
      } else if (_type == 1) {
        final d =
            store.drippers.where((x) => x.id == widget.editId).firstOrNull;
        if (d != null) {
          _dripperNameCtrl.text = d.name;
          _dripperGeometry = d.geometry;
          _dripperMaterial = d.material;
          _dripperNoteCtrl.text = d.flowNote;
        }
      } else {
        final f =
            store.filters.where((x) => x.id == widget.editId).firstOrNull;
        if (f != null) {
          _filterNameCtrl.text = f.name;
          _filterSpeedChoice = f.speed;
          _filterNoteCtrl.text = f.note;
        }
      }
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _grinderNameCtrl.dispose();
    _umCtrl.dispose();
    _v60HotCtrl.dispose();
    _grinderZeroCtrl.dispose();
    _dripperNameCtrl.dispose();
    _dripperNoteCtrl.dispose();
    _filterNameCtrl.dispose();
    _filterNoteCtrl.dispose();
    super.dispose();
  }

  TextEditingController get _activeNameCtrl => switch (_type) {
        0 => _grinderNameCtrl,
        1 => _dripperNameCtrl,
        _ => _filterNameCtrl,
      };

  InputDecoration _cleanInputDecoration(
    PocketColors c, {
    String? hintText,
    String? suffixText,
    int? hintMaxLines,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: c.isDark ? c.surfaceElevated : c.surfaceCanvas,
      hintText: hintText,
      hintMaxLines: hintMaxLines,
      suffixText: suffixText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.brandTerracotta, width: 1.5),
      ),
    );
  }

  void _switchTab(int next) {
    if (next == _type) return;
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() => _type = next);
    if (_pageCtrl.hasClients) {
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: PocketCurves.smoothOut,
      );
    }
  }

  void _save() {
    final name = _activeNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nama alat terlebih dahulu ya!')),
      );
      return;
    }
    final notifier = ref.read(pocketStoreProvider.notifier);
    final id = _isEditing
        ? widget.editId!
        : 'custom-${const Uuid().v4().substring(0, 8)}';

    if (_type == 0) {
      final um = double.tryParse(_umCtrl.text.trim()) ??
          _selectedUmPreset.toDouble();
      final v60 = (int.tryParse(_v60HotCtrl.text.trim()) ?? 22).clamp(1, 200);
      final parts = name.split(' ');
      final brand = parts.first;
      final model = parts.length > 1 ? parts.sublist(1).join(' ') : 'Custom';
      final zeroNote = _grinderZeroCtrl.text.trim().isEmpty
          ? 'Posisi paling rapat ringan saat gagang tidak jatuh (0 klik)'
          : _grinderZeroCtrl.text.trim();
      final spec = GrinderSpec(
        id: id,
        brand: brand,
        model: model,
        umPerClick: um.clamp(5, 150),
        clicksPerRev: 30,
        minClick: 0,
        maxClick: (v60 + 40).clamp(40, 250),
        v60HotMin: (v60 - 3).clamp(1, 200),
        v60HotMax: (v60 + 3).clamp(2, 220),
        v60HotDefault: v60,
        zeroPointNote: zeroNote,
        burrSpec: 'Custom Grinder',
        isOfficial: false,
      );
      if (_isEditing) {
        notifier.updateCustomGrinder(spec, activate: true);
      } else {
        notifier.addCustomGrinder(spec, activate: true);
      }
    } else if (_type == 1) {
      final dripperNote = _dripperNoteCtrl.text.trim().isEmpty
          ? 'Aliran seimbang untuk seduh harian'
          : _dripperNoteCtrl.text.trim();
      final spec = DripperSpec(
        id: id,
        name: name,
        geometry: _dripperGeometry,
        material: _dripperMaterial,
        capacityG: '12–25g',
        flowNote: dripperNote,
        isOfficial: false,
      );
      if (_isEditing) {
        notifier.updateCustomDripper(spec, activate: true);
      } else {
        notifier.addCustomDripper(spec, activate: true);
      }
    } else {
      final resolvedSpeed =
          _filterSpeedChoice == 'Tidak Yakin' ? 'Sedang' : _filterSpeedChoice;
      final offsetUm = switch (resolvedSpeed) {
        'Cepat' => -25.0,
        'Lambat' => 30.0,
        _ => 0.0,
      };
      final filterNote = _filterNoteCtrl.text.trim().isEmpty
          ? 'Kertas filter custom ($resolvedSpeed)'
          : _filterNoteCtrl.text.trim();
      final spec = FilterSpec(
        id: id,
        name: name,
        speed: resolvedSpeed,
        grindOffsetUm: offsetUm,
        note: filterNote,
        isOfficial: false,
      );
      if (_isEditing) {
        notifier.updateCustomFilter(spec, activate: true);
      } else {
        notifier.addCustomFilter(spec, activate: true);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Perubahan pada $name disimpan ✓'
              : '$name berhasil disimpan & diaktifkan ✓',
        ),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PocketTopBar(
              title: _isEditing ? 'Edit Alat Saya' : 'Tambah Alat Sendiri',
              onBack: () => context.pop(),
            ),
            // Pinned subtitle + silky PageController-synced 3-tab capsule
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Perbarui detail alat milikmu — perubahan langsung aktif saat menyeduh.'
                        : 'Isi info dasar alatmu. Detail teknis bersifat opsional agar tetap simpel.',
                    style: PocketTheme.ui(
                      size: 12.2,
                      weight: 500,
                      height: 1.4,
                      color: c.textSecondary,
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 11),
                    _SlidingGearTypeBar(
                      selected: _type,
                      pageController: _pageCtrl,
                      onChanged: _switchTab,
                    ),
                  ],
                ],
              ),
            ),

            // Silky 60fps horizontal PageView — zero height-snap or vertical bounce!
            Expanded(
              child: _isEditing
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
                      children: [
                        switch (_type) {
                          0 => _buildGrinderForm(c),
                          1 => _buildDripperForm(c),
                          _ => _buildFilterForm(c),
                        },
                      ],
                    )
                  : PageView(
                      controller: _pageCtrl,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (idx) {
                        if (idx != _type) {
                          HapticFeedback.selectionClick();
                          FocusScope.of(context).unfocus();
                          setState(() => _type = idx);
                        }
                      },
                      children: [
                        RepaintBoundary(
                          child: ListView(
                            key: const PageStorageKey('gear_form_grinder'),
                            padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
                            children: [_buildGrinderForm(c)],
                          ),
                        ),
                        RepaintBoundary(
                          child: ListView(
                            key: const PageStorageKey('gear_form_dripper'),
                            padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
                            children: [_buildDripperForm(c)],
                          ),
                        ),
                        RepaintBoundary(
                          child: ListView(
                            key: const PageStorageKey('gear_form_filter'),
                            padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
                            children: [_buildFilterForm(c)],
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
              child: PocketButton(
                label: _isEditing
                    ? 'Simpan Perubahan Alat'
                    : 'Simpan & Aktifkan Alat',
                pocketIcon: PocketIconType.check,
                iconSize: 18,
                height: 52,
                backgroundColor: c.brandEspresso,
                foregroundColor: c.textOnAccent,
                onTap: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrinderForm(PocketColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Identitas & Klik V60
        PocketCard(
          padding: const EdgeInsets.all(15),
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepSectionTitle(
                step: '1',
                title: 'Nama & Model Grinder',
                subtitle: 'Tulis merek dan seri grindermu',
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _grinderNameCtrl,
                decoration: _cleanInputDecoration(
                  c,
                  hintText: 'Contoh: Timemore C2, 1Zpresso Q Air, Mavo Phantox',
                  hintMaxLines: 2,
                ),
              ),
              const SizedBox(height: 15),
              _StepSectionTitle(
                step: '2',
                title: 'Klik Harian untuk V60 (Perkiraan)',
                subtitle:
                    'Biasanya putar berapa klik dari posisi mentok? Belum tahu? Biarkan 22 klik — nanti bisa diubah bebas saat Brew.',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _CircleStepBtn(
                    icon: PocketIconType.minus,
                    bg: c.surfaceElevated,
                    fg: c.textPrimary,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final cur = int.tryParse(_v60HotCtrl.text) ?? 22;
                      setState(
                        () => _v60HotCtrl.text = '${(cur - 1).clamp(1, 200)}',
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _v60HotCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: PocketTheme.mono(
                        size: 20,
                        weight: FontWeight.w800,
                        color: c.brandTerracottaInk,
                      ),
                      decoration: _cleanInputDecoration(
                        c,
                        suffixText: 'klik',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CircleStepBtn(
                    icon: PocketIconType.plus,
                    bg: c.brandEspresso,
                    fg: c.textOnAccent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      final cur = int.tryParse(_v60HotCtrl.text) ?? 22;
                      setState(
                        () => _v60HotCtrl.text = '${(cur + 1).clamp(1, 200)}',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),

        // Card 2: Collapsible Technical Options (Beginner-safe!)
        PocketCard(
          padding: EdgeInsets.zero,
          radius: 20,
          elevated: false,
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(
                    () => _showGrinderAdvanced = !_showGrinderAdvanced,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Teknis (Opsional)',
                              style: PocketTheme.ui(
                                size: 13,
                                weight: 800,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ukuran μm per klik & catatan titik nol — aman dilewati',
                              style: PocketTheme.ui(
                                size: 11.2,
                                weight: 500,
                                color: c.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _showGrinderAdvanced ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 240),
                        curve: PocketCurves.smoothOut,
                        child: PocketIcon(
                          PocketIconType.chevronRight,
                          size: 16,
                          color: _showGrinderAdvanced
                              ? c.brandTerracottaInk
                              : c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRect(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: PocketCurves.smoothOut,
                  child: _showGrinderAdvanced
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Text(
                                'Kehalusan per Klik (jika tahu)',
                                style: PocketTheme.ui(
                                  size: 12.5,
                                  weight: 700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Jarak pergeseran mata pisau (burr) tiap 1 klik. Kalau tidak tahu, biarkan Standar (~25 μm).',
                                style: PocketTheme.ui(
                                  size: 11.2,
                                  weight: 500,
                                  height: 1.38,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  (25, 'Standar (~25 μm)'),
                                  (15, 'Rapat (~15 μm)'),
                                  (30, 'Lebar (~30 μm)'),
                                ].map((opt) {
                                  final (val, lbl) = opt;
                                  final sel = _selectedUmPreset == val;
                                  return PocketPill(
                                    label: lbl,
                                    height: 32,
                                    fontSize: 11.5,
                                    backgroundColor: sel
                                        ? c.tintTerracotta
                                        : c.surfaceElevated,
                                    foregroundColor: sel
                                        ? c.brandTerracottaInk
                                        : c.textPrimary,
                                    borderColor: sel
                                        ? c.brandTerracotta
                                        : Colors.transparent,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedUmPreset = val;
                                        _umCtrl.text = '$val';
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 9),
                              TextField(
                                controller: _umCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _cleanInputDecoration(
                                  c,
                                  hintText: '25',
                                  suffixText: 'μm/klik',
                                ),
                              ),
                              const SizedBox(height: 13),
                              Text(
                                'Catatan Titik Nol (Zero Point)',
                                style: PocketTheme.ui(
                                  size: 12.5,
                                  weight: 700,
                                  color: c.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Titik nol adalah posisi putaran paling rapat sebelum mulai dihitung klik ke-1.',
                                style: PocketTheme.ui(
                                  size: 11.2,
                                  weight: 500,
                                  height: 1.38,
                                  color: c.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              TextField(
                                controller: _grinderZeroCtrl,
                                minLines: 2,
                                maxLines: 3,
                                decoration: _cleanInputDecoration(
                                  c,
                                  hintText:
                                      'Contoh: Putar mentok sampai burr menyentuh ringan dan gagang tidak jatuh sendiri',
                                  hintMaxLines: 3,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDripperForm(PocketColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Nama & Bentuk Dripper dengan Foto Asli
        PocketCard(
          padding: const EdgeInsets.all(15),
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepSectionTitle(
                step: '1',
                title: 'Nama & Model Dripper',
                subtitle: 'Contoh: Timemore B75, Hario V60 Keramik, Origami M',
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _dripperNameCtrl,
                decoration: _cleanInputDecoration(
                  c,
                  hintText: 'Tulis nama dripper kamu...',
                ),
              ),
              const SizedBox(height: 15),
              _StepSectionTitle(
                step: '2',
                title: 'Pilih Bentuk Dripper',
                subtitle: 'Pilih bentuk bagian dalam drippermu',
              ),
              const SizedBox(height: 10),
              ..._dripperGeometries.map((item) {
                final sel = _dripperGeometry == item.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _SelectableOptionCard(
                    selected: sel,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _dripperGeometry = item.id);
                    },
                    title: item.title,
                    subtitle: '${item.examples}\n${item.taste}',
                  ),
                );
              }),
              _SelectableOptionCard(
                selected: _dripperGeometry == 'Lainnya',
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _dripperGeometry = 'Lainnya');
                },
                title: 'Bentuk Lainnya',
                subtitle: 'Untuk dripper unik di luar 3 bentuk di atas',
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),

        // Card 2: Bahan & Catatan
        PocketCard(
          padding: const EdgeInsets.all(15),
          radius: 20,
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepSectionTitle(
                step: '3',
                title: 'Bahan & Catatan Dripper',
                subtitle: 'Membantu mengingat panas & aliran dripper',
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: ['Plastik', 'Keramik', 'Kaca', 'Metal / Baja']
                    .map((mat) {
                  final sel = _dripperMaterial == mat;
                  return PocketPill(
                    label: mat,
                    height: 32,
                    fontSize: 12,
                    backgroundColor:
                        sel ? c.tintTerracotta : c.surfaceElevated,
                    foregroundColor:
                        sel ? c.brandTerracottaInk : c.textPrimary,
                    borderColor:
                        sel ? c.brandTerracotta : Colors.transparent,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _dripperMaterial = mat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Catatan Karakter Dripper (Opsional)',
                style: PocketTheme.ui(
                  size: 12.5,
                  weight: 700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _dripperNoteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: _cleanInputDecoration(
                  c,
                  hintText:
                      'Contoh: Plastik ringan, cepat panas saat dibilas, aliran air lancar & jarang mampet',
                  hintMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterForm(PocketColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Nama & Kecepatan Aliran
        PocketCard(
          padding: const EdgeInsets.all(15),
          radius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepSectionTitle(
                step: '1',
                title: 'Nama Kertas Filter',
                subtitle: 'Contoh: Hario Putih 02, Cafec Abaca, Kertas Supermarket',
              ),
              const SizedBox(height: 9),
              TextField(
                controller: _filterNameCtrl,
                decoration: _cleanInputDecoration(
                  c,
                  hintText: 'Tulis nama kertas filter...',
                ),
              ),
              const SizedBox(height: 15),
              _StepSectionTitle(
                step: '2',
                title: 'Seberapa Cepat Air Turun di Kertas Ini?',
                subtitle:
                    'Belum tahu cepat atau lambat? Pilih "Tidak Yakin" — aman buat mulai.',
              ),
              const SizedBox(height: 10),
              ..._filterChoices.map((fc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SelectableOptionCard(
                    selected: _filterSpeedChoice == fc.id,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _filterSpeedChoice = fc.id);
                    },
                    title: fc.title,
                    subtitle: fc.desc,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 11),

        // Card 2: Catatan Filter
        PocketCard(
          padding: const EdgeInsets.all(15),
          radius: 20,
          elevated: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catatan Kertas Filter (Opsional)',
                style: PocketTheme.ui(
                  size: 13,
                  weight: 800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _filterNoteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: _cleanInputDecoration(
                  c,
                  hintText:
                      'Contoh: Kertas tipis, perlu dibilas air panas dulu biar bau kertas hilang, cocok untuk light roast',
                  hintMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SlidingGearTypeBar extends StatelessWidget {
  const _SlidingGearTypeBar({
    required this.selected,
    required this.pageController,
    required this.onChanged,
  });

  final int selected;
  final PageController pageController;
  final ValueChanged<int> onChanged;

  static const _labels = ['Grinder', 'Dripper', 'Filter'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.borderSubtle),
      ),
      child: AnimatedBuilder(
        animation: pageController,
        builder: (context, _) {
          final page = (pageController.hasClients &&
                  pageController.position.hasContentDimensions)
              ? (pageController.page ?? selected.toDouble())
              : selected.toDouble();
          // Maps page 0 -> -1.0, 1 -> 0.0, 2 -> 1.0 continuously!
          final alignX = (page - 1.0).clamp(-1.0, 1.0);

          return Stack(
            children: [
              Align(
                alignment: Alignment(alignX, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  heightFactor: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.brandEspresso,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: c.isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF1F1915)
                                    .withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(_labels.length, (i) {
                  final proximity = (1.0 - (page - i).abs()).clamp(0.0, 1.0);
                  final textColor =
                      Color.lerp(c.textSecondary, c.textOnAccent, proximity)!;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: Text(
                          _labels[i],
                          maxLines: 1,
                          style: PocketTheme.ui(
                            size: 13,
                            weight: proximity > 0.5 ? 700 : 600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepSectionTitle extends StatelessWidget {
  const _StepSectionTitle({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final String step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: c.tintTerracotta,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: PocketTheme.mono(
              size: 11,
              weight: FontWeight.w800,
              color: c.brandTerracottaInk,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PocketTheme.ui(
                  size: 13.5,
                  weight: 800,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: PocketTheme.ui(
                  size: 11.2,
                  weight: 500,
                  height: 1.38,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: PocketCurves.fast,
        curve: PocketCurves.smoothOut,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected
              ? c.tintTerracotta
              : (c.isDark ? c.surfaceElevated : c.surfaceCanvas),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? c.brandTerracotta : c.borderSubtle,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PocketTheme.ui(
                      size: 13,
                      weight: 800,
                      color: selected ? c.brandTerracottaInk : c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: PocketTheme.ui(
                      size: 11.2,
                      weight: 500,
                      height: 1.36,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: PocketCurves.fast,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? c.brandTerracotta : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? c.brandTerracotta : c.borderStrong,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? PocketIcon(
                      PocketIconType.check,
                      size: 13,
                      color: c.textOnAccent,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleStepBtn extends StatelessWidget {
  const _CircleStepBtn({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final PocketIconType icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PocketTapScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: PocketIcon(icon, size: 17, color: fg),
      ),
    );
  }
}
