import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/app_provider.dart';
import '../provider/auth_provider.dart';
import '../../news/provider/news_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final offline = context.watch<NewsProvider>().offline;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const ListTile(
            title: Text('Apariencia'),
            subtitle: Text('Personaliza cómo ves Nexo Noticias'),
            leading: Icon(Icons.light_mode_outlined),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: app.themeMode == ThemeMode.dark,
            onChanged: app.setDarkMode,
          ),

          ListTile(
            leading: const Icon(Icons.wifi_off_outlined),
            title: const Text('Modo sin conexión'),
            subtitle: Text(
              offline
                  ? 'Mostrando noticias locales'
                  : 'Caché disponible al perder la conexión',
            ),
          ),
          if (auth.user != null) ...[
            const Divider(height: 30),
            ListTile(
              title: const Text(
                'Eliminar cuenta',
                style: TextStyle(color: Colors.red),
              ),
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              onTap: () => _deleteAccount(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
          'Se borraran ajustes y comentarios que hallas hecho',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await auth.userService.deleteAccount(user);
      if (context.mounted) Navigator.pop(context);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.service.readableError(error))),
        );
      }
    }
  }
}
