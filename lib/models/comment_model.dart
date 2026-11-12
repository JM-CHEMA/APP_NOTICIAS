import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final int newsId;
  final String userId;
  final String authorName;
  final String content;
  final DateTime? createdAt;
  const CommentModel({required this.id, required this.newsId, required this.userId,
    required this.authorName, required this.content, this.createdAt});

  factory CommentModel.fromDocument(int newsId, DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      id: doc.id, newsId: newsId, userId: (data['userId'] ?? '').toString(),
      authorName: (data['authorName'] ?? 'Usuario').toString(),
      content: (data['content'] ?? '').toString(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate() : null,
    );
  }
}
