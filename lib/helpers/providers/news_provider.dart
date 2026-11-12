import 'package:flutter/foundation.dart';
import '../../models/news_model.dart';
import '../../models/category_model.dart';
import '../../services/news_service.dart';
import '../../services/cache_service.dart';

/// Presentación: organiza las consultas, sin construir URLs ni widgets.
class NewsProvider extends ChangeNotifier {
  final NewsService service;
  final CacheService cache;
  NewsProvider({required this.service, required this.cache});
  List<NewsModel> news = [];
  List<CategoryModel> categories = [];
  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  bool offline = false;
  String? error;
  String search = '';
  int? selectedCategoryId;
  int _page = 0;
  int _generation = 0;

  Future<void> initialize() async {
    await Future.wait([refresh(), loadCategories()]);
  }

  Future<void> loadCategories() async {
    try { categories = await service.getCategories(); notifyListeners(); }
    catch (_) { /* La lista de noticias funciona aunque fallen las categorías. */ }
  }

  Future<void> setSearch(String query) async {
    if (search == query.trim()) return;
    search = query.trim();
    news = []; // No mostramos noticias del filtro anterior durante la nueva búsqueda.
    hasMore = true;
    await refresh();
  }

  Future<void> setCategory(int? id) async {
    if (selectedCategoryId == id) return;
    selectedCategoryId = id;
    news = [];
    hasMore = true;
    await refresh();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final query = search;
    final category = selectedCategoryId;
    loading = true;
    loadingMore = false;
    error = null;
    notifyListeners();
    try {
      final result = await service.getNews(search: query, categoryId: category);
      if (generation != _generation) return;
      news = result.items;
      _page = 1;
      hasMore = _page < result.totalPages;
      offline = false;
      await cache.saveFirstPage(news, search: query, categoryId: category);
    } catch (_) {
      if (generation != _generation) return;
      final saved = await cache.loadFirstPage(search: query, categoryId: category);
      if (generation != _generation) return;
      offline = true;
      if (saved.isNotEmpty) {
        news = saved;
        _page = 1;
        hasMore = false;
        error = 'No fue posible actualizar. Mostrando noticias guardadas.';
      } else {
        // Si no hay caché, preservamos los resultados previos.
        error = 'No se pudo conectar con el servidor. Revisa internet.';
      }
    } finally {
      if (generation == _generation) { loading = false; notifyListeners(); }
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore || offline) return;
    final generation = _generation;
    loadingMore = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final result = await service.getNews(page: next, search: search, categoryId: selectedCategoryId);
      if (generation != _generation) return;
      final existing = news.map((e) => e.id).toSet();
      news = [...news, ...result.items.where((item) => !existing.contains(item.id))];
      _page = next;
      hasMore = next < result.totalPages && result.items.isNotEmpty;
    } catch (_) {
      if (generation == _generation) error = 'No se pudieron cargar más noticias.';
    } finally {
      if (generation == _generation) { loadingMore = false; notifyListeners(); }
    }
  }

  @override
  void dispose() { service.dispose(); super.dispose(); }
}

/// Búsqueda independiente para no alterar el listado de Inicio.
class SearchNewsProvider extends NewsProvider {
  SearchNewsProvider({required super.service, required super.cache});
}
