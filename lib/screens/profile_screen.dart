import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/providers/auth_provider.dart';
import '../models/user_profile_model.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onOpenSaved;

  const ProfileScreen({super.key, this.onOpenSaved});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
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

          const SizedBox(height: 36),

          if (user == null) ...[
            const CircleAvatar(
              radius: 42,
              child: Icon(Icons.person_outline, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Estás leyendo como invitado',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Iniciar sesión'),
            ),
          ] else
            StreamBuilder<UserProfileModel?>(
              stream: auth.userService.watchProfile(user.uid),
              builder: (context, snapshot) {
                final profile = snapshot.data;

                final name = profile?.name.isNotEmpty == true
                    ? profile!.name
                    : (user.displayName ?? 'Usuario');

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: profile?.imageUrl != null
                          ? NetworkImage(profile!.imageUrl!)
                          : null,
                      child: profile?.imageUrl == null
                          ? const Icon(Icons.person, size: 42)
                          : null,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                        fontSize: 23,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      user.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                        child: const Text('Editar perfil'),
                      ),
                    ),

                    if (snapshot.hasError)
                      const Text(
                        'No se pudo cargar el perfil desde Firestore.',
                      ),
                  ],
                );
              },
            ),

          const SizedBox(height: 34),

          const Text(
            'MI CUENTA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 12),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notificaciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),

          if (user != null) ...[
            const SizedBox(height: 20),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await context.read<AuthProvider>().signOut();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión cerrada.')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
