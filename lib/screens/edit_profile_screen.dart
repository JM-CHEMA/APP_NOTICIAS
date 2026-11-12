import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../helpers/providers/auth_provider.dart';
import '../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _initialized = false;
  String? _imageUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) { _initialized = true; _load(); }
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    _name.text = user.displayName ?? '';
    try {
      final profile = await auth.userService.watchProfile(user.uid).first;
      if (!mounted || profile == null) return;
      setState(() {
        _name.text = profile.name;
        _phone.text = profile.phone;
        _imageUrl = profile.imageUrl;
      });
    } catch (_) { /* Continúa con nombre de Auth si Firestore falla. */ }
  }

  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await auth.userService.updateProfile(user, name: _name.text, phone: _phone.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar el perfil.')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  Future<void> _pickImage() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery,
      maxWidth: 1100, imageQuality: 78);
    if (selected == null) return;
    final filename = selected.name.toLowerCase();
    if (!filename.endsWith('.png') && !filename.endsWith('.jpg') && !filename.endsWith('.jpeg')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una imagen JPG o PNG.')),
        );
      }
      return;
    }
    final bytes = await selected.readAsBytes();
    final type = filename.endsWith('.png') ? 'image/png' : 'image/jpeg';
    setState(() => _saving = true);
    try {
      final url = await auth.userService.uploadAvatar(user, bytes, type);
      if (mounted) setState(() => _imageUrl = url);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la fotografía. Revisa Firebase Storage.')),
        );
      }
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(28), children: [
        Center(child: Column(children: [
          CircleAvatar(radius: 48, backgroundImage: _imageUrl == null ? null : NetworkImage(_imageUrl!),
            child: _imageUrl == null ? const Icon(Icons.person, size: 46) : null),
          TextButton.icon(onPressed: _saving ? null : _pickImage,
            icon: const Icon(Icons.edit), label: const Text('Cambiar fotografía')),
          const Text('JPG o PNG · Máx. 5 MB', style: TextStyle(fontSize: 11)),
        ])),
        const SizedBox(height: 30),
        Form(key: _form, child: Column(children: [
          TextFormField(controller: _name, validator: Validators.requiredText,
            decoration: const InputDecoration(labelText: 'Nombre completo')),
          const SizedBox(height: 16),
          TextFormField(initialValue: user?.email ?? '', readOnly: true,
            decoration: const InputDecoration(labelText: 'Correo electrónico',
              helperText: 'El correo no se modifica desde este formulario.')),
          const SizedBox(height: 16),
          TextFormField(controller: _phone, validator: Validators.phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Teléfono')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Guardando...' : 'Guardar cambios'))),
        ])),
      ])),
    );
  }
}
