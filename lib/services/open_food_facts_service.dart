import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/meal.dart';

class OFFResult {
  final String name;
  final int calories;
  final Macros macros;

  const OFFResult({required this.name, required this.calories, required this.macros});
}

class OpenFoodFactsService {
  static const _base = 'https://world.openfoodfacts.org/cgi/search.pl';

  Future<OFFResult?> searchByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      if ((body['status'] as int?) != 1) return null;
      final p = body['product'] as Map<String, dynamic>? ?? {};
      final name = (p['product_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return null;
      final n = p['nutriments'] as Map<String, dynamic>? ?? {};
      final cal = (n['energy-kcal_100g'] as num?)?.round() ?? 0;
      if (cal == 0) return null;
      return OFFResult(
        name: name,
        calories: cal,
        macros: Macros(
          protein: (n['proteins_100g'] as num?)?.round() ?? 0,
          carbs: (n['carbohydrates_100g'] as num?)?.round() ?? 0,
          fat: (n['fat_100g'] as num?)?.round() ?? 0,
        ),
      );
    } catch (e) {
      debugPrint('OFacts barcode error: $e');
      return null;
    }
  }

  Future<List<OFFResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '10',
        'fields': 'product_name,nutriments',
        'lc': 'ar',
      });
      final resp = await http.get(uri).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return [];

      final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final products = (body['products'] as List?) ?? [];

      final results = <OFFResult>[];
      for (final p in products) {
        final name = (p['product_name'] as String?)?.trim() ?? '';
        if (name.isEmpty) continue;
        final n = p['nutriments'] as Map<String, dynamic>? ?? {};
        final cal = (n['energy-kcal_100g'] as num?)?.round() ?? 0;
        if (cal == 0) continue;
        results.add(OFFResult(
          name: name,
          calories: cal,
          macros: Macros(
            protein: (n['proteins_100g'] as num?)?.round() ?? 0,
            carbs: (n['carbohydrates_100g'] as num?)?.round() ?? 0,
            fat: (n['fat_100g'] as num?)?.round() ?? 0,
          ),
        ));
      }
      return results;
    } catch (e) {
      debugPrint('OFacts search error: $e');
      return [];
    }
  }
}
