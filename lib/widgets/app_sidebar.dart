import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../pages/login_page.dart';
import '../services/translation_service.dart';

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
  adminAppeals,
  profile,
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
  String _userRole = 'citizen';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await ApiService.getUserName();
    final role = await ApiService.getUserRole();
    if (mounted) {
      setState(() {
        _userName = name;
        _userRole = role;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A2035);
    final textDim = isDark ? Colors.white60 : const Color(0xFF5A6478);
    final accent = AppTheme.brandOrange;

    return ValueListenableBuilder<String>(
      valueListenable: T.locale,
      builder: (context, lang, child) {
        return Container(
          width: 280,
          decoration: BoxDecoration(
            color: bg,
            border: Border(right: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE8E3DB))),
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
                    Text(
                      'CS Alert',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _sectionHeader(T.get('menu_main'), textDim),
                      _menuItem(Icons.dashboard_outlined, T.get('dashboard'), AppSection.dashboard, textColor, accent),
                      _menuItem(Icons.grid_view_rounded, T.get('feed'), AppSection.feed, textColor, accent),
                      _menuItem(Icons.map_outlined, T.get('map'), AppSection.map, textColor, accent),
                      _menuItem(Icons.add_alert_rounded, T.get('report'), AppSection.report, textColor, accent),
                      _menuItem(Icons.folder_open_rounded, T.get('my_reports'), AppSection.myReports, textColor, accent),
                      _menuItem(Icons.notifications_none_rounded, T.get('notifications'), AppSection.notifications, textColor, accent),
                      
                      if (_userRole == 'admin' || _userRole == 'administrateur') ...[
                        const SizedBox(height: 24),
                        _sectionHeader(T.get('menu_admin'), textDim),
                        _menuItem(Icons.analytics_outlined, T.get('menu_overview'), AppSection.adminOverview, textColor, accent),
                        _menuItem(Icons.gavel_rounded, T.get('moderation'), AppSection.adminModeration, textColor, accent),
                        _menuItem(Icons.people_outline_rounded, T.get('users'), AppSection.adminUsers, textColor, accent),
                        _menuItem(Icons.shield_outlined, T.get('menu_appeals'), AppSection.adminAppeals, textColor, accent),
                      ],
                      
                      const SizedBox(height: 24),
                      _sectionHeader(T.get('menu_prefs'), textDim),
                      _menuItemAction(Icons.language_rounded, T.get('lang_toggle'), textColor, () => T.toggleLanguage()),
                      _menuItemAction(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, '${T.get('menu_mode')} ${isDark ? T.get('mode_light') : T.get('mode_dark')}', textColor, widget.onToggleTheme),
                      _menuItemAction(Icons.logout_rounded, T.get('logout'), AppTheme.red, () async {
                        await ApiService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                        }
                      }),
                    ],
                  ),
                ),
              ),
              // User Card
              InkWell(
                onTap: () => widget.onSelect(AppSection.profile),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F4EE),
                    borderRadius: BorderRadius.circular(16),
                    border: widget.selected == AppSection.profile ? Border.all(color: accent, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: accent,
                        child: Text(
                          _getInitials(_userName), 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_userName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(
                                (_userRole == 'admin' || _userRole == 'administrateur') 
                                  ? T.get('profile_role_admin') 
                                  : T.get('profile_role_citizen'),
                              style: TextStyle(color: textDim, fontSize: 10, fontWeight: FontWeight.w700)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
    );
  }

  Widget _menuItem(IconData icon, String label, AppSection section, Color textColor, Color accent) {
    final isSelected = widget.selected == section;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () => widget.onSelect(section),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected 
              ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
              : null,
          ),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: Icon(
              icon, 
              color: isSelected ? Colors.white : textColor.withOpacity(0.6), 
              size: 20
            ),
            title: Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.white : textColor, 
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              )
            ),
            selected: isSelected,
          ),
        ),
      ),
    );
  }

  Widget _menuItemAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: color.withOpacity(0.7), size: 20),
        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Utilisateur') return 'U';
    final parts = name.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
