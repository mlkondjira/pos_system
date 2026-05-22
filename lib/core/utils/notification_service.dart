import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:async';
import 'package:local_notifier/local_notifier.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Flux pour transmettre les clics sur les notifications à l'UI
  final StreamController<NotificationResponse> _selectNotificationStream =
      StreamController<NotificationResponse>.broadcast();
  Stream<NotificationResponse> get selectNotificationStream =>
      _selectNotificationStream.stream;

  // Stocke le payload si l'app a été lancée via une notification
  NotificationResponse? _initialResponse;
  NotificationResponse? get initialResponse => _initialResponse;

  /// Initialise le service. [onBackgroundHandler] est requis pour traiter les boutons d'actions.
  Future<void> initialize(
      void Function(NotificationResponse)? onBackgroundHandler) async {
    if (Platform.isWindows) {
      // Initialisation spécifique pour Windows
      await localNotifier.setup(
        appName: 'pos_system',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _selectNotificationStream.add(response);
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundHandler,
    );

    // Vérifier si l'app a été lancée par une notification
    final notificationAppLaunchDetails =
        await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      _initialResponse = notificationAppLaunchDetails?.notificationResponse;
    }
  }

  /// Demande les permissions de notification à l'utilisateur au démarrage.
  Future<void> requestPermissions() async {
    if (Platform.isWindows) return;

    if (Platform.isAndroid) {
      // Spécifique à Android 13+ (SDK 33)
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> showCriticalErrorNotification(
      {required String title, required String body}) async {
    if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        identifier: 'critical_error',
        title: title,
        body: body,
      );

      try {
        await notification.show();
      } catch (e) {
        debugPrint('Erreur notification Windows (Thread Error) : $e');
      }
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'critical_sync_errors',
      'Alertes Logistiques',
      channelDescription:
          'Notifications pour les erreurs de synchronisation de stock',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: 'open_transfers', // Identifiant de l'action
    );
  }

  /// Affiche une notification pour un nouveau transfert avec un bouton d'action.
  Future<void> showIncomingTransferNotification({
    required int transferId,
    required String ref,
    required String sourceShop,
  }) async {
    if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        identifier: 'transfer_$transferId',
        title: 'Nouveau transfert : $ref',
        body: 'Marchandise en provenance de $sourceShop',
        actions: [
          LocalNotificationAction(text: 'Marquer comme reçu'),
        ],
      );

      notification.onClick = () {
        // Sécurisation du thread pour Windows
        Future.microtask(() {
          _selectNotificationStream.add(NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotification,
              payload: 'transfer:$transferId'));
        });
      };

      (notification as dynamic).onActionPressed = (actionIndex) {
        if (actionIndex == 0) {
          Future.microtask(() {
            _selectNotificationStream.add(NotificationResponse(
              notificationResponseType:
                  NotificationResponseType.selectedNotificationAction,
              actionId: 'action_mark_received',
              payload: 'transfer:$transferId',
            ));
          });
        }
      };

      await notification.show();
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'transfer_alerts',
      'Transferts de stock',
      importance: Importance.max,
      priority: Priority.high,
      // Ajout du bouton d'action
      actions: [
        AndroidNotificationAction(
          'action_mark_received',
          'Marquer comme reçu',
          showsUserInterface: true, // OBLIGATOIRE pour afficher un dialogue
          cancelNotification: true,
        ),
      ],
    );

    await _notificationsPlugin.show(
      id: transferId,
      title: 'Nouveau transfert : $ref',
      body: 'Marchandise en provenance de $sourceShop',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'transfer:$transferId',
    );
  }

  /// Supprime une notification spécifique par son ID (utile pour effacer l'alerte de backlog).
  Future<void> cancelNotification(int id) async {
    if (Platform.isWindows) return;
    await _notificationsPlugin.cancel(id: id);
  }

  /// Affiche une notification persistante si la file d'attente est trop importante.
  Future<void> showSyncBacklogNotification(int count) async {
    final String message =
        'Il y a $count éléments en attente de synchronisation. Assurez-vous d\'être connecté.';

    if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        identifier: 'sync_backlog',
        title: '⚠️ Retard de synchronisation',
        body: message,
        actions: [
          LocalNotificationAction(text: 'Synchroniser maintenant'),
        ],
      );

      (notification as dynamic).onActionPressed = (actionIndex) {
        if (actionIndex == 0) {
          Future.microtask(() {
            _selectNotificationStream.add(
              const NotificationResponse(
                notificationResponseType:
                    NotificationResponseType.selectedNotificationAction,
                actionId: 'action_sync_now',
              ),
            );
          });
        }
      };

      await notification.show();
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sync_backlog_alerts',
      'Alertes Synchronisation',
      channelDescription:
          'Avertissements lorsque la file d\'attente est trop importante',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true, // Empêche la suppression par simple swipe sur Android
      actions: [
        AndroidNotificationAction('action_sync_now', 'Synchroniser maintenant',
            showsUserInterface: false),
      ],
    );

    await _notificationsPlugin.show(
      id: 999,
      title: '⚠️ Retard de synchronisation',
      body: message,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'open_sync_errors',
    );
  }

  /// Affiche une alerte lorsque le quota cloud approche de la limite.
  Future<void> showQuotaWarningNotification(
      {required String title, required String body}) async {
    if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        identifier: 'quota_warning',
        title: title,
        body: body,
      );
      await notification.show();
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'quota_alerts',
      'Alertes Quotas Cloud',
      channelDescription:
          'Avertissements sur l\'utilisation de l\'espace Supabase',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF9800), // Orange pour l'alerte
    );

    await _notificationsPlugin.show(
      id: 888,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'open_settings',
    );
  }

  /// Prévient le gérant qu'une promotion va bientôt se terminer.
  Future<void> showDiscountExpiryNotification({
    required int discountId,
    required String name,
    required DateTime endDate,
  }) async {
    final String message =
        'La promotion "$name" se termine demain à ${endDate.hour}:${endDate.minute.toString().padLeft(2, '0')}.';

    if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        identifier: 'expiry_$discountId',
        title: '⏰ Fin de promo proche',
        body: message,
      );
      await notification.show();
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'marketing_alerts',
      'Alertes Marketing',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      id: 2000 + discountId,
      title: '⏰ Fin de promo proche',
      body: message,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  /// Prévient le gérant qu'un coupon génère des remises excessives.
  Future<void> showHighLossDiscountNotification({
    required String couponCode,
    required double lossPercentage,
  }) async {
    final String message =
        'Le coupon "$couponCode" a généré des remises représentant ${lossPercentage.toStringAsFixed(1)}% du CA sur les 30 derniers jours.';

    if (Platform.isWindows) {
      final LocalNotification notification = LocalNotification(
        identifier: 'high_loss_discount_$couponCode',
        title: '🚨 Coupon à forte perte détecté',
        body: message,
      );
      await notification.show();
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_loss_alerts',
      'Alertes Coupons à Forte Perte',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD32F2F), // Rouge pour l'alerte
    );

    await _notificationsPlugin.show(
      id: 3000 + couponCode.hashCode,
      title: '🚨 Coupon à forte perte détecté',
      body: message,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'open_discounts_screen', // Pour ouvrir l'écran des remises
    );
  }
}
