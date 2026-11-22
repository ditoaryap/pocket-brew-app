/// Central application version & local database schema metadata.
/// Keep in sync with `version:` in `pubspec.yaml` when releasing updates.
class PocketVersion {
  PocketVersion._();

  static const String versionName = '1.0.0';
  static const int buildNumber = 1;
  static const int dbSchemaVersion = 1;

  static String get fullLabel => 'v$versionName (Build $buildNumber)';
}
