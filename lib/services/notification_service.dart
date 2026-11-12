import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  String topicForCategory(int categoryId) => 'news_category_$categoryId';
  Future<void> setCategorySubscription(int categoryId, bool enabled) async {
    final topic = topicForCategory(categoryId);
    debugPrint('FCM TOPIC: $topic');
    if (enabled) {
      if (!await requestPermission()) {
        throw Exception('No se concedieron permisos de notificación.');
      }
      await _messaging.subscribeToTopic(topic);
    } else {
      await _messaging.unsubscribeFromTopic(topic);
    }
  }
}
