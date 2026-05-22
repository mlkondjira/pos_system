import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  Future<T?> showAppDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    if (context == null) return Future.value(null);
    
    return showDialog<T>(
      context: context!,
      barrierDismissible: barrierDismissible,
      builder: (_) => child,
    );
  }

  Future<bool> showConfirm({
    required String title,
    required String content,
    String confirmLabel = 'Confirmer',
    bool isDestructive = false,
  }) async {
    final result = await showAppDialog<bool>(
      child: AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => navigatorKey.currentState?.pop(false), child: const Text('Annuler')),
          ElevatedButton(
            style: isDestructive ? ElevatedButton.styleFrom(backgroundColor: Colors.red) : null,
            onPressed: () => navigatorKey.currentState?.pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}