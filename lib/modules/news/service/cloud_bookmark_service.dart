import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/news_model.dart';

/// Una instantánea completa de los favoritos de una cuenta.
class CloudBookmarkSnapshot {
  final Map<int, NewsModel> stories;
  final bool fromCache;

  const CloudBookmarkSnapshot({required this.stories, required this.fromCache});
}

/// Servicio Firestore: no modifica widgets ni conoce el estado de navegación.
class CloudBookmarkService {
  final FirebaseFirestore db;

  CloudBookmarkService({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      db.collection('users').doc(uid).collection('bookmarks');

  Stream<CloudBookmarkSnapshot> watch(String uid) {
    return _collection(uid)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
          final stories = <int, NewsModel>{};
          for (final doc in snapshot.docs) {
            final id = int.tryParse(doc.id);
            if (id == null) continue;
            final raw = doc.data()['story'];
            if (raw is! Map) continue;
            try {
              final parsed = NewsModel.fromJson(Map<String, dynamic>.from(raw));
              if (parsed.id == id) stories[id] = parsed;
            } catch (_) {
              // Ignorar datos dañados, nunca bloquear toda la lista.
            }
          }
          return CloudBookmarkSnapshot(
            stories: stories,
            fromCache: snapshot.metadata.isFromCache,
          );
        });
  }

  Future<void> save(String uid, NewsModel news) async {
    // Se acota el HTML para mantener el documento por debajo del límite
    // de Firestore. La copia local conserva siempre el artículo completo.
    final story = news.toJson();
    final content = story['content'] as String? ?? '';
    if (content.length > 80000) {
      story['content'] = '';
    }
    await _collection(uid).doc('${news.id}').set({
      'newsId': news.id,
      'story': story,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String uid, int id) async {
    await _collection(uid).doc('$id').delete();
  }
}
