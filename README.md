# 📱 Community Security Alert - Mobile App

**Projet CS27 - Groupe 16**  
Cette application Flutter est le client mobile de la plateforme **Community Security Alert**. Elle permet aux citoyens de signaler des incidents en temps réel, de consulter les alertes locales et de communiquer avec les autorités.

---

## 🛠️ Installation et Configuration Rapide

Pour que l'application fonctionne correctement sur votre machine ou votre téléphone, suivez attentivement ces étapes.

### 1. Configuration du Backend
L'application mobile a besoin que le serveur tourne pour fonctionner.
1. Allez dans votre dossier backend (ex: `cominity_system_management/backend`).
2. Installez les dépendances : `npm install`
3. Lancez le serveur : `npm run dev` (ou `node server.js`)
4. **Important** : Assurez-vous que votre base de données MongoDB est active.

### 2. Installation de Flutter
1. Dans le dossier de cette application (`flutter_app`), installez les dépendances Flutter :
   ```bash
   flutter pub get
   ```

### 3. Configuration de l'IP (CRUCIAL)
Pour que l'application puisse "voir" votre serveur (qui tourne sur votre PC) depuis un téléphone ou un émulateur, vous devez configurer l'adresse IP.

1. Ouvrez le fichier : `lib/services/api_service.dart`
2. Modifiez la variable `_manualServerIp` à la ligne 14 :
   ```dart
   static const String _manualServerIp = "VOTRE_IP_ICI"; // ex: "192.168.1.15"
   ```
   *Astuce : Tapez `ipconfig` dans un terminal Windows pour trouver votre adresse IPv4.*

---

## 🚀 Lancement

### Sur Émulateur ou Web
```bash
flutter run
```

### Sur Téléphone Physique (Recommandé)
1. Connectez votre téléphone en USB (débogage USB activé).
2. Assurez-vous que votre téléphone et votre PC sont sur le **même réseau Wi-Fi**.
3. Lancez l'application : `flutter run`

---

## 📂 Gestion des Erreurs Fréquentes

| Erreur | Solution |
| :--- | :--- |
| **Connection Refused** | Vérifiez que le backend tourne et que l'IP dans `api_service.dart` est correcte. |
| **Images ne s'affichent pas** | Assurez-vous que le dossier `uploads/` existe dans le backend. |
| **Erreur MongoDB** | Vérifiez que votre chaîne de connexion dans le `.env` du backend est valide. |

---

## 📸 Fonctionnalités Mobile
- ✨ **Interface Moderne** : Design sombre premium (Blue & Purple).
- 📸 **Upload Photos** : Prise de photo directe ou galerie pour les signalements.
- 📍 **Géolocalisation** : Détection automatique de la position de l'incident.
- 💬 **Messagerie** : Chat intégré pour discuter avec les modérateurs.
- 🔔 **Notifications Status** : Suivi en temps réel de vos signalements.

---
**Développé avec ❤️ par le Groupe 16.**
