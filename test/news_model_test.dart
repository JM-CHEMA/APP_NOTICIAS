import 'package:flutter_test/flutter_test.dart';
import 'package:app_noticias/models/news_model.dart';

void main() {
  test('WordPress JSON se convierte en un modelo', () {
    final model = NewsModel.fromJson({
      'id': 51,
      'title': {'rendered': 'Noticia real'},
      'content': {'rendered': '<p>Hola</p>'},
      'excerpt': {'rendered': 'Hola'},
      'date': '2026-10-01T14:30:00',
      'categories': [2, 4],
      '_embedded': {'wp:featuredmedia': [
        {'source_url': 'https://example.com/media.jpg'}
      ]},
    });
    expect(model.id, 51);
    expect(model.title, 'Noticia real');
    expect(model.categoryIds, [2, 4]);
    expect(model.imageUrl, 'https://example.com/media.jpg');
    expect(model.content, '<p>Hola</p>');
  });

  test('Los modelos pueden recuperarse desde la caché JSON', () {
    const original = NewsModel(id: 123, title: 'Prueba', content: 'Contenido');
    final restored = NewsModel.fromJson(original.toJson());
    expect(restored.id, original.id);
    expect(restored.title, original.title);
  });
}
