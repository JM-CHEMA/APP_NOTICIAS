import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_noticias/modules/news/service/news_service.dart';

void main() {
  test('La consulta usa search, categories y page', () async {
    Uri? requested;
    final service = NewsService(
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'title': {'rendered': 'Uno'},
              'content': {'rendered': 'Hola'},
            },
          ]),
          200,
          headers: {'x-wp-totalpages': '3'},
        );
      }),
    );
    final result = await service.getNews(
      page: 2,
      search: 'flutter',
      categoryId: 7,
    );
    expect(requested!.queryParameters['search'], 'flutter');
    expect(requested!.queryParameters['categories'], '7');
    expect(requested!.queryParameters['page'], '2');
    expect(result.totalPages, 3);
    expect(result.items.single.id, 1);
    service.dispose();
  });
}
