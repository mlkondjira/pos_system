import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final inputPath = 'assets/logo.png';
  final outputPath = 'assets/icon_square.png';

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('❌ Erreur : Le fichier source $inputPath est introuvable.');
    exit(1);
  }

  final bytes = await inputFile.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    stderr.writeln('❌ Erreur : Impossible de décoder l\'image $inputPath.');
    exit(1);
  }

  // Déterminer la taille du carré (le plus grand côté)
  final int size = image.width > image.height ? image.width : image.height;

  // Créer une image carrée transparente
  final squareImage = img.Image(width: size, height: size, numChannels: 4);

  // Centrer le logo
  final int x = (size - image.width) ~/ 2;
  final int y = (size - image.height) ~/ 2;

  img.compositeImage(squareImage, image, dstX: x, dstY: y);

  // Sauvegarder
  await File(outputPath).writeAsBytes(img.encodePng(squareImage));
  stdout.writeln(
    '✅ Icône carrée générée avec succès : $outputPath (${size}x${size}px)',
  );
  exit(0);
}
