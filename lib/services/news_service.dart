import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category_model.dart';
import '../models/news_model.dart';

class NewsPage {
  final List<NewsModel> items;
  final int totalPages;
  const NewsPage(this.items, this.totalPages);
}

/// Única clase que conoce las URLs de la API de WordPress.
class NewsService {
  static const String _host = 'news.freepi.io';
  final http.Client _client;
  NewsService({http.Client? client}) : _client = client ?? http.Client();

  Future<NewsPage> getNews({int page = 1, int perPage = 10,
      String search = '', int? categoryId}) async {
    final params = <String, String>{
      'page': '$page', 'per_page': '$perPage', '_embed': '1',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null) 'categories': '$categoryId',
    };
    final uri = Uri.https(_host, '/wp-json/wp/v2/posts', params);
    final response = await _client.get(uri).timeout(const Duration(seconds: 18));
    if (response.statusCode == 400 && page > 1) {
      // WordPress devuelve 400 al solicitar una página fuera de rango.
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['code'] == 'rest_post_invalid_page_number') {
        return const NewsPage([], 0);
      }
    }
    _ensureSuccess(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) throw const FormatException('La API no devolvió una lista.');
    final total = int.tryParse(response.headers['x-wp-totalpages'] ?? '') ?? 1;
    return NewsPage(decoded.map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e as Map))).toList(), total);
  }

  Future<List<CategoryModel>> getCategories() async {
    final uri = Uri.https(_host, '/wp-json/wp/v2/categories', {'per_page': '100'});
    final response = await _client.get(uri).timeout(const Duration(seconds: 18));
    _ensureSuccess(response);
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) throw const FormatException('Categorías inválidas.');
    return data.map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<NewsModel> getNewsById(int id) async {
    final response = await _client.get(Uri.https(_host, '/wp-json/wp/v2/posts/$id', {'_embed':'1'}))
        .timeout(const Duration(seconds: 18));
    _ensureSuccess(response);
    return NewsModel.fromJson(Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)) as Map));
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error del servidor (${response.statusCode}).');
    }
  }

  void dispose() => _client.close();
}
