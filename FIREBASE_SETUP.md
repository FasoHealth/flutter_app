# Guide d'Installation Firebase Cloud Messaging

Ce guide vous explique comment configurer complètement Firebase Cloud Messaging (FCM) pour votre application Flutter Community Security.

## 📋 Prérequis

- Compte Firebase (gratuit)
- Android Studio ou VS Code
- Node.js 16+ (pour le backend)
- Un appareil Android ou iOS pour les tests

## 🔥 Configuration Firebase

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur **"Ajouter un projet"**
3. Donnez un nom à votre projet (ex: `community-security-app`)
4. Activez Google Analytics si souhaité
5. Cliquez sur **"Créer un projet"**

### 2. Ajouter l'application Android

1. Dans votre projet Firebase, cliquez sur **"Ajouter une application"**
2. Choisissez **"Android"**
3. **Nom du package**: `com.example.community_security_alert_app_flutter`
   - Trouvez ce nom dans `android/app/build.gradle.kts` à la ligne `applicationId`
4. **Nom de l'application**: `Community Security Alert`
5. **Certificat de signature de débogage**: 
   - Exécutez cette commande dans votre projet Flutter:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   - Copiez le **SHA-1** de la ligne `debug` et collez-le dans Firebase
6. Téléchargez `google-services.json`
7. Placez-le dans `android/app/google-services.json`

### 3. Ajouter l'application iOS

1. Dans Firebase, cliquez sur **"Ajouter une application"**
2. Choisissez **"iOS"**
3. **ID de bundle iOS**: `com.example.communitySecurityAlertAppFlutter`
4. **Nom de l'application**: `Community Security Alert`
5. Téléchargez `GoogleService-Info.plist`
6. Placez-le dans `ios/Runner/GoogleService-Info.plist`

### 4. Configurer Cloud Messaging

1. Dans Firebase Console, allez dans **"Cloud Messaging"**
2. Dans l'onglet **"Paramètres"**, configurez:
   - **Nom du serveur**: `Community Security Server`
   - **URL du serveur**: `https://votre-domaine.com/api`
   - **Clés du serveur**: Générez une nouvelle paire de clés

## 🤖 Configuration Android

### 1. Mettre à jour build.gradle (niveau app)

Le fichier `android/app/build.gradle.kts` est déjà configuré avec:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

### 2. Mettre à jour build.gradle (niveau projet)

Le fichier `android/build.gradle.kts` est déjà configuré avec:
```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### 3. Ajouter les permissions

Dans `android/app/src/main/AndroidManifest.xml`, ajoutez:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 4. Configurer ProGuard (optionnel)

Si vous utilisez ProGuard, ajoutez dans `android/app/proguard-rules.pro`:
```
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
```

## 🍏 Configuration iOS

### 1. Mettre à jour AppDelegate

Dans `ios/Runner/AppDelegate.swift`, ajoutez:
```swift
import Firebase
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Demander la permission de notification
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    } else {
      let settings: UIUserNotificationSettings =
        UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
      application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 2. Mettre à jour Info.plist

Dans `ios/Runner/Info.plist`, ajoutez:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>
```

## 📱 Configuration Flutter

Les dépendances sont déjà ajoutées dans `pubspec.yaml`:
```yaml
firebase_core: ^2.24.2
firebase_messaging: ^14.7.10
flutter_local_notifications: ^16.3.2
```

### Installation des dépendances

```bash
flutter pub get
```

## 🖥️ Configuration Backend

### 1. Télécharger la clé de service

1. Dans Firebase Console → **Paramètres du projet** → **Comptes de service**
2. Cliquez sur **"Générer une nouvelle clé privée"**
3. Téléchargez le fichier JSON
4. Renommez-le `firebase-service-account-key.json`
5. Placez-le dans `backend/`

### 2. Installer les dépendances backend

```bash
cd backend
npm install
```

### 3. Démarrer le serveur backend

```bash
# Développement
npm run dev

# Production
npm start
```

Le serveur démarrera sur `http://localhost:5000`

## 🧪 Test de l'intégration

### 1. Récupérer le FCM Token

1. Lancez l'application Flutter:
   ```bash
   flutter run
   ```
2. Allez sur la page de test: `http://localhost:xxxx/#/notification-test`
3. Copiez le FCM Token affiché

### 2. Tester les notifications

1. Dans le dossier `backend`, mettez à jour `TEST_TOKEN` dans `test-notifications.js`
2. Lancez le script de test:
   ```bash
   node test-notifications.js
   ```
3. Choisissez une notification à tester

### 3. Vérifier les logs

**Flutter:**
- Les logs FCM apparaissent dans la console avec les emojis 🔑, 📱, 📨

**Backend:**
- Les logs du serveur montrent les notifications envoyées

## 📊 Types de notifications

L'application supporte plusieurs types de notifications:

### 1. Nouvel incident
```json
{
  "type": "new_incident",
  "incidentId": "12345",
  "severity": "high",
  "location": "Centre-ville"
}
```

### 2. Incident mis à jour
```json
{
  "type": "incident_updated",
  "incidentId": "12345",
  "status": "résolu"
}
```

### 3. Nouveau message
```json
{
  "type": "new_message",
  "incidentId": "12345",
  "senderName": "Agent Smith"
}
```

### 4. Action admin
```json
{
  "type": "admin_action",
  "userId": "user123"
}
```

## 🚀 Déploiement

### Backend sur Render

1. Créez un compte sur [Render](https://render.com/)
2. Connectez votre dépôt GitHub
3. Créez un **Web Service** avec:
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment Variables**: 
     - `NODE_ENV=production`

### Mise à jour de l'URL dans Flutter

Dans `lib/services/api_service.dart`, mettez à jour `baseUrl`:
```dart
static String get baseUrl {
  return "https://votre-app-render.onrender.com/api";
}
```

## 🔧 Dépannage

### Problèmes courants

1. **"MISSING_INSTANCE_ID_SERVICE"**
   - Vérifiez que `google-services.json` est bien placé
   - Nettoyez le projet: `flutter clean && flutter pub get`

2. **"UNREGISTERED"**
   - Le token n'est plus valide, l'utilisateur doit réinstaller l'app
   - Vérifiez la configuration Firebase

3. **Notifications non reçues en premier plan**
   - Vérifiez que `flutter_local_notifications` est bien configuré
   - Les permissions sont-elles accordées ?

4. **Backend ne démarre pas**
   - Vérifiez que `firebase-service-account-key.json` est présent
   - Vérifiez les logs: `npm start`

### Debug avancé

**Flutter:**
```dart
// Activer les logs détaillés
await FirebaseMessaging.instance.setAutoInitEnabled(true);
```

**Backend:**
```bash
# Mode debug avec logs détaillés
DEBUG=fcm:* npm start
```

## 📚 Ressources utiles

- [Documentation Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

## 🎯 Prochaines étapes

1. ✅ Configuration Firebase
2. ✅ Service de notifications Flutter
3. ✅ Backend Node.js
4. ✅ Tests et validation
5. 🔄 Intégration avec votre logique métier
6. 🔄 Personnalisation des notifications
7. 🔄 Analytics et monitoring

Votre système de notifications push est maintenant prêt ! 🎉
