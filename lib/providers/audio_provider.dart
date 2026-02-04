import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Bundled workout music info
class BundledMusic {
  final String id;
  final String name;
  final String artist;
  final String assetPath;

  const BundledMusic({
    required this.id,
    required this.name,
    required this.artist,
    required this.assetPath,
  });
}

/// Audio Provider - Manages TTS counting and background music
class AudioProvider extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // TTS State
  bool _isTtsEnabled = true;
  bool _isTtsInitialized = false;
  final String _ttsLanguage = 'vi-VN';

  // Music State
  bool _isMusicEnabled = false;
  bool _isPlaying = false;
  bool _hasPermission = false;
  List<SongModel> _deviceSongs = [];
  SongModel? _currentSong;
  String? _currentBundledMusicId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Bundled music list
  static const List<BundledMusic> bundledMusic = [
    BundledMusic(
      id: 'workout_beat_1',
      name: 'Workout Beat',
      artist: 'HealthCare',
      assetPath: 'assets/audio/workout_beat.mp3',
    ),
    BundledMusic(
      id: 'energy_boost',
      name: 'Energy Boost',
      artist: 'HealthCare',
      assetPath: 'assets/audio/energy_boost.mp3',
    ),
    BundledMusic(
      id: 'motivation_mix',
      name: 'Motivation Mix',
      artist: 'HealthCare',
      assetPath: 'assets/audio/motivation_mix.mp3',
    ),
  ];

  // Getters
  bool get isTtsEnabled => _isTtsEnabled;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isPlaying => _isPlaying;
  bool get hasPermission => _hasPermission;
  List<SongModel> get deviceSongs => _deviceSongs;
  SongModel? get currentSong => _currentSong;
  String? get currentBundledMusicId => _currentBundledMusicId;
  Duration get position => _position;
  Duration get duration => _duration;

  AudioProvider() {
    _initTts();
    _initMusicPlayer();
  }

  // ============ TTS Methods ============

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage(_ttsLanguage);
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('TTS init error: $e');
    }
  }

  void toggleTts() {
    _isTtsEnabled = !_isTtsEnabled;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!_isTtsEnabled || !_isTtsInitialized) return;
    await _tts.speak(text);
  }

  /// Speak countdown number
  Future<void> speakCount(int count) async {
    await speak(count.toString());
  }

  /// Speak exercise name
  Future<void> speakExerciseName(String name) async {
    await speak(name);
  }

  // ============ Music Methods ============

  void _initMusicPlayer() {
    _musicPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _musicPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _musicPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _musicPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNextSong();
      }
    });
  }

  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    if (!_isMusicEnabled) {
      pauseMusic();
    }
    notifyListeners();
  }

  Future<void> requestPermission() async {
    _hasPermission = await _audioQuery.permissionsStatus();
    if (!_hasPermission) {
      _hasPermission = await _audioQuery.permissionsRequest();
    }
    notifyListeners();
  }

  Future<void> loadDeviceSongs() async {
    if (!_hasPermission) {
      await requestPermission();
    }
    if (_hasPermission) {
      _deviceSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      notifyListeners();
    }
  }

  /// Play bundled music
  Future<void> playBundledMusic(String musicId) async {
    final music = bundledMusic.firstWhere((m) => m.id == musicId);
    try {
      await _musicPlayer.setAsset(music.assetPath);
      await _musicPlayer.play();
      _currentBundledMusicId = musicId;
      _currentSong = null;
      _isMusicEnabled = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Play bundled music error: $e');
    }
  }

  /// Play device song
  Future<void> playDeviceSong(SongModel song) async {
    try {
      await _musicPlayer.setFilePath(song.data);
      await _musicPlayer.play();
      _currentSong = song;
      _currentBundledMusicId = null;
      _isMusicEnabled = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Play device song error: $e');
    }
  }

  Future<void> playMusic() async {
    await _musicPlayer.play();
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
    _currentSong = null;
    _currentBundledMusicId = null;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _musicPlayer.seek(position);
  }

  void _playNextSong() {
    // Auto-play next song logic
    if (_currentSong != null && _deviceSongs.isNotEmpty) {
      final currentIndex = _deviceSongs.indexWhere(
        (s) => s.id == _currentSong!.id,
      );
      if (currentIndex >= 0 && currentIndex < _deviceSongs.length - 1) {
        playDeviceSong(_deviceSongs[currentIndex + 1]);
      } else if (_deviceSongs.isNotEmpty) {
        playDeviceSong(_deviceSongs[0]); // Loop back to first
      }
    } else if (_currentBundledMusicId != null) {
      final currentIndex = bundledMusic.indexWhere(
        (m) => m.id == _currentBundledMusicId,
      );
      if (currentIndex >= 0 && currentIndex < bundledMusic.length - 1) {
        playBundledMusic(bundledMusic[currentIndex + 1].id);
      } else {
        playBundledMusic(bundledMusic[0].id); // Loop back to first
      }
    }
  }

  String get currentMusicName {
    if (_currentSong != null) {
      return _currentSong!.title;
    } else if (_currentBundledMusicId != null) {
      return bundledMusic
          .firstWhere((m) => m.id == _currentBundledMusicId)
          .name;
    }
    return '';
  }

  @override
  void dispose() {
    _tts.stop();
    _musicPlayer.dispose();
    super.dispose();
  }
}
