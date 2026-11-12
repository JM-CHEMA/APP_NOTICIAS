abstract final class Validators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null;
  static String? email(String? value) {
    if (requiredText(value) != null) return 'Introduce tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) return 'Correo no válido';
    return null;
  }
  static String? password(String? value) => (value ?? '').length < 8
      ? 'Escribe al menos 8 caracteres' : null;
  static String? phone(String? value) =>
      value != null && value.isNotEmpty && !RegExp(r'^\+?[0-9\s-]{7,18}$').hasMatch(value.trim())
          ? 'Teléfono no válido' : null;
}
