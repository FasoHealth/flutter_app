import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../pages/login_page.dart';

enum AppSection {
  feed,
  dashboard,
  map,
  report,
  myReports,
  notifications,
  adminOverview,
  adminModeration,
  adminUsers,
}

class AppSidebar extends StatefulWidget {
  final AppSection selected;
  final ValueChanged<AppSection> onSelect;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AppSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String _userName = 'Utilisateur';
  String _userRole = 'CITOYEN';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await ApiService.getUserName();
    final role = await ApiService.getUserRole();
    if (mounted) setState(() {
      _userName = name;
      _userRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF0A0D14) : const Color(0xFFF1F5F9);
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final accent = AppTheme.accentPurple;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COMMUNITY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1)),
                      Text('SECURITY ALERT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: textDim, letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sectionHeader('MENU PRINCIPAL', textDim),
                  _menuItem(Icons.dashboard_rounded, 'Tableau de bord', AppSection.dashboard, textColor, accent),
                  _menuItem(Icons.feed_rounded, 'Fil d\'actualité', AppSection.feed, textColor, accent),
                  _menuItem(Icons.map_rounded, 'Carte interactive', AppSection.map, textColor, accent),
                  _menuItem(Icons.add_alert_rounded, 'Signaler incident', AppSection.report, textColor, accent),
                  _menuItem(Icons.folder_shared_rounded, 'Mes signalements', AppSection.myReports, textColor, accent),
                  _menuItem(Icons.notifications_rounded, 'Notifications', AppSection.notifications, textColor, accent),
                  
                  if (_userRole == 'ADMINISTRATEUR') ...[
                    const SizedBox(height: 24),
                    _sectionHeader('ADMINISTRATION', textDim),
                    _menuItem(Icons.analytics_rounded, 'Vue d\'ensemble', AppSection.adminOverview, textColor, accent),
                    _menuItem(Icons.gavel_rounded, 'Modération', AppSection.adminModeration, textColor, accent),
                    _menuItem(Icons.people_alt_rounded, 'Utilisateurs', AppSection.adminUsers, textColor, accent),
                  ],
                  
                  const SizedBox(height: 24),
                  _sectionHeader('PRÉFÉRENCES', textDim),
                  _menuItemAction(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 'Mode ${isDark ? "Clair" : "Sombre"}', textColor, widget.onToggleTheme),
                  _menuItemAction(Icons.logout_rounded, 'Déconnexion', AppTheme.dangerRed, () async {
                    await ApiService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                    }
                  }),
                ],
              ),
            ),
          ),
          
          // User Profile Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161A22) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withOpacity(0.2),
                  child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_userRole.toLowerCase(), style: TextStyle(fontSize: 11, color: textDim)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withOpacity(0.5), letterSpacing: 1.5)),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, AppSection section, Color normalColor, Color activeColor) {
    final selected = widget.selected == section;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: () => widget.onSelect(section),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: activeColor.withOpacity(0.1),
        leading: Icon(icon, color: selected ? activeColor : normalColor.withOpacity(0.7), size: 22),
        title: Text(label, style: TextStyle(color: selected ? activeColor : normalColor, fontSize: 14, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        minLeadingWidth: 20,
      ),
    );
  }

  Widget _menuItemAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color.withOpacity(0.7), size: 22),
        title: Text(label, style: TextStyle(color: color, fontSize: 14)),
        minLeadingWidth: 20,
      ),
    );
  }
}
