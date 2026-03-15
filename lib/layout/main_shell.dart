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
import '../pages/admin_appeals_page.dart';
import '../pages/profile_page.dart';

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
      case AppSection.adminAppeals:
        return const AdminAppealsPage();
      case AppSection.profile:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : AppTheme.bgPrimary,
      drawer: !isDesktop 
          ? Drawer(
              child: AppSidebar(
                selected: _section,
                onSelect: (s) {
                  _navigateTo(s);
                  Navigator.pop(context);
                },
                isDarkMode: _isDarkMode,
                onToggleTheme: () {
                  final next = !_isDarkMode;
                  setState(() => _isDarkMode = next);
                  widget.onThemeChanged?.call(next);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              selected: _section,
              onSelect: _navigateTo,
              isDarkMode: _isDarkMode,
              onToggleTheme: () {
                final next = !_isDarkMode;
                setState(() => _isDarkMode = next);
                widget.onThemeChanged?.call(next);
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isDesktop)
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    iconTheme: IconThemeData(color: _isDarkMode ? Colors.white : AppTheme.brandNavy),
                    title: Text(
                      "CS Alert",
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : AppTheme.brandNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
