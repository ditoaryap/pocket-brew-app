enum BrewMode {
  hot,
  iced;

  String get label => this == hot ? 'Hot V60' : 'Japanese Iced';
  String get shortBadge => this == hot ? 'Hot V60' : 'Japanese';
}

/// 2-option Japanese Iced workflow confirmed by user:
/// - [iceFirst]: Ice cubes sit inside the server before brewing (rinse filter at sink; swirl server at finish).
/// - [brewFirst]: Brew hot concentrate into server first, then pour over ice cubes at the end.
enum IcedMethod {
  iceFirst,
  brewFirst;

  String get id => this == iceFirst ? 'ice_first' : 'brew_first';
  String get label =>
      this == iceFirst ? 'Es Duluan (Server)' : 'Seduh Dulu → Es';
  String get shortLabel => this == iceFirst ? 'Es Duluan' : 'Seduh Dulu';

  static IcedMethod fromId(String? value) =>
      value == 'brew_first' ? IcedMethod.brewFirst : IcedMethod.iceFirst;
}

enum UnitMode {
  gram,
  ml,
  oz;

  String get label => switch (this) {
        gram => 'g',
        ml => 'ml',
        oz => 'oz',
      };

  static UnitMode fromString(String? s) => switch (s) {
        'ml' => UnitMode.ml,
        'oz' => UnitMode.oz,
        _ => UnitMode.gram,
      };
}

enum TempUnit {
  celsius,
  fahrenheit;

  String get symbol => this == celsius ? '°C' : '°F';
  static TempUnit fromString(String? s) =>
      s == 'fahrenheit' ? TempUnit.fahrenheit : TempUnit.celsius;
}

enum RoastLevel {
  light,
  lightMedium,
  medium,
  mediumDark,
  dark;

  String get label => switch (this) {
        light => 'Light Roast',
        lightMedium => 'Light-Medium Roast',
        medium => 'Medium Roast',
        mediumDark => 'Medium-Dark Roast',
        dark => 'Dark Roast',
      };

  String get shortLabel => switch (this) {
        light => 'Light',
        lightMedium => 'Light-Med',
        medium => 'Medium',
        mediumDark => 'Med-Dark',
        dark => 'Dark',
      };

  static RoastLevel fromString(String? s) => switch (s) {
        'lightMedium' => RoastLevel.lightMedium,
        'medium' => RoastLevel.medium,
        'mediumDark' => RoastLevel.mediumDark,
        'dark' => RoastLevel.dark,
        _ => RoastLevel.light,
      };
}

enum BeanCondition {
  sealedNew,
  openedUsed;

  String get label =>
      this == sealedNew ? 'Baru (Utuh)' : 'Sudah Terpakai';

  static BeanCondition fromString(String? s) =>
      s == 'openedUsed' ? BeanCondition.openedUsed : BeanCondition.sealedNew;
}

enum PourPattern {
  spiral,
  center,
  pulse,
  osmotic,
  swirl;

  String get label => switch (this) {
        spiral => 'Spiral',
        center => 'Center',
        pulse => 'Pulse',
        osmotic => 'Osmotic',
        swirl => 'Swirl',
      };

  static PourPattern fromString(String? s) => switch (s) {
        'center' => PourPattern.center,
        'pulse' => PourPattern.pulse,
        'osmotic' => PourPattern.osmotic,
        'swirl' => PourPattern.swirl,
        _ => PourPattern.spiral,
      };
}

enum PourRate {
  slow,
  medium,
  fast;

  double get gramsPerSec => switch (this) {
        slow => 3.0,
        medium => 6.0,
        fast => 9.0,
      };

  String get shortName => switch (this) {
        slow => 'Pelan',
        medium => 'Sedang',
        fast => 'Cepat',
      };

  String get label => switch (this) {
        slow => 'Pelan (~30 ml/10 dtk)',
        medium => 'Sedang (~60 ml/10 dtk)',
        fast => 'Cepat (~90 ml/10 dtk)',
      };

  static PourRate fromString(String? s) => switch (s) {
        'slow' => PourRate.slow,
        'fast' => PourRate.fast,
        _ => PourRate.medium,
      };
}

enum TasteFeeling {
  sourSharp,
  balancedSweet,
  bitterDry,
  wateryWeak;

  String get title => switch (this) {
        sourSharp => 'Asam tajam / kecut',
        balancedSweet => 'Pas & manis',
        bitterDry => 'Pahit / sepat kering',
        wateryWeak => 'Encer / kurang tebal',
      };

  String get subtitle => switch (this) {
        sourSharp => 'Biasanya turun terlalu cepat',
        balancedSweet => 'Seimbang — Favorit!',
        bitterDry => 'Biasanya terlalu lama/halus',
        wateryWeak => 'Rasio air terlalu banyak',
      };

  static TasteFeeling fromString(String? s) => switch (s) {
        'sourSharp' => TasteFeeling.sourSharp,
        'bitterDry' => TasteFeeling.bitterDry,
        'wateryWeak' => TasteFeeling.wateryWeak,
        _ => TasteFeeling.balancedSweet,
      };
}

enum AppThemePref {
  light,
  dark,
  system;

  String get label => switch (this) {
        light => 'Terang',
        dark => 'Gelap',
        system => 'Ikuti HP',
      };

  static AppThemePref fromString(String? s) => switch (s) {
        'dark' => AppThemePref.dark,
        'system' => AppThemePref.system,
        _ => AppThemePref.light,
      };
}
