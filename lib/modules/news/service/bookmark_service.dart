import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_model.dart';

/// Caché local. Invitados y cuentas autenticadas usan espacios separados.
/// Las claves anteriores (sin UID) se conservan como favoritos del dispositivo.
class BookmarkService {
  static const String _guestIdsKey = 'bookmarked_news_ids';

  String _idsKey(String? uid) =>
      uid == null ? _guestIdsKey : 'bookmarked_news_ids_user_$uid';

  String _storyKey(int id, String? uid) =>
      uid == null ? 'saved_news_$id' : 'saved_news_user_${uid}_$id';

  String _importedKey(String uid) => 'imported_guest_bookmarks_$uid';

  Future<Set<int>> loadIds({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_idsKey(userId)) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> saveIds(Set<int> ids, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_idsKey(userId), ids.map((id) => '$id').toList());
  }

  Future<void> saveStory(NewsModel news, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storyKey(news.id, userId),
      jsonEncode(news.toJson()),
    );
  }

  Future<Map<int, NewsModel>> loadStories(
    Set<int> ids, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stories = <int, NewsModel>{};
    for (final id in ids) {
      final raw = prefs.getString(_storyKey(id, userId));
      if (raw == null) continue;
      try {
        stories[id] = NewsModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {
        // No se rompe la lista por una noticia almacenada corrupta.
      }
    }
    return stories;
  }

  Future<void> removeStory(int id, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storyKey(id, userId));
  }

  /// Registro de los IDs del invitado ya importados a una cuenta concreta.
  /// Permite importar nuevos favoritos del invitado más adelante.
  Future<Set<int>> importedGuestIds(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_importedKey(uid)) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> markGuestIdsImported(String uid, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _importedKey(uid),
      ids.map((id) => '$id').toList(),
    );
  }
}
