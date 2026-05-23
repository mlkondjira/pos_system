import 'package:supabase_flutter/supabase_flutter.dart';
import '../di/injection.dart';
import 'logger_service.dart';

class ErrorFormatter {
  static String format(dynamic error) {
    // Logging automatique de l'erreur technique brute
    getIt<LoggerService>().log(
      'Erreur capturée par le formateur',
      level: 'ERROR',
      error: error,
    );

    final String message = error.toString();

    // 1. Gestion des erreurs Supabase / Postgrest
    if (error is PostgrestException) {
      if (message.contains('duplicate key')) {
        return 'Cette donnée (ID ou code) existe déjà sur le serveur.';
      }
      if (message.contains('violates foreign key')) {
        return 'Impossible de supprimer : cet élément est utilisé par une autre partie du système.';
      }
      if (message.contains('JWT expired')) {
        return 'Votre session a expiré. Veuillez vous déconnecter et vous reconnecter.';
      }
      return 'Erreur serveur : ${error.message}';
    }

    if (error is AuthException) {
      if (message.contains('Invalid login credentials')) {
        return 'Email ou mot de passe incorrect.';
      }
      if (message.contains('Email not confirmed')) {
        return 'Veuillez confirmer votre adresse email avant de vous connecter.';
      }
      return error.message;
    }

    // 2. Gestion des erreurs réseau
    if (message.contains('SocketException') ||
        message.contains('Network') ||
        message.contains('Failed host lookup')) {
      return 'Problème de connexion internet. Vérifiez votre réseau.';
    }

    if (message.contains('TimeoutException')) {
      return 'Le serveur met trop de temps à répondre. Réessayez plus tard.';
    }

    // 3. Nettoyage des exceptions Dart standards
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }

    return 'Une erreur inattendue est survenue.';
  }
}
