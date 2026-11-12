import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/news_model.dart';
import '../../services/bookmark_service.dart';
import '../../services/cloud_bookmark_service.dart';

/// Controla favoritos locales y sincronización entre dispositivos.
/// Nunca mezcla automáticamente los favoritos de distintas cuentas.
class BookmarkProvider extends ChangeNotifier {
  final BookmarkService service;
  final CloudBookmarkService? _cloudOverride;

  BookmarkProvider(this.service, {CloudBookmarkService? cloud})
      : _cloudOverride = cloud;

  CloudBookmarkService? _cloud;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<CloudBookmarkSnapshot>? _bookmarkSubscription;
  final Set<int> _pending = {};
  int _sessionVersion = 0;
  bool _disposed = false;
  String? _uid;

  Set<int> savedIds = {};
  Map<int, NewsModel> savedStories = {};
  Set<int> guestIdsToImport = {};
  bool loading = false;
  bool importing = false;
  String? syncError;

  String? get userId => _uid;
  bool get isCloudEnabled => _uid != null && _cloud != null;
  bool get canImportGuest => isCloudEnabled && guestIdsToImport.isNotEmpty;
  bool contains(int id) => savedIds.contains(id);

  /// Primera carga: recupera las noticias anteriores del dispositivo.
  Future<void> initialize() async {
    savedIds = await service.loadIds();
    savedStories = await service.loadStories(savedIds);
    if (!_disposed) notifyListeners();
  }

  /// Llamar una sola vez después de inicializar Firebase y este provider.
  Future<void> startFirebaseSync({required bool firebaseReady}) async {
    if (!firebaseReady || _authSubscription != null) return;
    _cloud = _cloudOverride ?? CloudBookmarkService();
    final auth = FirebaseAuth.instance;
    final initialUid = auth.currentUser?.uid;
    if (initialUid != null) await _switchUser(initialUid);
    _authSubscription = auth.authStateChanges().listen((user) {
      if (user?.uid != _uid) {
        unawaited(_switchUser(user?.uid));
      }
    });
  }

  Future<void> _switchUser(String? uid) async {
    final version = ++_sessionVersion;
    _uid = uid;
    await _bookmarkSubscription?.cancel();
    _bookmarkSubscription = null;
    _pending.clear();
    if (_disposed || version != _sessionVersion) return;

    loading = true;
    syncError = null;
    guestIdsToImport = {};
    savedIds = {};
    savedStories = {};
    notifyListeners();

    try {
      final ids = await service.loadIds(userId: uid);
      final stories = await service.loadStories(ids, userId: uid);
      if (_disposed || version != _sessionVersion) return;
      savedIds = ids;
      savedStories = stories;

      if (uid != null) {
        final guestIds = await service.loadIds();
        final alreadyImported = await service.importedGuestIds(uid);
        if (_disposed || version != _sessionVersion) return;
        guestIdsToImport = guestIds.difference(alreadyImported);
      }
    } catch (error) {
      if (!_disposed && version == _sessionVersion) {
        syncError = 'No se pudieron cargar los favoritos locales: $error';
      }
    } finally {
      if (!_disposed && version == _sessionVersion) {
        loading = false;
        notifyListeners();
      }
    }

    if (uid == null || _cloud == null || _disposed || version != _sessionVersion) {
      return;
    }
    _bookmarkSubscription = _cloud!.watch(uid).listen(
      (snapshot) => unawaited(_applyCloudSnapshot(snapshot, uid, version)),
      onError: (Object error) {
        if (!_disposed && version == _sessionVersion) {
          syncError = 'No se pudieron sincronizar los favoritos: $error';
          notifyListeners();
        }
      },
    );
  }

  Future<void> _applyCloudSnapshot(
    CloudBookmarkSnapshot snapshot,
    String uid,
    int version,
  ) async {
    if (_disposed || version != _sessionVersion) return;

    // Una caché vacía no prueba que la nube esté vacía; conservamos lo local.
    if (snapshot.fromCache && snapshot.stories.isEmpty && savedIds.isNotEmpty) {
      return;
    }

    final remoteIds = snapshot.stories.keys.toSet();
    // Las escrituras locales en curso tienen prioridad hasta que terminen.
    for (final id in _pending) {
      if (savedIds.contains(id)) {
        remoteIds.add(id);
      } else {
        remoteIds.remove(id);
      }
    }
    final nextStories = <int, NewsModel>{};
    for (final id in remoteIds) {
      final existing = savedStories[id];
      final remote = snapshot.stories[id];
      // Preferir copia completa local cuando la nube guardó solo un resumen.
      if (existing != null && (remote?.content.isEmpty ?? true)) {
        nextStories[id] = existing;
      } else if (remote != null) {
        nextStories[id] = remote;
      }
    }
    savedIds = remoteIds;
    savedStories = nextStories;
    syncError = null;
    notifyListeners();
    await _persistSnapshot(uid, version);
  }

