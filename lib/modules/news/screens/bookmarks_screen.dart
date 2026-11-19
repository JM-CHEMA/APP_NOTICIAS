import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/components/empty_state.dart';
import '../components/news_card.dart';
import '../provider/bookmark_provider.dart';
import '../provider/news_provider.dart';
import '../models/news_model.dart';
import 'news_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<BookmarkProvider>();
    final visible = context.watch<NewsProvider>().news;
    final stories = <NewsModel>[];

    for (final id in saved.savedIds) {
      final stored = saved.savedStories[id];
      if (stored != null) {
        stories.add(stored);
      } else {
        for (final item in visible) {
          if (item.id == id) {
            stories.add(item);
            break;
          }
        }
      }
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Guardados',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              saved.isCloudEnabled
                  ? 'Sincronizados con tu cuenta y guardados en este dispositivo'
                  : 'Guardados únicamente en este dispositivo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (saved.canImportGuest)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tienes ${saved.guestIdsToImport.length} favoritos anteriores en este dispositivo.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Puedes copiarlos a esta cuenta. No se borrarán del dispositivo.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: saved.importing
                            ? null
                            : () => context
                                  .read<BookmarkProvider>()
                                  .importGuestBookmarks(),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          saved.importing
                              ? 'Importando...'
                              : 'Importar a mi cuenta',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (saved.syncError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                saved.syncError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (saved.loading) const LinearProgressIndicator(),
          Expanded(
            child: saved.savedIds.isEmpty
                ? const EmptyState(
                    icon: Icons.bookmark_border,
                    title: 'Sin noticias guardadas',
                    message: 'Guarda una noticia para verla aquí.',
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    children: [
                      ...stories.map(
                        (news) => NewsCard(
                          news: news,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => NewsDetailScreen(news: news),
                            ),
                          ),
                        ),
                      ),
                      if (stories.length < saved.savedIds.length)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Algunas noticias no tienen una copia local disponible.',
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
