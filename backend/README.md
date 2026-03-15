# Service de Notifications Push FCM

Service backend Node.js pour envoyer des notifications push via Firebase Cloud Messaging (FCM) pour l'application Community Security.

## Configuration

### 1. Installation des dépendances

```bash
npm install
```

### 2. Configuration Firebase

1. Allez dans la [Console Firebase](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. allez dans **Paramètres du projet** > **Comptes de service**
4. Cliquez sur **Générer une nouvelle clé privée**
5. Téléchargez le fichier JSON et renommez-le `firebase-service-account-key.json`
6. Placez ce fichier dans le répertoire `backend/`

### 3. Démarrage du serveur

```bash
# Production
npm start

# Développement (avec nodemon)
npm run dev
```

Le serveur démarrera sur le port 5000 par défaut.

## API Endpoints

### Notifications individuelles

**POST** `/api/send-notification`

Envoie une notification à un appareil spécifique.

```json
{
  "token": "fcm_token_de_l_appareil",
  "title": "Titre de la notification",
  "body": "Contenu de la notification",
  "data": {
    "type": "new_incident",
    "incidentId": "12345"
  },
  "imageUrl": "https://example.com/image.jpg"
}
```

### Notifications multiples

**POST** `/api/send-bulk-notification`

Envoie une notification à plusieurs appareils.

```json
{
  "tokens": ["token1", "token2", "token3"],
  "title": "Titre de la notification",
  "body": "Contenu de la notification",
  "data": {
    "type": "admin_action"
  }
}
```

### Notifications par topic

**POST** `/api/send-topic-notification`

Envoie une notification à tous les abonnés d'un topic.

```json
{
  "topic": "all_users",
  "title": "Titre de la notification",
  "body": "Contenu de la notification",
  "data": {
    "type": "system_update"
  }
}
```

### Endpoints spécifiques à l'application

#### Nouvel incident

**POST** `/api/notify-new-incident`

```json
{
  "incidentId": "12345",
  "title": "Vol signalé",
  "location": "Centre-ville",
  "severity": "high",
  "tokens": ["token1", "token2"] // Optionnel
}
```

#### Incident mis à jour

**POST** `/api/notify-incident-updated`

```json
{
  "incidentId": "12345",
  "status": "résolu",
  "tokens": ["token1", "token2"] // Optionnel
}
```

#### Nouveau message

**POST** `/api/notify-new-message`

```json
{
  "incidentId": "12345",
  "senderName": "Jean Dupont",
  "message": "J'ai vu quelque chose de suspect...",
  "userToken": "token_du_destinataire"
}
```

### Test

**GET** `/api/test`

Vérifie que le service fonctionne correctement.

## Intégration avec Flutter

Dans votre application Flutter, utilisez les méthodes du `PushNotificationService` :

```dart
// Envoyer le token au backend (déjà implémenté)
await ApiService.updateFCMToken(token);

// S'abonner à des topics
await PushNotificationService.subscribeToTopic('all_users');
await PushNotificationService.subscribeToTopic('admin_users');

// Écouter les messages
PushNotificationService.messageStream.listen((message) {
  // Traiter les messages reçus
});
```

## Structure des données

### Types de notifications

- `new_incident`: Nouvel incident signalé
- `incident_updated`: Incident mis à jour
- `new_message`: Nouveau message dans un incident
- `admin_action`: Action administrative

### Données personnalisées

Les notifications peuvent inclure des données personnalisées dans le champ `data` :

```json
{
  "type": "new_incident",
  "incidentId": "12345",
  "severity": "high",
  "location": "Centre-ville",
  "userId": "user123"
}
```

## Déploiement

### Render

1. Connectez-vous à [Render](https://render.com/)
2. Créez un nouveau **Web Service**
3. Liez votre dépôt GitHub
4. Configurez :
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Environment Variables**: Ajoutez `NODE_ENV=production`

### Autres plateformes

Le service peut être déployé sur n'importe quelle plateforme supportant Node.js :
- Heroku
- AWS
- Google Cloud
- Azure
- Serveur dédié/VPS

## Sécurité

- Ne jamais exposer la clé de service Firebase dans le frontend
- Utilisez toujours des variables d'environnement pour les données sensibles
- Validez toujours les données entrantes
- Limitez les requêtes par IP si nécessaire

## Monitoring

Les logs du service affichent :
- Les notifications envoyées avec succès
- Les erreurs d'envoi
- Les statistiques d'utilisation

```bash
# Voir les logs en temps réel
npm run dev
```

## Dépannage

### Erreurs courantes

1. **"INVALID_ARGUMENT"**: Vérifiez le format du token FCM
2. **"UNREGISTERED"**: L'appareil n'est plus enregistré, supprimez le token
3. **"UNAVAILABLE"**: Le service FCM est temporairement indisponible
4. **"INTERNAL"**: Erreur serveur Firebase, réessayez plus tard

### Test des notifications

Utilisez des outils comme Postman ou curl pour tester les endpoints :

```bash
curl -X POST http://localhost:5000/api/send-notification \
  -H "Content-Type: application/json" \
  -d '{
    "token": "votre_test_token",
    "title": "Test",
    "body": "Ceci est une notification de test"
  }'
```
