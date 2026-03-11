import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../pages/feed_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/map_page.dart';
import '../pages/report_incident_page.dart';
import '../pages/my_reports_page.dart';
import '../pages/notifications_page.dart';
import '../pages/admin_overview_page.dart';
import '../pages/admin_moderation_page.dart';
import '../pages/admin_users_page.dart';

class MainShell extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  const MainShell({super.key, required this.isDarkMode, this.onThemeChanged});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  AppSection _section = AppSection.feed;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) _isDarkMode = widget.isDarkMode;
  }

  void _navigateTo(AppSection s) => setState(() => _section = s);

  Widget _buildPage() {
    switch (_section) {
      case AppSection.feed:
        return FeedPage(onNavigateToReport: () => _navigateTo(AppSection.report));
      case AppSection.dashboard:
        return DashboardPage(
          onNavigateToReport: () => _navigateTo(AppSection.report), 
          onNavigateToMap: () => _navigateTo(AppSection.map), 
          onNavigateToNotifications: () => _navigateTo(AppSection.notifications),
          onNavigateToMyIncidents: () => _navigateTo(AppSection.myReports),
        );
      case AppSection.map:
        return const MapPage();
      case AppSection.report:
        return const ReportIncidentPage();
      case AppSection.myReports:
        return MyReportsPage(onNavigateToReport: () => _navigateTo(AppSection.report));
      case AppSection.notifications:
        return const NotificationsPage();
      case AppSection.adminOverview:
        return const AdminOverviewPage();
      case AppSection.adminModeration:
        return const AdminModerationPage();
      case AppSection.adminUsers:
        return const AdminUsersPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      body: Row(

        children: [
          AppSidebar(
            selected: _section,
            onSelect: (s) => setState(() => _section = s),
            isDarkMode: _isDarkMode,
            onToggleTheme: () async {
              final next = !_isDarkMode;
              await AppTheme.setIsDarkMode(next);
              if (mounted) {
                setState(() => _isDarkMode = next);
                widget.onThemeChanged?.call(next);
              }
            },
          ),
          Expanded(child: _buildPage()),
        ],
      ),
    );
  }
}
