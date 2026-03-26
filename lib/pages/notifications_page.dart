import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data['notifications'] ?? [];
          _unreadCount = data['unreadCount'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id, String? incidentId) async {
    try {
      final success = await ApiService.markNotificationRead(id);
      if (success && mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['_id'] == id);
          if (index != -1 && !_notifications[index]['isRead']) {
            _notifications[index]['isRead'] = true;
            _unreadCount = (_unreadCount - 1).clamp(0, 999);
          }
        });
        if (incidentId != null) {
          final incident = await ApiService.getIncidentById(incidentId);
          if (mounted && incident != null) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: incident)));
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur markRead: $e");
    }
  }

  Future<void> _markAllRead() async {
    try {
      final success = await ApiService.markAllNotificationsRead();
      if (success && mounted) {
        setState(() {
          for (var n in _notifications) {
            n['isRead'] = true;
          }
          _unreadCount = 0;
        });
      }
    } catch (e) {
      debugPrint("Erreur markAllRead: $e");
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    final days = diff.inDays;
    return "Il y a ${days}j";
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'incident_approved': return Icons.check_circle_outline_rounded;
      case 'incident_rejected': return Icons.cancel_outlined;
      case 'incident_resolved': return Icons.emoji_events_outlined;
      case 'new_incident_nearby': return Icons.shield_outlined;
      case 'new_message': return Icons.chat_bubble_outline_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'incident_approved': return const Color(0xFF10B981);
      case 'incident_rejected': return const Color(0xFFEF4444);
      case 'incident_resolved': return const Color(0xFF3B82F6);
      case 'new_incident_nearby': return AppTheme.brandOrange;
      case 'new_message': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF5A6478);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotifList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: AppTheme.brandOrange, size: 24),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Notifications",
                        style: GoogleFonts.inter(
                          fontSize: 24, 
                          fontWeight: FontWeight.w700, 
                          color: const Color(0xFF222222)
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.brandOrange, borderRadius: BorderRadius.circular(20)),
                        child: Text("$_unreadCount", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Restez informé de l'évolution de vos signalements.",
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF666666)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 20),
              tooltip: "Tout marquer comme lu",
              style: IconButton.styleFrom(foregroundColor: const Color(0xFF5A6478)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotifList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final type = notif['type'] ?? 'default';
        final isRead = notif['isRead'] ?? false;
        final color = _getNotifColor(type);
        final bgColor = color.withOpacity(0.1);

        return InkWell(
          onTap: () => _markAsRead(notif['_id'], notif['incident']?['_id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead ? Colors.white : const Color(0xFFF8F4EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isRead ? const Color(0xFFE8E3DB) : AppTheme.brandOrange.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getNotifIcon(type), color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'] ?? "",
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppTheme.brandOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Text("NOUVEAU", style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.brandOrange)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif['message'] ?? "",
                        style: GoogleFonts.inter(color: const Color(0xFF5A6478), fontSize: 13, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (notif['incident'] != null)
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, size: 12, color: Color(0xFF9BA3B4)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      notif['incident']['title'] ?? "",
                                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.brandOrange),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF9BA3B4)),
                              const SizedBox(width: 4),
                              Text(
                                _timeAgo(DateTime.parse(notif['createdAt'])),
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF9BA3B4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFE8E3DB)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            "Tout est calme",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "Vous n'avez aucune notification récente.\nSignalez des incidents pour rester informé !",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: const Color(0xFF999999), height: 1.5),
          ),
        ],
      ),
    );
  }
}
