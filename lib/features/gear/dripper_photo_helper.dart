/// Maps dripper geometry/name to bundled offline real photographs
/// sourced from Wikimedia Commons (stored locally in assets/images/drippers/).
class DripperPhotoHelper {
  static const String coneAsset = 'assets/images/drippers/cone_v60.jpg';
  static const String flatAsset = 'assets/images/drippers/flat_kalita.jpg';
  static const String hybridAsset =
      'assets/images/drippers/hybrid_immersion.jpg';

  static String? assetForGeometry(String geometry, {String name = ''}) {
    final g = '${geometry.toLowerCase()} ${name.toLowerCase()}';
    if (g.contains('hybrid') ||
        g.contains('switch') ||
        g.contains('clever') ||
        g.contains('katup') ||
        g.contains('rendam') ||
        g.contains('immersion')) {
      return hybridAsset;
    }
    if (g.contains('flat') ||
        g.contains('datar') ||
        g.contains('kalita') ||
        g.contains('b75') ||
        g.contains('april') ||
        g.contains('stagg')) {
      return flatAsset;
    }
    if (g.contains('cone') ||
        g.contains('kerucut') ||
        g.contains('v60') ||
        g.contains('origami') ||
        g.contains('kono') ||
        g.contains('60')) {
      return coneAsset;
    }
    return null;
  }
}
