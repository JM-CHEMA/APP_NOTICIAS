/// Una noticia normalizada. Nunca exponemos JSON a las pantallas.
class NewsModel {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final DateTime? date;
  final String? imageUrl;
  final String link;
  final List<int> categoryIds;

  const NewsModel({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt = '',
    this.date,
    this.imageUrl,
    this.link = '',
    this.categoryIds = const [],
  });

  /// Convierte tanto publicaciones reales como datos normalizados de la caché.
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    String rendered(dynamic value) => value is Map
        ? (value['rendered'] ?? '').toString()
        : (value ?? '').toString();

    final embedded = json['_embedded'];
    String? image = json['imageUrl']?.toString();
    if (image == null || image.isEmpty) {
      final media = embedded is Map ? embedded['wp:featuredmedia'] : null;
      if (media is List && media.isNotEmpty && media.first is Map) {
        image = (media.first as Map)['source_url']?.toString();
      }
      image ??= json['jetpack_featured_media_url']?.toString();
    }

    return NewsModel(
      id: (json['id'] as num).toInt(),
      title: rendered(json['title']),
      content: rendered(json['content']),
      excerpt: rendered(json['excerpt']),
      date: DateTime.tryParse((json['date'] ?? '').toString()),
      imageUrl: (image == null || image.isEmpty) ? null : image,
      link: (json['link'] ?? '').toString(),
      categoryIds: (json['categoryIds'] ?? json['categories']) is List
          ? ((json['categoryIds'] ?? json['categories']) as List)
              .whereType<num>().map((id) => id.toInt()).toList()
          : <int>[],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'content': content, 'excerpt': excerpt,
    'date': date?.toIso8601String(), 'imageUrl': imageUrl, 'link': link,
    'categoryIds': categoryIds,
  };
}
