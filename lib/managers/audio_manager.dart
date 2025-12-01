// lib/managers/audio_manager.dart
import 'package:flame_audio/flame_audio.dart';
import '../utils/platform_detector.dart'; // Agregar esta línea

class AudioManager {
  // Singleton pattern
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // Configuración de volumen
  double sfxVolume = 0.7;
  double musicVolume = 0.5;

  // Estado
  bool _initialized = false;
  bool _musicPlaying = false;
  bool _userInteracted = false;
  String? _pendingMusicFile;

  bool get initialized => _initialized;
  bool get isMusicPlaying => _musicPlaying;
  bool get userInteracted => _userInteracted;

  /// Inicializar el audio manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _initialized = true;

      // **CRÍTICO: Si NO es web, marcar como interactuado automáticamente**
      if (!PlatformDetector.requiresUserInteractionForAudio) {
        _userInteracted = true;
        print('Auto-interacted: Windows/Android platform detected');
      } else {
        print('Waiting for user interaction: Web platform detected');
      }

      print('AudioManager initialized successfully');
    } catch (e) {
      print('Error initializing AudioManager: $e');
      _initialized = false;
    }
  }

  /// Marcar que el usuario ha interactuado (solo necesario en web)
  void markUserInteraction() {
    if (_userInteracted) return;

    _userInteracted = true;
    print('User interaction detected - audio unlocked');

    // Si había música pendiente, reproducirla ahora
    if (_pendingMusicFile != null) {
      _playBgmInternal(_pendingMusicFile!);
      _pendingMusicFile = null;
    }
  }

  // ============================================================================
  // EFECTOS DE SONIDO
  // ============================================================================

  /// Reproducir efecto de sonido
  void playSfx(String fileName, {double? volume}) {
    if (!_initialized) return;

    // Solo en web verificar interacción
    if (PlatformDetector.requiresUserInteractionForAudio && !_userInteracted) {
      return; // Silenciosamente no hacer nada en web antes de interacción
    }

    try {
      FlameAudio.play(fileName, volume: (volume ?? 1.0) * sfxVolume);
    } catch (e) {
      print('Error playing sound $fileName: $e');
    }
  }

  // ============================================================================
  // MÚSICA DE FONDO
  // ============================================================================

  /// Reproducir música en loop
  Future<void> playBgm(String fileName, {double? volume}) async {
    if (!_initialized) return;

    print('Attempting to play BGM: $fileName');

    // **COMPORTAMIENTO DIFERENTE POR PLATAFORMA:**
    if (PlatformDetector.requiresUserInteractionForAudio && !_userInteracted) {
      // **WEB: Guardar como pendiente**
      print('Web: Music queued (waiting for user interaction)');
      _pendingMusicFile = fileName;
      return;
    } else {
      // **WINDOWS/ANDROID: Reproducir inmediatamente**
      print('Windows/Android: Playing music immediately');
      await _playBgmInternal(fileName, volume: volume);
    }
  }

  /// Reproducir música internamente
  Future<void> _playBgmInternal(String fileName, {double? volume}) async {
    try {
      // Si ya hay música sonando, detenerla primero
      if (_musicPlaying) {
        await stopBgm();
      }

      await FlameAudio.bgm.play(
        fileName,
        volume: (volume ?? 1.0) * musicVolume,
      );
      _musicPlaying = true;
      print('Music playing: $fileName');
    } catch (e) {
      print('Error playing music $fileName: $e');
    }
  }

  /// Detener la música de fondo
  Future<void> stopBgm() async {
    if (!_musicPlaying) return;

    try {
      await FlameAudio.bgm.stop();
      _musicPlaying = false;
      _pendingMusicFile = null;
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  /// Pausar la música de fondo
  void pauseBgm() {
    if (!_musicPlaying) return;

    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      print('Error pausing music: $e');
    }
  }

  /// Reanudar la música de fondo
  void resumeBgm() {
    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      print('Error resuming music: $e');
    }
  }

  // ============================================================================
  // LIMPIEZA
  // ============================================================================

  /// Limpiar recursos de audio
  Future<void> dispose() async {
    await stopBgm();
    FlameAudio.audioCache.clearAll();
    _initialized = false;
    _musicPlaying = false;
    _userInteracted = false;
    _pendingMusicFile = null;
  }
}
