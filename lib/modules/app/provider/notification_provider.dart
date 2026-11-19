import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService service;
  NotificationProvider(this.service);
  Set<int> enabledCategories = {};
  int? updatingId;
  String? error;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    enabledCategories = (prefs.getStringList('notification_category_ids') ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    notifyListeners();
  }

  Future<void> toggle(int id, bool enabled) async {
    updatingId = id;
    error = null;
    notifyListeners();
    try {
      await service.setCategorySubscription(id, enabled);
      if (enabled) {
        enabledCategories.add(id);
      } else {
        enabledCategories.remove(id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'notification_category_ids',
        enabledCategories.map((e) => '$e').toList(),
      );
    } catch (e) {
      error = 'No se pudo cambiar la suscripción. Comprueba Firebase y los permisos.';
    } finally {
      updatingId = null;
      notifyListeners();
    }
  }
}
