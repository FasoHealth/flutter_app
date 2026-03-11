import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/messenger_dialog.dart';

class IncidentDetailPage extends StatefulWidget {
  final IncidentModel incident;

  const IncidentDetailPage({super.key, required this.incident});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  String _userRole = '';
  String _userId = '';
  bool _isLoading = true;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.incident.status;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final role = await ApiService.getUserRole();
    final id = await ApiService.getUserId();
    if (mounted) {
      setState(() {
        _userRole = role;
        _userId = id ?? '';
        _isLoading = false;
      });
    }
  }

  void _openMessenger() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessengerDialog(
        incidentId: widget.incident.id,
        incidentTitle: widget.incident.title,
      ),
    );
  }

  Future<void> _resolve() async {
    final ok = await ApiService.markIncidentResolved(widget.incident.id);
    if (ok && mounted) {
      setState(() {
        _currentStatus = 'resolved';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement marqué comme résolu.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    final bool isMyReport = _userId == widget.incident.reportedBy;
    final bool canResolve = _currentStatus == 'approved' && (isMyReport || _userRole == 'ADMINISTRATEUR');

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.3),
            child: const BackButton(color: Colors.white),
          ),
        ),
      ),
      floatingActionButton: (isMyReport || _userRole == 'ADMINISTRATEUR') 
        ? FloatingActionButton.extended(
            onPressed: _openMessenger,
            label: const Text('DISCUTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            icon: const Icon(Icons.forum_rounded),
            backgroundColor: AppTheme.accentPurple,
          )
        : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Hero Section
            Stack(
              children: [
                if (widget.incident.images.isNotEmpty)
                  SizedBox(
                    height: 400,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: widget.incident.images.length,
                      itemBuilder: (context, index) => Image.network(widget.incident.images[index], fit: BoxFit.cover),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: AppTheme.cardDark,
                    child: Center(child: Icon(Icons.image_not_supported_rounded, size: 60, color: textDim.withOpacity(0.3))),
                  ),
                Positioned(
                  bottom: -2,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statusBadge(_currentStatus),
                      const SizedBox(width: 12),
                      _severityBadge(widget.incident.severity),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.incident.title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, height: 1.1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.accentPurple),
                      const SizedBox(width: 6),
                      Text('${widget.incident.createdAt.day}/${widget.incident.createdAt.month}/${widget.incident.createdAt.year} • ${widget.incident.createdAt.hour}:${widget.incident.createdAt.minute.toString().padLeft(2,"0")}', style: TextStyle(color: textDim, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  
                  if (canResolve)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton.icon(
                        onPressed: _resolve,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('MARQUER COMME RÉSOLU'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          minimumSize: const Size(double.infinity, 54),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                  
                  // Category Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.category_rounded, color: AppTheme.accentPurple, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CATÉGORIE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1)),
                            Text(widget.incident.category.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textDim, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text(widget.incident.description, style: TextStyle(fontSize: 16, color: textColor, height: 1.6)),
                  
                  const SizedBox(height: 32),
                  Text('LOCALISATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textDim, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: AppTheme.dangerRed, size: 24),
                        const SizedBox(width: 12),
                        Expanded(child: Text(widget.incident.location['address'] ?? 'Lieu non spécifié', style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      CircleAvatar(backgroundColor: textDim.withOpacity(0.1), radius: 20, child: Icon(Icons.person_rounded, color: textDim)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.incident.isAnonymous ? 'Citoyen Anonyme' : 'Signalement vérifié', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Information fournie par un utilisateur', style: TextStyle(color: textDim, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = AppTheme.warningOrange;
    if (status == 'approved') color = AppTheme.successGreen;
    if (status == 'resolved') color = Colors.blue;
    if (status == 'rejected') color = AppTheme.dangerRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _severityBadge(String s) {
    Color color = AppTheme.accentPurple;
    if (s == 'critical') color = AppTheme.dangerRed;
    if (s == 'high') color = AppTheme.warningOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('GRAVITÉ ${s.toUpperCase()}', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
