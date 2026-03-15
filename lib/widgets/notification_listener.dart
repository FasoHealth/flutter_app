import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/push_notification_service.dart';

class NotificationListener extends StatefulWidget {
  final Widget child;
  final Function(RemoteMessage)? onNotificationReceived;
  final Function(RemoteMessage)? onNotificationTapped;

  const NotificationListener({
    super.key,
    required this.child,
    this.onNotificationReceived,
    this.onNotificationTapped,
  });

  @override
  State<NotificationListener> createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<NotificationListener> {
  late StreamSubscription<RemoteMessage> _messageSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _messageSubscription = PushNotificationService.messageStream.listen((message) {
      widget.onNotificationReceived?.call(message);
      _handleNotificationNavigation(message);
    });
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final String? type = message.data['type'];
    final String? incidentId = message.data['incidentId'];
    
    if (type != null && incidentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToPage(type, incidentId);
      });
    }
  }

  void _navigateToPage(String type, String incidentId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'new_incident':
      case 'incident_updated':
        // Naviguer vers la page de détail de l'incident
        Navigator.pushNamed(
          context,
          '/incident-detail',
          arguments: incidentId,
        );
        break;
      case 'new_message':
        // Naviguer vers la page de messagerie de l'incident
        Navigator.pushNamed(
          context,
          '/incident-chat',
          arguments: incidentId,
        );
        break;
      case 'admin_action':
        // Naviguer vers le panneau admin si l'utilisateur est admin
        Navigator.pushNamed(context, '/admin');
        break;
      default:
        // Navigation par défaut vers les notifications
        Navigator.pushNamed(context, '/notifications');
    }
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Widget pour envelopper MaterialApp
class NotificationWrapper extends StatelessWidget {
  final Widget child;

  const NotificationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotificationReceived: (message) {
        // Afficher un snackbar ou un dialogue
        _showNotificationSnackBar(context, message);
      },
      child: child,
    );
  }

  void _showNotificationSnackBar(BuildContext context, RemoteMessage message) {
    final String? title = message.notification?.title;
    final String? body = message.notification?.body;

    if (title != null && body != null && ScaffoldMessenger.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(body),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              // La navigation sera gérée par le stream
            },
          ),
        ),
      );
    }
  }


}

// Widget pour afficher le statut des notifications
class NotificationStatusIndicator extends StatefulWidget {
  const NotificationStatusIndicator({super.key});

  @override
  State<NotificationStatusIndicator> createState() => _NotificationStatusIndicatorState();
}

class _NotificationStatusIndicatorState extends State<NotificationStatusIndicator> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await PushNotificationService.areNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
        color: _notificationsEnabled ? Colors.green : Colors.grey,
      ),
      onPressed: () async {
        await _checkNotificationStatus();
        
        if (!_notificationsEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les notifications sont désactivées. Veuillez les activer dans les paramètres.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      tooltip: _notificationsEnabled ? 'Notifications activées' : 'Notifications désactivées',
    );
  }
}

// Page de test pour les notifications
class NotificationTestPage extends StatefulWidget {
  const NotificationTestPage({super.key});

  @override
  State<NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<NotificationTestPage> {
  String? _fcmToken;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationInfo();
  }

  Future<void> _loadNotificationInfo() async {
    final token = PushNotificationService.fcmToken;
    final enabled = await PushNotificationService.areNotificationsEnabled();
    
    setState(() {
      _fcmToken = token;
      _notificationsEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut des Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _notificationsEnabled ? Icons.check_circle : Icons.error,
                          color: _notificationsEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _notificationsEnabled ? 'Activées' : 'Désactivées',
                          style: TextStyle(
                            color: _notificationsEnabled ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_fcmToken != null)
                      SelectableText(
                        _fcmToken!,
                        style: const TextStyle(fontSize: 12),
                      )
                    else
                      const Text('Token non disponible'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadNotificationInfo,
                      child: const Text('Actualiser'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions de Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await PushNotificationService.subscribeToTopic('test_topic');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abonné au topic test_topic')),
                        );
                      },
                      child: const Text('S\'abonner au topic de test'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await PushNotificationService.unsubscribeFromTopic('test_topic');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Désabonné du topic test_topic')),
                        );
                      },
                      child: const Text('Se désabonner du topic de test'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await PushNotificationService.clearAllNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications effacées')),
                        );
                      },
                      child: const Text('Effacer toutes les notifications'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
