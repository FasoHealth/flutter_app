import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';

class AdminModerationPage extends StatefulWidget {
  const AdminModerationPage({super.key});

  @override
  State<AdminModerationPage> createState() => _AdminModerationPageState();
}

class _AdminModerationPageState extends State<AdminModerationPage> {
  List<IncidentModel> _incidents = [];
  bool _loading = true;
  String _activeTab = 'pending';
  String _search = '';
  Map<String, int> _counts = {'pending': 0, 'approved': 0, 'rejected': 0, 'resolved': 0};
  String? _actionLoading;

  final Map<String, String> _catLabels = {
    'theft': 'Vol',
    'assault': 'Sécurité',
    'vandalism': 'Vandalisme',
    'suspicious_activity': 'Suspect',
    'fire': 'Incendie',
    'kidnapping': 'Enlèvement',
    'other': 'Autre'
  };

  final Map<String, IconData> _catIcons = {
    'theft': Icons.shield_outlined,
    'assault': Icons.warning_amber_rounded,
    'vandalism': Icons.gavel_rounded,
    'suspicious_activity': Icons.visibility_outlined,
    'fire': Icons.local_fire_department_outlined,
    'kidnapping': Icons.person_off_outlined,
    'other': Icons.help_outline_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAdminIncidents(status: _activeTab);
      if (mounted) {
        setState(() {
          _incidents = data;
          _loading = false;
          _counts[_activeTab] = data.length;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleModerate(String id, String status) async {
    setState(() => _actionLoading = '$id-$status');
    try {
      final success = await ApiService.moderateIncident(id, status, "Modération par l'administrateur");
      if (success && mounted) {
        _fetchIncidents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de modération.')));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange))
                : _incidents.isEmpty
                    ? _buildEmptyState()
                    : _buildIncidentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppTheme.brandOrange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Modération",
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF222222)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_counts['pending']! + _counts['approved']!} incidents",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _search = val),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Rechercher...",
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _fetchIncidents,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFE8E3DB)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      {'value': 'pending', 'label': 'En attente', 'icon': Icons.access_time_rounded},
      {'value': 'approved', 'label': 'Approuvés', 'icon': Icons.check_circle_outline_rounded},
      {'value': 'rejected', 'label': 'Rejetés', 'icon': Icons.close_rounded},
      {'value': 'resolved', 'label': 'Résolus', 'icon': Icons.emoji_events_outlined},
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE8E3DB)))),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tabs.map((tab) {
          final active = _activeTab == tab['value'];
          return InkWell(
            onTap: () {
              setState(() => _activeTab = tab['value'] as String);
              _fetchIncidents();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? AppTheme.brandOrange : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(tab['icon'] as IconData, size: 14, color: active ? AppTheme.brandOrange : const Color(0xFF9BA3B4)),
                  const SizedBox(width: 6),
                  Text(
                    tab['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? AppTheme.brandOrange : const Color(0xFF9BA3B4),
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

  Widget _buildIncidentList() {
    final filtered = _incidents.where((inc) => 
      _search.isEmpty || 
      inc.title.toLowerCase().contains(_search.toLowerCase()) ||
      (inc.location['address'] ?? '').toLowerCase().contains(_search.toLowerCase())
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildIncidentCard(filtered[index]),
    );
  }

  Widget _buildIncidentCard(IncidentModel inc) {
    final color = _getSeverityColor(inc.severity);
    final bgColor = color.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Icon(_catIcons[inc.category] ?? Icons.warning_amber_rounded, size: 20, color: color)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(_catLabels[inc.category] ?? inc.category, AppTheme.brandOrange),
                        const SizedBox(width: 6),
                        _buildBadge(inc.severity.toUpperCase(), color),
                        const SizedBox(width: 8),
                        Text(_timeAgo(inc.createdAt), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9BA3B4))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            inc.description,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF51596A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF9BA3B4)),
              const SizedBox(width: 4),
              Expanded(child: Text(inc.location['address'] ?? "", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5A6478)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (inc.status == 'pending') ...[
                const SizedBox(width: 8),
                _buildBadge("EN ATTENTE", AppTheme.yellow),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildActions(inc),
        ],
      ),
    );
  }

  Widget _buildActions(IncidentModel inc) {
    return Column(
      children: [
        if (_activeTab == 'pending')
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.check_rounded,
                  label: "Approuver",
                  color: AppTheme.green,
                  onPressed: () => _handleModerate(inc.id, 'approved'),
                  loading: _actionLoading == '${inc.id}-approved',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.close_rounded,
                  label: "Rejeter",
                  color: AppTheme.red,
                  onPressed: () => _handleModerate(inc.id, 'rejected'),
                  loading: _actionLoading == '${inc.id}-rejected',
                ),
              ),
            ],
          ),
        if (_activeTab == 'approved')
          _buildActionButton(
            icon: Icons.emoji_events_outlined,
            label: "Marquer Résolu",
            color: AppTheme.blue,
            onPressed: () => _handleModerate(inc.id, 'resolved'),
            loading: _actionLoading == '${inc.id}-resolved',
            fullWidth: true,
          ),
        const SizedBox(height: 8),
        _buildActionButton(
          icon: Icons.visibility_outlined,
          label: "Voir les détails",
          color: const Color(0xFF1A2035),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
          isOutline: true,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool loading = false,
    bool isOutline = false,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 40,
      child: loading
          ? Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color)))
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutline ? Colors.white : color,
                foregroundColor: isOutline ? color : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isOutline ? BorderSide(color: color) : BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Color _getSeverityColor(String sev) {
    switch (sev) {
      case 'critical': return AppTheme.red;
      case 'high': return const Color(0xFFF97316);
      case 'medium': return AppTheme.yellow;
      default: return AppTheme.green;
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return "Il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "Il y a ${diff.inHours}h";
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            "Tout est traité !",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            "Aucun signalement à modérer dans cet onglet.",
            style: GoogleFonts.inter(color: const Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
