import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../service/comment_service.dart';

/// Mediador entre pantalla y Firestore: ninguna pantalla construye rutas de BD.
class CommentProvider extends ChangeNotifier {
  final CommentService service;
  CommentProvider(this.service);

  Stream<List<CommentModel>> watchNewsComments(int newsId) =>
      service.watchComments(newsId);
  Future<void> publish(int newsId, User user, String text) =>
      service.addComment(newsId: newsId, user: user, content: text);
  Future<void> edit(CommentModel comment, User user, String text) =>
      service.editComment(comment, user, text);
  Future<void> remove(CommentModel comment, User user) =>
      service.deleteComment(comment, user);
}
