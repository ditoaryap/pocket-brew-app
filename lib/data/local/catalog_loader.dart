import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/models.dart';

class SeedCatalog {
  const SeedCatalog({
    required this.version,
    required this.grinders,
    required this.drippers,
    required this.filters,
    required this.recipes,
    required this.guides,
  });

  final String version;
  final List<GrinderSpec> grinders;
  final List<DripperSpec> drippers;
  final List<FilterSpec> filters;
  final List<BrewRecipe> recipes;
  final List<LearnGuide> guides;
}

class CatalogLoader {
  static SeedCatalog? _cached;

  static Future<SeedCatalog> loadBundled() async {
    if (_cached != null) return _cached!;
    final raw =
        await rootBundle.loadString('assets/catalog/catalog_seed_v1.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final catalog = SeedCatalog(
      version: map['catalog_version'] as String? ?? '1.0.0',
      grinders: (map['grinders'] as List<dynamic>)
          .map((e) => GrinderSpec.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      drippers: (map['drippers'] as List<dynamic>)
          .map((e) => DripperSpec.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      filters: (map['filters'] as List<dynamic>)
          .map((e) => FilterSpec.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      recipes: (map['recipes'] as List<dynamic>)
          .map((e) => BrewRecipe.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      guides: (map['guides'] as List<dynamic>)
          .map((e) => LearnGuide.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    _cached = catalog;
    return catalog;
  }
}
