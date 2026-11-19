import 'dart:async';

import 'package:audio_service/audio_service.dart' as bg;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:app_noticias/modules/radio/radio_constants.dart';
import 'package:app_noticias/modules/radio/models/station_model.dart';

class RadioAudioService extends bg.BaseAudioHandler {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  StationModel? _selectedStation;
  String? lastError;

  int _latestRequest = 0;
  Future<void> _switchTail = Future<void>.value();

  RadioAudioService() {
    _subscriptions.add(
      _player.playerStateStream.listen((_) => _publishState()),
    );

    _subscriptions.add(
      _player.playbackEventStream.listen(
        (_) => _publishState(),
        onError: (Object error, StackTrace stackTrace) {
          _reportError(error);
        },
      ),
    );

    _subscriptions.add(
      _player.errorStream.listen((error) => _reportError(error)),
    );

    _publishState();
  }

  StationModel? get selectedStation => _selectedStation;

  bg.AudioProcessingState _processingState(ja.ProcessingState state) {
    return switch (state) {
      ja.ProcessingState.idle => bg.AudioProcessingState.idle,
      ja.ProcessingState.loading => bg.AudioProcessingState.loading,
      ja.ProcessingState.buffering => bg.AudioProcessingState.buffering,
      ja.ProcessingState.ready => bg.AudioProcessingState.ready,
      ja.ProcessingState.completed => bg.AudioProcessingState.completed,
    };
  }

  void _publishState() {
    final stationAvailable = _selectedStation != null;

    final controls = <bg.MediaControl>[
      if (stationAvailable) bg.MediaControl.skipToPrevious,

      if (stationAvailable)
        _player.playing ? bg.MediaControl.pause : bg.MediaControl.play,

      if (stationAvailable) bg.MediaControl.skipToNext,
    ];

    playbackState.add(
      bg.PlaybackState(
        controls: controls,
        androidCompactActionIndices: stationAvailable
            ? const [0, 1, 2]
            : const [],
        processingState: _processingState(_player.processingState),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  void _reportError(Object error) {
    lastError = error.toString();

    playbackState.add(
      playbackState.value.copyWith(
        processingState: bg.AudioProcessingState.error,
        playing: false,
      ),
    );
  }

  Future<void> _changeStation(int direction) async {
    final stations = DemoData.stations;

    if (stations.isEmpty) {
      return;
    }

    final currentIndex = stations.indexWhere(
      (station) => station.id == _selectedStation?.id,
    );

    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + direction + stations.length) % stations.length;

    await selectStation(stations[nextIndex]);
  }

  @override
  Future<void> skipToPrevious() async {
    await _changeStation(-1);
  }

  @override
  Future<void> skipToNext() async {
    await _changeStation(1);
  }

  Future<void> selectStation(StationModel station) {
    final request = ++_latestRequest;

    final operation = _switchTail.then((_) async {
      if (request != _latestRequest) {
        return;
      }

      lastError = null;

      await _player.stop();

      if (request != _latestRequest) {
        return;
      }

      _selectedStation = station;

      mediaItem.add(
        bg.MediaItem(
          id: station.id,
          album: 'Radio en vivo',
          title: station.name,
          artist: '${station.acronym} · ${station.slogan}',
          artUri: station.imageUrl == null
              ? null
              : Uri.tryParse(station.imageUrl!),
        ),
      );

      _publishState();

      playbackState.add(
        playbackState.value.copyWith(
          processingState: bg.AudioProcessingState.loading,
          playing: false,
        ),
      );

      try {
        await _player
            .setUrl(station.streamUrl)
            .timeout(const Duration(seconds: 20));

        if (request != _latestRequest) {
          return;
        }

        // En radios en vivo, esperar el Future de play() puede no terminar nunca.
        unawaited(
          _player.play().catchError((Object error) {
            _reportError(error);
          }),
        );
      } catch (error) {
        if (request == _latestRequest) {
          await _player.stop();
          _reportError(error);
        }

        rethrow;
      }
    });

    // El siguiente cambio continua aun si el anterior fallo
    _switchTail = operation.then(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );

    return operation;
  }

  @override
  Future<void> playMediaItem(bg.MediaItem mediaItem) async {
    final station = DemoData.stationById(mediaItem.id);

    if (station != null) {
      await selectStation(station);
    }
  }

  @override
  Future<void> play() async {
    if (_selectedStation == null) {
      return;
    }

    if (_player.processingState == ja.ProcessingState.idle ||
        _player.processingState == ja.ProcessingState.completed) {
      await selectStation(_selectedStation!);
      return;
    }

    unawaited(
      _player.play().catchError((Object error) {
        _reportError(error);
      }),
    );
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    ++_latestRequest;

    await _player.stop();

    _publishState();
  }

  // Se llama cuando deja de utilizarse
  Future<void> disposeResources() async {
    ++_latestRequest;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    await _player.dispose();
  }
}
