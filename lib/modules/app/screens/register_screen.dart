import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/custom_text_field.dart';
import '../provider/auth_provider.dart';
import '../../../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_form.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      _name.text,
      _email.text,
      _password.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'No se pudo registrar.')),
      );
    }
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

                  const SizedBox(height: 34),

                  const Text(
                    'Crea tu cuenta',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Únete a una comunidad que quiere entender el mundo.',
                  ),

                  const SizedBox(height: 24),

                  CustomTextField(
                    controller: _name,
                    label: 'Nombre completo',
                    validator: Validators.requiredText,
                  ),

                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: _email,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),

                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: _password,
                    label: 'Contraseña',
                    obscureText: true,
                    validator: Validators.password,
                  ),

                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: _repeat,
                    label: 'Confirmar contraseña',
                    obscureText: true,
                    validator: (value) => value != _password.text
                        ? 'Las contraseñas no coinciden'
                        : null,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: auth.busy ? null : _register,
                      child: Text(auth.busy ? 'Creando...' : 'Crear cuenta'),
                    ),
                  ),

                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('¿Ya tienes cuenta? Inicia sesión'),
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
