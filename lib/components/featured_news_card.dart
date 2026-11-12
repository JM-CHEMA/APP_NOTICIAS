import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import '../helpers/providers/bookmark_provider.dart';
import '../utils/formatters.dart';
import 'news_picture.dart';

class FeaturedNewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback? onTap;
  const FeaturedNewsCard({super.key, required this.news, this.onTap});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<BookmarkProvider>().contains(news.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(height: 255, child: Stack(fit: StackFit.expand, children: [
        NewsPicture(url: news.imageUrl),
        const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xE6000000)]))),
        Positioned(top: 12, right: 12, child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.90),
          child: IconButton(
            onPressed: () => context.read<BookmarkProvider>().toggle(news.id, news: news),
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline, color: const Color(0xFF155EEF)),
          ),
        )),
        Positioned.fill(child: Material(color: Colors.transparent,
          child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF155EEF), borderRadius: BorderRadius.circular(5)),
                  child: const Text('EN PORTADA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Text(plainText(news.title), maxLines: 3, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'serif', color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 22, height: 1.08)),
                const SizedBox(height: 8),
                Text(shortDate(news.date), style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ]))),
        )),
      ])),
    );
  }
}
