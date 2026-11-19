import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_profile_model.dart';

class UserService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid);

  Stream<UserProfileModel?> watchProfile(String uid) => _ref(uid)
      .snapshots()
      .map(
        (snap) =>
            snap.exists ? UserProfileModel.fromJson(uid, snap.data()!) : null,
      );

  Future<void> ensureProfile(User user, {String? name}) => _ref(user.uid).set({
    'uid': user.uid,
    'email': user.email ?? '',
    'name': name ?? user.displayName ?? '',
  }, SetOptions(merge: true));

  Future<void> updateProfile(
    User user, {
    required String name,
    required String phone,
  }) async {
    await _ref(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'name': name.trim(),
      'phone': phone.trim(),
    }, SetOptions(merge: true));
    await user.updateDisplayName(name.trim());
  }

  Future<String> uploadAvatar(
    User user,
    Uint8List bytes,
    String contentType,
  ) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('La imagen excede 5 MB.');
    }
    final storageRef = FirebaseStorage.instance.ref(
      'profile_images/${user.uid}/avatar',
    );
    await storageRef.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await storageRef.getDownloadURL();
    await _ref(user.uid)
        .set({'imageUrl': url, 'uid': user.uid}, SetOptions(merge: true));
    return url;
  }

  /// La eliminación completa de datos relacionados requiere limpieza del backend.
  Future<void> deleteAccount(User user) async {
    // Firebase podría exigir reautenticación; en ese caso no borramos datos primero.
    await user.delete();
  }
}
