import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../helpers/providers/bookmark_provider.dart';
import '../utils/formatters.dart';
import 'news_picture.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback? onTap;
  const NewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<BookmarkProvider>().contains(news.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.40))),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: NewsPicture(url: news.imageUrl, height: 93, width: 100)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(shortDate(news.date).toUpperCase(), style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6,
                color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 4),
              Text(plainText(news.title), maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 7),
              Text('NEXO Actualidad', style: Theme.of(context).textTheme.bodySmall),
            ])),
            IconButton(
              tooltip: saved ? 'Quitar de guardados' : 'Guardar noticia',
              onPressed: () => context.read<BookmarkProvider>().toggle(news.id, news: news),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline,
                color: saved ? Theme.of(context).colorScheme.primary : null),
            ),
          ]),
        ),
      ),
    );
  }
}
