import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment_model.dart';

class CommentService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _comments(int newsId) =>
      _db.collection('news_comments').doc('$newsId').collection('items');

  Stream<List<CommentModel>> watchComments(int newsId) => _comments(newsId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => CommentModel.fromDocument(newsId, doc))
            .toList(),
      );

  Future<void> addComment({
    required int newsId,
    required User user,
    required String content,
  }) async {
    final text = content.trim();
    if (text.isEmpty || text.length > 2000) {
      throw Exception('Escribe un comentario de hasta 2000 caracteres.');
    }
    await _comments(newsId).add({
      'newsId': newsId,
      'userId': user.uid,
      'authorName': user.displayName?.isNotEmpty == true
          ? user.displayName
          : (user.email ?? 'Usuario'),
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editComment(CommentModel comment, User user, String text) async {
    if (comment.userId != user.uid) {
      throw Exception('No tienes permiso para editar.');
    }
    if (text.trim().isEmpty || text.trim().length > 2000) {
      throw Exception('Comentario inválido.');
    }
    await _comments(comment.newsId).doc(comment.id).update({
      'content': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(CommentModel comment, User user) async {
    if (comment.userId != user.uid) {
      throw Exception('No tienes permiso para eliminar.');
    }
    await _comments(comment.newsId).doc(comment.id).delete();
  }
}
