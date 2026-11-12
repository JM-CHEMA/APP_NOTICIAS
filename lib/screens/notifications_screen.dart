import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/providers/auth_provider.dart';
import '../helpers/providers/news_provider.dart';
import '../helpers/providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final categories = context.watch<NewsProvider>().categories;
    final state = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('Noticias según tus intereses'),
            subtitle: Text(
              'Selecciona las categorías de las que quieres recibir avisos.',
            ),
          ),

          const SizedBox(height: 20),

          if (!auth.firebaseReady)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Configura Firebase antes de activar notificaciones.',
              ),
            ),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),

          if (categories.isEmpty)
            const ListTile(title: Text('Categorías aún no disponibles')),

          ...categories.map(
            (category) => SwitchListTile(
              title: Text(category.name),
              secondary: Icon(_categoryIcon(category.name)),
              value: state.enabledCategories.contains(category.id),
              onChanged: !auth.firebaseReady || state.updatingId != null
                  ? null
                  : (enabled) => context.read<NotificationProvider>().toggle(
                      category.id,
                      enabled,
                    ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  IconData _categoryIcon(String categoryName) {
    switch (categoryName.toLowerCase().trim()) {
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

      case 'nacional':
        return Icons.flag_outlined;

      case 'política':
      case 'politica':
        return Icons.account_balance_outlined;

      case 'sin-categoría':
      case 'sin-categoria':
        return Icons.category_outlined;

      default:
        return Icons.article_outlined;
    }
  }
}
