import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../models/incident_model.dart';
import '../pages/incident_detail_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToReport;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToNotifications;
  final VoidCallback? onNavigateToMyIncidents;

  const DashboardPage({
    super.key,
    this.onNavigateToReport,
    this.onNavigateToMap,
    this.onNavigateToNotifications,
    this.onNavigateToMyIncidents,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _userName = 'Citoyen';
  List<IncidentModel> _allIncidents = [];
  String _categoryFilter = 'all';
  int _total = 0;
  int _approved = 0;
  int _pending = 0;
  int _resolved = 0;
  bool _isLoading = true;

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'TOUT'},
    {'value': 'theft', 'label': 'VOL'},
    {'value': 'assault', 'label': 'AGRESSION'},
    {'value': 'vandalism', 'label': 'VANDALISME'},
    {'value': 'fire', 'label': 'INCENDIE'},
    {'value': 'accident', 'label': 'ACCIDENT'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await ApiService.getUserName();
    if (mounted) setState(() => _userName = name);

    try {
      final incidents = await ApiService.getMyIncidents();
      if (!mounted) return;

      int approvedCount = 0;
      int pendingCount = 0;
      int resolvedCount = 0;

      for (var i in incidents) {
        if (i.status == 'approved') approvedCount++;
        else if (i.status == 'pending') pendingCount++;
        else if (i.status == 'resolved') resolvedCount++;
      }

      setState(() {
        _allIncidents = incidents;
        _total = incidents.length;
        _approved = approvedCount;
        _pending = pendingCount;
        _resolved = resolvedCount;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<IncidentModel> get _filteredIncidents {
    List<IncidentModel> list = _allIncidents;
    if (_categoryFilter != 'all') {
      list = list.where((i) => i.category == _categoryFilter).toList();
    }
    // Only show approved/resolved for "Alert cards" logic if requested, 
    // but here it's "My Reports", so we show all but let user filter.
    return list.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accentPurple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tableau de bord', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Ravi de vous revoir, $_userName', style: TextStyle(fontSize: 15, color: textDim)),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onNavigateToMyIncidents,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.accentPurple.withOpacity(0.1),
                    child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U', style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth = constraints.maxWidth;
                final itemWidth = (gridWidth - 12 * 3) / 4;
                return Row(
                  children: [
                    _buildMetric(itemWidth, _total.toString(), 'TOTAL', AppTheme.accentPurple, cardBg, textDim),
                    const SizedBox(width: 12),
                    _buildMetric(itemWidth, _approved.toString(), 'APPROUVÉ', AppTheme.successGreen, cardBg, textDim),
                    const SizedBox(width: 12),
                    _buildMetric(itemWidth, _pending.toString(), 'ATTENTE', AppTheme.warningOrange, cardBg, textDim),
                    const SizedBox(width: 12),
                    _buildMetric(itemWidth, _resolved.toString(), 'RÉSOLU', Colors.blue, cardBg, textDim),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Actions Section
            Text('ACTIONS RAPIDES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textDim, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                _actionButton(Icons.add_alert_rounded, 'Signaler', AppTheme.dangerRed, widget.onNavigateToReport),
                const SizedBox(width: 12),
                _actionButton(Icons.map_rounded, 'Carte', AppTheme.accentPurple, widget.onNavigateToMap),
                const SizedBox(width: 12),
                _actionButton(Icons.notifications_rounded, 'Alertes', AppTheme.warningOrange, widget.onNavigateToNotifications),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Recent Section Header with Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mes Signalements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                TextButton(
                  onPressed: widget.onNavigateToMyIncidents,
                  child: const Text('Voir tout', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final selected = _categoryFilter == cat['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat['label']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: selected ? Colors.white : textDim)),
                      selected: selected,
                      onSelected: (val) => setState(() => _categoryFilter = cat['value']!),
                      selectedColor: AppTheme.accentPurple,
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? Colors.transparent : textDim.withOpacity(0.1))),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(),))
            else if (_filteredIncidents.isEmpty)
              _buildEmptyState(cardBg, textColor, textDim)
            else
              ..._filteredIncidents.map((inc) => _buildIncidentTile(inc, cardBg, textColor, textDim)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(double width, String value, String label, Color color, Color cardBg, Color textDim) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: textDim, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentTile(IncidentModel inc, Color cardBg, Color textColor, Color textDim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.description_outlined, color: AppTheme.accentPurple, size: 20),
        ),
        title: Text(inc.title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
        subtitle: Text('${inc.category.toUpperCase()} • ${inc.createdAt.day}/${inc.createdAt.month}', style: TextStyle(color: textDim, fontSize: 13)),
        trailing: _statusChip(inc.status),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = AppTheme.warningOrange;
    if (status == 'approved') color = AppTheme.successGreen;
    if (status == 'resolved') color = Colors.blue;
    if (status == 'rejected') color = AppTheme.dangerRed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(Color cardBg, Color textColor, Color textDim) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 48, color: textDim.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Aucun signalement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Text('Participez à la sécurité de votre ville en signalant les incidents.', textAlign: TextAlign.center, style: TextStyle(color: textDim, fontSize: 12)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: widget.onNavigateToReport, child: const Text('Signaler maintenant')),
        ],
      ),
    );
  }
}
