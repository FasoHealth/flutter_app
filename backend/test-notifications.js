const axios = require('axios');

// Configuration du serveur local
const SERVER_URL = 'http://localhost:5000';

// Token FCM de test (remplacez par un vrai token)
const TEST_TOKEN = 'votre_fcm_token_ici';

// Exemples de notifications à tester
const notifications = [
  {
    name: 'Notification simple',
    endpoint: '/api/send-notification',
    data: {
      token: TEST_TOKEN,
      title: '🚨 Test de Notification',
      body: 'Ceci est une notification de test depuis le backend',
      data: {
        type: 'test',
        timestamp: new Date().toISOString()
      }
    }
  },
  {
    name: 'Nouvel incident',
    endpoint: '/api/notify-new-incident',
    data: {
      incidentId: '12345',
      title: 'Vol signalé',
      location: 'Centre commercial',
      severity: 'high',
      tokens: [TEST_TOKEN]
    }
  },
  {
    name: 'Incident mis à jour',
    endpoint: '/api/notify-incident-updated',
    data: {
      incidentId: '12345',
      status: 'En cours d\'investigation',
      tokens: [TEST_TOKEN]
    }
  },
  {
    name: 'Nouveau message',
    endpoint: '/api/notify-new-message',
    data: {
      incidentId: '12345',
      senderName: 'Agent Smith',
      message: 'Nous avons reçu votre signalement et nous enquêtons.',
      userToken: TEST_TOKEN
    }
  },
  {
    name: 'Notification topic',
    endpoint: '/api/send-topic-notification',
    data: {
      topic: 'all_users',
      title: '📢 Système',
      body: 'Maintenance prévue ce soir à 22h',
      data: {
        type: 'system_maintenance',
        scheduled_time: '22:00'
      }
    }
  }
];

// Fonction pour tester une notification
async function testNotification(notification) {
  try {
    console.log(`\n📤 Envoi: ${notification.name}`);
    console.log('Données:', JSON.stringify(notification.data, null, 2));
    
    const response = await axios.post(`${SERVER_URL}${notification.endpoint}`, notification.data);
    
    console.log('✅ Succès:', response.data);
    return true;
  } catch (error) {
    console.error('❌ Erreur:', error.response?.data || error.message);
    return false;
  }
}

// Fonction pour tester la connexion au serveur
async function testServerConnection() {
  try {
    console.log('🔍 Test de connexion au serveur...');
    const response = await axios.get(`${SERVER_URL}/api/test`);
    console.log('✅ Serveur connecté:', response.data);
    return true;
  } catch (error) {
    console.error('❌ Impossible de se connecter au serveur:', error.message);
    console.log('💡 Assurez-vous que le serveur est démarré avec: npm start');
    return false;
  }
}

// Menu interactif
async function showMenu() {
  const readline = require('readline');
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    console.log('\n📱 Menu de Test Notifications FCM');
    console.log('=====================================');
    
    notifications.forEach((notif, index) => {
      console.log(`${index + 1}. ${notif.name}`);
    });
    
    console.log('0. Tester toutes les notifications');
    console.log('q. Quitter');
    
    rl.question('\nChoisissez une option: ', (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// Fonction principale
async function main() {
  console.log('🚀 Script de Test Notifications FCM');
  console.log('====================================');
  
  // Vérifier la connexion au serveur
  const serverConnected = await testServerConnection();
  if (!serverConnected) {
    process.exit(1);
  }
  
  // Vérifier le token
  if (TEST_TOKEN === 'votre_fcm_token_ici') {
    console.log('\n⚠️  ATTENTION: Vous devez remplacer TEST_TOKEN par un vrai FCM token');
    console.log('   Lancez l\'app Flutter et récupérez le token depuis les logs ou la page de test');
  }
  
  while (true) {
    const choice = await showMenu();
    
    if (choice === 'q') {
      console.log('\n👋 Au revoir!');
      break;
    }
    
    if (choice === '0') {
      console.log('\n📤 Envoi de toutes les notifications...');
      let successCount = 0;
      
      for (const notif of notifications) {
        const success = await testNotification(notif);
        if (success) successCount++;
        
        // Pause entre les notifications
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      
      console.log(`\n📊 Résultat: ${successCount}/${notifications.length} notifications envoyées avec succès`);
    } else {
      const index = parseInt(choice) - 1;
      if (index >= 0 && index < notifications.length) {
        await testNotification(notifications[index]);
      } else {
        console.log('❌ Option invalide');
      }
    }
    
    console.log('\nAppuyez sur Entrée pour continuer...');
    await new Promise(resolve => {
      process.stdin.once('data', resolve);
    });
  }
}

// Exécuter si le script est appelé directement
if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  testNotification,
  testServerConnection,
  notifications
};
