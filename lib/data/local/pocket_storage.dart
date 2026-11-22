import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline-first local persistence backed by SharedPreferences
/// with dual-slot shadow backup (`_key` + `_backupKey`) so interrupted writes
/// or partial corruption never lose the user's coffee beans, recipes, or logs.
class PocketStorage {
  static const String _key = 'pocket_brew_state_v1';
  static const String _backupKey = 'pocket_brew_state_v1_backup';
  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> _getPrefs() async {
    return _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, dynamic>?> readState() async {
    try {
      final prefs = await _getPrefs();
      final primary = _tryDecodeMap(prefs.getString(_key));
      if (primary != null) return primary;

      // Fallback to last-known-good shadow backup if primary slot was corrupted.
      final backup = _tryDecodeMap(prefs.getString(_backupKey));
      if (backup != null) {
        await prefs.setString(_key, jsonEncode(backup));
        return backup;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _tryDecodeMap(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeState(Map<String, dynamic> data) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(data);

      // Rotate current valid primary state into shadow backup before overwriting.
      final existingPrimary = prefs.getString(_key);
      if (existingPrimary != null &&
          existingPrimary.isNotEmpty &&
          _tryDecodeMap(existingPrimary) != null) {
        await prefs.setString(_backupKey, existingPrimary);
      }

      await prefs.setString(_key, encoded);
    } catch (_) {
      // Safe no-op in constrained environments
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_key);
      await prefs.remove(_backupKey);
    } catch (_) {}
  }
}
