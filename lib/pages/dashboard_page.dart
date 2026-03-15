import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback onNavigateToReport;
  final VoidCallback onNavigateToMap;
  final VoidCallback onNavigateToNotifications;
  final VoidCallback onNavigateToMyIncidents;

  const DashboardPage({
    super.key,
    required this.onNavigateToReport,
    required this.onNavigateToMap,
    required this.onNavigateToNotifications,
    required this.onNavigateToMyIncidents,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic> _stats = {
    'total': 0,
    'approved': 0,
    'pending': 0,
    'resolved': 0,
    'recent': <IncidentModel>[],
  };
  bool _loading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getUserName(),
        ApiService.getMyIncidents(),
      ]);
      
      final name = results[0] as String;
      final incidents = results[1] as List<IncidentModel>;
      
      if (mounted) {
        // Calcul des mois pour le graphique (6 derniers mois)
        final now = DateTime.now();
        final Map<int, int> last6MonthsCounts = {};
        final List<String> monthNames = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
        
        List<Map<String, dynamic>> monthlyData = [];
        for (int i = 5; i >= 0; i--) {
          var d = DateTime(now.year, now.month - i);
          int count = incidents.where((inc) => inc.createdAt.year == d.year && inc.createdAt.month == d.month).length;
          monthlyData.add({
            'label': monthNames[d.month - 1],
            'count': count,
          });
        }

        setState(() {
          _userName = name.split(' ')[0];
          _stats = {
            'total': incidents.length,
            'approved': incidents.where((i) => i.status == 'approved').length,
            'pending': incidents.where((i) => i.status == 'pending').length,
            'resolved': incidents.where((i) => i.status == 'resolved').length,
            'recent': incidents.take(6).toList(),
            'monthlyData': monthlyData,
          };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brandOrange));
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.brandOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Bonjour, ${_userName ?? "CITOYEN"}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.flash_on_rounded, color: AppTheme.brandOrange, size: 28),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bienvenue sur votre tableau de bord citoyen.',
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF666666)),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard('Total Signalés', _stats['total'].toString(), Icons.campaign_rounded, AppTheme.brandOrange, AppTheme.brandOrangePale, constraints.maxWidth),
                  _buildStatCard('Approuvés', _stats['approved'].toString(), Icons.check_circle_outline_rounded, AppTheme.green, AppTheme.greenBg, constraints.maxWidth),
                  _buildStatCard('En attente', _stats['pending'].toString(), Icons.access_time_rounded, AppTheme.yellow, AppTheme.yellowBg, constraints.maxWidth),
                  _buildStatCard('Résolus', _stats['resolved'].toString(), Icons.emoji_events_outlined, AppTheme.blue, AppTheme.blueBg, constraints.maxWidth),
                ],
              );
            }),
            const SizedBox(height: 32),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildMainColumn()),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildSideColumn()),
                ],
              )
            else
              Column(
                children: [
                  _buildMainColumn(),
                  const SizedBox(height: 24),
                  _buildSideColumn(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, Color bgColor, double maxWidth) {
    final isDesktop = maxWidth > 900;
    final cardWidth = isDesktop ? (maxWidth - (3 * 16)) / 4 : (maxWidth - 16) / 2;
    
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainColumn() {
    return Column(
      children: [
        _buildCard(
          title: 'Signalements par mois',
          icon: Icons.bar_chart_rounded,
          child: Container(
            height: 180,
            alignment: Alignment.center,
            child: _stats['total'] > 0 
              ? _buildChartPlaceholder() 
              : Text('Aucune donnée à afficher pour le moment.', style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 14)),
          ),
        ),
        const SizedBox(height: 24),
        _buildCard(
          title: 'Derniers Signalements',
          trailing: TextButton(
            onPressed: widget.onNavigateToMyIncidents,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Voir tout', style: GoogleFonts.inter(color: AppTheme.brandOrange, fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.brandOrange),
              ],
            ),
          ),
          child: (_stats['recent'] as List).isEmpty 
            ? _buildEmptyRecent() 
            : _buildRecentList(),
        ),
      ],
    );
  }

  Widget _buildSideColumn() {
    return Column(
      children: [
        _buildCard(
          title: 'Actions rapides',
          icon: Icons.flash_on_rounded,
          child: Column(
            children: [
              _buildQuickAction('Nouveau signalement', Icons.add_circle_outline_rounded, AppTheme.brandOrange, widget.onNavigateToReport, true),
              _buildQuickAction('Voir notifications', Icons.notifications_none_rounded, const Color(0xFF1A2035), widget.onNavigateToNotifications, false),
              _buildQuickAction('Carte des alertes', Icons.map_outlined, const Color(0xFF1A2035), widget.onNavigateToMap, false),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2035), Color(0xFF2E3D6A)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.brandOrangeLight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'LE SAVIEZ-VOUS ?',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Plus vous ajoutez de détails et de photos précises, plus vite l\'incident sera traité par les autorités.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.75), height: 1.6),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _stats['total'] > 0 ? (_stats['resolved'] / _stats['total']) : 0,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandOrange),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Taux de résolution', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.5))),
                  Text(
                    '${_stats['total'] > 0 ? ((_stats['resolved'] / _stats['total']) * 100).round() : 0}%',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.brandOrangeLight),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required String title, IconData? icon, Widget? trailing, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[Icon(icon, color: AppTheme.brandOrange, size: 18), const SizedBox(width: 10)],
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF222222))),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, Color color, VoidCallback onTap, bool isPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary ? AppTheme.brandOrange : Colors.white,
            foregroundColor: isPrimary ? Colors.white : const Color(0xFF222222),
            elevation: 0,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFE8E3DB)),
            ),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    final List<Map<String, dynamic>> monthlyData = _stats['monthlyData'] ?? [];
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    // Trouver le maximum pour proportionner les barres (min 1 pour éviter div/0)
    int maxCount = 1;
    for (var d in monthlyData) {
      if (d['count'] > maxCount) maxCount = d['count'];
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyData.map((data) {
        double heightRatio = data['count'] / maxCount;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (data['count'] > 0)
              Text('${data['count']}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.brandOrange)),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 10 + (heightRatio * 100), // Hauteur max de la barre = 110
              decoration: BoxDecoration(
                color: data['count'] > 0 ? AppTheme.brandOrange : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
            const SizedBox(height: 8),
            Text(data['label'], style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRecent() {
    return Column(
      children: [
        Icon(Icons.description_outlined, size: 48, color: Colors.grey.withOpacity(0.2)),
        const SizedBox(height: 16),
        Text('Aucun signalement', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          'Commencez à aider votre communauté en signalant un incident.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: widget.onNavigateToReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandOrange,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Signaler maintenant'),
        ),
      ],
    );
  }

  Widget _buildRecentList() {
    final Map<String, String> catLabels = {
      'theft': 'Vol', 'assault': 'Agression', 'vandalism': 'Vandalisme',
      'suspicious_activity': 'Suspect', 'fire': 'Incendie', 'kidnapping': 'Enlèvement', 'other': 'Autre'
    };
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(flex: 3, child: _tableHeader('Incident')),
              Expanded(flex: 2, child: _tableHeader('Catégorie')),
              Expanded(flex: 2, child: _tableHeader('Date')),
              Expanded(flex: 2, child: _tableHeader('Statut')),
            ],
          ),
        ),
        const Divider(height: 1),
        ...(_stats['recent'] as List<IncidentModel>).map((inc) => InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentDetailPage(incident: inc))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(inc.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: _buildBadge(catLabels[inc.category] ?? inc.category)),
                    Expanded(flex: 2, child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF999999)),
                        const SizedBox(width: 4),
                        Text('${inc.createdAt.day}/${inc.createdAt.month}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF999999))),
                      ],
                    )),
                    Expanded(flex: 2, child: _buildStatusBadge(inc.status)),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        )),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF999999), letterSpacing: 0.5));
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF475569), fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Map<String, Color> colors = {
      'pending': AppTheme.yellow,
      'approved': AppTheme.brandOrange,
      'resolved': AppTheme.blue,
      'rejected': AppTheme.red,
    };
    final Map<String, String> labels = {
      'pending': 'Attente',
      'approved': 'Confirmé',
      'resolved': 'Résolu',
      'rejected': 'Rejeté',
    };
    final color = colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(labels[status] ?? status, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
