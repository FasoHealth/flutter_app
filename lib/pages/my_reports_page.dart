import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/incident_model.dart';

class MyReportsPage extends StatefulWidget {
  final VoidCallback? onNavigateToReport;

  const MyReportsPage({super.key, this.onNavigateToReport});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : const Color(0xFF1E293B);
    final textDim = isDark ? AppTheme.textSecondary : const Color(0xFF64748B);
    final cardBg = isDark ? AppTheme.cardDark : Colors.white;

    // Remove redundant Scaffold
    return Column(
      children: [
        _buildHeader(textColor, textDim),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            color: AppTheme.accentPurple,
            child: FutureBuilder<List<IncidentModel>>(
              future: ApiService.getMyIncidents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: AppTheme.dangerRed)));
                
                final list = snapshot.data ?? [];
                if (list.isEmpty) return _buildEmptyState(textColor, textDim, cardBg);

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _buildReportCard(list[index], cardBg, textColor, textDim),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color textDim) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mes Signalements', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
              Text('Historique de vos contributions à la sécurité.', style: TextStyle(color: textDim, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: widget.onNavigateToReport,
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: const Text('NOUVEAU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, padding: const EdgeInsets.symmetric(horizontal: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(IncidentModel inc, Color cardBg, Color textColor, Color textDim) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(inc.category.toUpperCase(), style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                _statusBadge(inc.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(inc.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 8),
            Text(inc.description, style: TextStyle(color: textDim, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.dangerRed),
                const SizedBox(width: 4),
                Expanded(child: Text(inc.location['address'] ?? 'Lieu inconnu', style: TextStyle(color: textDim, fontSize: 12), overflow: TextOverflow.ellipsis)),
                Text('${inc.createdAt.day}/${inc.createdAt.month}/${inc.createdAt.year}', style: TextStyle(color: textDim.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = AppTheme.warningOrange;
    if (status == 'approved') color = AppTheme.successGreen;
    if (status == 'rejected') color = AppTheme.dangerRed;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(Color textColor, Color textDim, Color cardBg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: textDim.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Aucun historique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('Vos signalements apparaîtront ici une fois envoyés.', textAlign: TextAlign.center, style: TextStyle(color: textDim)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: widget.onNavigateToReport, child: const Text('Signaler un incident')),
          ],
        ),
      ),
    );
  }
}
