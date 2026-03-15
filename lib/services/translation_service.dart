import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class T {
  static final ValueNotifier<String> locale = ValueNotifier<String>('fr');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = prefs.getString('language') ?? 'fr';
  }

  static Future<void> toggleLanguage() async {
    final newLang = locale.value == 'fr' ? 'en' : 'fr';
    debugPrint("Switching language to: $newLang");
    locale.value = newLang; // Réaction immédiate !
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLang);
  }

  static String get(String key) {
    return _localizedValues[locale.value]?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'fr': {
       'login': 'Se connecter',
       'register': 'Rejoindre la communauté',
       'report': 'Signaler un incident',
       'home_title': 'Plateforme citoyenne de sécurité',
       'home_subtitle': 'Ensemble, rendons notre communauté plus sûre.',
       'home_desc': "Community Security Alert vous permet de signaler instantanément des incidents de sécurité, d'être alerté en temps réel et de protéger vos proches.",
       'feed': "Fil d'actualité",
       'dashboard': "Tableau de bord",
       'map': 'Carte des alertes',
       'my_reports': 'Mes signalements',
       'moderation': 'Modération',
       'users': 'Utilisateurs',
       'logout': 'Déconnexion',
       'lang_toggle': 'Switch to English',
       'menu_main': 'MENU PRINCIPAL',
       'menu_admin': 'ADMINISTRATION',
       'menu_overview': "Vue d'ensemble",
       'menu_appeals': 'Recours',
       'menu_prefs': 'PRÉFÉRENCES',
       'menu_mode': 'Mode',
       'mode_light': 'Clair',
       'mode_dark': 'Sombre',
       'notifications': 'Notifications',
       'profile_title': 'Mon Profil',
       'profile_role_citizen': 'CITOYEN',
       'profile_role_admin': 'ADMIN',
       'profile_stats_alerts': 'Alertes',
       'profile_stats_impact': 'Impact',
       'profile_settings_title': 'Paramètres du profil',
       'profile_settings_desc': 'Gérez vos informations et préférences de contact.',
       'profile_name': 'Nom complet',
       'profile_phone': 'Numéro de téléphone',
       'profile_email': 'E-mail (non modifiable)',
       'profile_city': 'Ville de résidence',
       'profile_city_placeholder': 'Ouagadougou',
       'profile_save': 'Sauvegarder mon profil',
       'profile_saving': 'Enregistrement...',
       'profile_saved': 'Enregistré',
       'profile_notif_title': 'Préférences de notification',
       'profile_notif_radius': 'Rayon de surveillance actif',
    },
    'en': {
       'login': 'Login',
       'register': 'Join the community',
       'report': 'Report an incident',
       'home_title': 'Citizen Security Platform',
       'home_subtitle': 'Together, let\'s make our community safer.',
       'home_desc': 'Community Security Alert allows you to instantly report security incidents, get real-time alerts, and protect your loved ones.',
       'feed': 'News Feed',
       'dashboard': 'Dashboard',
       'map': 'Alerts Map',
       'my_reports': 'My Reports',
       'moderation': 'Moderation',
       'users': 'Users',
       'logout': 'Logout',
       'lang_toggle': 'Passer en Français',
       'menu_main': 'MAIN MENU',
       'menu_admin': 'ADMINISTRATION',
       'menu_overview': 'Overview',
       'menu_appeals': 'Appeals',
       'menu_prefs': 'PREFERENCES',
       'menu_mode': 'Mode',
       'mode_light': 'Light',
       'mode_dark': 'Dark',
       'notifications': 'Notifications',
       'profile_title': 'My Profile',
       'profile_role_citizen': 'CITIZEN',
       'profile_role_admin': 'ADMIN',
       'profile_stats_alerts': 'Alerts',
       'profile_stats_impact': 'Impact',
       'profile_settings_title': 'Profile Settings',
       'profile_settings_desc': 'Manage your contact information and preferences.',
       'profile_name': 'Full Name',
       'profile_phone': 'Phone Number',
       'profile_email': 'Email (read-only)',
       'profile_city': 'City of Residence',
       'profile_city_placeholder': 'London',
       'profile_save': 'Save my profile',
       'profile_saving': 'Saving...',
       'profile_saved': 'Saved',
       'profile_notif_title': 'Notification Preferences',
       'profile_notif_radius': 'Active Surveillance Radius',
    }
  };
}
