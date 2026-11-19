import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/components/empty_state.dart';
import '../components/news_card.dart';
import '../provider/news_provider.dart';
import 'news_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      context.read<SearchNewsProvider>().setSearch('');
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      context.read<SearchNewsProvider>().setSearch(value.trim());
    });
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    context.read<SearchNewsProvider>().setSearch(value.trim());
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    context.read<SearchNewsProvider>().setSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SearchNewsProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Image.asset(
                  isDark
                      ? 'assets/images/logo_nexo_black.png'
                      : 'assets/images/logo_nexo_white.png',
                  width: 160,
                  height: 55,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar noticias o temas',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Expanded(
            child: state.search.isEmpty
                ? const EmptyState(
                    icon: Icons.manage_search,
                    title: 'Encuentra lo que te interesa',
                    message: 'Escribe una palabra para buscar noticias',
                  )
                : state.loading && state.news.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: state.refresh,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (event) {
                        if (event.metrics.pixels >=
                            event.metrics.maxScrollExtent - 250) {
                          state.loadMore();
                        }
                        return false;
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          Text(
                            '${state.news.length} resultados cargados para “${state.search}”',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),

                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(state.error!),
                            ),

                          const SizedBox(height: 16),

                          if (state.news.isEmpty)
                            const SizedBox(
                              height: 280,
                              child: EmptyState(
                                icon: Icons.search_off,
                                title: 'Sin resultados',
                                message: 'Prueba con otras palabras',
                              ),
                            ),

                          ...state.news.map(
                            (news) => NewsCard(
                              news: news,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NewsDetailScreen(news: news),
                                ),
                              ),
                            ),
                          ),

                          if (state.loadingMore)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
