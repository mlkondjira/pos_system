import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggerService {
  File? _logFile;

  Future<void> _init() async {
    if (_logFile != null) return;
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/app_logs.txt');
  }

  /// Wrappers pratiques pour les différents niveaux de log
  Future<void> info(String message) => log(message, level: 'INFO');
  
  Future<void> warning(String message) => log(message, level: 'WARN');
  
  Future<void> error(String message, {dynamic error, StackTrace? stackTrace}) {
    return log(message, level: 'ERROR', error: error, stackTrace: stackTrace);
  }

  /// Enregistre un message dans le fichier de log local
  Future<void> log(String message, {String level = 'INFO', dynamic error, StackTrace? stackTrace}) async {
    await _init();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    
    String logLine = '[$timestamp] [$level] $message';
    if (error != null) logLine += ' | Error: $error';
    if (stackTrace != null) logLine += '\nStackTrace: $stackTrace';
    logLine += '\n';

    // Optionnel: Rotation du fichier si > 2Mo
    if (await _logFile!.exists() && await _logFile!.length() > 2 * 1024 * 1024) {
      await _logFile!.rename('${_logFile!.path}.old');
    }

    await _logFile!.writeAsString(logLine, mode: FileMode.append, flush: true);
  }

  Future<File?> getLogFile() async {
    await _init();
    if (await _logFile!.exists()) return _logFile;
    return null;
  }

  Future<void> clearLogs() async {
    await _init();
    if (await _logFile!.exists()) {
      await _logFile!.delete();
    }
  }
}