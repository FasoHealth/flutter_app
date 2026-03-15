import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';
import 'report_incident_page.dart';

class MyReportsPage extends StatefulWidget {
  final VoidCallback onNavigateToReport;

  const MyReportsPage({super.key, required this.onNavigateToReport});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  List<IncidentModel> _incidents = [];
  bool _loading = true;
  String _statusFilter = '';

  final Map<String, String> _catLabels = {
    'theft': 'Vol',
    'assault': 'Agression',
    'vandalism': 'Vandalisme',
    'suspicious_activity': 'Suspect',
    'fire': 'Incendie',
    'kidnapping': 'Enlèvement',
    'other': 'Autre'
  };

  final Map<String, String> _sevLabels = {
    'low': 'Faible',
    'medium': 'Moyen',
    'high': 'Élevé',
    'critical': 'Critique'
  };

  final Map<String, String> _statusLabels = {
    'pending': 'En attente',
    'approved': 'Approuvé',
    'resolved': 'Résolu',
    'rejected': 'Rejeté'
  };

  final List<Map<String, dynamic>> _statusFilters = [
    {'value': '', 'label': 'Tous', 'icon': null},
    {'value': 'pending', 'label': 'En attente', 'icon': Icons.access_time_rounded},
    {'value': 'approved', 'label': 'Approuvés', 'icon': Icons.check_circle_outline_rounded},
    {'value': 'resolved', 'label': 'Résolus', 'icon': Icons.emoji_events_outlined},
    {'value': 'rejected', 'label': 'Rejetés', 'icon': Icons.cancel_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyIncidents();
  }

  Future<void> _fetchMyIncidents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMyIncidents();
      if (mounted) {
        setState(() {
          _incidents = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _statusFilter.isEmpty 
        ? _incidents 
        : _incidents.where((i) => i.status == _statusFilter).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryCards(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
                : filtered.isEmpty
                    ? _buildEmptyState(filtered.length != _incidents.length)
                    : _buildIncidentsList(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Padding réduit
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.folder_outlined, color: AppTheme.brandOrange, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Mes Signalements",
                  style: GoogleFonts.inter(
                    fontSize: 20, // Plus petit pour éviter l'overflow
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF222222)
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Suivez vos alertes envoyées",
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIncidentPage())),
            icon: const Icon(Icons.add, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.brandOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_loading || _incidents.isEmpty) return const SizedBox.shrink();

    final total = _incidents.length;
    final approved = _incidents.where((i) => i.status == 'approved').length;
    final pending = _incidents.where((i) => i.status == 'pending').length;
    final resolved = _incidents.where((i) => i.status == 'resolved').length;
    final rejected = _incidents.where((i) => i.status == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildSummaryMiniCard("Total", total.toString(), AppTheme.brandOrange, AppTheme.brandOrangePale),
          _buildSummaryMiniCard("Approuvés", approved.toString(), AppTheme.green, AppTheme.greenBg),
          _buildSummaryMiniCard("En attente", pending.toString(), AppTheme.yellow, AppTheme.yellowBg),
          _buildSummaryMiniCard("Résolus", resolved.toString(), AppTheme.blue, AppTheme.blueBg),
          _buildSummaryMiniCard("Rejetés", rejected.toString(), AppTheme.red, const Color(0xFFFFEBEE)),
        ],
      ),
    );
  }

  Widget _buildSummaryMiniCard(String label, String value, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5A6478))),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _statusFilters.map((f) {
          final active = _statusFilter == f['value'];
          return InkWell(
            onTap: () => setState(() => _statusFilter = f['value'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppTheme.brandOrange : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppTheme.brandOrange : const Color(0xFFE8E3DB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (f['icon'] != null) ...[
                    Icon(f['icon'] as IconData, size: 14, color: active ? Colors.white : const Color(0xFF5A6478)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    f['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF5A6478),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncidentsList(List<IncidentModel> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildIncidentCard(filtered[index]),
    );
  }

  Widget _buildIncidentCard(IncidentModel inc) {
    final statusColor = _getStatusColor(inc.status);
    
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8E3DB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, size: 20, color: Color(0xFF1A2035)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text("Le ${inc.createdAt.day}/${inc.createdAt.month}/${inc.createdAt.year}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9BA3B4))),
                    ],
                  ),
                ),
                _buildStatusBadge(inc.status),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge(_catLabels[inc.category] ?? inc.category, const Color(0xFFF1F5F9)),
                _buildBadge(_sevLabels[inc.severity] ?? inc.severity, const Color(0xFFF1F5F9)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              inc.description,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5A6478), height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9BA3B4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    inc.location['address'] ?? "Lieu non précisé", 
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5A6478)), 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9BA3B4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppTheme.green;
      case 'resolved': return AppTheme.blue;
      case 'rejected': return AppTheme.red;
      default: return AppTheme.yellow;
    }
  }

  Widget _buildBadge(String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF475569))),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = AppTheme.yellow;
    if (status == 'approved') color = AppTheme.green;
    if (status == 'resolved') color = AppTheme.blue;
    if (status == 'rejected') color = AppTheme.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(_statusLabels[status] ?? status, style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            isFiltered ? "Aucun signalement dans cette catégorie" : "Aucun signalement envoyé",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            isFiltered ? "Essayez un autre filtre." : "Vous n'avez pas encore signalé d'incident.",
            style: GoogleFonts.inter(color: const Color(0xFF999999)),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIncidentPage())),
              icon: const Icon(Icons.flash_on_rounded),
              label: const Text("Signaler maintenant"),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandOrange, foregroundColor: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
