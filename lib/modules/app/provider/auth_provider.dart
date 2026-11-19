import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../service/auth_service.dart';
import '../service/user_service.dart';

/// Estado de la sesión: Authentication y el perfil de Firestore son
/// operaciones independientes. La escritura del perfil no bloquea el login.
class AuthProvider extends ChangeNotifier {
  final bool firebaseReady;
  final AuthService service;
  final UserService userService;

  AuthProvider({
    required this.firebaseReady,
    required this.service,
    required this.userService,
  }) {
    if (firebaseReady) {
      _subscription = service.authChanges.listen((value) {
        user = value;
        notifyListeners();
      });
      user = service.currentUser;
    }
  }

  StreamSubscription<User?>? _subscription;
  User? user;
  bool busy = false;
  String? error;

  bool get isLoggedIn => user != null;

  /// Intenta guardar los datos básicos en Firestore, pero no bloquea la sesión.
  /// Si falla, el error aparecerá en la consola para poder diagnosticarlo.
  Future<void> _syncProfile(User account, {String? name}) async {
    try {
      await userService.ensureProfile(account, name: name);
    } catch (e) {
      debugPrint('No se pudo sincronizar el perfil en Firestore: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (!firebaseReady) {
      error = 'Firebase no está configurado todavía.';
      notifyListeners();
      return false;
    }

    busy = true;
    error = null;
    notifyListeners();

    try {
      // Esta es la única operación que esperamos para confirmar el acceso.
      final credential = await service.signIn(email, password);
      final signedInUser = credential.user ?? service.currentUser;

      if (signedInUser == null) {
        error = 'No fue posible confirmar la sesión.';
        return false;
      }

      user = signedInUser;

      // La escritura de Firestore continúa independientemente del login.
      // Un fallo del perfil NO invalida una autenticación correcta.
      unawaited(_syncProfile(signedInUser));
      return true;
    } catch (e) {
      debugPrint('Error de Firebase Authentication al iniciar sesión: $e');
      error = service.readableError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    if (!firebaseReady) {
      error = 'Firebase no está configurado todavía.';
      notifyListeners();
      return false;
    }

    busy = true;
    error = null;
    notifyListeners();

    try {
      final credential = await service.register(email, password, name);
      final registeredUser = credential.user ?? service.currentUser;

      if (registeredUser == null) {
        error = 'No fue posible confirmar la nueva cuenta.';
        return false;
      }

      user = registeredUser;
      // Registrar la cuenta y guardar su perfil son pasos independientes.
      unawaited(_syncProfile(registeredUser, name: name));
      return true;
    } catch (e) {
      debugPrint('Error al registrar la cuenta: $e');
      error = service.readableError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await service.signOut();
    user = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await service.resetPassword(email);
      return true;
    } catch (e) {
      error = service.readableError(e);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
