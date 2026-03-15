import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;
  static final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  static Future<void> initialize() async {
    try {
      // 1. Demander les permissions (iOS/Android 13+)
      await _requestPermissions();
      
      // 2. Configurer les notifications locales pour le mode foreground
      await _initializeLocalNotifications();
      
      // 3. Configurer les gestionnaires de messages
      _setupMessageHandlers();
      
      // 4. Récupérer et envoyer le token au backend
      await _getFCMToken();
      
      if (kDebugMode) print('✅ PushNotificationService initialisé avec succès');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur initialisation PushNotificationService: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.requestNotificationsPermission();
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTapped(response);
      },
    );
  }

  static void _setupMessageHandlers() {
    // Message reçu quand l'app est en premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Message reçu quand l'app est en arrière-plan mais ouverte
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Message reçu quand l'app était complètement fermée
    _handleInitialMessage();
  }

  static Future<void> _getFCMToken() async {
    try {
      String? token = await _fcm.getToken();
      
      if (token != null) {
        _fcmToken = token;
        if (kDebugMode) print('🔑 FCM Token: $token');
        await ApiService.updateFCMToken(token);
      }

      // Écouter les changements de token
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (kDebugMode) print('🔄 FCM Token rafraîchi: $newToken');
        ApiService.updateFCMToken(newToken);
      });
    } catch (e) {
      if (kDebugMode) print('❌ Erreur récupération FCM token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) print('📱 Message en premier plan: ${message.messageId}');
    
    // Afficher la notification localement
    await _showLocalNotification(message);
    
    // Traiter le message
    _processMessage(message);
    
    // Émettre le message pour les widgets qui écoutent
    _messageStreamController.add(message);
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) print('📱 App ouverte depuis notification: ${message.messageId}');
    _processMessage(message);
    _messageStreamController.add(message);
  }

  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    
    if (initialMessage != null) {
      if (kDebugMode) print('📱 Message initial au démarrage: ${initialMessage.messageId}');
      _processMessage(initialMessage);
      _messageStreamController.add(initialMessage);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'community_security_channel',
      'Community Security Alerts',
      channelDescription: 'Notifications de sécurité communautaire',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        message.notification?.body ?? '',
        htmlFormatBigText: true,
        contentTitle: message.notification?.title ?? '',
        htmlFormatContentTitle: true,
      ),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? 'Vous avez reçu une nouvelle notification',
      notificationDetails: platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) print('🔔 Notification cliquée: ${response.payload}');
    
    // Naviguer vers la page appropriée selon le payload
    if (response.payload != null) {
      // Pour l'instant, on log le payload
      // La navigation sera gérée par les widgets qui écoutent le stream
      try {
        if (kDebugMode) print('Payload: ${response.payload}');
      } catch (e) {
        if (kDebugMode) print('Erreur parsing payload: $e');
      }
    }
  }

  static void _processMessage(RemoteMessage message) {
    if (kDebugMode) print('📨 Traitement message: ${message.data}');
    
    final String? type = message.data['type'];
    final String? incidentId = message.data['incidentId'];
    final String? userId = message.data['userId'];
    
    switch (type) {
      case 'new_incident':
        if (kDebugMode) print('🚨 Nouvel incident signalé: $incidentId');
        break;
      case 'incident_updated':
        if (kDebugMode) print('📝 Incident mis à jour: $incidentId');
        break;
      case 'new_message':
        if (kDebugMode) print('💬 Nouveau message: $incidentId');
        break;
      case 'admin_action':
        if (kDebugMode) print('👮 Action admin: $userId');
        break;
      default:
        if (kDebugMode) print('📭 Type de message non géré: $type');
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      if (kDebugMode) print('✅ Abonné au topic: $topic');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur abonnement topic $topic: $e');
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      if (kDebugMode) print('✅ Désabonné du topic: $topic');
    } catch (e) {
      if (kDebugMode) print('❌ Erreur désabonnement topic $topic: $e');
    }
  }

  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    if (kDebugMode) print('🗑️ Toutes les notifications locales effacées');
  }

  static Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id: id);
    if (kDebugMode) print('🗑️ Notification $id effacée');
  }

  static Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }
    return false;
  }

  static void dispose() {
    _messageStreamController.close();
  }
}

// Global background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) print("Handling a background message: ${message.messageId}");
}
