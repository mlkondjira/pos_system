import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart' as win32;

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;
  static final Map<String, String> _soundCache = {};

  /// Extrait un asset vers un fichier temporaire pour que Win32 puisse y accéder
  static Future<String> _getCachePath(String assetName) async {
    if (_soundCache.containsKey(assetName)) return _soundCache[assetName]!;

    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, assetName);
    final file = File(path);

    if (!await file.exists()) {
      final data = await rootBundle.load('assets/sounds/$assetName');
      await file.writeAsBytes(data.buffer.asUint8List());
    }

    _soundCache[assetName] = path;
    return path;
  }

  static Future<void> playScannerSound(bool success) async {
    try {
      if (Platform.isWindows) {
        // 1. Préparer le fichier .wav personnalisé
        final fileName = success ? 'BEEP.wav' : 'ERROR.wav';
        final filePath = await _getCachePath(fileName);

        // 2. Préparer le pointeur de chaîne UTF-16 pour Windows
        final pathPtr = filePath.toNativeUtf16();

        // 3. PlaySound : Nom du fichier, instance (0), Drapeaux (FILENAME + ASYNC)
        win32.PlaySound(
          pathPtr,
          0,
          win32.SND_FILENAME | win32.SND_ASYNC | win32.SND_NODEFAULT,
        );

        malloc.free(pathPtr);
        return;
      }

      if (!_initialized && Platform.isWindows) {
        // Sur Windows, on configure le mode de log pour réduire le trafic sur le canal
        _player.setReleaseMode(ReleaseMode.stop);
        _initialized = true;
      }

      final source = success
          ? AssetSource('sounds/BEEP.mp3')
          : AssetSource('sounds/ERROR.mp3');

      // Sur Windows, on évite d'écouter les streams de position/durée
      // qui sont la cause principale des erreurs de thread.
      await _player.stop(); // Arrêter avant de rejouer
      await _player.play(source, volume: 0.5);
    } catch (e) {
      debugPrint('AudioService: Erreur lors de la lecture du son : $e');
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
