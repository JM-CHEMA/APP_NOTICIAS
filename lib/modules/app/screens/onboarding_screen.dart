import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo_nexo.png',
                        width: 180,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 48),

                    Text(
                      'BIENVENIDO A NEXO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: colors.primary,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Entiende el mundo,\nno solo lo leas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Historias esenciales, contexto y análisis para estar al día.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 38),

                    Card(
                      elevation: 0,
                      color: colors.primary.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: colors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            leading: Icon(
                              Icons.explore_outlined,
                              color: colors.primary,
                              size: 28,
                            ),
                            title: const Text(
                              'Tu actualidad, a tu manera',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Explora noticias, categorías y encuentra los temas que te interesan.',
                            ),
                          ),

                          Divider(
                            height: 1,
                            indent: 18,
                            endIndent: 18,
                            color: colors.outlineVariant,
                          ),

                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            leading: Icon(
                              Icons.bookmark_outline_rounded,
                              color: colors.primary,
                              size: 28,
                            ),
                            title: const Text(
                              'Guarda las historias que importan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              'Guarda tus lecturas y recibe novedades de tus temas favoritos.',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Comenzar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        '¿No tienes una cuenta? Crear cuenta',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
