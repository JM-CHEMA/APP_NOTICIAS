import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_text_field.dart';
import '../helpers/providers/auth_provider.dart';
import '../utils/validators.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(_email.text, _password.text);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Error al iniciar sesión.')),
      );
    }
  }

  Future<void> _resetPassword() async {
    if (Validators.email(_email.text) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe primero un correo válido.')),
      );
      return;
    }

    final sent = await context.read<AuthProvider>().resetPassword(_email.text);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Revisa tu correo para recuperar tu contraseña.'
              : 'No fue posible enviar el correo.',
        ),
      ),
    );
  }

  void _continueWithoutAccount() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.asset(
                      isDark
                          ? 'assets/images/logo_nexo_black.png'
                          : 'assets/images/logo_nexo_white.png',
                      width: 190,
                      height: 75,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 48),

                  const Text(
                    'Bienvenid@',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text('Las noticias que importan, en un solo lugar.'),

                  const SizedBox(height: 28),

                  CustomTextField(
                    controller: _email,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),

                  const SizedBox(height: 14),

                  CustomTextField(
                    controller: _password,
                    label: 'Contraseña',
                    obscureText: true,
                    validator: Validators.password,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: auth.busy ? null : _login,
                      child: Text(auth.busy ? 'Entrando...' : 'Iniciar sesión'),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text('¿Aún no tienes cuenta? Regístrate'),
                    ),
                  ),

                  Center(
                    child: TextButton(
                      onPressed: _continueWithoutAccount,
                      child: const Text('Continuar sin cuenta'),
                    ),
                  ),

                  if (!auth.firebaseReady)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Configura Firebase para habilitar el acceso.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
