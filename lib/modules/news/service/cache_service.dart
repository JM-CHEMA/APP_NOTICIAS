import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_model.dart';

/// Caché de texto: las imágenes remotas no están garantizadas sin conexión.
class CacheService {
  String _key(String search, int? categoryId) =>
      'cached_news_${Uri.encodeComponent(search)}_${categoryId ?? 'all'}';

  Future<void> saveFirstPage(
    List<NewsModel> news, {
    String search = '',
    int? categoryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(search, categoryId),
      jsonEncode(news.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<NewsModel>> loadFirstPage({
    String search = '',
    int? categoryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(search, categoryId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
