const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

// Initialiser Firebase Admin SDK
const serviceAccount = require('./firebase-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Votre configuration Firebase
});

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Route pour envoyer une notification push à un utilisateur spécifique
app.post('/api/send-notification', async (req, res) => {
  try {
    const { token, title, body, data, imageUrl } = req.body;

    if (!token || !title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Token, title et body sont requis'
      });
    }

    const message = {
      token: token,
      notification: {
        title: title,
        body: body,
        ...(imageUrl && { imageUrl: imageUrl })
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'community_security_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default',
          clickAction: 'FLUTTER_NOTIFICATION_CLICK'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    
    console.log('Notification envoyée avec succès:', response);
    
    res.json({
      success: true,
      messageId: response,
      message: 'Notification envoyée avec succès'
    });

  } catch (error) {
    console.error('Erreur envoi notification:', error);
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la notification',
      error: error.message
    });
  }
});

// Route pour envoyer des notifications à plusieurs utilisateurs
app.post('/api/send-bulk-notification', async (req, res) => {
  try {
    const { tokens, title, body, data, imageUrl } = req.body;

    if (!tokens || !Array.isArray(tokens) || tokens.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Tokens array est requis et ne doit pas être vide'
      });
    }

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Title et body sont requis'
      });
    }

    const message = {
      notification: {
        title: title,
        body: body,
        ...(imageUrl && { imageUrl: imageUrl })
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'community_security_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    // Envoyer à tous les tokens (max 500 tokens par requête)
    const chunks = [];
    for (let i = 0; i < tokens.length; i += 500) {
      chunks.push(tokens.slice(i, i + 500));
    }

    const results = [];
    for (const chunk of chunks) {
      const response = await admin.messaging().sendMulticast({
        ...message,
        tokens: chunk
      });
      results.push(response);
    }

    const totalSuccess = results.reduce((sum, r) => sum + r.successCount, 0);
    const totalFailure = results.reduce((sum, r) => sum + r.failureCount, 0);

    console.log(`Notifications envoyées: ${totalSuccess} succès, ${totalFailure} échecs`);

    res.json({
      success: true,
      totalSent: tokens.length,
      successCount: totalSuccess,
      failureCount: totalFailure,
      results: results
    });

  } catch (error) {
    console.error('Erreur envoi bulk notification:', error);
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi des notifications',
      error: error.message
    });
  }
});

// Route pour envoyer une notification à un topic
app.post('/api/send-topic-notification', async (req, res) => {
  try {
    const { topic, title, body, data, imageUrl } = req.body;

    if (!topic || !title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Topic, title et body sont requis'
      });
    }

    const message = {
      topic: topic,
      notification: {
        title: title,
        body: body,
        ...(imageUrl && { imageUrl: imageUrl })
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'community_security_channel',
          icon: '@mipmap/ic_launcher',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    
    console.log('Notification topic envoyée avec succès:', response);
    
    res.json({
      success: true,
      messageId: response,
      message: 'Notification topic envoyée avec succès'
    });

  } catch (error) {
    console.error('Erreur envoi notification topic:', error);
    
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la notification topic',
      error: error.message
    });
  }
});

// Routes spécifiques pour votre application de sécurité communautaire

// Notifier un nouvel incident
app.post('/api/notify-new-incident', async (req, res) => {
  try {
    const { incidentId, title, location, severity, tokens } = req.body;

    const message = {
      notification: {
        title: '🚨 Nouvel Incident Signalé',
        body: `${title} - ${location}`,
      },
      data: {
        type: 'new_incident',
        incidentId: incidentId,
        severity: severity,
        location: location
      }
    };

    let response;
    if (tokens && Array.isArray(tokens)) {
      // Envoyer à des tokens spécifiques
      response = await admin.messaging().sendMulticast({
        ...message,
        tokens: tokens
      });
    } else {
      // Envoyer à tous les utilisateurs du topic
      response = await admin.messaging().send({
        ...message,
        topic: 'all_users'
      });
    }

    res.json({
      success: true,
      message: 'Notification d\'incident envoyée',
      response: response
    });

  } catch (error) {
    console.error('Erreur notification incident:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la notification d\'incident',
      error: error.message
    });
  }
});

// Notifier une mise à jour d'incident
app.post('/api/notify-incident-updated', async (req, res) => {
  try {
    const { incidentId, status, tokens } = req.body;

    const message = {
      notification: {
        title: '📝 Incident Mis à Jour',
        body: `L'incident a été mis à jour: ${status}`,
      },
      data: {
        type: 'incident_updated',
        incidentId: incidentId,
        status: status
      }
    };

    let response;
    if (tokens && Array.isArray(tokens)) {
      response = await admin.messaging().sendMulticast({
        ...message,
        tokens: tokens
      });
    } else {
      response = await admin.messaging().send({
        ...message,
        topic: 'all_users'
      });
    }

    res.json({
      success: true,
      message: 'Notification de mise à jour envoyée',
      response: response
    });

  } catch (error) {
    console.error('Erreur notification mise à jour:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la notification de mise à jour',
      error: error.message
    });
  }
});

// Notifier un nouveau message
app.post('/api/notify-new-message', async (req, res) => {
  try {
    const { incidentId, senderName, message, userToken } = req.body;

    const notificationMessage = {
      token: userToken,
      notification: {
        title: `💬 Nouveau message de ${senderName}`,
        body: message.length > 100 ? message.substring(0, 100) + '...' : message,
      },
      data: {
        type: 'new_message',
        incidentId: incidentId,
        senderName: senderName
      }
    };

    const response = await admin.messaging().send(notificationMessage);

    res.json({
      success: true,
      message: 'Notification de message envoyée',
      messageId: response
    });

  } catch (error) {
    console.error('Erreur notification message:', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'envoi de la notification de message',
      error: error.message
    });
  }
});

// Route de test
app.get('/api/test', (req, res) => {
  res.json({
    success: true,
    message: 'FCM Service is running!',
    timestamp: new Date().toISOString()
  });
});

// Démarrer le serveur
app.listen(PORT, () => {
  console.log(`🚀 Serveur FCM démarré sur le port ${PORT}`);
  console.log(`📱 Service de notifications Firebase Cloud Messaging actif`);
});

module.exports = app;
