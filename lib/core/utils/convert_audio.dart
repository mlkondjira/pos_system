import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  // 1. Vérifier si FFmpeg est installé avant de commencer
  String ffmpegCmd = 'ffmpeg';

  try {
    await Process.run(ffmpegCmd, ['-version']);
  } catch (_) {
    // Tentative de secours : vérifier si ffmpeg.exe est à la racine du projet
    final localFfmpeg = File('ffmpeg.exe');
    if (await localFfmpeg.exists()) {
      ffmpegCmd = p.absolute(localFfmpeg.path);
      stdout.writeln('ℹ️ Utilisation de FFmpeg local trouvé à la racine.');
    } else {
      stderr.writeln(
        '❌ Erreur : FFmpeg n\'est pas installé ou n\'est pas dans le PATH.',
      );
      stderr.writeln(
        'Conseil : Copiez ffmpeg.exe à la racine de : ${Directory.current.path}',
      );
      exit(1);
    }
  }

  // Localiser le dossier des sons (chemin relatif à la racine du projet)
  final soundsDir = Directory('assets/sounds');

  if (!await soundsDir.exists()) {
    stderr.writeln('Erreur : Dossier assets/sounds/ introuvable.');
    return;
  }

  stdout.writeln('--- Début de la conversion audio (MP3 -> WAV) ---');

  await for (final entity in soundsDir.list()) {
    if (entity is File && p.extension(entity.path).toLowerCase() == '.mp3') {
      final inputPath = entity.path;
      final outputPath = p.setExtension(inputPath, '.wav');
      final outputFile = File(outputPath);

      // Vérification de la date de modification pour éviter les conversions inutiles
      if (await outputFile.exists()) {
        final inputMod = await entity.lastModified();
        final outputMod = await outputFile.lastModified();
        if (outputMod.isAfter(inputMod)) {
          stdout.writeln('Ignoré : ${p.basename(inputPath)} (déjà à jour).');
          continue;
        }
      }

      stdout.writeln('Traitement de : ${p.basename(inputPath)}...');

      // Exécution de FFmpeg
      // -y : Écrase le fichier de sortie s'il existe
      // -i : Fichier d'entrée
      final result = await Process.run(ffmpegCmd, [
        '-y',
        '-i',
        inputPath,
        outputPath,
      ]);

      if (result.exitCode == 0) {
        stdout.writeln('✅ Succès : ${p.basename(outputPath)} généré.');
      } else {
        stderr.writeln(
          '❌ Erreur pour ${p.basename(inputPath)} : ${result.stderr}',
        );
      }
    }
  }

  stdout.writeln('--- Nettoyage des fichiers orphelins (.wav sans .mp3) ---');

  await for (final entity in soundsDir.list()) {
    if (entity is File && p.extension(entity.path).toLowerCase() == '.wav') {
      final mp3Path = p.setExtension(entity.path, '.mp3');
      if (!await File(mp3Path).exists()) {
        stdout.writeln(
          'Suppression de : ${p.basename(entity.path)} (source MP3 introuvable).',
        );
        await entity.delete();
      }
    }
  }

  stdout.writeln('--- Conversion terminée ---');
}