  Future<void> _persistSnapshot(String uid, int version) async {
    final ids = {...savedIds};
    final stories = {...savedStories};
    try {
      for (final story in stories.values) {
        if (version != _sessionVersion) return;
        await service.saveStory(story, userId: uid);
      }
      if (version != _sessionVersion) return;
      await service.saveIds(ids, userId: uid);
    } catch (error) {
      debugPrint('No se pudo almacenar la caché de favoritos: $error');
    }
  }

  /// Acción optimista: primero actualiza UI y almacenamiento local.
  /// Si hay sesión, Firestore sincronizará la noticia entre dispositivos.
  Future<void> toggle(int id, {NewsModel? news}) async {
    if (loading || importing || _pending.contains(id)) return;
    final uid = _uid;
    final version = _sessionVersion;
    final removing = savedIds.contains(id);
    final previousIds = {...savedIds};
    final previousStories = {...savedStories};

    if (removing) {
      savedIds.remove(id);
      savedStories.remove(id);
    } else {
      savedIds.add(id);
      if (news != null) savedStories[id] = news;
    }
    _pending.add(id);
    syncError = null;
    notifyListeners();

    try {
      await service.saveIds({...savedIds}, userId: uid);
      if (removing) {
        await service.removeStory(id, userId: uid);
      } else if (news != null) {
        await service.saveStory(news, userId: uid);
      }
    } catch (error) {
      if (version == _sessionVersion && !_disposed) {
        savedIds = previousIds;
        savedStories = previousStories;
        syncError = 'No se pudo guardar en este dispositivo: $error';
        notifyListeners();
      }
      _pending.remove(id);
      return;
    }

    if (uid == null || _cloud == null || version != _sessionVersion) {
      _pending.remove(id);
      return;
    }
    if (!removing && news == null) {
      _pending.remove(id);
      syncError = 'No se pudo sincronizar: falta el contenido de la noticia.';
      notifyListeners();
      return;
    }

    // No bloquear el botón ni la navegación esperando la red de Firestore.
    unawaited(_writeCloud(
      uid: uid,
      version: version,
      id: id,
      removing: removing,
      news: news,
    ));
  }

  Future<void> _writeCloud({
    required String uid,
    required int version,
    required int id,
    required bool removing,
    NewsModel? news,
  }) async {
    try {
      if (removing) {
        await _cloud!.remove(uid, id);
      } else {
        await _cloud!.save(uid, news!);
      }
    } catch (error) {
      if (!_disposed && version == _sessionVersion) {
        syncError = 'Favorito guardado localmente; no se pudo sincronizar: $error';
        notifyListeners();
      }
    } finally {
      // No liberar la escritura de otra sesión que reutilice el mismo ID.
      if (version == _sessionVersion) _pending.remove(id);
    }
  }

  /// Importar requiere acción explícita del usuario: nunca mezcla cuentas.
  Future<void> importGuestBookmarks() async {
    final uid = _uid;
    if (uid == null || _cloud == null || importing || guestIdsToImport.isEmpty) {
      return;
    }
    final version = _sessionVersion;
    final ids = {...guestIdsToImport};
    importing = true;
    // Evita que una instantánea previa de Firestore oculte la importación.
    _pending.addAll(ids);
    syncError = null;
    notifyListeners();
    final imported = <int>{};
    try {
      final guestStories = await service.loadStories(ids);
      for (final id in ids) {
        if (version != _sessionVersion || _disposed) return;
        final story = guestStories[id];
        if (story == null) continue;
        savedIds.add(id);
        savedStories[id] = story;
        notifyListeners();
        await service.saveStory(story, userId: uid);
        await _cloud!.save(uid, story);
        imported.add(id);
      }
      if (version != _sessionVersion || _disposed) return;
      await service.saveIds({...savedIds}, userId: uid);
      final previouslyImported = await service.importedGuestIds(uid);
      await service.markGuestIdsImported(uid, {...previouslyImported, ...imported});
      if (version == _sessionVersion && !_disposed) {
        guestIdsToImport = ids.difference(imported);
        if (guestIdsToImport.isNotEmpty) {
          syncError = 'Algunos favoritos antiguos no tenían una copia local para importar.';
        }
      }
    } catch (error) {
      if (!_disposed && version == _sessionVersion) {
        syncError = 'No se completó la importación: $error';
      }
    } finally {
      if (!_disposed && version == _sessionVersion) {
        _pending.removeAll(ids);
        importing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionVersion++;
    _authSubscription?.cancel();
    _bookmarkSubscription?.cancel();
    super.dispose();
  }
}
