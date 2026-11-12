import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> register(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  Future<void> signOut() => _auth.signOut();
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  String readableError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email': return 'El correo no es válido.';
        case 'user-not-found': case 'wrong-password': case 'invalid-credential':
          return 'Correo o contraseña incorrectos.';
        case 'email-already-in-use': return 'Este correo ya está registrado.';
        case 'weak-password': return 'Utiliza una contraseña más segura.';
        case 'network-request-failed': return 'Revisa tu conexión a internet.';
        case 'requires-recent-login': return 'Vuelve a iniciar sesión para continuar.';
        case 'too-many-requests': return 'Demasiados intentos. Prueba más tarde.';
      }
    }
    return 'No fue posible completar la operación. Inténtalo de nuevo.';
  }
}
