import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_noticias/modules/news/models/news_model.dart';
import 'package:app_noticias/modules/news/service/bookmark_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('separación: invitado, cuenta A y cuenta B', () async {
    final service = BookmarkService();
    await service.saveIds({1, 2});
    await service.saveIds({3}, userId: 'A');
    await service.saveIds({4}, userId: 'B');

    expect(await service.loadIds(), {1, 2});
    expect(await service.loadIds(userId: 'A'), {3});
    expect(await service.loadIds(userId: 'B'), {4});
  });

  test('se conservan artículos completos en almacenamiento local', () async {
    final service = BookmarkService();
    final news = NewsModel(
      id: 8,
      title: 'Nota guardada',
      content: '<p>Contenido de prueba</p>',
      date: DateTime(2026, 11, 11),
    );
    await service.saveIds({8}, userId: 'A');
    await service.saveStory(news, userId: 'A');

    final result = await service.loadStories({8}, userId: 'A');
    expect(result[8]?.title, 'Nota guardada');
    expect(result[8]?.content, '<p>Contenido de prueba</p>');
    expect(await service.loadStories({8}, userId: 'B'), isEmpty);
  });

  test('importación de invitado queda registrada por cuenta', () async {
    final service = BookmarkService();
    await service.markGuestIdsImported('A', {1, 3});
    expect(await service.importedGuestIds('A'), {1, 3});
    expect(await service.importedGuestIds('B'), isEmpty);
  });
}
