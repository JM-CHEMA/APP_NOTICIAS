import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../components/empty_state.dart';
import '../components/news_card.dart';
import '../components/featured_news_card.dart';
import '../helpers/providers/news_provider.dart';
import '../helpers/providers/auth_provider.dart';
import '../models/news_model.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NewsProvider>();
    final user = context.watch<AuthProvider>().user;

    final firstName = user?.displayName?.trim().split(' ').first;

    final greeting = firstName == null || firstName.isEmpty
        ? 'Bienvenid@'
        : 'Bienvenid@, $firstName';

    final isFirstLoading = state.loading && state.news.isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String categoryLabel = 'Para ti';

    for (final category in state.categories) {
      if (category.id == state.selectedCategoryId) {
        categoryLabel = category.name;
        break;
      }
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.refresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: (event) {
            if (event.metrics.pixels >= event.metrics.maxScrollExtent - 250) {
              state.loadMore();
            }
            return false;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  isDark
                      ? 'assets/images/logo_nexo_black.png'
                      : 'assets/images/logo_nexo_white.png',
                  width: 160,
                  height: 55,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                readOnly: true,
                onTap: onSearchTap,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar noticias, temas...',
                ),
              ),

              const SizedBox(height: 20),

              if (state.offline)
                _message(
                  context,
                  'Sin conexión: se muestran noticias guardadas.',
                ),

              if (state.error != null) _message(context, state.error!),

              const SizedBox(height: 20),

              Text(
                'Filtrar por categoría',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCategoryFilter(context, state),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 22),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          'Categoría: $categoryLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              if (isFirstLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(70),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.news.isEmpty)
                Column(
                  children: [
                    const SizedBox(height: 30),

                    const EmptyState(
                      icon: Icons.newspaper_outlined,
                      title: 'Sin noticias',
                      message: 'No hay contenido disponible para mostrar.',
                    ),

                    TextButton(
                      onPressed: state.refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                )
              else ...[
                Text(
                  'Historia destacada',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                FeaturedNewsCard(
                  news: state.news.first,
                  onTap: () => _open(context, state.news.first),
                ),

                const SizedBox(height: 26),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Últimas noticias',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    Text(
                      '${state.news.length} artículos',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                ...state.news
                    .skip(1)
                    .map(
                      (news) => NewsCard(
                        news: news,
                        onTap: () => _open(context, news),
                      ),
                    ),

                if (state.loadingMore)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context, NewsProvider state) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explorar categorías',
                style: Theme.of(sheetContext).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'Selecciona los temas que quieres explorar.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 18),

              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.55,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _categoryOption(sheetContext, state, 'Para ti', null),

                    ...state.categories.map(
                      (category) => _categoryOption(
                        sheetContext,
                        state,
                        category.name,
                        category.id,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _categoryOption(
    BuildContext context,
    NewsProvider state,
    String label,
    int? categoryId,
  ) {
    final colors = Theme.of(context).colorScheme;

    final isSelected = state.selectedCategoryId == categoryId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),

          leading: Icon(
            _categoryIcon(label),
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
          ),

          title: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          trailing: isSelected
              ? Icon(Icons.check_circle_rounded, color: colors.primary)
              : null,

          onTap: () {
            Navigator.of(context).pop();
            state.setCategory(categoryId);
          },
        ),
      ),
    );
  }

  IconData _categoryIcon(String categoryName) {
    switch (categoryName.toLowerCase().trim()) {
      case 'para ti':
        return Icons.auto_awesome_outlined;

      case 'comercio':
        return Icons.storefront_outlined;

      case 'deportes':
        return Icons.sports_soccer_outlined;

      case 'espectáculos':
      case 'espectaculos':
        return Icons.theater_comedy_outlined;

      case 'finanzas':
        return Icons.account_balance_wallet_outlined;

      case 'internacional':
        return Icons.public_outlined;

      case 'local':
        return Icons.location_on_outlined;

      case 'mercado de valores':
        return Icons.show_chart_rounded;

      default:
        return Icons.article_outlined;
    }
  }

  Widget _message(BuildContext context, String message) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Text(
      message,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 12,
      ),
    ),
  );

  void _open(BuildContext context, NewsModel news) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NewsDetailScreen(news: news)),
  );
}
