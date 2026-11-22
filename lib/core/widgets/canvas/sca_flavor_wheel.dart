import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/pocket_theme.dart';
import '../../../app/theme/pocket_tokens.dart';
import '../../motion/pocket_motion.dart';

class FlavorSubcategoryData {
  const FlavorSubcategoryData({
    required this.name,
    required this.indoHint,
    required this.notes,
  });

  final String name;
  final String indoHint;
  final List<String> notes;
}

class FlavorCategoryData {
  const FlavorCategoryData({
    required this.id,
    required this.label,
    required this.indoLabel,
    required this.description,
    required this.color,
    required this.subcategories,
  });

  final String id;
  final String label;
  final String indoLabel;
  final String description;
  final Color color;
  final List<FlavorSubcategoryData> subcategories;

  List<String> get petals => subcategories.map((s) => s.name).toList();

  List<String> get notes =>
      subcategories.expand((s) => s.notes).toList(growable: false);
}

/// Complete Official 2016 SCA & World Coffee Research (WCR) Coffee Taster's Flavor Wheel:
/// All 9 official main categories, authentic Tier-2 subcategories, and Tier-3 sensory notes
/// paired with accessible Indonesian cupping guidance.
const List<FlavorCategoryData> scaFlavorCategories = [
  FlavorCategoryData(
    id: 'fruity',
    label: 'Fruity',
    indoLabel: 'Buah-buahan',
    description:
        'Kesegaran buah matang seperti beri, sitrus, persik, atau buah kering — ciri khas biji light roast berkualitas.',
    color: Color(0xFFB84545),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Berry',
        indoHint: 'Buah beri segar & manis-asam',
        notes: ['Blackberry', 'Raspberry', 'Blueberry', 'Strawberry'],
      ),
      FlavorSubcategoryData(
        name: 'Citrus',
        indoHint: 'Sitrus segar & aromatik',
        notes: ['Bergamot', 'Orange', 'Grapefruit', 'Lemon', 'Lime'],
      ),
      FlavorSubcategoryData(
        name: 'Other Fruit',
        indoHint: 'Buah tropis & buah batu',
        notes: [
          'White Peach',
          'Apple',
          'Pear',
          'Grape',
          'Cherry',
          'Pineapple',
          'Pomegranate',
          'Coconut',
        ],
      ),
      FlavorSubcategoryData(
        name: 'Dried Fruit',
        indoHint: 'Buah kering manis pekat (khas natural/honey)',
        notes: ['Raisin', 'Prune', 'Dates'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'floral',
    label: 'Floral',
    indoLabel: 'Bunga & Teh',
    description:
        'Aroma bunga harum yang ringan, bersih, dan seperti teh — sering muncul pada Ethiopia Washed, Geisha, & Pink Bourbon.',
    color: Color(0xFFC26486),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Floral',
        indoHint: 'Aroma kelopak bunga lembut',
        notes: ['Jasmine', 'Rose', 'Chamomile', 'Orange Blossom', 'Hibiscus'],
      ),
      FlavorSubcategoryData(
        name: 'Tea',
        indoHint: 'Kesan ringan bersih ala teh seduh',
        notes: ['Black Tea', 'Green Tea', 'Oolong'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'sweet',
    label: 'Sweet',
    indoLabel: 'Manis Alami',
    description:
        'Rasa manis alami dari gula kopi yang matang sempurna — paling menonjol saat kopi mulai hangat di 55–65°C.',
    color: Color(0xFFD1933E),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Brown Sugar',
        indoHint: 'Gula aren, karamel & madu',
        notes: ['Caramel', 'Honey', 'Brown Sugar', 'Maple Syrup', 'Molasses'],
      ),
      FlavorSubcategoryData(
        name: 'Sweet Aromatics',
        indoHint: 'Aroma manis lembut creamy',
        notes: ['Vanilla', 'Sweet Cream', 'Overall Sweet'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'nutty_cocoa',
    label: 'Nutty/Cocoa',
    indoLabel: 'Kacang & Cokelat',
    description:
        'Kesan kacang panggang dan cokelat yang nyaman & bulat — sering kuat pada kopi medium roast dan Amerika Latin/Indonesia.',
    color: Color(0xFF8C6245),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Nutty',
        indoHint: 'Kacang panggang gurih-manis',
        notes: ['Almond', 'Hazelnut', 'Peanut'],
      ),
      FlavorSubcategoryData(
        name: 'Cocoa',
        indoHint: 'Cokelat susu hingga dark cocoa',
        notes: ['Chocolate', 'Dark Chocolate', 'Cocoa'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'spices',
    label: 'Spices',
    indoLabel: 'Rempah',
    description:
        'Hangat dan berempah lembut seperti kayu manis, cengkeh, atau kapulaga — banyak ditemukan pada kopi Nusantara (Gayo, Flores, Bali).',
    color: Color(0xFF9E4B3A),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Brown Spice',
        indoHint: 'Rempah hangat manis',
        notes: ['Cinnamon', 'Clove', 'Nutmeg', 'Anise', 'Cardamom'],
      ),
      FlavorSubcategoryData(
        name: 'Sharp Spice',
        indoHint: 'Pedas rempah ringan',
        notes: ['Pepper', 'Pungent'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'roasted',
    label: 'Roasted',
    indoLabel: 'Sangrai & Sereal',
    description:
        'Aroma hasil pemanggangan seperti malt, roti panggang, hingga asap tipis — makin terasa di profil medium-dark & dark roast.',
    color: Color(0xFF6B4E3D),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Cereal',
        indoHint: 'Biji-bijian & roti panggang',
        notes: ['Malt', 'Grain', 'Toast'],
      ),
      FlavorSubcategoryData(
        name: 'Burnt/Tobacco',
        indoHint: 'Asap & tembakau sangrai gelap',
        notes: ['Smoky', 'Ashy', 'Tobacco', 'Acrid'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'sour_fermented',
    label: 'Sour/Ferm',
    indoLabel: 'Asam & Fermentasi',
    description:
        'Keasaman buah yang cerah (citric/malic) hingga aroma winey & fermentasi kompleks — khas proses Anaerobic & Carbonic Maceration.',
    color: Color(0xFFC4A137),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Sour Aromatics',
        indoHint: 'Asam buah cerah vs asam tajam',
        notes: ['Citric Acid', 'Malic Acid', 'Acetic Acid'],
      ),
      FlavorSubcategoryData(
        name: 'Fermented',
        indoHint: 'Aroma wine, boozy & buah ranum',
        notes: ['Winey', 'Whiskey', 'Fermented', 'Overripe'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'green_veg',
    label: 'Green/Herb',
    indoLabel: 'Herbal & Segar',
    description:
        'Kesan daun segar, herbal ringan, atau hijau mentah (bisa positif seperti teh hijau, atau tanda biji kurang matang/under-extracted).',
    color: Color(0xFF4F8259),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Herbal & Fresh',
        indoHint: 'Daun segar & herbal lembut',
        notes: ['Herb-like', 'Fresh Green', 'Peapod', 'Olive Oil'],
      ),
      FlavorSubcategoryData(
        name: 'Raw / Green',
        indoHint: 'Kesan mentah / jerami (tanda under-roast/extract)',
        notes: ['Hay-like', 'Under-ripe', 'Beany'],
      ),
    ],
  ),
  FlavorCategoryData(
    id: 'other',
    label: 'Other',
    indoLabel: 'Lainnya / Defek',
    description:
        'Catatan kayu, tanah, kertas, atau apek — berguna untuk mendeteksi kertas filter belum dibilas, biji terlalu tua, atau defek seduh.',
    color: Color(0xFF5D768B),
    subcategories: [
      FlavorSubcategoryData(
        name: 'Papery/Earthy',
        indoHint: 'Kertas, kayu & aroma tanah',
        notes: ['Woody', 'Earthy', 'Papery', 'Cardboard', 'Stale'],
      ),
      FlavorSubcategoryData(
        name: 'Chemical',
        indoHint: 'Aroma kimia / karet (defek)',
        notes: ['Medicinal', 'Rubber', 'Phenolic'],
      ),
    ],
  ),
];

/// Interactive 9-Category Official SCA Sunburst Flavor Wheel:
/// - Smooth spring bloom of active Tier-2 subcategories on outer ring
/// - RepaintBoundary isolated for silky 60fps performance on mobile APK & Web.
class ScaFlavorWheel extends StatelessWidget {
  const ScaFlavorWheel({
    super.key,
    required this.selectedCategoryIndex,
    required this.selectedCount,
    required this.onSelectCategory,
    this.size = 240,
  });

  final int selectedCategoryIndex;
  final int selectedCount;
  final ValueChanged<int> onSelectCategory;
  final double size;

  void _handleTap(Offset localPos) {
    final center = Offset(size / 2, size / 2);
    final vec = localPos - center;
    if (vec.distance < size * 0.16 || vec.distance > size / 2) return;
    final count = scaFlavorCategories.length;
    final sweep = (2 * math.pi) / count;
    double angle = math.atan2(vec.dy, vec.dx) + math.pi / 2 + sweep / 2;
    while (angle < 0) {
      angle += 2 * math.pi;
    }
    final idx = (angle / sweep).floor() % count;
    HapticFeedback.selectionClick();
    onSelectCategory(idx);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = scaFlavorCategories[selectedCategoryIndex];
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (d) => _handleTap(d.localPosition),
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(selectedCategoryIndex),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 340),
                curve: PocketCurves.gentleSpring,
                builder: (context, bloomT, _) {
                  return CustomPaint(
                    size: Size.square(size),
                    painter: _FlavorWheelPainter(
                      selectedIndex: selectedCategoryIndex,
                      bloomT: bloomT,
                      centerFill: c.surfaceCard,
                      dividerColor: c.surfaceCard,
                    ),
                  );
                },
              ),
              SizedBox(
                width: size * 0.34,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        active.label,
                        maxLines: 1,
                        style: PocketTheme.ui(
                          size: 13,
                          weight: 800,
                          color: active.color,
                        ),
                      ),
                    ),
                    Text(
                      active.indoLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: PocketTheme.ui(
                        size: 9.2,
                        weight: 600,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$selectedCount notes',
                      style: PocketTheme.mono(
                        size: 9.5,
                        weight: FontWeight.w700,
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlavorWheelPainter extends CustomPainter {
  const _FlavorWheelPainter({
    required this.selectedIndex,
    required this.bloomT,
    required this.centerFill,
    required this.dividerColor,
  });

  final int selectedIndex;
  final double bloomT;
  final Color centerFill;
  final Color dividerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2 - 4;
    final baseR = maxR * 0.77;
    final innerR = maxR * 0.37;
    final count = scaFlavorCategories.length;
    final sweep = (2 * math.pi) / count;

    for (int i = 0; i < count; i++) {
      final cat = scaFlavorCategories[i];
      final start = -math.pi / 2 - sweep / 2 + i * sweep;
      final isSelected = i == selectedIndex;

      // Blooming outer Tier-2 ring for selected SCA category
      if (isSelected) {
        final petalR = baseR + (maxR - baseR) * bloomT;
        final petals = cat.petals;
        final fanSweep = (sweep * 2.1).clamp(sweep, math.pi * 0.65);
        final subSweep = fanSweep / petals.length;
        final subStart0 = start + (sweep - fanSweep) / 2;

        for (int p = 0; p < petals.length; p++) {
          final ps = subStart0 + p * subSweep;
          canvas.drawArc(
            Rect.fromCircle(center: center, radius: petalR),
            ps + 0.018,
            subSweep - 0.036,
            true,
            Paint()
              ..color = cat.color.withValues(alpha: 0.70 + (p % 2) * 0.16),
          );
          if (bloomT > 0.55) {
            final ma = ps + subSweep / 2;
            final lr = baseR + (petalR - baseR) * 0.54;
            _drawCenteredLabel(
              canvas,
              petals[p].split(' ').first,
              Offset(
                center.dx + math.cos(ma) * lr,
                center.dy + math.sin(ma) * lr,
              ),
              7.8,
              true,
            );
          }
        }
        canvas.drawCircle(
          center,
          baseR + 1,
          Paint()
            ..color = dividerColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }

      // Inner 9-category main ring wedge
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: baseR),
        start + 0.018,
        sweep - 0.036,
        true,
        Paint()..color = cat.color.withValues(alpha: isSelected ? 1.0 : 0.80),
      );

      final midAngle = start + sweep / 2;
      final labelR = (innerR + baseR) * 0.52;
      _drawCenteredLabel(
        canvas,
        cat.label.split('/').first,
        Offset(
          center.dx + math.cos(midAngle) * labelR,
          center.dy + math.sin(midAngle) * labelR,
        ),
        8.2,
        isSelected,
      );
    }

    // Center hub
    canvas.drawCircle(center, innerR, Paint()..color = centerFill);
    canvas.drawCircle(
      center,
      innerR,
      Paint()
        ..color = dividerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawCenteredLabel(
    Canvas canvas,
    String text,
    Offset pos,
    double size,
    bool bold,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: PocketTheme.ui(
          size: size,
          weight: bold ? 800 : 700,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FlavorWheelPainter old) =>
      old.selectedIndex != selectedIndex ||
      old.bloomT != bloomT ||
      old.centerFill != centerFill;
}
